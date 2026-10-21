#!/usr/bin/env python3
"""Headless EclipseOS QEMU boot test.

This is deliberately dependency-free (Python standard library only). It:

1. starts QEMU with UEFI (OVMF) or legacy BIOS firmware, with an optional
   VirtualBox-like ``pc`` machine, VMware SVGA adapter and IDE optical drive;
   in direct-kernel mode it can boot an extracted kernel/initrd without a
   ``boot=live`` argument, emulating a rewritten VirtualBox unattended menu;
2. reads the serial console until the live image's boot-check service emits
   ``ECLIPSEOS_BOOT_OK``;
3. rejects a non-zero ``failed_units`` count;
4. requests a framebuffer screenshot over QMP;
5. checks that the screenshot is not an all-black frame;
6. writes a small JSON report and exits non-zero on failure.

The image must contain the Phase 1 ``eclipseos-bootcheck`` service. Without it
this test cannot pass; that is intentional. Do not weaken the marker to make a
broken image look successful.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import time
import zlib
from datetime import datetime, timezone
from pathlib import Path

MARKER = "ECLIPSEOS_BOOT_OK"
FAIL_MARKER = "ECLIPSEOS_BOOT_FAIL"
OVMF_PAIRS = (
    ("/usr/share/OVMF/OVMF_CODE_4M.fd", "/usr/share/OVMF/OVMF_VARS_4M.fd"),
    ("/usr/share/OVMF/OVMF_CODE.fd", "/usr/share/OVMF/OVMF_VARS.fd"),
    ("/usr/share/ovmf/OVMF_CODE.fd", "/usr/share/ovmf/OVMF_VARS.fd"),
)
OVMF_COMBINED = ("/usr/share/ovmf/OVMF.fd", "/usr/share/qemu/OVMF.fd")


def log(message: str) -> None:
    print(f"[test] {message}", flush=True)


def die(message: str, code: int = 1) -> "None":
    print(f"[test] ERROR: {message}", file=sys.stderr, flush=True)
    raise SystemExit(code)


def find_ovmf() -> tuple[str, str | None, str | None]:
    """Return ("pair"|"combined", code, vars)."""
    for code, variables in OVMF_PAIRS:
        if Path(code).is_file() and Path(variables).is_file():
            return "pair", code, variables
    for combined in OVMF_COMBINED:
        if Path(combined).is_file():
            return "combined", combined, None
    die(
        "UEFI firmware not found. Install the 'ovmf' package, or test BIOS "
        "with --firmware bios."
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class Qmp:
    """Tiny QMP client for commands used by this test."""

    def __init__(self, socket_path: Path, timeout: float = 20.0) -> None:
        deadline = time.monotonic() + timeout
        last_error: Exception | None = None
        self.sock: socket.socket | None = None
        while time.monotonic() < deadline:
            try:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.settimeout(10.0)
                sock.connect(str(socket_path))
                self.sock = sock
                break
            except OSError as exc:
                last_error = exc
                time.sleep(0.1)
        if self.sock is None:
            raise RuntimeError(f"could not connect to QMP socket: {last_error}")
        self.file = self.sock.makefile("rwb", buffering=0)
        greeting = self._read_message()
        if "QMP" not in greeting:
            raise RuntimeError(f"unexpected QMP greeting: {greeting!r}")
        self.command("qmp_capabilities")

    def _read_message(self) -> dict:
        assert self.sock is not None
        deadline = time.monotonic() + 20.0
        while time.monotonic() < deadline:
            try:
                line = self.file.readline()
            except socket.timeout:
                continue
            if not line:
                raise RuntimeError("QMP connection closed")
            try:
                message = json.loads(line.decode("utf-8"))
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"invalid QMP message: {line!r}") from exc
            if "event" in message:
                continue
            return message
        raise TimeoutError("timed out waiting for a QMP response")

    def command(self, execute: str, arguments: dict | None = None) -> dict:
        payload: dict[str, object] = {"execute": execute}
        if arguments:
            payload["arguments"] = arguments
        assert self.sock is not None
        self.file.write(json.dumps(payload).encode("utf-8") + b"\n")
        response = self._read_message()
        if "error" in response:
            raise RuntimeError(f"QMP {execute} failed: {response['error']}")
        return response.get("return", {})

    def close(self) -> None:
        try:
            self.file.close()
        except Exception:
            pass
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass


def write_png_from_ppm(ppm_path: Path, png_path: Path) -> None:
    """Convert a QEMU P6 PPM to a dependency-free RGB PNG."""
    data = ppm_path.read_bytes()
    match = re.match(rb"P6\s+(?:#[^\n\r]*[\s\r\n]+)*(\d+)\s+(\d+)\s+(\d+)\s", data)
    if not match:
        raise ValueError("QEMU screenshot is not a P6 PPM")
    width, height, maxval = (int(value) for value in match.groups())
    if maxval != 255:
        raise ValueError(f"unsupported PPM maxval: {maxval}")
    pixels = data[match.end():]
    expected = width * height * 3
    if len(pixels) < expected:
        raise ValueError(f"truncated PPM: have {len(pixels)} of {expected} bytes")
    pixels = pixels[:expected]

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    raw = bytearray()
    stride = width * 3
    for row in range(height):
        raw.append(0)  # PNG filter: none
        start = row * stride
        raw.extend(pixels[start:start + stride])

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    png_path.write_bytes(png)


def capture_screenshot(
    qmp: Qmp, outdir: Path, stem: str, *, inspect: bool = False
) -> tuple[Path, dict | None]:
    """Save one QMP screendump as PNG; the intermediate PPM is removed."""
    ppm_path = outdir / f"{stem}.ppm"
    png_path = outdir / f"{stem}.png"
    try:
        qmp.command("screendump", {"filename": str(ppm_path)})
        if not ppm_path.is_file() or ppm_path.stat().st_size == 0:
            raise RuntimeError("QMP returned no screenshot data")
        info = inspect_ppm(ppm_path) if inspect else None
        write_png_from_ppm(ppm_path, png_path)
        return png_path, info
    finally:
        ppm_path.unlink(missing_ok=True)


def inspect_ppm(ppm_path: Path) -> dict:
    """Report whether the framebuffer contains meaningful content."""
    data = ppm_path.read_bytes()
    match = re.match(rb"P6\s+(?:#[^\n\r]*[\s\r\n]+)*(\d+)\s+(\d+)\s+(\d+)\s", data)
    if not match:
        raise ValueError("QEMU screenshot is not a P6 PPM")
    width, height, maxval = (int(value) for value in match.groups())
    if maxval != 255:
        raise ValueError(f"unsupported PPM maxval: {maxval}")
    pixels = data[match.end():match.end() + width * height * 3]
    if len(pixels) < width * height * 3:
        raise ValueError("truncated PPM")

    total = width * height
    stride_pixels = max(1, total // 100_000)
    non_black = 0
    sampled = 0
    colours: set[tuple[int, int, int]] = set()
    for pixel_index in range(0, total, stride_pixels):
        offset = pixel_index * 3
        rgb = (pixels[offset], pixels[offset + 1], pixels[offset + 2])
        sampled += 1
        if max(rgb) > 24:
            non_black += 1
        colours.add(rgb)

    non_black_ratio = non_black / sampled if sampled else 0.0
    return {
        "width": width,
        "height": height,
        "sampled_pixels": sampled,
        "non_black_ratio": round(non_black_ratio, 6),
        "unique_colours": len(colours),
        "meaningful": non_black_ratio >= 0.002 and len(colours) >= 4,
    }


def tail(path: Path, lines: int = 60) -> str:
    try:
        content = path.read_text(errors="replace").splitlines()
        return "\n".join(content[-lines:])
    except OSError:
        return "<unavailable>"


def qemu_command(args: argparse.Namespace, workdir: Path, qmp_socket: Path,
                 serial_path: Path, qemu_log: Path) -> tuple[list[str], Path | None]:
    iso = Path(args.iso).resolve()
    command = [
        "qemu-system-x86_64",
        "-name", "eclipseos-test",
        "-machine", args.machine,
        "-m", str(args.memory),
        "-smp", str(args.cpus),
    ]

    if args.optical == "ide":
        if args.machine != "pc":
            die("--optical ide requires --machine pc")
        # Secondary IDE master: this is the layout used by the VirtualBox
        # wizard's default IDE optical controller.
        command += [
            "-drive",
            f"if=ide,index=2,media=cdrom,readonly=on,file={iso}",
        ]
    else:
        command += ["-cdrom", str(iso)]

    if args.direct_kernel:
        if not args.kernel or not args.initrd:
            die("--direct-kernel requires --kernel and --initrd")
        kernel = Path(args.kernel).resolve()
        initrd = Path(args.initrd).resolve()
        if not kernel.is_file():
            die(f"kernel not found: {kernel}")
        if not initrd.is_file():
            die(f"initrd not found: {initrd}")
        command += [
            "-kernel", str(kernel),
            "-initrd", str(initrd),
            "-append", args.kernel_append,
        ]
    else:
        command += ["-boot", "order=d,menu=off"]

    command += [
        "-display", "none",
        "-serial", f"file:{serial_path}",
        "-monitor", "none",
        "-qmp", f"unix:{qmp_socket},server=on,wait=off",
        "-snapshot",
        "-no-reboot",
        "-pidfile", str(workdir / "qemu.pid"),
    ]
    if args.vga == "std":
        # The default QEMU std-VGA EDID is 1280x800. EclipseOS evidence must be
        # captured at 1920x1080, so advertise that mode explicitly. The
        # VirtualBox storage-profile test still uses the same std-VGA device.
        command += ["-vga", "none", "-device", "VGA,edid=on,xres=1920,yres=1080"]
    else:
        command += ["-vga", args.vga]

    kvm_usable = (
        sys.platform.startswith("linux")
        and os.path.exists("/dev/kvm")
        and os.access("/dev/kvm", os.R_OK | os.W_OK)
    )
    if kvm_usable:
        command += ["-accel", "kvm", "-cpu", "host"]
        log("Using KVM acceleration")
    else:
        command += ["-accel", "tcg,thread=multi", "-cpu", "max"]
        log("KVM unavailable; using TCG software emulation (slow)")

    vars_copy: Path | None = None
    if args.firmware == "uefi":
        kind, code, variables = find_ovmf()
        if kind == "pair":
            assert variables is not None
            vars_copy = workdir / "OVMF_VARS.fd"
            shutil.copyfile(variables, vars_copy)
            command += [
                "-drive", f"if=pflash,format=raw,unit=0,readonly=on,file={code}",
                "-drive", f"if=pflash,format=raw,unit=1,file={vars_copy}",
            ]
            log(f"UEFI firmware: {code}")
        else:
            command += ["-bios", code]
            log(f"UEFI combined firmware: {code}")
    else:
        log("Legacy BIOS firmware (SeaBIOS)")

    return command, vars_copy


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--firmware", choices=("uefi", "bios"), default="uefi")
    parser.add_argument("--iso", required=True)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--memory", type=int, default=4096)
    parser.add_argument("--cpus", type=int, default=2)
    parser.add_argument(
        "--machine",
        choices=("q35", "pc"),
        default="q35",
        help="QEMU machine type (default: q35; pc for VirtualBox-like IDE)",
    )
    parser.add_argument(
        "--vga",
        choices=("std", "vmware"),
        default="std",
        help="QEMU VGA adapter (default: std; vmware is VMSVGA-like)",
    )
    parser.add_argument(
        "--optical",
        choices=("auto", "ide"),
        default="auto",
        help="Optical attachment (default: q35 -cdrom; ide is secondary master)",
    )
    parser.add_argument(
        "--direct-kernel",
        action="store_true",
        help="Boot the supplied kernel/initrd directly instead of the ISO bootloader",
    )
    parser.add_argument("--kernel", help="Kernel for --direct-kernel")
    parser.add_argument("--initrd", help="Initrd for --direct-kernel")
    parser.add_argument(
        "--kernel-append",
        default="console=tty0 console=ttyS0,115200n8 quiet",
        help="Kernel command line for --direct-kernel (default omits boot=live)",
    )
    parser.add_argument("--outdir", required=True)
    parser.add_argument(
        "--screenshot-interval",
        type=int,
        default=30,
        help="seconds between early diagnostic screenshots (0 disables; default 30)",
    )
    parser.add_argument(
        "--max-screenshots",
        type=int,
        default=10,
        help="maximum number of early screenshots (default 10)",
    )
    args = parser.parse_args()

    iso = Path(args.iso).resolve()
    outdir = Path(args.outdir).resolve()
    if not iso.is_file():
        die(f"ISO not found: {iso}")
    outdir.mkdir(parents=True, exist_ok=True)

    serial_path = outdir / "serial.log"
    qemu_log = outdir / "qemu.log"
    result_path = outdir / "result.json"
    serial_path.write_bytes(b"")
    qemu_log.write_bytes(b"")

    tmpdir = Path(tempfile.mkdtemp(prefix="eclipseos-qemu-"))
    qmp_socket = tmpdir / "qmp.sock"
    command, _ = qemu_command(args, tmpdir, qmp_socket, serial_path, qemu_log)
    log(f"Starting QEMU ({args.firmware})")
    log(" ".join(command))

    started = time.monotonic()
    marker_line = ""
    fail_line = ""
    failed_units: int | None = None
    screenshot_result: dict | None = None
    early_screenshots: list[str] = []
    final_png: Path | None = None
    failure_reason = ""

    with qemu_log.open("wb") as log_handle:
        process = subprocess.Popen(
            command,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )

    qmp: Qmp | None = None
    try:
        try:
            qmp = Qmp(qmp_socket)
        except Exception as exc:
            log(f"warning: QMP not available yet: {exc}")

        deadline = started + args.timeout
        next_status = started + 15
        next_qmp_retry = started + 2
        next_screenshot = started + 8.0
        screenshot_count = 0

        while time.monotonic() < deadline:
            if process.poll() is not None:
                failure_reason = f"QEMU exited early with status {process.returncode}"
                break
            serial_text = serial_path.read_text(errors="replace")
            for line in serial_text.splitlines():
                if FAIL_MARKER in line:
                    fail_line = line.strip()
                    break
                if MARKER in line:
                    marker_line = line.strip()
                    units = re.search(r"failed_units=(\d+)", line)
                    if units:
                        failed_units = int(units.group(1))
                    break
            if marker_line or fail_line:
                break

            now = time.monotonic()
            if qmp is None and now >= next_qmp_retry:
                try:
                    qmp = Qmp(qmp_socket, timeout=2.0)
                except Exception:
                    next_qmp_retry = now + 10.0

            if (
                qmp is not None
                and args.screenshot_interval > 0
                and screenshot_count < args.max_screenshots
                and now >= next_screenshot
            ):
                elapsed_shot = int(now - started)
                stem = f"boot-{screenshot_count + 1:02d}-{elapsed_shot:04d}s"
                try:
                    path, _ = capture_screenshot(qmp, outdir, stem)
                    early_screenshots.append(str(path))
                    log(f"Early screenshot: {path.name}")
                except Exception as exc:
                    log(f"warning: early screenshot failed: {exc}")
                screenshot_count += 1
                next_screenshot = now + args.screenshot_interval

            if now >= next_status:
                elapsed = int(now - started)
                log(f"waiting for boot marker ({elapsed}s elapsed; timeout {args.timeout}s)")
                next_status = now + 15
            time.sleep(1.0)

        elapsed = time.monotonic() - started
        if fail_line:
            reason_match = re.search(r"reason=(\S+)", fail_line)
            failure_reason = "guest reported boot failure"
            if reason_match:
                failure_reason += f": {reason_match.group(1)}"
            failure_reason += f" ({fail_line})"
            log(failure_reason)
        elif not marker_line:
            if not failure_reason:
                failure_reason = f"boot marker not seen within {args.timeout}s"
            log(failure_reason)
        elif failed_units is not None and failed_units != 0:
            failure_reason = f"{failed_units} systemd unit(s) failed in the live session"
            log(failure_reason)
        else:
            log(f"Boot marker seen after {elapsed:.1f}s: {marker_line}")
            time.sleep(8.0)

        if qmp is None:
            try:
                qmp = Qmp(qmp_socket, timeout=2.0)
            except Exception as exc:
                if not failure_reason:
                    failure_reason = f"QMP unavailable for screenshot: {exc}"
                    log(failure_reason)
                else:
                    log(f"warning: QMP unavailable for final screenshot: {exc}")

        if qmp is not None:
            stem = "screenshot" if not failure_reason else "failure-screenshot"
            try:
                final_png, screenshot_result = capture_screenshot(
                    qmp, outdir, stem, inspect=True
                )
                if screenshot_result is None:
                    raise RuntimeError("screenshot inspection returned no data")
                log(
                    "Screenshot: "
                    f"{screenshot_result['width']}x{screenshot_result['height']}, "
                    f"non-black={screenshot_result['non_black_ratio']:.3%}, "
                    f"colours={screenshot_result['unique_colours']}"
                )
                if not failure_reason and not screenshot_result["meaningful"]:
                    failure_reason = "framebuffer screenshot is blank or nearly blank"
                    log(failure_reason)
            except Exception as exc:
                if not failure_reason:
                    failure_reason = f"screenshot failed: {exc}"
                    log(failure_reason)
                else:
                    log(f"warning: final screenshot failed: {exc}")
    finally:
        if qmp is not None:
            try:
                qmp.command("quit")
            except Exception:
                pass
            qmp.close()
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except OSError:
                process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except OSError:
                    process.kill()
        shutil.rmtree(tmpdir, ignore_errors=True)

    duration = time.monotonic() - started
    result = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "firmware": args.firmware,
        "machine": args.machine,
        "vga": args.vga,
        "optical": args.optical,
        "boot_mode": "direct-kernel" if args.direct_kernel else "iso",
        "kernel": str(Path(args.kernel).resolve()) if args.direct_kernel else None,
        "initrd": str(Path(args.initrd).resolve()) if args.direct_kernel else None,
        "kernel_append": args.kernel_append if args.direct_kernel else None,
        "iso": str(iso),
        "iso_sha256": sha256_file(iso),
        "duration_seconds": round(duration, 1),
        "marker": marker_line,
        "failure_marker": fail_line,
        "failed_units": failed_units,
        "screenshot": str(final_png) if final_png else None,
        "screenshot_info": screenshot_result,
        "early_screenshots": early_screenshots,
        "result": "pass" if not failure_reason else "fail",
        "failure_reason": failure_reason,
    }
    result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    log(f"Result written to {result_path}")

    if failure_reason:
        print("\n--- QEMU log (tail) ---", file=sys.stderr)
        print(tail(qemu_log), file=sys.stderr)
        print("\n--- serial log (tail) ---", file=sys.stderr)
        print(tail(serial_path), file=sys.stderr)
        return 1
    log("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

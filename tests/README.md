# EclipseOS tests

Automated tests are a release gate. This directory will grow with the build.

Current tests:

- [`../scripts/test-qemu.sh`](../scripts/test-qemu.sh) — wrapper for headless
  UEFI and BIOS boot tests, plus the VirtualBox storage-profile test (`pc`
  machine, IDE optical drive, 2048 MiB, standard VGA).
- [`qemu_boot_test.py`](qemu_boot_test.py) — QEMU/QMP driver: waits for a
  serial marker from the live desktop, captures early diagnostic screenshots
  and a final framebuffer screenshot, rejects failed units, boot-failure
  markers and blank frames.
- [`../scripts/static-check.sh`](../scripts/static-check.sh) — shell syntax,
  ShellCheck, Python/JSON syntax and desktop-entry validation. Run with
  `make static-check`.
- `installer/` — disposable virtual-disk installation tests, added in Phase 3.
- `screenshots/` — generated captures, never edited to hide failures.

The boot marker is emitted by the `eclipseos-bootcheck` service. The Phase 1
default ISO passed UEFI and BIOS in run #3 at 22.1 s, and the strict ISO passed
both in run #4 at 24.2 s. The final Phase 1 rebuild (run `39547858160`) passed
all three gates: UEFI, BIOS, and the VirtualBox storage profile, the latter at
37.3 s. All Phase 1 markers reported
`ECLIPSEOS_BOOT_OK stage=desktop session=x11 failed_units=0`. Evidence is in
[`../docs/evidence/phase1`](../docs/evidence/phase1/README.md).

The Phase 2 image replaces that session with SDDM and Plasma. Its marker
reports `session=wayland` or `session=x11`, plus `theme=`, `virt=` and
`selection=`. QEMU runs are virtual machines, so the new
`eclipseos-session.service` should make them report
`session=x11 virt=qemu selection=eclipseos-x11` (the exact `virt` value is
provided by `systemd-detect-virt`). A Phase 2 image is not accepted until the
marker and a non-blank 1920x1080 framebuffer are captured from the Plasma
desktop. The first QEMU runs captured 1280x800 only; they are historical
evidence, not Phase 2 acceptance.

### VirtualBox storage-profile coverage

`make test-vbox-uefi` uses the VirtualBox wizard's default storage shape:
UEFI, `pc`, an IDE-attached optical drive, 2048 MiB, and a standard QEMU VGA
adapter. QEMU's `-vga vmware` device is not a substitute for VirtualBox:
Linux detects that it is running under QEMU and `vmwgfx` refuses to probe it,
so the graphical session cannot start. The real VMSVGA path is therefore
covered by the local VirtualBox acceptance test, while QEMU covers the
storage/firmware path.

`make test-vbox-unattended` is a **manual negative control**, not part of
`make test-all`. It boots the extracted kernel and initrd with no `boot=live`
on the command line and is expected to stop in the initramfs. It documents the
rewritten-menu failure mode; it is not a release gate. The positive boot path
and the prevention of VISO creation are the regression checks.

`make test-theme-light` boots the extracted kernel with `boot=live` plus
`eclipseos.theme=light`. It is a manual evidence target, not yet part of
`make test-all`, because light-theme acceptance evidence is still being
collected. The screen resolution remains whatever the QEMU display advertises;
a std-VGA EDID override at 1920x1080 was tested and rejected after it produced
a black framebuffer with only a cursor.

### Serial marker contract

The live image's `eclipseos-bootcheck` service must write a line like this to
`/dev/ttyS0` once the session is actually usable:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark virt=qemu selection=eclipseos-x11 failed_units=0
```

If the session does not start, it writes:

```text
ECLIPSEOS_BOOT_FAIL stage=desktop reason=plasma-not-running
```

The test requires `failed_units=0`. A missing marker, a failure marker, a
non-zero unit count or a blank framebuffer is a test failure. The marker must
not be emitted by a timer that runs before the desktop, and it must not be
faked on a broken image. `session=x11` is expected in QEMU and VirtualBox
because `systemd-detect-virt` reports a VM; `session=wayland` is expected on
physical hardware. `scripts/test-qemu.sh` enforces `--expect-session x11` by
default so a QEMU run cannot silently fall back to the Wayland path this
change is meant to avoid. Either value proves Plasma itself is running.

### Screenshots

The QEMU driver requests a framebuffer dump every 30 seconds (the first at
about 8 seconds, so the GRUB menu is captured), up to 10 early images. It
writes them as `boot-NN-<seconds>s.png`, then saves the final frame as
`screenshot.png` on success or `failure-screenshot.png` on failure. The PPM
intermediate is removed. All captures are diagnostic evidence and are uploaded
by CI.

QEMU tests use TCG when KVM is unavailable. They are slower but still valid;
timing assertions must account for that.

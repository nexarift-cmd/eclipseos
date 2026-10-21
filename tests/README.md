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

The boot marker is emitted by the Phase 1 `eclipseos-bootcheck` service. The
original default ISO passed UEFI and BIOS in run #3 at 22.1 s, and the strict
ISO passed both in run #4 at 24.2 s. The final Phase 1 rebuild (run
`39547858160`) passed all three gates: UEFI, BIOS, and the VirtualBox storage
profile, the latter at 37.3 s. All markers reported
`ECLIPSEOS_BOOT_OK stage=desktop session=x11 failed_units=0`. Evidence is in
[`../docs/evidence/phase1`](../docs/evidence/phase1/README.md).

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

### Serial marker contract

The live image's `eclipseos-bootcheck` service must write a line like this to
`/dev/ttyS0` once the session is actually usable:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 failed_units=0
```

If the session does not start, it writes:

```text
ECLIPSEOS_BOOT_FAIL stage=desktop reason=openbox-not-running
```

The test requires `failed_units=0`. A missing marker, a failure marker, a
non-zero unit count or a blank framebuffer is a test failure. The marker must
not be emitted by a timer that runs before the desktop, and it must not be
faked on a broken image. Phase 2 will report the real Plasma session name.

### Screenshots

The QEMU driver requests a framebuffer dump every 30 seconds (the first at
about 8 seconds, so the GRUB menu is captured), up to 10 early images. It
writes them as `boot-NN-<seconds>s.png`, then saves the final frame as
`screenshot.png` on success or `failure-screenshot.png` on failure. The PPM
intermediate is removed. All captures are diagnostic evidence and are uploaded
by CI.

QEMU tests use TCG when KVM is unavailable. They are slower but still valid;
timing assertions must account for that.

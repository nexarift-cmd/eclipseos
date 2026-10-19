# EclipseOS tests

Automated tests are a release gate. This directory will grow with the build.

Planned tests:

- `test-qemu.sh` — wrapper for headless UEFI and BIOS boot tests.
- `qemu_boot_test.py` — QEMU/QMP driver: waits for a serial marker from the
  live desktop, captures a framebuffer screenshot, and rejects a black or
  non-booting screen.
- `static/` — shell syntax, JSON/XML/QML parsing, desktop-file validation,
  package-list and licence checks.
- `installer/` — disposable virtual-disk installation tests, added in Phase 3.
- `screenshots/` — generated captures, never edited to hide failures.

The boot marker will be emitted by a system service in Phase 1. The test is
not considered passed until it has run against a real built ISO on a Linux
host with QEMU.

### Serial marker contract

The live image's `eclipseos-bootcheck` service must write a line like this to
`/dev/ttyS0` once the session is actually usable:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=wayland failed_units=0
```

The test requires `failed_units=0`. A missing marker, a non-zero unit count or
a blank framebuffer is a test failure. The marker must not be emitted by a
timer that runs before the desktop, and it must not be faked on a broken
image. The service is installed in Phase 1 and refined in Phase 2 when the
real Plasma session exists.

QEMU tests use TCG when KVM is unavailable. They are slower but still valid;
timing assertions must account for that.

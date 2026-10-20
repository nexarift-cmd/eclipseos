# EclipseOS tests

Automated tests are a release gate. This directory will grow with the build.

Current tests:

- [`../scripts/test-qemu.sh`](../scripts/test-qemu.sh) — wrapper for headless
  UEFI and BIOS boot tests.
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
test ran against the built default ISO in GitHub Actions run #3: UEFI and BIOS
both reported the marker after 22.1 s with `failed_units=0`, and both result
files report `"result": "pass"`. The strict ISO also passed both tests in run
#4 at 24.2 s. Evidence is in
[`../docs/evidence/phase1`](../docs/evidence/phase1/README.md).

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

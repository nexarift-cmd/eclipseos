# EclipseOS tests

Automated tests are a release gate. This directory will grow with the build.

Current tests:

- [`../scripts/test-qemu.sh`](../scripts/test-qemu.sh) — wrapper for headless
  UEFI and BIOS boot tests, the 1366x768 fitted-display/panel gate, plus the
  VirtualBox storage-profile test (`pc` machine, IDE optical drive, 2048 MiB,
  standard VGA).
- [`qemu_boot_test.py`](qemu_boot_test.py) — QEMU/QMP driver: waits for a
  serial marker from the live desktop, captures early diagnostic screenshots
  and a final framebuffer screenshot, rejects failed units, boot-failure
  markers, blank frames and, in the 1366x768 gate, a clipped bottom panel.
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
reports `session=wayland` or `session=x11`, plus `theme=`, `theme_status=`,
`applied_theme=`, `display=`, `display_initial=`, `display_mode=`,
`display_output=`, `display_target=`, `display_source=`,
`display_modeline=`, `guard=`, `guard_panel=`, `virt=`, `selection=`,
`vm_tuning=` and `failed_units=`. `display=` is the final framebuffer recorded
by `eclipseos-display` in the live user's runtime directory; `unknown` means
the session did not record a mode.
QEMU runs are virtual machines, so `eclipseos-session.service` makes them
report `session=x11 virt=kvm selection=eclipseos-x11`. The exact `virt` value
is provided by `systemd-detect-virt`; KVM is expected on the CI runner.

Run [40113308256](https://github.com/nexarift-cmd/eclipseos/actions/runs/40113308256)
from branch head `41645a9` is the current Phase 2 QEMU evidence set. It passed
the UEFI, BIOS, 1366x768 panel and VirtualBox-storage-profile gates at
1280x720, plus the 1920x1080 light, dark and SDDM greeter captures. The default
marker was:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop display=1280x720 display_initial=1280x800 display_mode=EclipseOS-1280x720 display_output=Virtual-1 display_target=1280x720 display_source=modeline display_modeline=existing guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The 1366x768 gate started from a 1366x768 EDID mode and reported:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop display=1280x720 display_initial=1366x768 display_mode=EclipseOS-1280x720 display_output=Virtual-1 display_target=1280x720 display_source=modeline display_modeline=existing guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The final marker says `display_modeline=existing` because the pre-Plasma
wrapper and the post-Plasma guard are separate `fit` invocations. The first
invocation added the CVT modeline; the guard found it already present,
re-selected it and re-anchored the panel. The final screenshot is exactly
1280x720, and panel edge detection found the floating panel at rows 663-711
with an 8 px gap. A 1360x768 or any taller result fails the gate.

The light marker was:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=light theme_status=applied applied_theme=light scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.light.desktop display=1920x1080 display_initial=1920x1080 display_mode=unknown display_output=unknown display_target=keep display_source=keep display_modeline=none guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

The light screenshot is genuinely light; the dark capture is dark and shows
Firefox open after the Start-menu launch step. Both are 1920x1080 framebuffer
captures, not upscales, because the visual targets pass
`eclipseos.display=keep`. The light panel was detected at rows 1023-1077 and
the dark panel at 1023-1071; both are fully visible. `scheme=unknown` is
expected after Plasma applies a look-and-feel package: Plasma may remove the
local `ColorScheme` key while retaining the rendered colours. The light gate
checks the successful apply status, the applied theme and the light
look-and-feel; the screenshot is the visual check.

The current run also captured an open Kickoff menu, a `firefox` search result,
and Firefox ESR displaying the offline EclipseOS start page. The greeter
capture shows the branded SDDM screen and the X11 session selection. Those
captures and the result JSONs are in
[`../docs/evidence/phase2`](../docs/evidence/phase2/README.md).

The power-off action and tray-control clicks were not exercised. The power
menu was observed open and the tray icons are visible, but that is not the
same as testing the actions. A Phase 2 image is **not fully accepted** until
the remaining gates in the evidence index are closed.

`eclipseos-bootcheck` reports `stage=greeter session=greeter` instead of
`stage=desktop` when the kernel command line contains
`eclipseos.autologin=off`. In that mode it waits for `sddm-greeter`, not
`plasmashell`, and the SDDM drop-in leaves `User=` empty. This is a test-only
path for greeter evidence; normal live boots still autologin.

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

`make test-theme-light` boots the extracted kernel with `boot=live`, the
`eclipseos.theme=light` one-shot selector and a QEMU std-VGA EDID mode of
1920x1080. `make test-1920-dark` also uses the extracted kernel and captures
the dark desktop at the same resolution. Both pass
`eclipseos.display=keep` so the VM display fitter does not shrink a fixed
screenshot-evidence mode. Both close the welcome terminal with a QMP Alt+F4
before the final screenshot so the taskbar and Start button are visible.

These targets now pass and their captures have been inspected: the light
image is genuinely light and the dark image is dark. They remain separate
visual-evidence steps rather than members of the minimal `make test-all`
boot gate, so a compositor screenshot regression does not hide a core boot
failure. CI still runs and uploads them on every build.

`make test-sddm` boots with `eclipseos.autologin=off`, waits for the SDDM
greeter and captures the branded login screen at 1920x1080. It now passes and
shows `Desktop Session: EclipseOS (X11)`, but a successful greeter marker
does not prove that a real user can log in.

The start-menu automation in `qemu_boot_test.py` opens Kickoff, searches for
`firefox`, launches the browser and captures the result. It is visual evidence
only; it does not click Start-menu power actions or tray controls.

### Serial marker contract

The live image's `eclipseos-bootcheck` service must write a line like this to
`/dev/ttyS0` once the session is actually usable:

```text
ECLIPSEOS_BOOT_OK stage=desktop session=x11 theme=dark theme_status=not-checked applied_theme=not-checked scheme=unknown plasma_theme=default lookandfeel=org.eclipseos.desktop display=1280x720 display_initial=1280x800 display_mode=EclipseOS-1280x720 display_output=Virtual-1 display_target=1280x720 display_source=modeline display_modeline=existing guard=ready guard_panel=1 virt=kvm selection=eclipseos-x11 vm_tuning=1 failed_units=0
```

`display_target=keep` marks a visual-evidence boot that deliberately bypasses
the fitter. `guard=ready guard_panel=1` means the post-Plasma display guard ran
and found a panel; the 1366x768 gate additionally checks the panel edges in the
screenshot. The greeter path writes a similar line with
`stage=greeter session=greeter` and no panel. `vm_tuning=1` means
`eclipseos-vm-tuning.service` detected a VM and applied the compositor
settings; `0` is expected on physical hardware. On a one-shot light boot, the
desktop marker additionally reports `theme_status=applied applied_theme=light`
and `lookandfeel=org.eclipseos.light.desktop`.

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

The optional `--video-edid WxH` flag replaces QEMU's default VGA adapter with
`-device VGA,edid=on,xres=W,yres=H` so a std-VGA guest receives a synthetic
native mode. It is test-only and never changes the ISO. A 1920x1080 PNG is
only accepted as 1920x1080 evidence if the QEMU result JSON and the PNG
dimensions agree; do not upscale a smaller capture.

`--expect-display WxH` verifies the final framebuffer after the guest has
fitted its mode. `--check-panel` scans the final screenshot for the floating
panel's top and bottom edges: both must be on-screen, the panel must be a
plausible height, and it must be horizontally centred. The lowest strong edge
with a small gap below it is treated as the panel bottom; the nearest strong
edge above it is the panel top. This avoids confusing a maximised window's
bottom border with the panel. A panel clipped by the bottom of the framebuffer
has no bottom edge and fails the check.

`make test-1366x768` models the laptop that exposed the bug. QEMU exposes a
1366x768 EDID host mode; the guest session must fit it to 1280x720, and the
final screenshot must be exactly 1280x720 with both panel edges visible. It
passed in run 40113308256: `display_initial=1366x768`, `display=1280x720`,
`display_source=modeline`, and the panel edges were detected at rows 663 and
711. `--video-edid` and `--expect-display` may differ for this reason. The
capture and result JSON are in
[`../docs/evidence/phase2`](../docs/evidence/phase2/README.md).

QEMU tests use TCG when KVM is unavailable. They are slower but still valid;
timing assertions must account for that.

# VirtualBox support and known limitations

Status: **Phase 2 candidate.** This document records what EclipseOS does and does not
provide in VirtualBox. It is deliberately explicit: the "pre-installed
VirtualBox guest utilities" part of the original requirement is **not met**,
and the ISO does not pretend otherwise.

## Summary

| Capability | Status in the EclipseOS ISO | Notes |
| --- | --- | --- |
| Boot in VirtualBox UEFI and BIOS | **Phase 1 verified at 2048 MiB; final Phase 2 ISO not yet re-run** | EFI and BIOS both reached the Phase 1 live desktop on 2026-10-20. The Phase 2 BIOS boot on `768a4f9` reached the desktop at 3000 MiB. 2048 MiB is the acceptance size on this host; 4096 MiB is recommended but could not be started on the 5.1 GB test host. |
| Graphics controller | VMSVGA | Selected by `scripts/create-vbox-vm.sh`; 128 MiB video RAM. |
| Basic desktop rendering | Phase 1 verified at 2048 MiB via X11/openbox; Phase 2 verified in QEMU only | No Oracle Guest Additions required. Performance and maximum resolution depend on the host and VirtualBox version. The final Phase 2 ISO has not been inspected in real VirtualBox. |
| Automatic guest resolution / window resize | **Partial, VM-safe default only** | Host-window resize still requires Guest Additions. The EclipseOS X11 session tries the exact 1280x720 mode first, adds a CVT 1280x720 modeline if it is absent, and only then accepts a smaller advertised mode inside that target. The post-Plasma guard reasserts the fit and re-anchors the bottom panel. VMSVGA's 1280x800 default is taller than a 1366x768 host window. The user can still change mode with `xrandr`; Guest Additions are not bundled. |
| Seamless mouse integration | **Not available** | The guest uses a relative pointer. Use VirtualBox's host key to release the pointer. |
| Shared clipboard | **Not available** | No Guest Additions. Clipboard settings in the VM do nothing useful. |
| Shared folders | **Not available** | No Guest Additions. |
| 3D acceleration | Enabled in the 2 GiB tests; performance unverified | The desktop rendered with the option enabled. If rendering fails, turn 3D off and use the X11 session. |
| USB 3.0 / xHCI | Not enabled by the VM script | The VirtualBox Extension Pack is not distributed with EclipseOS. |
| Secure Boot | **Not tested** | Test with Secure Boot disabled until the signed-boot path is verified in Phase 6. |
| Audio | Expected | Intel HDA emulation. No Guest Additions required. |
| Time synchronisation | systemd-timesyncd over NAT | No Guest Additions time sync. |

## New VM wizard: the unattended-install trap

VirtualBox's **New VM** wizard can create a different optical medium than the
ISO you selected. If the ISO is added in the wizard and **Skip Unattended
Installation** is left unticked, VirtualBox detects the Debian-derived live
image as a Debian installer and builds an auxiliary VISO. The VISO maps a
generated `/boot/grub/grub.cfg` over the live ISO's menu. That generated menu
replaces the kernel command line and **removes `boot=live`**, so the kernel
starts but `initramfs-tools` falls back to `BOOT=local` and stops at a BusyBox
`(initramfs)` prompt. This is not an EclipseOS squashfs or kernel failure.

Reproduction, root cause and final verification are in
[`evidence/phase1/virtualbox-unattended.md`](evidence/phase1/virtualbox-unattended.md).
The fix is in the final Phase 1 ISO (`aade6c67…c397`): VirtualBox reports
`Unattended installation supported = no`, `VBoxManage unattended install`
fails instead of creating a VISO, and the skip path reaches the desktop at
2048 MiB in both EFI and BIOS.

There are three ways to avoid or recover from it:

1. **Use a current EclipseOS ISO.** The build brands `/.disk/info` as
   `EclipseOS ...` instead of `Debian GNU/Linux ...`, so VirtualBox no longer
   offers the Debian unattended path. The live ISO is attached directly.
2. **In the wizard, tick "Skip Unattended Installation".** This keeps the
   original ISO's GRUB menu and its `boot=live` argument.
3. **Attach the ISO after creating the VM.** Create the VM without an ISO,
   then add the ISO to the optical drive in Storage settings. This bypasses
   the wizard's unattended medium entirely.

The live initramfs also defaults to `BOOT=live` as a defence in depth. If an
older VM already has a VirtualBox unattended VISO, replacing the ISO file it
imports with a current build lets that VM boot live again even though the VISO
still supplies the rewritten menu. The `/etc/initramfs-tools/initramfs.conf`
line used to generate that initramfs is restored after the initrd is built, so
an installed system does not inherit `BOOT=live`.

## Why the guest utilities are absent

1. Debian 13 (`trixie`) stable does not ship `virtualbox-guest-utils` in its
   stable archive. The package has appeared in Debian `contrib`/unstable, but
   that is not a stable, supportable input for this release.
2. The official Oracle VirtualBox Guest Additions are licensed under the
   VirtualBox Personal Use and Evaluation License (PUEL), not an open-source
   licence. EclipseOS does not redistribute them.
3. There has been no legal review of a backport of Debian's contrib package.
   Until that review exists, shipping it would violate the project's
   open-source-only policy.
4. The VirtualBox Extension Pack is also PUEL and is not distributed.

This is a licensing and support decision, not an oversight.

## What works without Guest Additions

The open-source Linux stack already contains what a VirtualBox guest needs for
a basic desktop:

- the kernel `vmwgfx` driver drives the VMSVGA adapter;
- Mesa provides OpenGL/software rendering;
- the X11 session (Phase 1: LightDM + openbox; Phase 2: Plasma X11 fallback)
  does not depend on Guest Additions;
- NAT networking, DHCP and DNS work through the emulated Ethernet adapter;
- audio works through the emulated HDA controller;
- the VM can boot from the ISO with EFI or BIOS firmware.

The result is usable for testing the operating system, but it is not the
seamless VirtualBox integration a user gets with Guest Additions.

## Manual workarounds

These are host-side or user-side options, not features of the ISO:

- **Resolution:** the X11 session starts at exactly 1280x720 when the adapter
  advertises it, or adds a CVT 1280x720 modeline when it does not. If that
  fails, it uses the largest advertised mode inside the 1280x720 target. Run
  `xrandr` to list modes or select another mode. Do not expect arbitrary
  host-window resizing; that requires Guest Additions.
  `eclipseos.display=keep` on the kernel command line keeps the adapter
  default, and `eclipseos.display=WxH` requests another target.
- **Pointer:** use the VirtualBox host key (usually Right Ctrl) to release the
  pointer from the guest.
- **File transfer:** attach a second virtual disk, use a network service you
  install yourself, or rebuild the ISO with an extra package. EclipseOS does
  not enable SSH or a file-sharing service by default.
- **3D:** disable 3D acceleration in the VM settings if the desktop is black,
  corrupted or extremely slow, then retry the X11 session.
- **Guest Additions:** a user may install Oracle's Guest Additions manually
  inside a running system. They are not part of EclipseOS, are PUEL-licensed,
  and are not covered by EclipseOS testing.

## What the VirtualBox VM script sets

`scripts/create-vbox-vm.sh` creates a VM with:

- 4096 MiB RAM by default, 2 vCPUs; use `--memory 2048` for the acceptance
  configuration on this 5.1 GB host;
- 128 MiB video RAM, VMSVGA;
- EFI firmware by default (`--no-efi` for BIOS);
- a 25 GiB VDI disk;
- the ISO attached to the SATA optical drive;
- NAT networking.

The script path attaches the ISO directly and is not affected by the wizard's
unattended VISO trap.

It no longer enables clipboard or drag-and-drop modes, because those settings
would only be meaningful with Guest Additions. If you install Guest Additions
yourself, enable those features in VirtualBox afterwards.

## Acceptance status

VirtualBox 7.2.20 booted the Phase 1 ISO in EFI and BIOS modes on 2026-10-20.
Both sessions reached the live X11 desktop, with the GRUB menu and desktop
captured in [`evidence/phase1`](evidence/phase1/README.md). The VM used 2
vCPUs, 128 MiB VMSVGA video and a 25 GiB disk.

Phase 2 QEMU run 40113308256 booted the final candidate seven times, including
three fitted default boots and a 1366x768 EDID/panel gate at 1280x720. That is
QEMU std-VGA evidence, not VirtualBox VMSVGA evidence. The final Phase 2 ISO from
`41645a9` has **not** been booted in real VirtualBox; only the earlier
`768a4f9` ISO reached a VirtualBox BIOS desktop at 3000 MiB. See
[`evidence/phase2`](evidence/phase2/README.md) for the artifact and the
remaining gates.

**2048 MiB is the accepted VirtualBox acceptance size on this host.** The
script's 4096 MiB setting is the recommended configuration, but it could not be
started here: this 5.1 GB host has no hardware-virtualisation passthrough and
cannot allocate the 4 GiB guest. The exact failure is in
[`evidence/phase1/virtualbox-host-limit.txt`](evidence/phase1/virtualbox-host-limit.txt).
4096 MiB remains **recommended but untested** on this host and must be checked
on a larger host or real hardware before being claimed as verified.

The BIOS run's 30-second screenshot showed `vmwgfx` warnings while VirtualBox
was using its Hyper-V/NEM fallback; the desktop was present at 60 seconds.
QEMU uses `-vga std`, so it cannot prove VirtualBox graphics behaviour. This
is recorded as a host-specific observation, not a passed performance test.

## Future work

The guest-utilities question is revisited only if:

- a future Debian stable release ships a redistributable, reviewed guest
  utilities package; or
- the project decides to document a fully user-installed, non-redistributed
  Guest Additions path after a licence review.

Even then, the decision must be recorded in [`licenses.md`](licenses.md), and
the ISO must keep working without the utilities.

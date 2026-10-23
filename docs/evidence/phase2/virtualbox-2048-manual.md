# Phase 2 real VirtualBox boot, 2048 MiB

Status: **passed for the reported boot**, manual evidence. This is not a full
Phase 2 acceptance record: the report did not include a screenshot, a serial
log or a separate firmware-mode run. It predates the Firefox, light/dark,
SDDM and VM-tuning changes; see
[`virtualbox-3000-bios-manual.md`](virtualbox-3000-bios-manual.md) for the
later BIOS report and [`README.md`](README.md) for the final QEMU evidence.

## Image

- Build: GitHub Actions run
  [39693031395](https://github.com/nexarift-cmd/eclipseos/actions/runs/39693031395),
  commit `78474f5`.
- ISO: `eclipseos-26.10-amd64.iso`
- SHA-256:
  `fdf62a578dd0a1fbf842b6102aaf07bedc2bfd5da4db033bc3499d26162cdacc`
- VirtualBox: 7.2.20r175154.
- Guest RAM: 2048 MiB.
- Host: AMD Ryzen 3 2200U, approximately 5 GiB visible RAM.

## Observed by the project owner

The ISO booted into the Plasma desktop. The taskbar, Start menu, desktop
applications and the EclipseOS theme were usable. Networking worked:
`ping debian.org` returned 3 of 3 replies. `free -m` reported 633 MB
available.

There was a slight input/desktop lag. The host has limited RAM and no
hardware-virtualisation passthrough in this configuration. This is recorded as
an observation, not a failure; the guest reached the desktop and remained
usable. The VM tuning change in this branch disables blur, contrast,
translucency and window animations in virtual machines to reduce that cost.

## Limits of this evidence

- The report does not state whether the VirtualBox machine used UEFI or BIOS.
  It therefore does not by itself prove both firmware paths; the QEMU UEFI and
  BIOS gates still cover those paths separately.
- No VirtualBox screenshot or serial log was supplied. The evidence is the
  project owner's manual report.
- VirtualBox Guest Additions are not installed. The open-source guest-utility
  gap remains documented.
- This boot used 2048 MiB. The planned 4096 MiB gate remains untested on this
  host.
- It does not replace the outstanding 1920x1080 light/dark visual evidence,
  the SDDM greeter check, Start-menu interaction evidence or real-hardware
  Wayland verification.

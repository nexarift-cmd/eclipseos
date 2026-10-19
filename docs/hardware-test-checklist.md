# EclipseOS hardware test checklist

Use a disposable machine, spare disk or full backup. Record one row per test
system. Mark each item Pass, Fail, Blocked or N/A and attach evidence.

## Test system record

| Field | Value |
| --- | --- |
| Tester / date | |
| Machine make/model | |
| Firmware version/date | |
| CPU | |
| GPU and driver | |
| Wi-Fi / Ethernet chipsets | |
| Audio codec | |
| Storage model / interface | |
| RAM | |
| Display(s) and resolution | |
| ISO filename | |
| ISO SHA256 | |
| Boot mode | UEFI / BIOS |
| Secure Boot | On / Off / MOK enrolled |
| Installer mode | Erase / Alongside / Manual / LUKS |
| Installed session | Wayland / X11 |
| Result summary | |

## Live media and boot

- [ ] SHA256 of ISO matches the published file.
- [ ] USB written with Rufus / Etcher / dd / other: __________.
- [ ] Firmware boot menu shows the USB entry.
- [ ] UEFI boot reaches GRUB.
- [ ] BIOS/legacy boot reaches GRUB (if supported by machine).
- [ ] GRUB theme renders at native resolution and menu is keyboard-usable.
- [ ] Plymouth splash appears without corruption.
- [ ] Live desktop appears and the live user can log in/auto-login.
- [ ] No failed systemd units: `systemctl --failed`.
- [ ] Boot time from firmware hand-off to desktop: ______ seconds.
- [ ] Screen remains usable after a reboot and a second cold boot.
- [ ] Live session survives removing/reinserting the USB only if expected
      (the live root must remain available).

## Display and graphics

- [ ] Native resolution detected.
- [ ] External display hotplug and mirroring.
- [ ] Wayland session starts.
- [ ] X11 fallback session starts.
- [ ] Window decorations, rounded corners and transparency render correctly.
- [ ] No screen tearing in video playback (record if present).
- [ ] Suspend/resume restores display.
- [ ] Multi-monitor scaling/refresh rates.

## Input

- [ ] Built-in keyboard and touchpad.
- [ ] External USB keyboard and mouse.
- [ ] Fn keys (brightness, volume, airplane mode) where applicable.
- [ ] Touchscreen or pen (if present).
- [ ] Accessibility: screen reader, zoom, sticky keys, high contrast.

## Audio and video

- [ ] Speakers and headphones; automatic switching.
- [ ] Microphone capture.
- [ ] Volume keys and mute.
- [ ] Webcam with a test app.
- [ ] Media playback via Haruna/VLC with hardware decoding off/on.

## Networking

- [ ] Ethernet DHCP and static configuration.
- [ ] Wi-Fi scan, connect, reconnect after suspend.
- [ ] WPA2 and WPA3 networks where available.
- [ ] VPN via NetworkManager (if configured).
- [ ] Bluetooth pairing, audio profile, file transfer.
- [ ] Firewall enabled with default deny inbound.
- [ ] `ping`, DNS and HTTPS work.
- [ ] No unexpected listening services.

## Storage and filesystems

- [ ] Internal NVMe/SATA disk visible in live session.
- [ ] USB storage mount/unmount/eject.
- [ ] TRIM timer enabled on SSD (`systemctl status fstrim.timer`).
- [ ] SMART data readable via the chosen tool.
- [ ] Disk encryption unlock at boot, if used.
- [ ] Read-only filesystem check after unclean shutdown.
- [ ] Free space warning and low-disk behaviour.

## Installer

- [ ] Locale/timezone/keyboard settings persist into installed system.
- [ ] Erase disk install on a disposable disk.
- [ ] Alongside install preserves existing OS and data.
- [ ] Manual partition install with shared ESP.
- [ ] LUKS install and unlock.
- [ ] User account creation requires a real password.
- [ ] Installed system does not retain live passwordless sudo.
- [ ] UEFI boot entry created and boots.
- [ ] BIOS boot works on legacy test machine/VM.
- [ ] Windows dual boot still boots and `os-prober` entry is correct.
- [ ] Installer log has no alarming errors.
- [ ] Failed/cancelled install leaves a recoverable state.

## Installed desktop

- [ ] SDDM greeter appears and accepts the password.
- [ ] Wayland session starts; X11 fallback available.
- [ ] Taskbar, Start menu, search and system tray work.
- [ ] Snap layouts and virtual desktops work.
- [ ] Lock screen locks/unlocks and does not expose another session.
- [ ] Light/dark mode and wallpaper picker persist after logout.
- [ ] Settings pages open; unavailable hardware is reported honestly.
- [ ] Files, terminal, editor, viewer, media player, calculator and browser.
- [ ] Store opens and can install/remove a small package.
- [ ] Update check and install; reboot state is correct.
- [ ] Automatic security updates configured.
- [ ] NTP time sync and locale.

## Power and thermal

- [ ] Suspend, resume, and repeated cycles.
- [ ] Hibernate if configured (not required for 26.10).
- [ ] Lid close behaviour.
- [ ] Battery percentage and charging state.
- [ ] Power profiles switch.
- [ ] Fan/thermal behaviour under a short sustained load.
- [ ] Shutdown and reboot cleanly, no filesystem errors.

## Peripherals

- [ ] USB 2.0 and USB 3.x storage.
- [ ] Printer (USB and network) via CUPS.
- [ ] Scanner if supported.
- [ ] Gamepad/controller (if in scope for the test system).
- [ ] Thunderbolt/USB-C dock and display output.
- [ ] Fingerprint reader (often unsupported; mark N/A if no driver).
- [ ] Webcam privacy switch and media keys.

## Virtualisation

- [ ] VirtualBox UEFI live boot.
- [ ] VirtualBox BIOS live boot.
- [ ] VirtualBox screen resize with VMSVGA.
- [ ] Clipboard/shared folders: record whether Guest Additions are present.
- [ ] QEMU UEFI smoke test and screenshot.
- [ ] QEMU BIOS smoke test and screenshot.
- [ ] 4 GB / 2 vCPU memory pressure test.

## Security and privacy

- [ ] Firewall on after install.
- [ ] No telemetry or analytics traffic observed on a new install.
- [ ] SSH server not listening by default.
- [ ] No default passwords or reused live credentials.
- [ ] APT sources and keys are the expected Debian/EclipseOS sources.
- [ ] Secure Boot state and MOK enrollment documented.
- [ ] Full-disk encryption state verified.
- [ ] Update signatures verified.
- [ ] Crash reporting disabled or explicitly opt-in.

## Evidence

For every failure attach:

- date/time and test ID;
- screenshots or photos;
- relevant journal excerpt (`journalctl -b`, `dmesg`);
- hardware IDs (`lspci -nnk`, `lsusb`, `inxi -Fz` if available);
- whether the issue reproduces in live and installed mode.

## Severity

- **S1:** boot failure, data loss, security bypass, installer destroys wrong
  disk.
- **S2:** major hardware not working, installer failure, unusable desktop.
- **S3:** degraded but usable feature, visual defect with workaround.
- **S4:** cosmetic issue.

Do not ship a release candidate with open S1 issues.

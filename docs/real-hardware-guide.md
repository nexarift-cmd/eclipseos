# EclipseOS real-hardware guide

This guide describes how to prepare and install EclipseOS on a physical
x86_64 PC. It is written for the planned `eclipse-26.10` release. **No
physical-hardware test has been performed yet**; treat early images as
experimental and do not install them on a machine whose data you cannot
restore.

## 1. Read this first

- **Back up first.** Make a second copy of important files on a separate
  drive, not just another partition on the same disk.
- Create a full disk image if you are attempting dual boot, repartitioning or
  encryption.
- Keep the Windows BitLocker recovery key and your Microsoft account
  credentials available if BitLocker is enabled.
- Disconnect any drive that is not part of the installation. One wrong disk
  selection can erase a backup or a second OS.
- The installer's "erase disk" option destroys the selected drive. There is
  no undo.
- Pre-release EclipseOS has not been through a full hardware qualification.
  Do not use it as the only OS on a work machine.
- Laptop firmware updates and storage firmware updates should be completed
  before installation, while the vendor tooling is still available.

## 2. Requirements

- x86_64 PC with UEFI (preferred) or legacy BIOS
- 4 GB RAM minimum; 8 GB recommended
- 25 GB disk minimum; 40 GB or more recommended
- USB flash drive of at least 8 GB (the ISO may be close to 4 GB)
- working network connection for installer updates and optional drivers
- a Linux-compatible keyboard and display

Check firmware settings and device support before wiping anything. Some
Wi-Fi chipsets and NVIDIA GPUs need optional proprietary components; see
[licenses.md](licenses.md).

## 3. Download and verify the ISO

Download both files from the same release:

```text
eclipseos-26.10-amd64.iso
eclipseos-26.10-amd64.iso.sha256
```

### Windows PowerShell

```powershell
Get-FileHash .\eclipseos-26.10-amd64.iso -Algorithm SHA256
Get-Content .\eclipseos-26.10-amd64.iso.sha256
```

The hash must match exactly. The SHA256 file contains a relative filename;
on Windows you can compare the hexadecimal string manually or use `certutil`:

```powershell
certutil -hashfile .\eclipseos-26.10-amd64.iso SHA256
```

### Linux

```bash
cd ~/Downloads
sha256sum -c eclipseos-26.10-amd64.iso.sha256
```

### macOS

```bash
shasum -a 256 eclipseos-26.10-amd64.iso
cat eclipseos-26.10-amd64.iso.sha256
```

If the hashes differ, delete the ISO, download it again and verify before
writing it to USB. Do not use an unverified image on real hardware.

## 4. Write the ISO to a USB drive

Writing an ISO is destructive to the USB drive. There is no need to format it
first; the tool will overwrite it.

### Option A: Rufus (Windows)

1. Download Rufus from the official site and verify its signature.
2. Insert the USB drive and start Rufus.
3. Select the EclipseOS ISO.
4. Use **GPT** partition scheme and **UEFI (non-CSM)** target for a UEFI
   system. For a legacy-only machine, use **MBR** and BIOS mode.
5. Keep the default image-writing mode unless the release notes say
   otherwise. Accept the prompt to download/use the UEFI:NTFS helper only if
   the ISO exceeds the FAT32 file-size limit and the notes explicitly require
   it.
6. Confirm that only the intended USB drive is selected, then write.
7. Wait for verification to finish.

Some very large ISOs cannot be stored as a single >4 GB file on FAT32. If the
EclipseOS ISO exceeds this limit, the release notes will specify the supported
Rufus mode. Do not silently switch to a workaround you do not understand.

### Option B: balenaEtcher (Windows/macOS/Linux)

1. Select **Flash from file** and choose the verified ISO.
2. Select the correct USB target.
3. Click **Flash** and wait for validation.
4. Ignore any Windows prompt to format the newly written USB after Etcher
   finishes; the drive contains a live system, not a normal filesystem.

### Option C: `dd` (Linux/macOS)

Find the device first. This is the step where people destroy their disks.

```bash
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS
```

Identify the USB drive by size and model (for example `/dev/sdc`), not by a
guess. Confirm all its partitions are unmounted:

```bash
sudo umount /dev/sdc* 2>/dev/null || true
```

Write with progress reporting:

```bash
sudo dd if=./eclipseos-26.10-amd64.iso of=/dev/sdc bs=4M \
  status=progress oflag=sync conv=fsync
sync
```

On macOS, use `/dev/rdiskN` (the raw device) and unmount with `diskutil`:

```bash
diskutil list
diskutil unmountDisk /dev/diskN
sudo dd if=./eclipseos-26.10-amd64.iso of=/dev/rdiskN bs=4m
sync
```

**`of=` must be the whole USB device, never a partition such as
`/dev/sdc1`, and never your system disk.** Double-check before pressing
Enter.

### Option D: Ventoy

Ventoy can boot ISOs copied to a prepared Ventoy USB drive. EclipseOS aims to
support normal boot media; if Ventoy fails, re-test with Rufus/Etcher/dd
before reporting a boot bug. Secure Boot mode in Ventoy can change the boot
path and must be disclosed in the bug report.

## 5. Firmware / BIOS setup

Use the vendor's boot-menu key (often F12, F11, F8 or Esc) for one-time boot
selection, and the setup key (often F2, F10 or Del) for permanent settings.

Recommended settings:

- **Boot mode:** UEFI, with CSM/legacy support disabled for a UEFI install.
  Use legacy BIOS only for old hardware or firmware that cannot boot the
  UEFI entry.
- **Secure Boot:** disable for initial testing. Phase 6 targets a signed shim
  and a documented MOK flow. Do not assume the RC image is Secure Boot-ready
  until its release notes say so.
- **Fast Boot:** disabled while learning/testing, so the firmware menus and
  USB boot are reliable.
- **Secure Boot / TPM / BitLocker:** the installer does not use TPM automatic
  unlock in 26.10. If BitLocker is enabled, suspend protection or save the
  recovery key before changing boot order.
- **SATA mode:** AHCI. If Windows was installed in Intel RST/RAID mode,
  changing this can make Windows unbootable; understand the conversion before
  proceeding.
- **Other OS / CSM:** on some boards this is required for legacy boot; it can
  also disable pure UEFI boot.
- **USB boot:** enabled; a USB port directly on the machine is preferable
  during installation.
- **Firmware update:** complete vendor firmware updates first.

If the machine does not offer a UEFI USB boot entry, confirm the ISO checksum,
try another port, temporarily disable Secure Boot, and ensure the USB was
written in the correct mode for the target firmware.

## 6. Boot the live session

1. Insert the USB and power on.
2. Open the boot menu and select the USB device (often prefixed `UEFI:`).
3. Choose **Start EclipseOS Live** in GRUB.
4. Wait for the EclipseOS splash and desktop.
5. The live user is `eclipse` with no password. This is intentionally only
   for the live session.
6. Check display, keyboard, touchpad, Wi-Fi, audio, and storage visibility
   before installing.

An "Install EclipseOS" desktop icon starts the installer. Do not start the
installer until your backups and disk selection are clear.

## 7. Dual-boot warnings

EclipseOS plans to support "install alongside" and manual partitioning, but
these are the highest-risk paths.

- **Back up Windows and make a full disk image.** Partition changes can fail
  after a power loss or firmware bug.
- Turn off Windows **Fast Startup** and perform a full shutdown before
  installing, so NTFS is not left hibernated.
- If using BitLocker, suspend it or keep the recovery key. Changing the boot
  order can trigger a recovery prompt on the next Windows boot.
- Shrink the Windows partition from Windows Disk Management, then leave
  **unallocated space**. Do not create an extra partition for EclipseOS with
  a Windows tool unless the installer instructions explicitly say to.
- Use "alongside" only when the free space is already correct and the target
  disk is unambiguous.
- Manual partitioning: keep the existing EFI System Partition; do not format
  it. Add only the needed root/swap/EFI entries. On a UEFI system, a shared ESP
  is normal.
- Do not install GRUB over a disk whose bootloader layout you do not
  understand. The installer will show its target; read it.
- Windows feature updates can reset the firmware boot order. Use the firmware
  boot menu to select EclipseOS and repair with `efibootmgr` if needed.
- Legacy BIOS dual boot requires careful MBR handling; UEFI is the supported
  primary path.
- Never choose "erase disk" when dual booting.

If you are not confident, install EclipseOS on a blank disk or a virtual
machine first.

## 8. Installer choices

The installer will ask for:

- language, region, keyboard;
- disk mode: erase, alongside, or manual;
- optional full-disk encryption (LUKS);
- user account, hostname and a real password;
- optional NVIDIA/firmware packages;
- a final summary and destructive-operation confirmation.

Confirm that:

- the selected disk is the correct one;
- the EFI System Partition is the existing ESP on a UEFI dual-boot system;
- encryption passphrases are recorded **off** the machine (the passphrase
  cannot be recovered if lost);
- the user password is strong and not reused;
- the bootloader target and boot order are what you expect.

The installed system will not auto-login and will not retain the live
session's passwordless sudo policy.

### LUKS notes

Full-disk encryption protects data at rest when powered off. It does not
protect a running unlocked system. There is no TPM auto-unlock in 26.10;
expect to enter the passphrase at boot. Keep a written recovery passphrase in
a secure place separate from the PC. A lost passphrase means permanent data
loss.

## 9. First boot and post-install

- Remove the USB when prompted, or select the internal disk in the firmware
  boot menu.
- Log in at the EclipseOS greeter with the account created by the installer.
- Connect to the network and apply updates.
- Verify that the firewall is active and automatic security updates are
  configured.
- Check suspend/resume only after saving your work.
- Test sound, Bluetooth, webcam, printing and external displays one device at
  a time.
- Do not disable Secure Boot or the firewall permanently to work around a
  driver issue; record the issue and use the hardware checklist.

## 10. Troubleshooting

### Blank screen after GRUB

Try the X11 fallback session or add `nomodeset` temporarily to the kernel
command line in GRUB. On NVIDIA systems, the open-source `nouveau`/Mesa path
may be insufficient; install the optional NVIDIA driver only after booting a
working session. Record the GPU model and driver version.

### Wayland desktop fails

At the login screen choose the "EclipseOS on X11" session. Include the
session type and `journalctl --no-pager -b` output in the report.

### Wi-Fi not detected

Check `lspci -nnk` and the hardware checklist. Some chipsets require
non-free firmware or are unsupported. Ethernet or USB tethering can provide
network access for diagnostics.

### Installer cannot find the disk

Check the SATA/NVMe mode and whether the firmware presents the disk in RAID
or Intel RST mode. Some laptops require disabling RST or installing a driver.
Do not convert a Windows RAID layout without a backup and a clear recovery
plan.

### System will not boot after install

Use the firmware boot menu, check the ESP contents, and boot the live ISO to
run diagnostics. Do not repeatedly reinstall over unknown partitions. If
dual booting, verify Windows still boots independently and that its recovery
key is available.

### Secure Boot

Initial images are expected to require Secure Boot disabled. A future signed
build will require enrolling the EclipseOS certificate in MOK or relying on
the signed shim. Do not assume third-party NVIDIA modules are signed; MOK
enrollment may be required after installing them.

## 11. Backup-first checklist

Before you touch the installer:

- [ ] Important files copied to a separate external drive.
- [ ] Full disk image or at least a Windows system image created.
- [ ] Windows/BitLocker recovery key saved and accessible.
- [ ] Windows Fast Startup disabled.
- [ ] Firmware version and model recorded.
- [ ] USB drive verified and ISO SHA256 matches.
- [ ] Target disk serial/size written down.
- [ ] Other drives disconnected or clearly identified.
- [ ] Free space for dual boot prepared in Windows, if applicable.
- [ ] A second machine or phone is available to read recovery instructions.
- [ ] You accept that early EclipseOS builds may fail and require recovery.

If any line cannot be checked, stop and resolve it before installing.

## 12. Reporting hardware results

Include:

- exact PC/laptop model and firmware version;
- CPU, GPU, Wi-Fi/Ethernet, audio and storage models;
- EclipseOS ISO name and SHA256;
- UEFI or BIOS, Secure Boot state;
- installer mode (erase, alongside, manual, LUKS);
- a photo or screenshot of the failure where possible;
- `journalctl --no-pager -b`, `dmesg`, `lspci -nnk`, `lsusb`;
- whether the issue reproduces in the live session and/or installed system.

Use the structured checklist in
[`hardware-test-checklist.md`](hardware-test-checklist.md).

EclipseOS 26.10 - live image
============================

This is a bootable EclipseOS live image built from Debian GNU/Linux 13
("trixie") with the Debian live-build tooling. It is a Phase 2 preview: the
desktop session is Plasma 6 with SDDM. Physical machines use Wayland by
default; virtual machines are switched to Plasma X11 automatically by
systemd-detect-virt. Phase 2 visual polish, VirtualBox acceptance and
1920x1080 light/dark evidence are still in progress.

Boot it as a CD/DVD or write it to a USB device. Both UEFI and legacy BIOS
firmware are supported. The image is hybrid: the same file boots from optical
media, a USB stick and virtual machines.

Live session
  User:      eclipse
  Password:  none (the account is live-only)
  Sudo:      passwordless, for the live session only

The live user is intentionally unauthenticated and must not be used on an
installed system. The Phase 3 installer will require a real password for the
installed user and will not copy the live account.

Checksums
  eclipseos-26.10-amd64.iso.sha256 is published next to this image. Verify it
  before booting:
      sha256sum -c eclipseos-26.10-amd64.iso.sha256

Licensing
  The complete component inventory and every non-free firmware exception are
  documented in /usr/share/doc/eclipseos/ on the running system and in
  docs/licenses.md in the source repository. No proprietary driver, Oracle
  VirtualBox Guest Additions or VirtualBox Extension Pack is distributed with
  this image.

Virtual machines
  VirtualBox: use EFI, at least 2 GiB RAM (4 GiB recommended), 2 CPUs,
  128 MiB video, VMSVGA graphics. EclipseOS selects Plasma X11 in VirtualBox.
  QEMU: `make test-all` in the source repository boots this image headlessly
  with UEFI (OVMF) and legacy BIOS firmware. QEMU also selects Plasma X11.
  QEMU cannot validate VirtualBox VMSVGA or real-hardware Wayland.

"Windows 11" is a trademark of Microsoft Corporation. EclipseOS is not
affiliated with Microsoft and contains no Microsoft assets.

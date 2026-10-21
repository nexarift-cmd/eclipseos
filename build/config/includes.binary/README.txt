EclipseOS 26.10 - live image
============================

This is a bootable EclipseOS live image built from Debian GNU/Linux 13
("trixie") with the Debian live-build tooling. It is a Phase 2 preview: the
desktop session is Plasma 6 with SDDM, Wayland by default and Plasma X11 as the
fallback. Phase 2 visual polish and acceptance are still in progress.

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
  VirtualBox: use EFI, 4 GiB RAM, 2 CPUs, 128 MiB video, VMSVGA graphics.
  QEMU: `make test-all` in the source repository boots this image headlessly
  with UEFI (OVMF) and legacy BIOS firmware.

"Windows 11" is a trademark of Microsoft Corporation. EclipseOS is not
affiliated with Microsoft and contains no Microsoft assets.

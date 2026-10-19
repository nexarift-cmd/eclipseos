# Live-build configuration

This directory will contain the Debian `live-build` tree used by
`scripts/build.sh`. It is intentionally incomplete in Phase 0; no ISO has been
built.

Planned contents:

```text
auto/
  config                    # lb config options (hybrid ISO, archives, bootloaders)
  build                     # optional pre/post build wrapper
  clean                     # optional clean wrapper
config/
  package-lists/
    eclipse-base.list.chroot
    eclipse-desktop.list.chroot
    eclipse-apps.list.chroot
    eclipse-installer.list.chroot
    eclipse-vm.list.chroot
  includes.chroot/          # branded files, defaults, services, policy, apps
  hooks/
    0100-branding.hook.chroot
    0200-services.hook.chroot
    0300-licences.hook.chroot
    0400-cleanup.hook.chroot
    9000-verify.hook.chroot
  archives/
    trixie.pinned.list.chroot   # release snapshot, added in Phase 6
  bootloaders/
    grub-pc/                # BIOS GRUB config/theme
    grub-efi/               # UEFI GRUB config/theme
    theme/                  # shared EclipseOS GRUB assets
  includes.binary/          # ISO-level BRANDING/README/metadata
```

Rules:

- Package lists are curated; no meta-package is included without checking its
  dependency set.
- Hooks must be non-interactive, idempotent and fail the build on error.
- No secrets, personal data or build-host paths may be written into the ISO.
- Every proprietary or redistributable-firmware exception is declared in
  `docs/licenses.md`.
- A clean build must work from a fresh checkout using `make iso`.
- The live user is `eclipse`; no installed-system password may be baked in.

The minimal Phase 1 configuration will be added only when a Debian 13 build
host is available. See [`../docs/build-environment.md`](../docs/build-environment.md).

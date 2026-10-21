# Live-build configuration

This is the Debian `live-build` tree used by `scripts/build.sh`. It contains
the **Phase 2** desktop preview: hybrid UEFI/BIOS boot, GRUB/Plymouth branding,
SDDM autologin as `eclipse`, and a Plasma 6 desktop with Wayland as the default
session and X11 as the fallback. The Phase 1 LightDM/Openbox session has been
removed. See [`../docs/roadmap.md`](../docs/roadmap.md) for acceptance status.

## Layout

```text
auto/
  config                    # lb config options (hybrid ISO, archives, bootloaders)
config/
  package-lists/
    eclipse-base.list.chroot
    eclipse-desktop.list.chroot
    eclipse-firmware.list.chroot.in   # template -> .list.chroot at build time
    live.list.chroot                  # explicit comment-only file; stops live-config
  includes.chroot/          # baked identity, user, services, session, themes
  hooks/normal/
    0100-branding.chroot
    0200-services.chroot
    0300-licences.chroot
    9900-verify.chroot
  bootloaders/grub-pc/      # shared by BIOS and UEFI GRUB
    config.cfg
    grub.cfg
    theme.cfg
    live-theme/theme.txt
    splash.png              # generated
    unicode.pf2             # copied from grub-common
  includes.binary/
    README.txt              # ISO-level note
```

## Generated inputs

`scripts/build.sh` produces these before `lb config`/`lb build`. All are
gitignored:

- `branding/assets/*.png|svg` from `branding/render.py`;
- `config/includes.chroot/usr/share/backgrounds/eclipseos/` wallpaper;
- `config/includes.chroot/usr/share/pixmaps/eclipseos/` user icon;
- `config/includes.chroot/usr/share/plymouth/themes/eclipseos/{splash,logo}.png`;
- `config/bootloaders/grub-pc/{splash.png,unicode.pf2}`;
- `config/package-lists/eclipse-firmware.list.chroot` (omitted entirely when
  `STRICT_FOSS=1`);
- `config/includes.chroot/usr/share/doc/eclipseos/{copyright,licenses.md,version}`.

`make assets` renders the brand files alone. `make clean` removes all generated
inputs.

## Rules

- Package lists are curated; no meta-package is included without checking its
  dependency set.
- Hooks are plain `sh`, non-interactive, idempotent and fail the build on
  error. They are named `NNNN-name.chroot` (not stock `.hook.chroot` names) so
  they sort predictably and are not caught by stock-hook gitignore patterns.
- `/etc/hosts`, `/etc/resolv.conf` and `/etc/hostname` live in
  `includes.chroot`. live-build's `chroot_prep` re-copies them after hooks;
  writing them only from a hook would be overwritten.
- `live-config` is deliberately not installed. The explicit comment-only
  `live.list.chroot` prevents `lb config` from auto-generating a list that
  includes it.
- No secrets, personal data or build-host paths may be written into the ISO.
- Every non-free firmware package is declared in
  [`../docs/licenses.md`](../docs/licenses.md) and in the allowlist in
  `0300-licences.chroot`.
- A clean build must work from a fresh checkout using `make iso`.
- The live user is `eclipse`; no installed-system password may be baked in.

## Hook order

Stock live-build hooks are symlinked into `config/hooks/normal/` by
`lb config`. They run in lexicographic order around the EclipseOS hooks:

1. `0100-branding` — identity, hostname, timezone, live user, sudoers;
2. `0200-services` — enable LightDM, NetworkManager, timesyncd and bootcheck;
3. stock `1000`–`9000` hooks — system maintenance and cleanup;
4. `0300-licences` — package manifest and non-free policy gate;
5. `9900-verify` — final assertions before squashfs creation.

The number ranges intentionally leave room for Phase 2+ hooks without
renumbering.

## Bootloader notes

`config/bootloaders/grub-pc/` is used for both firmware paths: live-build's
`binary_grub_cfg` sources this directory for BIOS and UEFI. `theme.cfg`
selects the theme only when both `live-theme/theme.txt` and `splash.png`
exist, otherwise GRUB falls back to plain colours.

`grub.cfg` is a template. live-build substitutes `@LINUX_LIVE@` with the
generated live entries and the other `@...@` placeholders before packing the
ISO. Do not replace it with a static menu.

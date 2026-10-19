# EclipseOS branding

All product artwork in this repository is original and released under the
project licence (GPL-3.0-or-later). No Microsoft assets are permitted or used.

## Phase 1 assets

`branding/tokens.json` is the source of truth for the palette. `render.py`
renders the Phase 1 artwork with the Python standard library only (no Pillow,
Cairo or SVG dependency). The generated PNGs are not committed; `make iso`
runs the renderer and stages them into the live-build tree.

Current outputs:

```text
branding/
├── render.py                             # deterministic, dependency-free renderer
├── tokens.json                           # palette and geometry tokens
└── assets/                               # generated, gitignored
    ├── eclipseos-wallpaper-1920x1080.png
    ├── eclipseos-grub-splash-1024x768.png
    ├── eclipseos-plymouth-splash-1920x1080.png
    ├── eclipseos-progress-track.png      # Plymouth progress bar track (360x4)
    ├── eclipseos-progress-fill.png       # Plymouth progress bar fill (360x4)
    ├── eclipseos-mark.png                # 1024x1024 RGBA
    ├── eclipseos-mark-256.png            # 256x256 RGBA
    └── eclipseos-logo.svg
```

The GRUB splash, Plymouth splash, progress bar, wallpaper and mark are used by
`build/config/bootloaders/grub-pc/` and the Plymouth theme in
`build/config/includes.chroot/`. `scripts/build.sh` copies them into place and
`9900-verify.chroot` fails the build if they are missing.

The Eclipse motif is a dark occluding disc inside a violet-to-amber corona.
The mark is designed to remain legible at small sizes and as a single-colour
glyph. Inter (SIL OFL 1.1) is the UI font; DejaVu and Liberation are fallbacks.

## Planned assets (Phase 2 and later)

The full product will add application icons, place icons, SDDM theme assets,
light/dark wallpaper variants and QML theme images. Those are not part of the
Phase 1 live ISO and will be generated from the same tokens where practical.

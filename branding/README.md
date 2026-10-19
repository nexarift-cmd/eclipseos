# EclipseOS branding

All product artwork is original and will be released under the project
licence. No Microsoft assets are permitted.

Planned assets:

```text
branding/
├── logo/
│   ├── eclipseos-mark.svg          # standalone symbol
│   ├── eclipseos-wordmark.svg      # symbol + EclipseOS typography
│   └── eclipseos-monochrome.svg
├── wallpapers/
│   ├── eclipseos-dawn.svg          # default light
│   ├── eclipseos-midnight.svg      # default dark
│   └── exports/                    # PNG/JPEG rendered at product sizes
├── icons/
│   ├── apps/                       # original app icons for Eclipse apps
│   └── places/                     # Eclipse Files sidebar icons
├── grub/
│   ├── background.svg
│   ├── theme.txt
│   └── fonts/
├── plymouth/
│   ├── eclipseos.plymouth
│   ├── eclipseos.script
│   └── assets/
├── sddm/
│   └── eclipseos/                  # QML theme assets
└── tokens.json                     # design tokens / palette / spacing
```

Identity brief:

- Eclipse motif: a dark occluding disc inside a corona of violet-to-amber
  light. The mark must remain legible at 16 px and as a single-colour glyph.
- Default accent: a deep violet to warm amber gradient; UI surfaces use a
  neutral violet-black rather than pure black in dark mode.
- Type: Inter (SIL OFL) with Debian fallbacks; clean, not a Segoe copy.
- Corners: 8 px for windows and large panels, 12–16 px for floating surfaces.
- Motion: short (120–200 ms) ease-out transitions; no motion that traps input.
- Accessibility: AA contrast in both themes, non-colour state indicators,
  reduced-motion support.
- Wallpapers: abstract eclipse/corona fields with enough negative space for
  taskbar and desktop icons; no photographic Microsoft derivatives.

`tokens.json` is the source of truth for palette and geometry in Phase 2.
Raster exports for GRUB/Plymouth/SDDM will be generated reproducibly from the
SVG sources and checked in only if the build tool cannot render SVG.

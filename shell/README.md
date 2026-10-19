# EclipseOS desktop shell

The shell is built on KDE Plasma 6.3 rather than a new compositor. This keeps
Wayland/X11 plumbing, screen sharing, input methods, accessibility, tray
protocols and hardware support in the hands of a mature upstream while the
visible EclipseOS layer remains custom.

Planned layout:

```text
shell/
├── layout/
│   ├── eclipseos-panel.conf
│   └── eclipseos-desktop.js          # Plasma layout script
├── plasmoids/
│   ├── org.eclipseos.startmenu/      # Start menu QML
│   ├── org.eclipseos.taskview/       # optional task view overlay
│   └── org.eclipseos.widgets/        # weather, clock, calendar panel
├── kwin/
│   ├── eclipseos-snaplayouts/        # KWin script + QML overlay
│   └── eclipseos-animations/         # effect timing / rounded corners
├── look-and-feel/
│   └── org.eclipseos.desktop/        # colours, decoration, splash, lock screen
├── sddm/
│   └── eclipseos/                    # QML greeter theme
├── desktop/
│   ├── eclipseos-install.desktop
│   ├── eclipse-files.desktop
│   └── ...
└── README.md
```

Design constraints:

- Original branding only; no Microsoft logos, icons, fonts or wallpapers.
- Start menu, taskbar and window behaviour are functionally inspired by
  modern desktop conventions, not pixel-copied from Windows.
- The shell must work on Plasma Wayland and provide an X11 fallback.
- Every animation must degrade safely under software rendering.
- The panel must remain usable at 1024x768 and with multiple monitors.
- Keyboard navigation and screen-reader labels are required, not optional.
- The installed user's session must never inherit live-session autologin or
  sudo rules.
- Snap layouts use KWin APIs; if a feature is not feasible on both session
  types, the X11 fallback is documented rather than silently broken.

Phase 2 creates the theme, layout and Start menu. Phase 5 adds the snap-layout
overlay, widgets and final animation tuning.

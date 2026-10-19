# Calamares installer

Phase 3 will implement the installer configuration and branding. This
directory is a Phase 0 scaffold.

Planned layout:

```text
installer/
├── config/
│   ├── settings.conf
│   ├── modules/
│   │   ├── welcome.conf
│   │   ├── locale.conf
│   │   ├── keyboard.conf
│   │   ├── partition.conf
│   │   ├── users.conf
│   │   ├── packages.conf
│   │   ├── summary.conf
│   │   ├── finished.conf
│   │   └── bootloader.conf
│   └── branding/
│       └── eclipseos/
│           ├── branding.desc
│           ├── logo.png
│           ├── welcome.png
│           ├── stylesheet.qss
│           ├── show.qml
│           └── slideshow/
├── scripts/
│   └── eclipse-installer       # PolicyKit-aware launcher
└── README.md
```

Requirements:

- Windows-setup-style sequence but original EclipseOS visual assets.
- Erase, alongside and manual disk modes.
- Destructive operations require explicit selection and a final summary.
- LUKS full-disk encryption is optional.
- Real password required for the installed account.
- UEFI and BIOS bootloader installation tested in disposable VMs.
- NVIDIA/firmware package selection is explicit and licence-visible.
- No automatic repartitioning, no telemetry, no hidden network calls.
- Installer logs must be available on failure.

Do not fork Calamares unless a required upstream capability is genuinely
missing. Prefer its supported modules and QML branding.

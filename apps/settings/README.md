# Eclipse Settings

Phase 4 application. Planned stack: **C++ / Qt 6 / QML**, packaged as
`eclipse-settings`.

Pages:

- Network — NetworkManager D-Bus, Wi-Fi, Ethernet, VPN state
- Display — KScreen, resolution, scale, refresh, arrangement
- Sound — PipeWire/WirePlumber devices, volume, profiles
- Personalization — accent, light/dark, wallpaper, theme, panel
- Accounts — AccountsService, profile image, password via PolicyKit
- Apps — installed applications, defaults, removals via PackageKit
- Time & Language — timedated/localed
- Privacy — location, camera/microphone portal state, recent files
- Updates — Eclipse Update integration
- About — OS, kernel, Plasma/Qt, hardware, licence notices

Non-goals:

- Reimplementing NetworkManager or PipeWire.
- Storing passwords itself.
- Running the whole UI as root.
- Claiming a setting was applied when the backend rejected it.

The app must report unavailable hardware and missing permissions clearly, and
must be keyboard-navigable. Privileged changes use narrow PolicyKit actions.

Source and packaging are added in Phase 4 after the base desktop is proven.

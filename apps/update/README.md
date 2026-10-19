# Eclipse Update

Phase 4 application. Planned stack: **C++ / Qt 6 / QML** front-end plus a
narrowly scoped PolicyKit-authorized helper over APT.

Responsibilities:

- refresh APT metadata with user-visible progress and cancellable network
  operations;
- show security updates first, with severity, size and reboot requirement;
- require explicit confirmation before installing;
- display the real APT error, not a generic success state;
- never add unsigned repositories or signing keys;
- never silently enable telemetry or proprietary drivers;
- integrate with `unattended-upgrades` for security-only automatic updates.

The privileged helper validates arguments, uses a fixed allow-list of APT
operations and writes a log that the UI can display. No general-purpose root
shell is exposed.

Discover/Eclipse Store remains the place to browse and install applications;
Eclipse Update focuses on system package updates and security.

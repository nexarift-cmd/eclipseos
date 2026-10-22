// EclipseOS Start menu defaults. Kickoff favorites are menu IDs, not
// applications: URLs. Keep only applications that are part of the Phase 2
// desktop so the menu does not advertise packages that are not installed.

applet.currentConfigGroup = ["General"];
applet.writeConfig("icon", "eclipseos");
applet.writeConfig("favoritesPortedToKAstats", false);
applet.writeConfig("favorites", [
    "firefox-esr.desktop",
    "org.kde.dolphin.desktop",
    "org.kde.konsole.desktop",
    "org.kde.kate.desktop",
    "systemsettings.desktop",
    "org.kde.kinfocenter.desktop"
]);
applet.currentConfigGroup = [];

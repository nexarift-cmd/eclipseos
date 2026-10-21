// EclipseOS default Plasma layout.
//
// Windows 11-inspired: the taskbar sits at the bottom, uses a centred
// alignment, and starts with the EclipseOS launcher followed by pinned and
// running applications, the system tray, the clock and Show Desktop.
//
// This file is executed by Plasma's layout engine on a fresh profile. Keep it
// compatible with Plasma 6.3 (Debian 13) and avoid importing third-party QML.

var panel = new Panel
panel.location = "bottom"
panel.height = 48
panel.alignment = "center"

var kickoff = panel.addWidget("org.kde.plasma.kickoff")
kickoff.currentConfigGroup = ["General"]
kickoff.writeConfig("icon", "eclipseos")

var tasks = panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers",
    "applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop,applications:systemsettings.desktop")

panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity())
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image"
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
    desktopsArray[j].writeConfig("Image", "file:///usr/share/backgrounds/eclipseos/eclipseos-wallpaper-1920x1080.png")
}

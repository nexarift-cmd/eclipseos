// EclipseOS default Plasma layout.
//
// Windows 11-inspired: a floating, centred bottom taskbar with the EclipseOS
// launcher, pinned/running applications, the system tray, the clock and Show
// Desktop. Fit-to-content plus centre alignment keeps the launcher group
// centred instead of stretching it across the screen.
//
// This file is executed by Plasma's layout engine on a fresh profile. Keep it
// compatible with Plasma 6.3 (Debian 13) and avoid importing third-party QML.

var panel = new Panel
panel.location = "bottom"
panel.height = 48
panel.lengthMode = "fit"
panel.alignment = "center"
panel.offset = 0
panel.floating = true
panel.opacity = "translucent"

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity())
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image"
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
    desktopsArray[j].writeConfig("Image", "file:///usr/share/backgrounds/eclipseos/eclipseos-wallpaper-light-1920x1080.png")
}

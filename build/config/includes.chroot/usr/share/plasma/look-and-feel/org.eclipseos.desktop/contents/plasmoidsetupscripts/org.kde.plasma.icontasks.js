// Set the EclipseOS pinned applications before the Icons-Only Task Manager
// reads its launcher list. Writing these via the layout script is too late:
// the task manager has already loaded its configuration by then.

applet.currentConfigGroup = ["General"];
applet.writeConfig("launchers",
    "applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:org.kde.kate.desktop,applications:systemsettings.desktop");
applet.currentConfigGroup = [];

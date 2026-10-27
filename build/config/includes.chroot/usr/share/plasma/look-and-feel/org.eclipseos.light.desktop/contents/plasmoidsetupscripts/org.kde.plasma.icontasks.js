// Set the EclipseOS pinned applications before the Icons-Only Task Manager
// reads its launcher list. Writing these via the layout script is too late:
// the task manager has already loaded its configuration by then.
//
// `launchers` is a QStringList in Plasma's configuration schema. Passing a
// comma-joined string here stores one invalid entry, which Plasma renders as
// a single generic page icon; the JavaScript array is converted to a string
// list and keeps the individual application launchers intact.

applet.currentConfigGroup = ["General"];
applet.writeConfig("launchers", [
    "applications:firefox-esr.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:systemsettings.desktop"
]);
applet.currentConfigGroup = [];

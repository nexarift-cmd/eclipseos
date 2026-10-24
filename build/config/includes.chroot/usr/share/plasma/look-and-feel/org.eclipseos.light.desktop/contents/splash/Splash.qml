import QtQuick 2.15

Rectangle {
    id: root
    color: "#0B0714"

    Image {
        anchors.fill: parent
        source: "file:///usr/share/backgrounds/eclipseos/eclipseos-wallpaper-1920x1080.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.55
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "EclipseOS"
            color: "#F5F1FA"
            font.family: "Inter"
            font.pixelSize: 44
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Your desktop, in a new light."
            color: "#C9C1D8"
            font.family: "Inter"
            font.pixelSize: 16
        }
    }
}

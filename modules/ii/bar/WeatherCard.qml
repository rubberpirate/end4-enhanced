import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.small
    property color bgColor: Appearance.colors.colSurfaceContainerHigh
    property color fgColor: Appearance.colors.colOnSurfaceVariant
    color: "transparent" 
    
    implicitWidth: columnLayout.implicitWidth + 14 * 2
    implicitHeight: columnLayout.implicitHeight + 10 * 2
    Layout.fillWidth: true
    property alias title: title.text
    property alias value: value.text
    property alias symbol: symbol.text

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: (root.title === "Sunrise" || root.title === "Sunset") ? "transparent" : root.bgColor

        gradient: {
            if (root.title === "Sunrise") {
                return sunriseGradient;
            } else if (root.title === "Sunset") {
                return sunsetGradient;
            } else {
                return null;
            }
        }
    }

    Gradient {
        id: sunriseGradient
        GradientStop { 
            position: 0.0; 
            color: Appearance.m3colors.m3tertiaryFixed || Appearance.colors.colTertiary 
        } 
        GradientStop { 
            position: 1.0; 
            color: Appearance.m3colors.m3tertiaryContainer 
        } 
    }

    Gradient {
        id: sunsetGradient
        GradientStop { 
            position: 0.0; 
            color: Appearance.m3colors.m3secondaryFixedDim || Appearance.colors.colSecondary 
        } 
        GradientStop { 
            position: 1.0; 
            color: Appearance.m3colors.m3primaryContainer 
        } 
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: 10
        }
        spacing: -4

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                id: title
                Layout.alignment: Qt.AlignLeft
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.fgColor
            }

            Item { Layout.fillWidth: true }

            MaterialSymbol {
                id: symbol
                Layout.alignment: Qt.AlignRight
                fill: 0
                iconSize: Appearance.font.pixelSize.normal
                color: root.fgColor
            }
        }

        StyledText {
            id: value
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.fgColor
            opacity: 0.6
        }
    }
}
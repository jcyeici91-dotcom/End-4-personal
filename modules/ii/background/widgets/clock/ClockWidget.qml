import QtQuick
import QtQuick.Layouts
import QtCore
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "clock"

    readonly property bool enableLockClockScaling: true
    readonly property real lockClockScaleValue: 3     // escala x reloj

    readonly property real lockCenterOffsetX: 0               //   - negativo = sube/izquierda
    readonly property real lockCenterOffsetY: 0               //   - positivo = baja/derecha

    readonly property real lockStatusTextScale: GlobalStates.screenLocked ? 1 : 1.0           // escala texto

    readonly property bool showWelcomeOnLock: true
    readonly property real lockWelcomeTextScale: GlobalStates.screenLocked ? 1.30 : 1.0       // escala “welcome”

    // Anti-blur
    readonly property real lockUiAntiScale: (
        GlobalStates.screenLocked && enableLockClockScaling
            ? (1.0 / root.effectiveClockScale)
            : 1.0
    )

    readonly property string homePath: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string userFromHomePath: {
        var p = root.homePath || "";
        while (p.length > 1 && p.endsWith("/"))
            p = p.slice(0, p.length - 1);

        var parts = p.split("/");
        var last = (parts.length > 0) ? parts[parts.length - 1] : "";
        return last;
    }

    readonly property string userDisplayName: userFromHomePath

    // Se mantiene por compatibilidad, aunque ya no se usa en el texto (porque ahora es fijo)
    readonly property string welcomeMessage: (
        userDisplayName !== ""
            ? Translation.tr("Bienvenido, %1").arg(userDisplayName)
            : Translation.tr("Bienvenido")
    )

    readonly property real effectiveClockScale: (
        enableLockClockScaling && GlobalStates.screenLocked
            ? lockClockScaleValue
            : 1.0
    )

    implicitHeight: contentColumn.implicitHeight * effectiveClockScale
    implicitWidth: contentColumn.implicitWidth * effectiveClockScale

    readonly property string clockStyle: GlobalStates.screenLocked ? Config.options.background.widgets.clock.styleLocked : Config.options.background.widgets.clock.style
    readonly property bool forceCenter: (GlobalStates.screenLocked && Config.options.lock.centerClock)
    readonly property bool shouldShow: (!Config.options.background.widgets.clock.showOnlyWhenLocked || GlobalStates.screenLocked)
    property bool wallpaperSafetyTriggered: false
    needsColText: clockStyle === "digital"

    x: forceCenter ? ((root.screenWidth - root.width) / 2 + lockCenterOffsetX) : targetX
    y: forceCenter ? ((root.screenHeight - root.height) / 2 + lockCenterOffsetY) : targetY

    visibleWhenLocked: true

    property var textHorizontalAlignment: {
        if (!Config.options.background.widgets.clock.digital.adaptiveAlignment || root.forceCenter || Config.options.background.widgets.clock.digital.vertical)
            return Text.AlignHCenter;
        if (root.x < root.scaledScreenWidth / 3)
            return Text.AlignLeft;
        if (root.x > root.scaledScreenWidth * 2 / 3)
            return Text.AlignRight;
        return Text.AlignHCenter;
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 10

        scale: root.effectiveClockScale
        transformOrigin: Item.Center

        FadeLoader {
            id: cookieClockLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockStyle === "cookie" && (root.shouldShow)
            fade: false
            sourceComponent: Column {
                spacing: 10
                CookieClock {
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                FadeLoader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    shown: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text !== ""
                    sourceComponent: CookieQuote {}
                }
            }
        }

        FadeLoader {
            id: digitalClockLoader
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockStyle === "digital" && (root.shouldShow)
            fade: false
            sourceComponent: DigitalClock {
                colText: root.colText
                textHorizontalAlignment: root.textHorizontalAlignment
            }
        }

           Item {
            id: welcomeText
            anchors.horizontalCenter: parent.horizontalCenter

            visible: root.showWelcomeOnLock && GlobalStates.screenLocked
            opacity: visible ? 1 : 0

            // Anti-blur (igual que antes)
            scale: root.lockUiAntiScale
            transformOrigin: Item.Center

            implicitHeight: welcomeBg.implicitHeight
            implicitWidth: welcomeBg.implicitWidth

            Rectangle {
                id: welcomeBg
                anchors.centerIn: parent
                clip: true

                radius: Appearance.rounding.small
                implicitHeight: welcomeRow.implicitHeight + 5 * 2
                implicitWidth: welcomeRow.implicitWidth + 10 * 2

                // Color que sigue el tema (igual criterio que tus badges)
                color: ColorUtils.transparentize(
                    Appearance.colors.colSecondaryContainer,
                    root.clockStyle === "cookie" ? 0 : 1
                )

                RowLayout {
                    id: welcomeRow
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        text: "format_quote"
                        iconSize: Math.round(Appearance.font.pixelSize.large * root.lockWelcomeTextScale)
                        color: root.clockStyle === "cookie"
                            ? Appearance.colors.colOnSecondaryContainer
                            : root.colText
                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ClockText {
                        Layout.alignment: Qt.AlignVCenter

                        text: "No pain 💪 No gain"
                        horizontalAlignment: Text.AlignHCenter

                        font {
                            pixelSize: Math.round(Appearance.font.pixelSize.large * root.lockWelcomeTextScale)
                            weight: Font.DemiBold
                        }

                        color: root.clockStyle === "cookie"
                            ? Appearance.colors.colOnSecondaryContainer
                            : ColorUtils.transparentize(root.colText, 0.05)

                        renderType: Text.NativeRendering
                        antialiasing: true

                        style: Text.Raised
                        styleColor: Appearance.colors.colShadow

                        elide: Text.ElideRight
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                    }
                }
            }

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        StatusRow {
            anchors.horizontalCenter: parent.horizontalCenter

            // Anti-blur: el badge
            scale: root.lockUiAntiScale
            transformOrigin: Item.Center
        }
    }

    component StatusRow: Item {
        id: statusText
        implicitHeight: statusTextBg.implicitHeight
        implicitWidth: statusTextBg.implicitWidth

        StyledRectangularShadow {
            target: statusTextBg
            visible: statusTextBg.visible && root.clockStyle === "cookie"
            opacity: statusTextBg.opacity
        }

        Rectangle {
            id: statusTextBg
            anchors.centerIn: parent
            clip: true

            // Badge
            opacity: (safetyStatusText.shown || lockStatusText.shown) ? 1 : 0
            visible: opacity > 0

            implicitHeight: statusTextRow.implicitHeight + 5 * 2
            implicitWidth: statusTextRow.implicitWidth + 5 * 2
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, root.clockStyle === "cookie" ? 0 : 1)

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on implicitHeight {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            RowLayout {
                id: statusTextRow
                anchors.centerIn: parent
                spacing: 14

                Item {
                    Layout.fillWidth: root.textHorizontalAlignment !== Text.AlignLeft
                    implicitWidth: 1
                }

                ClockStatusText {
                    id: safetyStatusText
                    shown: root.wallpaperSafetyTriggered
                    statusIcon: "hide_image"
                    statusText: Translation.tr("Wallpaper safety enforced")
                }

                ClockStatusText {
                    id: lockStatusText
                    shown: GlobalStates.screenLocked && Config.options.lock.showLockedText
                    statusIcon: "lock"
                    statusText: Translation.tr("Locked")
                }

                Item {
                    Layout.fillWidth: root.textHorizontalAlignment !== Text.AlignRight
                    implicitWidth: 1
                }
            }
        }
    }

    component ClockStatusText: Row {
        id: statusTextRow
        property alias statusIcon: statusIconWidget.text
        property alias statusText: statusTextWidget.text
        property bool shown: true
        property color textColor: root.clockStyle === "cookie" ? Appearance.colors.colOnSecondaryContainer : root.colText
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        spacing: 4

        MaterialSymbol {
            id: statusIconWidget
            anchors.verticalCenter: statusTextRow.verticalCenter

            // Evita borrosidad por fracciones
            iconSize: Math.round(Appearance.font.pixelSize.huge * root.lockStatusTextScale)

            color: statusTextRow.textColor
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }

        ClockText {
            id: statusTextWidget
            color: statusTextRow.textColor
            horizontalAlignment: root.textHorizontalAlignment
            anchors.verticalCenter: statusTextRow.verticalCenter
            font {
                pixelSize: Math.round(Appearance.font.pixelSize.large * root.lockStatusTextScale)
                weight: Font.Normal
            }

            renderType: Text.NativeRendering
            antialiasing: true

            style: Text.Raised
            styleColor: Appearance.colors.colShadow
        }
    }
}


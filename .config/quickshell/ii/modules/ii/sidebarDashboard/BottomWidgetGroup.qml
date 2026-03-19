pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

// --- IMPORTS DE LOS WIDGETS ---
import qs.modules.ii.sidebarDashboard.calendar
import qs.modules.ii.sidebarDashboard.todo
import qs.modules.ii.sidebarDashboard.pomodoro
import qs.modules.ii.sidebarDashboard.calculator // Calculadora



Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    // Altura ajustada para que quepan bien los gráficos del sistema
    implicitHeight: collapsed ? collapsedBottomWidgetGroupRow.implicitHeight : 380 
    
    property int selectedTab: Persistent.states.sidebar.bottomGroup.tab
    property int previousIndex: -1
    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed
    
    // --- LISTA DE PESTAÑAS (TABS) ---
    property var tabs: [
        {
            "type": "calendar",
            "name": Translation.tr("Calendar"),
            "icon": "calendar_month",
            "widget": "calendar/CalendarWidget.qml"
        },
        {
            "type": "todo",
            "name": Translation.tr("To Do"),
            "icon": "done_outline",
            "widget": "todo/TodoWidget.qml"
        },
        {
            "type": "timer",
            "name": Translation.tr("Timer"),
            "icon": "schedule",
            "widget": "pomodoro/PomodoroWidget.qml"
        },
        {
            "type": "calculator",
            "name": Translation.tr("Calculator"),
            "icon": "calculate",
            "widget": "calculator/CalculatorWidget.qml"
         
        }
    ]

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function setCollapsed(state) {
        Persistent.states.sidebar.bottomGroup.collapsed = state;
        if (collapsed) {
            bottomWidgetGroupRow.opacity = 0;
        } else {
            collapsedBottomWidgetGroupRow.opacity = 0;
        }
        collapseCleanFadeTimer.start();
    }

    Timer {
        id: collapseCleanFadeTimer
        interval: Appearance.animation.elementMove.duration / 2
        repeat: false
        onTriggered: {
            if (collapsed)
                collapsedBottomWidgetGroupRow.opacity = 1;
            else
                bottomWidgetGroupRow.opacity = 1;
        }
    }

    Keys.onPressed: event => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabs.length - 1);
            } else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0);
            }
            event.accepted = true;
        }
    }

    // VISTA COLAPSADA (MINIMIZADA)
    RowLayout {
        id: collapsedBottomWidgetGroupRow
        opacity: collapsed ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: collapsedBottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        spacing: 15

        CalendarHeaderButton {
            Layout.margins: 10
            Layout.rightMargin: 0
            forceCircle: true
            downAction: () => {
                root.setCollapsed(false);
            }
            contentItem: MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.larger
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer1
            }
        }

        StyledText {
            property int remainingTasks: Todo.list.filter(task => !task.done).length
            Layout.margins: 10
            Layout.leftMargin: 0
            text: Translation.tr("%1    •    %2 tasks").arg(DateTime.collapsedCalendarFormat).arg(remainingTasks)
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }
    }

    // VISTA EXPANDIDA (NORMAL)
    RowLayout {
        id: bottomWidgetGroupRow

        opacity: collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: bottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        anchors.fill: parent
        spacing: 20

        // BARRA LATERAL DE PESTAÑAS (NAVEGACIÓN)
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 10
            Layout.topMargin: 10
            implicitWidth: tabBar.implicitWidth
            
            // Botones de las pestañas
            NavigationRailTabArray {
                id: tabBar
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                currentIndex: root.selectedTab
                expanded: false
                Repeater {
                    model: root.tabs
                    NavigationRailButton {
                        required property int index
                        required property var modelData
                        showToggledHighlight: false
                        toggled: root.selectedTab == index
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                        onPressed: {
                            root.previousIndex = root.selectedTab // Guardar previo para animación
                            root.selectedTab = index;
                            Persistent.states.sidebar.bottomGroup.tab = index;
                        }
                    }
                }
            }
            // Botón de colapsar
            CalendarHeaderButton {
                anchors.left: parent.left
                anchors.top: parent.top
                forceCircle: true
                downAction: () => {
                    root.setCollapsed(true);
                }
                contentItem: MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // ÁREA DE CONTENIDO (Donde se muestra el widget)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: tabStack
                anchors.fill: parent
                // Ajuste para evitar solapamiento
                anchors.bottomMargin: 0 
                anchors.topMargin: 0

                Component.onCompleted: {
                    tabStack.source = root.tabs[root.selectedTab].widget;
                }

                onSourceChanged: {
                    // Resetear opacidad al cambiar fuente para asegurar visibilidad
                    tabStack.opacity = 1
                }
            }
            
            // Lógica de cambio de pestaña
            Connections {
                target: root
                function onSelectedTabChanged() {
                     // Determinar dirección de animación
                    if (root.selectedTab > root.previousIndex)
                        switchAnim.down = true;
                    else
                        switchAnim.down = false;
                    
                    // Ejecutar animación manual
                    switchAnim.restart()
                }
            }
            
            // Animación manual secuencial para cambio de pestaña
            SequentialAnimation {
                id: switchAnim
                property bool down: false
                
                // 1. Desvanecer salida
                ParallelAnimation {
                    NumberAnimation {
                        target: tabStack
                        property: "opacity"
                        to: 0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: tabStack.anchors
                        property: "topMargin"
                        to: 10 * (switchAnim.down ? -1 : 1)
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
                
                // 2. Cambiar Fuente (Instante)
                ScriptAction {
                    script: {
                        tabStack.source = root.tabs[root.selectedTab].widget
                        // Resetear margen para la entrada
                        tabStack.anchors.topMargin = 10 * -(switchAnim.down ? -1 : 1)
                    }
                }
                
                // 3. Desvanecer entrada
                ParallelAnimation {
                    NumberAnimation {
                        target: tabStack.anchors
                        property: "topMargin"
                        to: 0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: tabStack
                        property: "opacity"
                        to: 1
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}

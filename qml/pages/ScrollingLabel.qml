import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: item

    property int _currentOffset: 0
    property alias _leftMargin: placeHolder.x
    readonly property bool running: textSlideAnimation.running
    property alias font: label.font
    property alias text: label.text
    property alias color: label.color
    property alias horizontalAlignment: label.horizontalAlignment

    anchors {
        left: parent.left
        right: parent.right
    }
    clip: true

    height: label.implicitHeight

    Label {
        id: label

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: _leftMargin
        }

        truncationMode: TruncationMode.Fade
    }

    Item {
        id: placeHolder
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: label.implicitWidth

        MouseArea {
            anchors.fill: parent
            drag {
                target: parent
                axis: Drag.XAxis
                minimumX: Math.min(item.width - label.implicitWidth, 0)
                maximumX: 0
            }

            onPressed: {
                textSlideAnimation.stop();
            }
            onReleased: {
                _currentOffset = _leftMargin;
                textSlideAnimation.start();
            }

        }
    }

    SequentialAnimation on _leftMargin {
        id: textSlideAnimation
        loops: Animation.Infinite
        running: false

        PauseAnimation {
            duration: 1000
        }
        NumberAnimation {
            to: item.width - label.implicitWidth
            duration: Math.max((label.implicitWidth - item.width + _currentOffset) / 0.050, 0)
        }
        PauseAnimation {
            duration: 1000
        }
        NumberAnimation {
            to: 0
            duration: Math.max((label.implicitWidth - item.width) / 0.050, 0)
        }
        ScriptAction {
            script: {
                _currentOffset = 0;
            }
        }
    }

    Component.onCompleted: {
        startAnimation();
    }

    function startAnimation(){
        console.log("ScrollingLabel.startAnimation")
        if (item.width < label.implicitWidth){
            item.horizontalAlignment = Text.AlignLeft
            textSlideAnimation.start();
        }
    }
    function stopAnimation(){
        textSlideAnimation.stop();
        _leftMargin = 0;
    }

}


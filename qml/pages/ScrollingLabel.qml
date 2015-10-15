import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    id: label

    property int textOffset: Theme.horizontalPageMargin
    property int _leftMargin: textOffset
    readonly property bool running: textSlideAnimation.running

    anchors {
        left: parent.left
        right: parent.right
        leftMargin: _leftMargin
    }

    truncationMode: TruncationMode.Fade

    SequentialAnimation on _leftMargin {
        id: textSlideAnimation
        loops: Animation.Infinite
        running: false

        PauseAnimation {
            duration: 3000
        }
        NumberAnimation {
            to: label.width - label.implicitWidth - label.textOffset
            duration: Math.max((label.textOffset + label.implicitWidth - label.width) * 50, 0)
        }
        PauseAnimation {
            duration: 1000
        }
        NumberAnimation {
            to: label.textOffset
            duration: Math.max((label.textOffset + label.implicitWidth - label.width) * 50, 0)
        }
    }

    function startAnimation(){
        console.log("ScrollingLabel.startAnimation")
        console.log("width = " + width);
        console.log("implicitWidth = " + implicitWidth);
        console.log("textOffset = " + textOffset);
        if (width < implicitWidth + textOffset){
            textSlideAnimation.start();
        }
    }
    function stopAnimation(){
        textSlideAnimation.stop();
        _leftMargin = textOffset;
    }


}

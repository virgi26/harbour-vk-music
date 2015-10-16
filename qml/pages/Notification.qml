/*
  Copyright (C) 2015 Alexander Ladygin
  Contact: Alexander Ladygin <fake.ae@gmail.com>
  All rights reserved.

  This file is part of Harbour-vk-music.

  Harbour-vk-music is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Harbour-vk-music is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Harbour-vk-music.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/misc.js" as Misc

Item {
    id: notification

    anchors.fill: parent

    MouseArea {
        id: mouseAreaFull

        anchors.fill: parent

        onClicked: {
            notificationLoader.active = false;
            flickable.enabled = true;
            flickable.visible = true;
        }

        Rectangle {
            id: rectangle

            width: Screen.width - 2*Theme.paddingLarge
            height: column.height + Theme.paddingLarge
            x: Theme.paddingLarge
            y: Theme.paddingLarge

            color: mouseArea.pressed && mouseArea.containsMouse
                           ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                           : "transparent"
            border.color: Theme.highlightColor
            border.width: 2
            radius: 10

            SequentialAnimation on border.color {
                    ColorAnimation { to: "red"; duration: 200 }
                    ColorAnimation { to: Theme.highlightColor; duration: 200 }
                    ColorAnimation { to: "red"; duration: 200 }
                    ColorAnimation { to: Theme.highlightColor; duration: 200 }
                    ColorAnimation { to: "red"; duration: 200 }
                    ColorAnimation { to: Theme.highlightColor; duration: 200 }
                    ColorAnimation { to: "red"; duration: 200 }
                    ColorAnimation { to: Theme.highlightColor; duration: 200 }
                    ColorAnimation { to: "red"; duration: 200 }
                    ColorAnimation { to: Theme.highlightColor; duration: 200 }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent

                onClicked: {
                    notificationLoader.active = false;
                    flickable.enabled = true;
                    flickable.visible = true;

                    switch (errorCode){
                        case 5://invalid session, redirect to login page
                            pageStack.push(Qt.resolvedUrl("LoginPage.qml"));
                            break;
                        default:
                            break;
                    }
                }
            }


            Column {
                id: column

                spacing:Theme.paddingSmall
                x: Theme.paddingLarge
                y: Theme.paddingSmall


                Label {
                    text: qsTr("Error occured")
                    font.pixelSize: Theme.fontSizeSmall
                    color:Theme.highlightColor
                }

                Label {
                    font.pixelSize: Theme.fontSizeSmall
                    color:Theme.secondaryHighlightColor
                    text: errorMessage
                    width: rectangle.width - 2 * Theme.paddingLarge
                    wrapMode: Text.WordWrap
                }
            }

        }
    }

}

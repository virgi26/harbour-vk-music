/*
  Copyright (C) 2015 Petr Vytovtov
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
import harbour.vk.music.audioplayerinfo 1.0

CoverBackground {
    Image {
        id: logo

        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -parent.height/6
            horizontalCenter: parent.horizontalCenter
        }

        source: "../images/harbour-vk-music.png"
        height: parent.width/2
        width: parent.width/2
    }

    Label {
        id: label

        anchors {
            top: logo.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }

        text: qsTr("Music")
        font.pixelSize: Theme.fontSizeExtraLarge
        color: Theme.highlightColor

    }


    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: AudioPlayerInfo.status == AudioPlayerInfo.Playing
                            ? "image://theme/icon-cover-pause"
                            : "image://theme/icon-cover-play"
            onTriggered: {
                AudioPlayerInfo.status == AudioPlayerInfo.Playing
                    ? AudioPlayerInfo.pause()
                    : AudioPlayerInfo.play()
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next-song"
            onTriggered: {
                AudioPlayerInfo.playNext();
            }
        }

    }
}



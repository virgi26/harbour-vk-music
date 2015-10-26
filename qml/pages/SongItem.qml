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
import harbour.vk.music.audioplayerhelper 1.0
import "../utils/vkapi.js" as VKAPI
import "../utils/database.js" as DB
import "../utils/misc.js" as Misc

ListItem {
    id: songItem

    contentHeight: label.height + 2*Theme.paddingSmall
    contentWidth: parent.width

    menu: contextMenu

    Label {
        id: label

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: owner_id !== userId ? (Theme.horizontalPageMargin + Theme.paddingMedium) : Theme.horizontalPageMargin
            topMargin: Theme.paddingSmall
            bottomMargin: Theme.paddingSmall
        }

        text: (aid > -1) ? artist + " - " + title : ""
        truncationMode: TruncationMode.Fade
        width: parent.width - 2*Theme.paddingMedium - 2*Theme.horizontalPageMargin - cachedIcon.width
        font {
            pixelSize: Theme.fontSizeMedium
            italic: owner_id !== userId
        }
        maximumLineCount: 1

        color: index === listView.currentIndex ? Theme.highlightColor : Theme.primaryColor

        SequentialAnimation on scale {
            id: highlight
            running: false

            NumberAnimation {
                to: 1.1
                duration: 200
            }
            NumberAnimation {
                to: 1
                duration: 200
            }
        }
    }

    Image {
        id: cachedIcon

        anchors {
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
            right: parent.right
        }

        source: "image://theme/icon-s-device-upload"
        visible: cached
    }

    Image {
        id: errorIcon

        anchors {
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
            right: parent.right
        }

        height: Theme.iconSizeSmall
        width: Theme.iconSizeSmall
        source: "../images/exclamation.png"
        visible: error
    }

    RemorseItem { id: remorse }

    Component {
        id: contextMenu
        ContextMenu {
            MenuItem {
                text: qsTr("Add")
                onClicked: VKAPI.addAudio(songItem, accessToken, aid, owner_id, parseAPIResponse_add);
                visible: owner_id !== userId
            }
            MenuItem {
                text: qsTr("Remove")
                onClicked: {
                    remorse.execute(
                                songItem
                                , qsTr("Deleting")
                                , removeAudio
                                , 3000
                                )
                }
                visible: owner_id === userId
            }
            MenuItem {
                text: qsTr("Clear cache")
                onClicked: {
                    Utils.deleteFile(cacheDir, Misc.getFileName2(owner_id, aid));
                    DB.removeLastAccessedEntry(Misc.getFileName2(owner_id, aid));
                    Utils.getFreeSpace(cacheDir);
                    listModel.setProperty(index, "cached", false);
                    if (index === listView.currentIndex){
                        controlsPanel.hideCacheIcon();
                    }
                }

                visible: cached
            }
        }
    }

    onClicked: {
        console.log("ListItem:onClicked");
        highlight.start();
        controlsPanel.userInteraction = true;
        listView.currentIndex = index;
        playThisSong();
        controlsPanel.showFull();
    }


    function removeAudio(){
        VKAPI.removeAudio(songItem, accessToken, aid, owner_id, parseAPIResponse_remove);
    }

    function playThisSong(){
        console.log("playThisSong: " + aid);
        controlsPanel.stop();

        controlsPanel.playSong({
            aid: aid
            , owner_id: owner_id
            , artist: artist
            , title: title
            , duration: duration
            , date: date
            , url: url
            , lyrics_id: lyrics_id
            , album_id: album_id
            , genre_id: genre_id
            , cached: cached
            , error: error
        });

        if (index === listModel.count - 1){//last song is playing
            if (AudioPlayerHelper.shuffle){
                requestRandomSong();
            } else {
                requestMoreSongs();
            }
        }
    }

}

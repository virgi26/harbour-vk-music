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
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../utils/database.js" as DB

Dialog {
    DialogHeader {
        id: header
        title: qsTr("Select path")
    }

    SilicaListView {
        id: listView

        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        model: ListModel {
            id: listModel
        }
        delegate: BackgroundItem {
                Label {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: path
                    color: listView.currentIndex === index ? Theme.highlightColor : Theme.primaryColor
                }

                onClicked: {
                    listView.currentIndex = index
                }
        }

    }

    Component.onCompleted: {
        listModel.append({path: qsTr("Local cache")});
        if (sdcardPath){
            listModel.append({path: qsTr("SD card directory")});
            listModel.append({path: qsTr("SD card hidden directory")});
        }
    }

    onAccepted: {
        var oldValue = cacheDir;
        switch (listView.currentIndex){
            case 1: cacheDir = sdcardPath + "/harbour-vk-music";break;
            case 2: cacheDir = sdcardPath + "/.harbour-vk-music";break;
            default: cacheDir = Utils.getDefaultCacheDirPath();
        }

        if (!Utils.checkCacheDir(cacheDir)){
            cacheDir = oldValue;
        }

        if (oldValue !== cacheDir){
            Utils.clearCacheDir(oldValue);
            DB.clearLastAccessedDateTable();
        }
    }

}

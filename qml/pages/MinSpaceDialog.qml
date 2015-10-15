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
import "../utils/database.js" as DB

Dialog {
    DialogHeader {
        id: header
        title: qsTr("Select size")
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
        listModel.append({path: qsTr("No restrictions")});
        listModel.append({path: qsTr("1GB")});
        listModel.append({path: qsTr("2GB")});
        listModel.append({path: qsTr("5GB")});
        listModel.append({path: qsTr("No cache")});
    }

    onAccepted: {
        switch (listView.currentIndex){
            case 0: minimumFreeSpaceKBytes = 0;break;
            case 1: minimumFreeSpaceKBytes = 1024*1024;break;
            case 2: minimumFreeSpaceKBytes = 2*1024*1024;break;
            case 3: minimumFreeSpaceKBytes = 5*1024*1024;break;
            case 4: minimumFreeSpaceKBytes = 1024*1024*1024;break;
            default: minimumFreeSpaceKBytes = 1024*1024;
        }
    }

}

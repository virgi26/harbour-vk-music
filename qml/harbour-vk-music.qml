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
import "pages"
import "utils/database.js" as Database
import "utils/vkapi.js" as VKAPI

ApplicationWindow
{
    id: applicationWindow

    property string accessToken: Database.getProperty("accessToken");
    property int userId: Database.getProperty("userId")
    property string cacheDir: Database.getProperty("cacheDir")
    property int freeSpaceKBytes
    property int minimumFreeSpaceKBytes: Database.getProperty("minimumFreeSpaceKBytes")
    property string sdcardPath: Utils.sdcardPath()
    property bool humanFriendlyFileNames: false
    property bool enableBitRate: Database.getProperty("enableBitRate")

    readonly property int _DEFAULT_PAGE_SIZE: (Screen.sizeCategory >= Screen.Large) ? 100 : 50

    property alias controlsPanel: controlsPanel

    bottomMargin: controlsPanel.visibleSize

    initialPage: Component {
        MusicList {id: musicList}
    }

    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
    _defaultPageOrientations: Orientation.Portrait

    Component.onCompleted: {
        if (!minimumFreeSpaceKBytes){
            minimumFreeSpaceKBytes = 1024*1024;
        }
    }

    Component.onDestruction: {
        console.log("onDestruction");
        Utils.clearCacheDirFromGarbage(cacheDir, userId);
        console.log("onDestruction complete");
    }

    ControlsPanel {
        id: controlsPanel
    }

    Connections {
        target: Utils

        onFreeSpaceUpdated: {
            console.log("onFreeSpaceUpdated: " + freeSpace);
            if (freeSpace === -1){
                console.log("Error getting free space for " + cacheDir);
                cacheDir = "";
            } else {
                freeSpaceKBytes = freeSpace;
            }
        }
    }

    onMinimumFreeSpaceKBytesChanged: {
        Database.setProperty("minimumFreeSpaceKBytes", minimumFreeSpaceKBytes);
    }

    onCacheDirChanged: {
        Database.setProperty("cacheDir", cacheDir);
        Utils.getFreeSpace(cacheDir);
    }

    onAccessTokenChanged: {
        validateToken();
    }

    function validateToken(){
        if (!accessToken || !userId){
            console.log("access_token or user_id is undefined");
//            pageStack.push(Qt.resolvedUrl("pages/LoginPage.qml"));
        } else {
            checkCacheDir();
            Utils.getFreeSpace(cacheDir);

            var cachedFiles = Utils.getCachedFileNames(cacheDir);
            for (var index in cachedFiles){
                Database.checkLastAccessDate(cachedFiles[index]);
            }

            Utils.clearCacheDirFromGarbage(cacheDir, userId);
            //TODO validate session
        }
    }

    function checkCacheDir() {
        if (!Utils.checkCacheDir(cacheDir)){
            cacheDir = Utils.getDefaultCacheDirPath();
        }
    }

}



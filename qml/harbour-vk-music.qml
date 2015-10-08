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
import "pages"
import "utils/database.js" as Database
import "utils/vkapi.js" as VKAPI

ApplicationWindow
{
    id: applicationWindow

    property string accessToken
    property int userId
    readonly property int _DEFAULT_PAGE_SIZE: (Screen.sizeCategory >= Screen.Large) ? 60 : 30

    property alias controlsPanel: controlsPanel

    bottomMargin: controlsPanel.visibleSize

    initialPage: Component {
        MusicList {}
    }

    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.Portrait
    _defaultPageOrientations: Orientation.Portrait

    Component.onCompleted: {
        validateToken();
    }

    ControlsPanel {
        id: controlsPanel
    }

    function validateToken(){
        userId = Database.getProperty("userId");
        accessToken = Database.getProperty("accessToken");

        if (!accessToken || !userId){
            console.log("access_token or user_id is undefined");
            pageStack.push(Qt.resolvedUrl("pages/LoginPage.qml"));
        } else {
            Utils.clearCacheDirFromGarbage("", userId);


            //TODO validate session
        }
    }

}



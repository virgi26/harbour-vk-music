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
import "../utils/database.js" as Database

Page {
    readonly property string defaultURL: "https://oauth.vk.com/authorize?" +
                                "client_id=5089725" +
                                "&scope=audio,offline" +
                                "&redirect_uri=https://oauth.vk.com/blank.html" +
                                "&display=mobile" +
                                "&response_type=token"

    SilicaFlickable{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    loginView.url = defaultURL;
                    loginView.reload;
                }
            }
        }

        SilicaWebView {
            id: loginView
            anchors.fill: parent
            url: defaultURL

            onUrlChanged: {//parsing url

                console.log("parsing url");

                var ACCESS_TOKEN = "access_token";
                var USER_ID = "user_id";
                var urlStr = url.toString();

                if (urlStr.indexOf(ACCESS_TOKEN) === -1){
                    console.log("access token not found in URL");
                } else {
                    console.log("access token is present in URL: " + url);

                    var startIndex = urlStr.indexOf(ACCESS_TOKEN) + ACCESS_TOKEN.length + 1;
                    accessToken = urlStr.substring(startIndex, urlStr.indexOf("&", startIndex) === -1 ? urlStr.length : urlStr.indexOf("&", startIndex));
                    Database.setProperty("accessToken", accessToken);
                    console.log("accessToken = " + accessToken);
                    startIndex = urlStr.indexOf(USER_ID) + USER_ID.length + 1;
                    userId = urlStr.substring(startIndex, urlStr.indexOf("&", startIndex) === -1 ? urlStr.length : urlStr.indexOf("&", startIndex));
                    Database.setProperty("userId", userId);
                    console.log("userId = " + userId);

                    pageStack.pop();
                    loginView.destroy();
                }

            }
        }
    }


}

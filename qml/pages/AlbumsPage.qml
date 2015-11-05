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
import "../utils/vkapi.js" as VKAPI

Page {
    id: page

    property string errorMessage
    property int errorCode
    property var applyAlbumFilter
    property bool endOfAlbumList: false

    property alias listModel: listModel

    SilicaFlickable {
        id: flickable//do not change, binded to name in Notification component

        anchors.fill: parent

        PageHeader {
            id: header

            title: qsTr("Albums")
        }

        Rectangle {
            anchors {
                top: header.bottom
                left: parent.left
                bottom: parent.bottom
                right: parent.right
            }

            color: "transparent"

            SilicaListView {
                id: listView

                anchors {
                    fill: parent
                    topMargin: Theme.paddingLarge
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                width: parent.width

                model: listModel
                delegate: ListItem {
                    id: item

                    Label {
                        anchors {
                            fill: parent
                            topMargin: Theme.paddingSmall
                            bottomMargin: Theme.paddingSmall
                            leftMargin: Theme.horizontalPageMargin
                        }

                        color: index === listView.currentIndex ? Theme.highlightColor : Theme.primaryColor
                        text: title
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: !truncated ? Text.AlignHCenter : Text.AlignLeft
                        truncationMode: TruncationMode.Fade
                        font {
                            family: Theme.fontFamilyHeading
                            pixelSize: Theme.fontSizeLarge
                        }

                        scale: listView.currentIndex === index ? 1.1 : 1
                    }



                    onClicked: {
                        if (listView.currentIndex === index){
                            pageStack.navigateBack(PageStackAction.Animated);
                            applyAlbumFilter(album_id, title);
                        } else {
                            listView.currentIndex = index;
                        }
                    }
                }

                onMovementEnded: {
                    if (atYEnd){
                        requestMoreAlbums();
                    }
                }
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")

                onClicked: {
                    reloadAlbumList();
                }
            }
        }


        ListModel{
            id: listModel

            onRowsInserted: {
                loadingIndicator.running = false;
            }

        }
    }

    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: false // true
    }

    Loader {
        id:notificationLoader//do not change, binded to name in Notification component
    }

    onStatusChanged: {
        console.log("onStatusChanged = " + page.status);

        if (page.status === PageStatus.Active) {
            controlsPanel.hidePanel();
            controlsPanel.showLyrics = false;
        }

    }

    function setCurrentItemIndex(){
        for (var i = 0; i < listModel.count; i++){
            if(controlsPanel.albumId === listModel.get(i).album_id){
                listView.currentIndex = i;
                break;
            }
        }
    }

    function clearAlbumsListModel(){
        console.log("clearListModel");
        endOfAlbumList = false;
        listModel.clear();
    }

    function reloadAlbumList(){
        clearAlbumsListModel();
        listModel.append({
                             album_id: -1
                             , title: "My music"
                         });
        listView.currentIndex = 0;
        loadingIndicator.running = true;
        VKAPI.getAlbums(page, accessToken, userId, parseAPIResponse_getAlbums, 0, _DEFAULT_PAGE_SIZE);
    }

    function requestMoreAlbums(){
        if (endOfAlbumList){
            return;
        }

        loadingIndicator.running = true;
        VKAPI.getAlbums(page, accessToken, userId, parseAPIResponse_getAlbums, listModel.count - 1, _DEFAULT_PAGE_SIZE);
    }

    function parseAPIResponse_getAlbums(responseText){
        if (!responseText){
            console.log("Network access error");
            handleError(-1, "Network access error");
            return;
        }

        if (responseText === VKAPI.TIME_OUT_RESPONSE){
            console.log("Timeout waiting for server to reply");
            handleError(-1, "Timeout waiting for server to reply");
            return;
        }

        var json;
        try {
            json = JSON.parse(responseText);
        } catch (err) {
            console.log("Can not parse API response");
            handleError(-1, "Can not parse API response");
            return;
        }

        if (json.error) {//got error
            console.log("Server reported error: " + json.error.error_msg);
            handleError(json.error.error_code, "Server reported error: " + json.error.error_msg)
            return;
        }

        var items = json.response.items;
        for (var i in items) {
            var album = {
                album_id: items[i].id
                , title: items[i].title
            };

            listModel.append(album);
        }
        if (items.length < _DEFAULT_PAGE_SIZE){
            console.log("reached end of the list");
            endOfAlbumList = true;
            loadingIndicator.running = false;
        }

        setCurrentItemIndex();
    }

    function handleError(code, message){
        console.log("handleError");
        loadingIndicator.running = false;

        errorMessage = message;
        errorCode = code;
        flickable.enabled = false;
        flickable.visible = false;
        notificationLoader.active = true;
        notificationLoader.source = "Notification.qml";
    }
}

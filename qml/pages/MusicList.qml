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
import org.nemomobile.notifications 1.0
import QtMultimedia 5.0
import "../utils/database.js" as Database
import "../utils/vkapi.js" as VKAPI
import "../utils/misc.js" as Misc
import harbour.vk.music.audioplayerinfo 1.0


Page {
    id: musicListPage

    property string errorMessage
    property int errorCode
    property bool searchShown: false
    property bool listChanged: false

    property alias listView: listView
    property alias listModel: listModel


    SilicaFlickable {
        id: flickable

        anchors.fill: parent
//        anchors.bottomMargin: controlsPanel.visibleSize

        Rectangle {//helper for searchField resize animation
            id: magicalDivider

            anchors.left: parent.left

            color: "transparent"
            y: -1
            height: 1
            width: searchIcon.width + Theme.horizontalPageMargin

            NumberAnimation on width {
                id: showSearch

                to: flickable.width - clearSearchIcon.width - Theme.horizontalPageMargin
                duration: 300
                running: false

                onStarted: {
                    console.log("show search");
                    controlsPanel.hidePanel();
                    searchField.enabled = true;
                    searchField.color = Theme.primaryColor
                }

                onStopped: {
                    header.visible = false
                    clearSearchIcon.visible = true
                    searchField.forceActiveFocus();
                    searchShown = true;
                }
            }

            NumberAnimation on width {
                id: hideSearch

                to: searchIcon.width + Theme.horizontalPageMargin
                duration: 300
                running: false

                onStarted: {
                    console.log("hide search");
                    flickable.forceActiveFocus();
                    header.visible = true
                    clearSearchIcon.visible = false;
                    searchField.text = "";
                }

                onStopped: {
                    searchField.enabled = false;
                    searchField.color = "transparent"
                    flickable.forceActiveFocus();//for caret to disappear
                    searchShown = false;
//                    controlsPanel.hidePanel();
                }
            }
        }

        PageHeader {
            id: header
            title: qsTr("My music")

            anchors.top: parent.top
            anchors.left: magicalDivider.right

            width: (parent.width - magicalDivider.width)
        }

        IconButton {
            id: searchIcon

            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: header.verticalCenter
            }

            icon.source: "image://theme/icon-m-search"

            onClicked: {
                if (!searchShown){
                    showSearch.start();
                } else {
                    flickable.forceActiveFocus();
                    applySearchFilter();
                }
            }
        }

        IconButton {
            id: clearSearchIcon

            anchors {
                left: magicalDivider.right
                verticalCenter: header.verticalCenter
            }

            icon.source: "image://theme/icon-m-clear"
            visible: false

            onClicked: {
                if (searchShown){
                    hideSearch.start();
                    if (listChanged){
                        applySearchFilter();
                        listChanged = false;
                    }
                }
            }
        }

        TextField {
            id: searchField

            anchors {
                left: searchIcon.right
                right: magicalDivider.right
            }

            font {
                pixelSize: Theme.fontSizeLarge
                family: Theme.fontFamilyHeading
            }

            y: searchIcon.height / 4//fucking magic

            textLeftMargin: 0
            textRightMargin: 0

            placeholderText: qsTr("Search")
            color: "transparent"
            enabled: false

            EnterKey.enabled: text.length > 0
            EnterKey.iconSource: "image://theme/icon-m-search"
            EnterKey.onClicked: {
                flickable.forceActiveFocus();
                applySearchFilter();
            }

            onClicked: {
                controlsPanel.hidePanel();
            }

        }

        Rectangle {
            id: spacer
            height: Theme.paddingLarge
            anchors.top: header.bottom
        }

        Rectangle {
            anchors.top: spacer.bottom
            height: parent.height - header.height - 3*Theme.paddingMedium
            width: parent.width
            color: "transparent"

            SilicaListView {
                id: listView

                currentIndex: AudioPlayerInfo.currentIndex

                anchors.fill: parent
                anchors.bottomMargin: Theme.paddingLarge

                delegate: SongItem {}
                model: listModel

                VerticalScrollDecorator {
                }

                Transition {
                    id: listViewDisplacedAnimation
                    NumberAnimation { properties: "y"; duration: 250 }
                }

                displaced: listViewDisplacedAnimation

                onMovementEnded: {
                    if (atYEnd){
                        requestMoreSongs();
                    }
                }

                onCurrentIndexChanged: {
                }

                onMovementStarted: {
                    listView.forceActiveFocus();//hide keyboard
                    controlsPanel.partiallyHide();
                }

            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Logout")
                onClicked: {
                    loadingIndicator.running = true;
                    controlsPanel.hidePanel();
                    clearListModel();
                    Utils.clearCookies();
                    Database.setProperty("accessToken", "");
                    Database.setProperty("userId", "");
                    accessToken = "";
                    userId = "";
                    loadingIndicator.running = false;
                }
                visible: accessToken
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    controlsPanel.hidePanel();
                    pageStack.push(Qt.resolvedUrl("Settings.qml"), {clearIcons: clearCacheIcons})
                }
            }
            MenuItem {
                text: qsTr("Login")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"));
                }
                visible: !accessToken
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    reloadList();
                }
                enabled: !loadingIndicator.running
            }

        }

    }



    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: false // true
    }

    ListModel{
        id: listModel

        ListElement {
            aid: -1
            owner_id: -1
            artist: ""
            title: ""
            duration: -1
            date: -1
            url: ""
            lyrics_id: -1
            album_id: -1
            genre_id: -1
            cached: false
        }

        onRowsInserted: {
            loadingIndicator.running ? loadingIndicator.running = false : null;
        }

        onCountChanged: {
            AudioPlayerInfo.listSize = count;
        }

    }

    Connections {
        target: applicationWindow
        onAccessTokenChanged: {//reload list
            console.log("onAccessTokenChanged: " + accessToken);
            if (accessToken){
                reloadList();
            }
        }
    }

    Connections {
        target: AudioPlayerInfo

        onCurrentIndexChanged: {
            console.log("AudioPlayerInfo:onCurrentIndexChanged");
            if (AudioPlayerInfo.currentIndex === -1){//this is default value
                //do nothing
            } else if (AudioPlayerInfo.currentIndex < -1
                    || AudioPlayerInfo.currentIndex >= listModel.count){//exceded values reassigned to defaultvalue
                AudioPlayerInfo.currentIndex = -1;
            } else if (AudioPlayerInfo.currentIndex === listModel.count - 1) {//last song is playing
                requestMoreSongs();
            } else {
                listView.currentItem.playThisSong();//autoplay on selecting new song
            }
        }

        onFileCached: {
            console.log("AudioPlayerInfo:onFileCached");
            listModel.setProperty(itemIndex, "cached", true);
        }
    }

    Notification {
        id: errorNotification
        category: "error"
        summary: qsTr("Error occured")
        urgency: Notification.Critical
        onClicked: {
            console.log("Notification clicked");
            pageStack.push(Qt.resolvedUrl("LoginPage.qml"));
        }
    }

    Loader {
        id:notificationLoader
    }

    Component {
        id: notification

        MouseArea {
            id: mouseAreaFull

            width: Screen.width
            height: Screen.height
            x: 0
            y: 0

            onPressed: {
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

                    onPressed: {
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

    function parseAPIResponse_getList(responseText){
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
            var song = {
                aid: items[i].id
                , owner_id: items[i].owner_id
                , artist: items[i].artist
                , title: items[i].title
                , duration: items[i].duration
                , date: items[i].date
                , url: items[i].url
                , lyrics_id: items[i].lyrics_id
                , album_id: items[i].album_id
                , genre_id: items[i].genre_id
            };
            //check for cached file
            var filePath = Utils.getFilePath("", Misc.getFileName(song));
            song.cached = filePath ? true : false;

            listModel.append(song);
        }
    }

    function clearCacheIcons(){//should be called after clearing cache
        for (var i = 0; i < listModel.count; i++){
            listModel.setProperty(i, "cached", false);
        }
    }

    function reloadList(){
        console.log("reloadList");

        if (!searchField.text){
            applySearchFilter();
            return;
        }

        loadingIndicator.running = true;
        clearListModel();
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, 0, _DEFAULT_PAGE_SIZE);
    }

    function requestMoreSongs(){
        console.log("requestMoreSongs");
        loadingIndicator.running = true;
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, listModel.count, _DEFAULT_PAGE_SIZE, Utils.encodeURL(searchField.text));
    }

    function handleError(code, message){
        loadingIndicator.running = false;

        errorNotification.body = message;
        errorNotification.publish();

        errorMessage = message;
        errorCode = code;
        flickable.enabled = false;
        flickable.visible = false;
        notificationLoader.active = true;
        notificationLoader.sourceComponent = notification;
    }

    function applySearchFilter(){
        console.log("applySearchFilter");
        loadingIndicator.running = true;
        clearListModel();
        listChanged = true;
        AudioPlayerInfo.currentIndex = -1;
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, listModel.count, _DEFAULT_PAGE_SIZE, Utils.encodeURL(searchField.text));
    }

    function clearListModel(){
        console.log("clearListModel");
        listView.displaced = null;
        listModel.clear();
        listView.displaced = listViewDisplacedAnimation;
    }
}



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
import org.nemomobile.notifications 1.0
import QtMultimedia 5.0
import "../utils/database.js" as Database
import "../utils/vkapi.js" as VKAPI
import "../utils/misc.js" as Misc
import harbour.vk.music.audioplayerhelper 1.0


Page {
    id: musicListPage

    property string errorMessage
    property int errorCode
    property bool downloadPlayListMode: false

    property bool _searchShown: false
    property bool _listChanged: false
    property bool _endOfAudioList: false
    property bool _searchInProgress: false
    property bool _showMoreButtonVisible: false
    property bool _showMore: false
    property var _availableNumbers: []//contains song numbers available for shuffle
    property int _needMoreRandomSongsCount: 0
    property bool _justLoaded: false//used to redirect next button behaviour to play first song after list refresh

    property alias listView: listView
    property alias listModel: listModel


    SilicaFlickable {
        id: flickable//do not change, binded to name in Notification component

        anchors.fill: parent

        Item {//helper for searchField resize animation
            id: magicalDivider

            anchors.left: parent.left

            y: -1
            height: 1
            width: searchIcon.width + Theme.horizontalPageMargin

            NumberAnimation on width {
                id: showSearch

                to: flickable.width - clearSearchIcon.width - Theme.horizontalPageMargin - Theme.paddingLarge//not to overlap with page animation
                duration: 300
                running: false

                onStarted: {
                    console.log("show search");
                    controlsPanel.hidePanel();
                    searchField.enabled = true;
                    searchField.visible = true;
                    searchField.color = Theme.primaryColor
                }

                onStopped: {
                    header.visible = false
                    clearSearchIcon.visible = true
                    searchField.forceActiveFocus();
                    _searchShown = true;
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
                    searchField.visible = false;
                    searchField.color = "transparent"
                    flickable.forceActiveFocus();//for caret to disappear
                    _searchShown = false;
                }
            }
        }

        PageHeader {
            id: header
            title: {
                switch (controlsPanel.albumId){
                    case -1: return qsTr("My music");
                    case -2: return qsTr("Shuffle");
                    default: return controlsPanel.albumTitle;
                }
            }

            anchors.top: parent.top
            anchors.left: magicalDivider.right

            width: (parent.width - magicalDivider.width)

            visible: accessToken

            MouseArea {
                id: headerMouseArea
                anchors.fill: parent

                onClicked: {
                    pageStack.navigateForward(PageStackAction.Animated);
                }

                onPressAndHold: {
                    secretTimer.start();
                }

                onReleased: {
                    secretTimer.stop();
                }

                Timer {
                    id: secretTimer
                    interval: 5000
                    running: false

                    onTriggered: {
                        downloadPlayList();
                    }
                }
            }
        }

        IconButton {
            id: searchIcon

            visible: accessToken && controlsPanel.albumId === -1//API does not support filters inside of albums

            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: header.verticalCenter
            }

            icon.source: "image://theme/icon-m-search"

            onClicked: {
                if (!_searchShown){
                    showSearch.start();
                    _listChanged = false;
                } else {
                    flickable.forceActiveFocus();
                    reloadList();
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
                if (_searchShown){
                    searchField.text = "";
                    hideSearch.start();
                    if (_listChanged){
                        reloadList();
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
            visible: false

            EnterKey.enabled: text.length > 0
            EnterKey.iconSource: "image://theme/icon-m-search"
            EnterKey.onClicked: {
                flickable.forceActiveFocus();
                reloadList();
            }

            onClicked: {
                controlsPanel.hidePanel();
            }

        }

        Item {
            id: spacer
            height: Theme.paddingLarge
            anchors.top: header.bottom
        }

        Item {
            anchors.top: spacer.bottom
            height: parent.height - header.height - 3*Theme.paddingMedium
            width: parent.width

            SilicaListView {
                id: listView

                anchors.fill: parent
                anchors.bottomMargin: Theme.paddingLarge

                delegate: SongItem {}
                model: listModel
                maximumFlickVelocity: 2500*Theme.pixelRatio

                VerticalScrollDecorator {
                }

                Transition {
                    id: listViewDisplacedAnimation
                    NumberAnimation { properties: "y"; duration: 250 }
                }

                displaced: listViewDisplacedAnimation

                onMovementStarted: {
                    listView.forceActiveFocus();//hide keyboard
                    controlsPanel.partiallyHide();
                }

                onMovementEnded: {
                    if (!_searchInProgress && !_endOfAudioList && (contentHeight - contentY - height < 500*Theme.pixelRatio)){
                        if (AudioPlayerHelper.shuffle){//load only by button and last song
//                            requestMoreRandomSongs(_DEFAULT_RANDOM_SONGS_COUNT);
                        } else {
                            requestMoreSongs();
                        }
                    }
                }

                footer: _showMoreButtonVisible
                          ? showMoreButtonComponent
                          : loadingIndicatorComponent

            }
        }

        PullDownMenu {//TODO remorse timer
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    controlsPanel.hidePanel();
                    pageStack.push(Qt.resolvedUrl("About.qml"));
                }
            }
            MenuItem {
                text: qsTr("Logout")
                onClicked: {
                    remorsePopup.execute(qsTr("You will be logged out"), logout, 3000);
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
                    pageStack.push(Qt.resolvedUrl("LoginPage.qml"), {parentPage: musicList});
                }
                visible: !accessToken
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    wiseReload();
                }
                enabled: !_searchInProgress && accessToken
            }

        }

    }

    Label {
        id: pleaseLoginLabel

        anchors.centerIn: parent

        width: parent.width - 2*Theme.paddingSmall
        text: qsTr("Please login")
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeLarge
        visible: !accessToken
    }

    RemorsePopup {
        id: remorsePopup
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
            error: false
        }

        onRowsInserted: {
            _searchInProgress ? _searchInProgress = false : null;
        }

    }

    Component {
        id: loadingIndicatorComponent
        BusyIndicator {
            anchors.centerIn: parent
            size: BusyIndicatorSize.Medium
            running: _searchInProgress
            height: _searchInProgress ? Theme.iconSizeMedium : 0
        }
    }

    Component {
        id: showMoreButtonComponent
        Button {
            anchors.centerIn: parent
            text: qsTr("Show more")

            onClicked: {
                _showMoreButtonVisible = false
                _showMore = true;
                AudioPlayerHelper.shuffle ? requestMoreRandomSongs(_DEFAULT_RANDOM_SONGS_COUNT) : requestMoreSongs();
            }
        }
    }

    Timer {
        id: waitForPageStack
        interval: 1000
        running: false
        repeat: false

        onTriggered: {
            console.log("creating albums page")
            var albumsPage = pageStack.pushAttached(
                        Qt.resolvedUrl("AlbumsPage.qml")
                        , {applyAlbumFilter: applyAlbumFilter}
                        );
            if (albumsPage.listModel.count === 0){//update album list beforehand for smooth animation
                albumsPage.reloadAlbumList();
            } else {
                albumsPage.setCurrentItemIndex();
            }
        }
    }

    Notification {
        id: errorNotification
        category: "error"
        summary: qsTr("Error occured")
        onClicked: {
            console.log("Notification clicked");
        }
    }

    Loader {
        id:notificationLoader//do not change, binded to name in Notification component
    }



    Binding {
        target: AudioPlayerHelper
        property: "currentIndex"
        value: listView.currentIndex
    }

    Binding {
        target: AudioPlayerHelper
        property: "listSize"
        value: listModel.count
    }

    Binding {
        target: AudioPlayerHelper
        property: "downloadPlayListMode"
        value: downloadPlayListMode
    }

    Connections {
        target: applicationWindow

        onAccessTokenChanged: {//reload list
            console.log("MusicList:onAccessTokenChanged: " + accessToken);
            if (accessToken){
                reloadList();
                waitForPageStack.start();
            }
        }

        onCacheDirChanged: {
            //reload list
            console.log("onCacheDirChanged: " + cacheDir);
            if (cacheDir){
                reloadList();
            }
        }
    }

    Connections {
        target: AudioPlayerHelper

        onStatusChanged: {
            _justLoaded = false;
        }

        onPlayNextRequested: {
            controlsPanel.userInteraction = true;//magic
            if ((listView.currentIndex === undefined && listModel.count > 0)
                    || (_justLoaded && listModel.count > 0)
                    || (AudioPlayerHelper.repeat && listView.currentIndex === listModel.count - 1)
                ){//play first
                listView.currentIndex = 0;
                listView.currentItem.loadThisSong();
            } else if (listView.currentIndex < listModel.count - 1){//play next
                listView.currentIndex++;
                listView.currentItem.loadThisSong();
            }
        }

        onPlayPreviousRequested: {
            if (listView.currentIndex > 0){//play previous
                listView.currentIndex--;
                listView.currentItem.loadThisSong();
            }
        }

        onFileCached: {
            console.log("AudioPlayerHelper:onFileCached");
            listModel.setProperty(itemIndex, "cached", true);
            listModel.setProperty(itemIndex, "error", false);
        }

        onFileUnCached: {
            console.log("AudioPlayerHelper:onFileUnCached");
            listModel.setProperty(itemIndex, "cached", false);
            listModel.setProperty(itemIndex, "error", false);
        }

        onFileError: {
            console.log("AudioPlayerHelper:onFileError");
            listModel.setProperty(itemIndex, "cached", false);
            listModel.setProperty(itemIndex, "error", true);
        }

        onFileDeleted: {
            console.log("AudioPlayerHelper:onFileCached");
            for (var i = 0; i < listModel.count; i++){//remove cached icon
                if (fileName === Misc.getFileName(listModel.get(i))){
                    listModel.setProperty(i, "cached", false);
                    break;
                }
            }
        }

        onShuffleChanged: {
            console.log("AudioPlayerHelper:onShuffleChanged: shuffle = " + AudioPlayerHelper.shuffle);
            console.log("AudioPlayerHelper:onShuffleChanged: ignoreChange = " + ignoreChange);

            if (ignoreChange){
                return;
            }

            wiseReload();
        }
    }

    Component.onCompleted: {
        applicationWindow.validateToken();
        if (accessToken){
            reloadList();
            waitForPageStack.start();
        }
    }

    onStatusChanged: {
        if (musicList.status === PageStatus.Active){
            if (controlsPanel.song){
                controlsPanel.partiallyHide();
            }
        }
    }

    function wiseReload(){
        if (AudioPlayerHelper.shuffle) {//shuffle on
            if (searchField.visible){
                hideSearch.start();
            }
            clearAudioListModel();
            clearSearchField();
            controlsPanel.albumId = -2;
            _searchInProgress = true;
            VKAPI.getCount(musicListPage, accessToken, userId, parseAPIResponse_getCount);
        } else {//shuffle off
            clearAudioListModel();
            controlsPanel.albumId = -1;
            reloadList();
        }
    }

    function logout(){
        _searchInProgress = true;
        controlsPanel.hidePanel();
        clearAudioListModel();
        controlsPanel.stop();
        searchField.text = "";
        controlsPanel.albumId = -1;
        pageStack.popAttached();
        Utils.clearCookies();
        Utils.clearCacheDir(cacheDir);
        Database.clearLastAccessedDateTable();
        Database.setProperty("accessToken", "");
        Database.setProperty("userId", "");
        accessToken = "";
        userId = "";
        _searchInProgress = false;
    }

    function parseAPIResponse_getList(responseText){
        try {
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
            var count = 0;

            if (listModel.count === 0) {
                _justLoaded = true;
            }

            for (var i in items) {
                if (!_showMore && items[i].owner_id !== userId){
                    _showMoreButtonVisible = true;
                    break;
                }

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
                    , error: false
                };
                //check for cached file
                var filePath = Utils.getFilePath(cacheDir, Misc.getFileName(song));
                song.cached = filePath ? true : false;

                listModel.append(song);
                _listChanged = true;
            }
            console.log("added " + items.length + " songs to playlist");
            if (items.length < _DEFAULT_PAGE_SIZE && _showMore){
                console.log("reached end of the list");
                _endOfAudioList = true;
            }

        } finally {
            _searchInProgress = false;

            if (AudioPlayerHelper.shuffle){
                if (listModel.count === 1){//first song, autoplay
                    listView.currentIndex = 0;
                    listView.currentItem.loadThisSong();
                    if (_needMoreRandomSongsCount === 0){//request one more song
                        requestRandomSong();
                    }
                }
                if (_availableNumbers.length > 0){
                    if (_needMoreRandomSongsCount > 0){
                        requestRandomSong();
                    } else {
                        _showMoreButtonVisible = true;
                    }
                }

            }

            if (!controlsPanel.song && listModel.count > 0){
                listView.currentIndex = 0;
                listView.currentItem.loadThisSong(false);
            }
            if (!controlsPanel.open){
                controlsPanel.showFull();
            }
        }
    }

    function clearCacheIcons(){//should be called after clearing cache
        for (var i = 0; i < listModel.count; i++){
            listModel.setProperty(i, "cached", false);
        }
    }

    function reloadList(){
        console.log("reloadList");

        _showMore = false;
        _showMoreButtonVisible = false;

        if (!searchField.text){
            applySearchFilter();
            return;
        }

        _searchInProgress = true;
        clearAudioListModel();
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, 0, _DEFAULT_PAGE_SIZE, Utils.encodeURL(searchField.text), controlsPanel.albumId);
    }

    function requestMoreSongs(){
        console.log("requestMoreSongs");

        if (_searchInProgress || _endOfAudioList){
            return;
        }

        _searchInProgress = true;
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, listModel.count, _DEFAULT_PAGE_SIZE, Utils.encodeURL(searchField.text), controlsPanel.albumId);
    }

    function handleError(code, message){
        _searchInProgress = false;

        errorNotification.body = message;
        errorNotification.publish();

        errorMessage = message;
        errorCode = code;
        flickable.enabled = false;
        flickable.visible = false;
        notificationLoader.active = true;
        notificationLoader.source = "Notification.qml";
    }

    function applySearchFilter(){
        console.log("applySearchFilter");
        _searchInProgress = true;
        clearAudioListModel();
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, listModel.count, _DEFAULT_PAGE_SIZE, Utils.encodeURL(searchField.text), controlsPanel.albumId);
    }

    function clearAudioListModel(){
        console.log("clearListModel");
        _endOfAudioList = false;
        listView.displaced = null;
        listModel.clear();
        listView.displaced = listViewDisplacedAnimation;
    }

    function clearSearchField(){
        searchField.text = "";
    }

    function applyAlbumFilter(albumId, albumTitle){
        controlsPanel.albumTitle = albumTitle;
        controlsPanel.albumId = albumId;
        clearSearchField();
        AudioPlayerHelper.overrideShuffle(false);
        hideSearch.start();
        applySearchFilter();
    }

    function downloadPlayList(){
        console.log("downloadPlayList started");

        downloadPlayListMode = !downloadPlayListMode;

        if (downloadPlayListMode){
            if (listModel.count === 0){
                downloadPlayListMode = false;
                return;
            }

            errorMessage = qsTr("Downloading playlist...");
            errorCode = 0;
            flickable.enabled = false;
            flickable.visible = false;
            notificationLoader.active = true;
            notificationLoader.source = "Notification.qml";

            for (var i = 0; i < listModel.count; i++){
                if (!listModel.get(i).cached){
                    listView.currentIndex = i;
                    listView.currentItem.loadThisSong();
                    controlsPanel.showFull();
                    break;
                }
            }
        } else {
            errorMessage = qsTr("Downloading playlist stopped");
            errorCode = 0;
            flickable.enabled = false;
            flickable.visible = false;
            notificationLoader.active = true;
            notificationLoader.source = "Notification.qml";
        }

    }

    function parseAPIResponse_getCount(responseText){
        _searchInProgress = false;

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

        var responseCode = json.response;
        console.log("total songs count = " + responseCode);

        createShuffleSequence(responseCode);
        requestMoreRandomSongs(_DEFAULT_RANDOM_SONGS_COUNT);
    }

    function createShuffleSequence(totalCount){
        console.log("createShuffleSequence: count = " + totalCount);

        _availableNumbers = [];

        for (var i = 0; i < totalCount; i++){
            _availableNumbers[i] = i;
        }
    }

    function getRandomSongNumber(){
        console.log("getRandomSongNumber");

        var randomIndex = Math.floor(Math.random() * _availableNumbers.length);
        var num = _availableNumbers[randomIndex];
        _availableNumbers.splice(randomIndex, 1);

        console.log("getRandomSongNumber: random song number = " + num);

        return num;
    }

    function requestRandomSong(){
        console.log("requestRandomSong");

        if (_searchInProgress || _availableNumbers.length === 0){
            return;
        }

        var songNum = getRandomSongNumber();
        _searchInProgress = true;
        _needMoreRandomSongsCount--;
        VKAPI.getAudioList(musicListPage, accessToken, userId, parseAPIResponse_getList, songNum, 1);
    }

    function requestMoreRandomSongs(count){
        if (count < 1) {
            return;
        }
        _needMoreRandomSongsCount = count;

        requestRandomSong();
    }

}



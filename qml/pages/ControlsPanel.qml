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
import QtMultimedia 5.0
import harbour.vk.music.downloadmanager 1.0
import harbour.vk.music.audioplayerinfo 1.0
import "../utils/misc.js" as Misc
import "../utils/database.js" as DB

DockedPanel {
    id: controlsPanel

    property var song: {
        aid: 0
        ; owner_id: 0
        ; artist: ""
        ; title: ""
        ; duration: 0
        ; date: ""
        ; url: ""
        ; lyrics_id: 0
        ; album_id: 0
        ; genre_id: 0
        ; cached: false
    }
    property bool userInteraction: false
    property bool partiallyHidden: true
    property string albumTitle
    property int albumId: -1//default value for My music

    property alias audioPlayer: audioPlayer
    property alias nextButton: nextButton
    property alias previousButton: previousButton
    property alias sliderHeight: songProgress.height

    height: column.height
    width: parent.width

    opacity: Qt.inputMethod.visible ? 0.0 : 1.0
    Behavior on opacity { FadeAnimator {}}

    dock: Dock.Bottom

    Column{
        id: column

        width: parent.width
        spacing: partiallyHidden ? 0 : Theme.paddingMedium

        Rectangle {
            id: topSpacer
            visible: !partiallyHidden
            height: Theme.paddingSmall
            width: 1
            color: "transparent"
        }

        Label {
            id: artistLabel

            visible: !partiallyHidden

            text: {
                song.artist ? song.artist : ""
            }
            font.pixelSize: Theme.fontSizeMedium
            truncationMode: TruncationMode.Fade
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.paddingLarge
            color: Theme.highlightColor
        }

        ScrollingLabel {
            id: titleLabel

            visible: !partiallyHidden

            anchors {
                left: parent.left
                right: parent.right
            }

            text: {
                song.title ? song.title : ""
            }
            font.pixelSize: Theme.fontSizeMedium
            textOffset: Theme.horizontalPageMargin
            color: Theme.secondaryHighlightColor

            onTextChanged: {
                if (controlsPanel.open && !controlsPanel.partiallyHidden){
                    titleLabel.stopAnimation();
                    titleLabel.startAnimation();
                }
            }
        }

        Row {
            id: buttons
            spacing: Theme.paddingMedium

            visible: !partiallyHidden

            Rectangle {
                id: spacer
                height: 1
                width: (column.width - playButton.width - pauseButton.width - previousButton.width - nextButton.width - 4*Theme.paddingMedium) / 2
                color: "transparent"
            }

            IconButton {
                id: previousButton
                icon.source: "image://theme/icon-m-previous?" + (pressed === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    if (AudioPlayerInfo.currentIndex > 0){
                        userInteraction = true;
                        AudioPlayerInfo.currentIndex--;
                    }
                }
            }
            IconButton {
                id: playButton
                icon.source: "image://theme/icon-l-play?" + (audioPlayer.playbackState === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    console.log("playing audio");
                    play();
                }
            }
            IconButton {
                id: pauseButton
                icon.source: "image://theme/icon-l-pause?" + (audioPlayer.playbackState === Audio.PausedState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    console.log("paused audio");
                    pause();
                }
            }
            IconButton {
                id: nextButton
                icon.source: "image://theme/icon-m-next?" + (pressed === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    if (AudioPlayerInfo.currentIndex < AudioPlayerInfo.listSize - 1){
                        userInteraction = true;
                        AudioPlayerInfo.currentIndex++;
                    }
                }
            }
        }

        Slider {
            id: songProgress

            width: parent.width

            visible: open && (song.aid > 0)

            minimumValue: 0
            maximumValue: song.duration ? song.duration : 0
            value: 0
            valueText: partiallyHidden ?
                            ""
                            : Format.formatDuration(
                                   songProgress.value
                                   , songProgress.value >= 3600 ? Format.DurationLong : Format.DurationShort
                              )
                              + " - "
                              + Format.formatDuration(
                                    song.duration
                                    , song.duration >= 3600 ? Format.DurationLong : Format.DurationShort
                                )
            enabled: (audioPlayer.status === Audio.Loaded
                            || audioPlayer.status === Audio.Buffered)
                        && !partiallyHidden
                        && !song.error

            label: partiallyHidden
                   ? (song.artist
                      ? (song.artist
                         + (song.title
                            ? " - " + song.title
                            : ""))
                      : (song.title
                         ? song.title
                         : ""))
                   : ""

            onReleased: {
                audioPlayer.seek(value * 1000);
                console.log("new position = " + audioPlayer.position);
            }
        }
    }

    Item{
        anchors {
            right: column.right
            top: column.top
            topMargin: buttons.y + (buttons.height - downloadIndicator.height)/2
            rightMargin: Theme.paddingSmall
        }

        height: downloadIndicator.height
        width: downloadIndicator.width


        BusyIndicator {
            id: downloadIndicator

            property bool clearingCache: false

            size: BusyIndicatorSize.Medium
            running: applicationWindow.applicationActive
                        && (audioPlayer.status === Audio.Loading
                            || audioPlayer.status === Audio.Buffering
                            || downloadManager.downloading
                            || clearingCache
                            )


        }

        Text {
            id: progressText
            anchors.centerIn: downloadIndicator
            color: Theme.primaryColor
            visible: downloadIndicator.running
            font.pixelSize: Theme.fontSizeSmall
        }

        IconButton {
            id: cachedIcon

            anchors.centerIn: downloadIndicator

            icon.source: "image://theme/icon-s-device-upload"
            visible: false

            onClicked:{//clear cache
                downloadIndicator.clearingCache = true;
                Utils.deleteFile(cacheDir, Misc.getFileName(song));
                DB.removeLastAccessedEntry(Misc.getFileName(song));
                Utils.getFreeSpace(cacheDir);
                AudioPlayerInfo.signalFileUnCached(AudioPlayerInfo.currentIndex);
                controlsPanel.hideCacheIcon();
                downloadIndicator.clearingCache = false;
            }
        }

        Image {
            id: errorIcon

            anchors.centerIn: downloadIndicator

            height: Theme.iconSizeSmall
            width: Theme.iconSizeSmall
            source: "../images/exclamation.png"
            visible: false
        }
    }

    Label {
        id: bitRateLabel

        anchors.left: column.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.bottom: column.bottom

        visible: !partiallyHidden && enableBitRate

        font.pixelSize: Theme.fontSizeExtraSmall
    }

    Audio {
        id: audioPlayer

        onSourceChanged: {
            console.log("new song url: " + source);
        }

        onStatusChanged: {
            console.log("audio status: " + getAudioStatus(status));

            bitRateLabel.text = Math.floor(audioPlayer.metaData.audioBitRate/1000) + "kbps";
        }

        onPositionChanged: {
            if (applicationWindow.applicationActive && !songProgress.pressed) {
                songProgress.value = position / 1000
            }
        }

        onPlaying: {
            userInteraction = false;
            AudioPlayerInfo.status = AudioPlayerInfo.Playing;
        }

        onPaused: {
            userInteraction = false;
            AudioPlayerInfo.status = AudioPlayerInfo.Paused;
        }

        onStopped: {
            console.log("playback stopped with userInteraction = " + userInteraction);
            AudioPlayerInfo.status = AudioPlayerInfo.Paused;
            songProgress.value = 0;
            bitRateLabel.text = "";
            if (userInteraction){//stopped by user
                //do nothing
            } else {//end of the song, play next
                AudioPlayerInfo.currentIndex++;
            }
        }

    }

    MouseArea {
        id: dockPanelMouseArea

        anchors.fill: parent

        enabled: partiallyHidden

        onClicked: {
            console.log("dockPanelMouseArea:onClicked")
            showFull();
        }
    }




    DownloadManager {
        id: downloadManager

        property int retryCount: 0

        onDownloadStarted: {
            console.log("Download Started");
            AudioPlayerInfo.status = AudioPlayerInfo.Buffering;
        }

        onDownloadComplete: {
            console.log("Download Complete");
            retryCount = 0;
            AudioPlayerInfo.signalFileCached(AudioPlayerInfo.currentIndex);
            song.cached = true;
            cachedIcon.visible = true;
            audioPlayer.source = filePath;
            AudioPlayerInfo.status = AudioPlayerInfo.Paused;
            audioPlayer.play();
            DB.setLastAccessedDate(Misc.getFileName(song));
            Utils.getFreeSpace(cacheDir);
        }

        onDownloadUnsuccessful: {
            console.log("Download unsuccessful");
            errorIcon.visible = true;
            song.error = true;
            AudioPlayerInfo.signalFileError(AudioPlayerInfo.currentIndex);
//            AudioPlayerInfo.currentIndex++;
        }

        onProgress: {
            console.log("onProgress: " + nPercentage);
            progressText.text = nPercentage + "%"
        }
    }

    Connections {
        target: AudioPlayerInfo

        onPauseRequested: {
            pause();
        }

        onPlayRequested: {
            play();
        }

        onPlayNextRequested: {
            if (AudioPlayerInfo.currentIndex < AudioPlayerInfo.listSize - 1){
                userInteraction = true;
                AudioPlayerInfo.currentIndex++;
            }
        }
    }

    Timer {
        id: waitForDockerCloseAnimationAndOpenTimer

        triggeredOnStart: false
        interval: 0
        repeat: false
        running: false

        onTriggered: {
            partiallyHidden = true;
            if (AudioPlayerInfo.currentIndex !== -1
                    || song.aid > 0){
                show();
            }
        }
    }

    Timer {
        id: waitForKeyboardCloseAnimationAndOpenTimer

        triggeredOnStart: false
        interval: 500
        repeat: false
        running: false

        onTriggered: {
            if (AudioPlayerInfo.currentIndex !== -1
                    || song.aid > 0){
                show();
            }
        }
    }

    onAlbumIdChanged: {
        console.log("onAlbumIdChanged: " + albumId + " - " + albumTitle);
    }

    function getAudioStatus(status){
        switch(status){
            case Audio.NoMedia: return "No media";
            case Audio.Loading: return "Loading";
            case Audio.Loaded: return "Loaded";
            case Audio.Buffering: return "Buffering";
            case Audio.Stalled: return "Stalled";
            case Audio.Buffered: return "Buffered";
            case Audio.EndOfMedia: return "EndOfMedia";
            case Audio.InvalidMedia: return "InvalidMedia";
            case Audio.UnknownStatus: return "UnknownStatus";
            default: return "Undefined";
        }

    }

    function playSong(newSong){
        song = newSong;
        cachedIcon.visible = song.cached;
        errorIcon.visible = false;
        AudioPlayerInfo.title = song.title;
        AudioPlayerInfo.artist = song.artist;
        var fileName = Misc.getFileName(song);//no extension
        var filePath = Utils.getFilePath(cacheDir, fileName);
        if (filePath) {
            if (!song.cached){
                AudioPlayerInfo.signalFileCached(AudioPlayerInfo.currentIndex);
            }
            audioPlayer.source = filePath;
            audioPlayer.play();
            DB.setLastAccessedDate(fileName);
        } else {//check free space before download
            if (freeSpaceKBytes < minimumFreeSpaceKBytes){
                console.log("out of free disk space");
                for (var i = 0; i < 1000 && freeSpaceKBytes < minimumFreeSpaceKBytes; i++){//delete files until there is space
                    var lastAccessedFileName = DB.getLastAccessedFileName();
                    if (lastAccessedFileName){
                        freeSpaceKBytes += Utils.deleteFile(cacheDir, lastAccessedFileName);//returns size of deleted file
                        DB.removeLastAccessedEntry(lastAccessedFileName);
                        AudioPlayerInfo.signalFileDeleted(lastAccessedFileName);
                        console.log("freeSpaceKBytes after delete = " + freeSpaceKBytes);
                    } else {
                        break;
                    }
                }
            }
            if (freeSpaceKBytes < minimumFreeSpaceKBytes){//still? play from web
                audioPlayer.source = song.url;
                audioPlayer.play();
                Utils.getFreeSpace(cacheDir);
            } else {//free space ok, download
                downloadManager.download(song.url, fileName, cacheDir);
            }
        }
    }

    function partiallyHide(){
        console.log("partiallyHide");
        titleLabel.stopAnimation();

        if (!applicationWindow.applicationActive){
            return;
        }

        if (!partiallyHidden
                || !open){
            controlsPanel.hide(true);
            waitForDockerCloseAnimationAndOpenTimer.start();
        }
    }

    function hidePanel(){
        console.log("hidePanel");
        titleLabel.stopAnimation();

        if (!applicationWindow.applicationActive){
            return;
        }

        hide();
        partiallyHidden = true;
    }

    function showFull(){
        console.log("showFull");

        if (!applicationWindow.applicationActive){
            return;
        }

        partiallyHidden = false;

        if (!controlsPanel.open){
            waitForKeyboardCloseAnimationAndOpenTimer.start();
        }

        titleLabel.stopAnimation();
        titleLabel.startAnimation();
    }

    function stop(){
        if (audioPlayer.playbackState === Audio.PlayingState){
            audioPlayer.stop();
        }
    }

    function play(){
        userInteraction = true;
        if (song.cached){
            audioPlayer.play();
        } else {
            console.log("wow! song not cached or null");

            //maybe we are at index -1? start playing
            if (AudioPlayerInfo.currentIndex == -1){
                AudioPlayerInfo.currentIndex++;
            }
        }
    }

    function pause(){
        userInteraction = true;
        if (song.cached){
            audioPlayer.pause();
        } else {
            console.log("wow! song not cached, this should not happen!");
        }
    }

    function hideCacheIcon(){
        cachedIcon.visible = false;
    }
}

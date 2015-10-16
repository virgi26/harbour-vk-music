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
import "../utils/misc.js" as Misc
import "../utils/database.js" as DB

Page {
    id: settings
    property var clearIcons

    PageHeader {
        id: header
        title: qsTr("Settings")

        anchors.top: parent.top
    }

    SilicaFlickable {
        anchors {
            top: header.bottom
        }

        width: parent.width
        contentHeight: column.height

        Column {
            id: column

            width: parent.width

            spacing: Theme.paddingMedium

            DetailItem {
                id: freeSpace
                label: qsTr("Free space available")
                value: Math.floor(freeSpaceKBytes / 1024) + " MB"
            }

//            DetailItem {
//                id: minFreeSpace
//                label: qsTr("Minimum free space")
//                value: Math.floor(minimumFreeSpaceKBytes / 1024) + " MB"
//            }

            BackgroundItem {
                id: minFreeSpace
                width: parent.width
                height: Math.max(minFreeSpaceLabelText.height, minFreeSpaceValueText.height) + 2*Theme.paddingSmall

                Text {
                    id: minFreeSpaceLabelText

                    text: qsTr("Minimum free space")

                    y: Theme.paddingSmall
                    anchors {
                        left: parent.left
                        right: parent.horizontalCenter
                        rightMargin: Theme.paddingSmall
                        leftMargin: Theme.horizontalPageMargin
                    }
                    horizontalAlignment: Text.AlignRight
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }

                Text {
                    id: minFreeSpaceValueText

                    y: Theme.paddingSmall
                    anchors {
                        left: parent.horizontalCenter
                        right: parent.right
                        leftMargin: Theme.paddingSmall
                        rightMargin: Theme.horizontalPageMargin
                    }

                    text: {
                        switch (minimumFreeSpaceKBytes){
                            case 0: return qsTr("No restrictions");
                            case 1024*1024: return qsTr("1GB");
                            case 2*1024*1024: return qsTr("2GB");
                            case 5*1024*1024: return qsTr("5GB");
                            case 1024*1024*1024: return qsTr("No cache");
                            default: return qsTr("1GB");
                        }
                    }

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("MinSpaceDialog.qml"));
                }
            }

            DetailItem {
                id: cacheSize
                label: qsTr("Cache directory size")
                value: Utils.getCacheDirSize(cacheDir);

                BusyIndicator {
                    id: clearingCacheIndicator

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: Theme.paddingSmall
                    }

                    running: false;
                }
            }

            BackgroundItem {
                id: cacheDirPath
                width: parent.width
                height: Math.max(labelText.height, valueText.height) + 2*Theme.paddingSmall

                Text {
                    id: labelText

                    text: qsTr("Cache location")

                    y: Theme.paddingSmall
                    anchors {
                        left: parent.left
                        right: parent.horizontalCenter
                        rightMargin: Theme.paddingSmall
                        leftMargin: Theme.horizontalPageMargin
                    }
                    horizontalAlignment: Text.AlignRight
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }

                Text {
                    id: valueText

                    y: Theme.paddingSmall
                    anchors {
                        left: parent.horizontalCenter
                        right: parent.right
                        leftMargin: Theme.paddingSmall
                        rightMargin: Theme.horizontalPageMargin
                    }

                    text: {
                        switch (cacheDir){
                            case Utils.getDefaultCacheDirPath(): return qsTr("Local cache");
                            case sdcardPath + "/harbour-vk-music": return qsTr("SD card directory");
                            case sdcardPath + "/.harbour-vk-music": return qsTr("SD card hidden directory");
                            default: "";
                        }
                    }

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                }

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("CacheDirDialog.qml"));
                }
            }

            Button {
                text: qsTr("Clear cache directory")

                anchors.horizontalCenter: parent.horizontalCenter

                onPressed: {
                    clearingCacheIndicator.running = true;
                    Utils.clearCacheDir(cacheDir);
                    cacheSize.value = Utils.getCacheDirSize(cacheDir);
                    clearIcons();
                    clearingCacheIndicator.running = false;
                }
            }

            TextSwitch {
                id: humanFriendlyFileNamesSwitch

                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Human friendly file names")
                checked: humanFriendlyFileNames

                onCheckedChanged: {
                    humanFriendlyFileNames = checked;
                }

                enabled: false;
            }

            TextSwitch {
                id: enableBitRateSwitch

                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Show bit rate")
                checked: enableBitRate

                onCheckedChanged: {
                    enableBitRate = checked;
                    DB.setProperty("enableBitRate", enableBitRate);
                }
            }
        }


    }
}

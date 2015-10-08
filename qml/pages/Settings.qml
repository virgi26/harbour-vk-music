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
                label: qsTr("Author")
                value: "Alexander Ladygin (virgi26)"
            }

            DetailItem {
                label: qsTr("Mail to")
                value: "fake.ae@gmail.com"
            }

            DetailItem {
                id: cacheSize
                label: qsTr("Cache directory size")
                value: Utils.getCacheDirSize("");

                BusyIndicator {
                    id: clearingCacheIndicator

                    anchors {
                        verticalCenter: cacheSize.verticalCenter
                        right: cacheSize.right
                        rightMargin: Theme.paddingSmall
                    }

                    running: false;
                }
            }

            Button {
                text: qsTr("Clear cache directory")

                anchors.horizontalCenter: parent.horizontalCenter

                onPressed: {
                    clearingCacheIndicator.running = true;
                    Utils.clearCacheDir("");
                    cacheSize.value = Utils.getCacheDirSize("");
                    clearIcons();
                    clearingCacheIndicator.running = false;
                }
            }
        }


    }
}

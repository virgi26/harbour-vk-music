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
#include "audioplayerinfo.h"
#include <QDebug>

AudioPlayerInfo::AudioPlayerInfo(QObject *parent):
    QObject(parent)
    , _currentIndex(-1)
{
}

AudioPlayerInfo::~AudioPlayerInfo(){

}

void AudioPlayerInfo::setCurrentIndex(int newIndex){
    if (newIndex == _currentIndex){
        return;
    }

//    qDebug() << "currentIndex = " << newIndex;
    _currentIndex = newIndex;
    emit currentIndexChanged();
}

void AudioPlayerInfo::setListSize(int newListSize){
    if (newListSize == _listSize){
        return;
    }

//    qDebug() << "currentListSize = " << newListSize;
    _listSize = newListSize;
    emit listSizeChanged();
}

void AudioPlayerInfo::setStatus(Status newStatus){
    if (newStatus == _status){
        return;
    }

//    qDebug() << "status = " << newStatus;
    _status = newStatus;
    emit statusChanged();
}

void AudioPlayerInfo::setTitle(QString newTitle){
    if (newTitle == _title){
        return;
    }

//    qDebug() << "title = " << newTitle;
    _title = newTitle;
    emit titleChanged();
}

void AudioPlayerInfo::setArtist(QString newArtist){
    if (newArtist == _artist){
        return;
    }

//    qDebug() << "artist = " << newArtist;
    _artist = newArtist;
    emit artistChanged();
}

void AudioPlayerInfo::play(){
    emit playRequested();
}

void AudioPlayerInfo::pause(){
    emit pauseRequested();
}

void AudioPlayerInfo::playNext(){
    emit playNextRequested();
}

void AudioPlayerInfo::signalFileCached(int itemIndex){
    emit fileCached(itemIndex);
}

void AudioPlayerInfo::signalFileDeleted(QString fileName){
    emit fileDeleted(fileName);
}

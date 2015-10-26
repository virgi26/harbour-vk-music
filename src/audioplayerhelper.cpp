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
#include "audioplayerhelper.h"
#include <QDebug>

AudioPlayerHelper::AudioPlayerHelper(QObject *parent):
    QObject(parent)
    , _currentIndex(-1)
    , _shuffle(false)
    , _repeat(false)
{
}

AudioPlayerHelper::~AudioPlayerHelper(){

}

void AudioPlayerHelper::setCurrentIndex(int newIndex){
    if (newIndex == _currentIndex){
        return;
    }

//    qDebug() << "currentIndex = " << newIndex;
    _currentIndex = newIndex;
    emit currentIndexChanged();
}

void AudioPlayerHelper::setListSize(int newListSize){
    if (newListSize == _listSize){
        return;
    }

//    qDebug() << "currentListSize = " << newListSize;
    _listSize = newListSize;
    emit listSizeChanged();
}

void AudioPlayerHelper::setStatus(Status newStatus){
    if (newStatus == _status){
        return;
    }

//    qDebug() << "status = " << newStatus;
    _status = newStatus;
    emit statusChanged();
}

void AudioPlayerHelper::setTitle(QString newTitle){
    if (newTitle == _title){
        return;
    }

//    qDebug() << "title = " << newTitle;
    _title = newTitle;
    emit titleChanged();
}

void AudioPlayerHelper::setArtist(QString newArtist){
    if (newArtist == _artist){
        return;
    }

//    qDebug() << "artist = " << newArtist;
    _artist = newArtist;
    emit artistChanged();
}

void AudioPlayerHelper::setShuffle(bool shuffle){
    if (shuffle == _shuffle){
        return;
    }

    _shuffle = shuffle;
    emit shuffleChanged(false);
}

void AudioPlayerHelper::overrideShuffle(bool shuffle){
    _shuffle = shuffle;
    emit shuffleChanged(true);
}

void AudioPlayerHelper::setRepeat(bool repeat){
    if (repeat == _repeat){
        return;
    }

    _repeat = repeat;
    emit repeatChanged();
}

void AudioPlayerHelper::setDownloadPlayListMode(bool downloadPlayListMode){
    if (downloadPlayListMode == _downloadPlayListMode){
        return;
    }

    _downloadPlayListMode = downloadPlayListMode;
    emit downloadPlayListModeChanged();
}

void AudioPlayerHelper::play(){
    emit playRequested();
}

void AudioPlayerHelper::pause(){
    emit pauseRequested();
}

void AudioPlayerHelper::playNext(){
    emit playNextRequested();
}

void AudioPlayerHelper::playPrevious(){
    emit playPreviousRequested();
}

void AudioPlayerHelper::signalFileCached(int itemIndex){
    emit fileCached(itemIndex);
}

void AudioPlayerHelper::signalFileError(int itemIndex){
    emit fileError(itemIndex);
}

void AudioPlayerHelper::signalFileUnCached(int itemIndex){
    emit fileUnCached(itemIndex);
}

void AudioPlayerHelper::signalFileDeleted(QString fileName){
    emit fileDeleted(fileName);
}

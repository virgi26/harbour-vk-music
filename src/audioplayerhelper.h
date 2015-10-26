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

#ifndef AUDIOPLAYERHELPER_H
#define AUDIOPLAYERHELPER_H

#include <QObject>

class AudioPlayerHelper : public QObject
{
    Q_OBJECT
    Q_ENUMS(Status)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString artist READ artist WRITE setArtist NOTIFY artistChanged)
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(int listSize READ listSize WRITE setListSize NOTIFY listSizeChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(bool repeat READ repeat WRITE setRepeat NOTIFY repeatChanged)
    Q_PROPERTY(bool downloadPlayListMode READ downloadPlayListMode WRITE setDownloadPlayListMode NOTIFY downloadPlayListModeChanged)

public:
    AudioPlayerHelper(QObject *parent = 0);
    ~AudioPlayerHelper();

    enum Status {
        Playing
        , Paused
        , Buffering
    };

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrevious();
    Q_INVOKABLE void signalFileCached(int itemIndex);
    Q_INVOKABLE void signalFileError(int itemIndex);
    Q_INVOKABLE void signalFileUnCached(int itemIndex);
    Q_INVOKABLE void signalFileDeleted(QString fileName);
    Q_INVOKABLE void overrideShuffle(bool shuffle);


    int currentIndex() const {return _currentIndex;}
    void setCurrentIndex(int newIndex);

    int listSize() const {return _listSize;}
    void setListSize(int newListSize);

    QString title() const {return _title;}
    void setTitle(QString newTitle);

    QString artist() const {return _artist;}
    void setArtist(QString newArtist);

    Status status() const {return _status;}
    void setStatus(Status newStatus);

    bool shuffle() const {return _shuffle;}
    void setShuffle(bool shuffle);

    bool repeat() const {return _repeat;}
    void setRepeat(bool repeat);

    bool downloadPlayListMode() const {return _downloadPlayListMode;}
    void setDownloadPlayListMode(bool downloadPlayListMode);

signals:
    void downloadPlayListModeChanged();
    void repeatChanged();
    void shuffleChanged(bool ignoreChange);
    void currentIndexChanged();
    void statusChanged();
    void titleChanged();
    void artistChanged();
    void playRequested();
    void pauseRequested();
    void playNextRequested();
    void playPreviousRequested();
    void listSizeChanged();
    void fileCached(int itemIndex);
    void fileError(int itemIndex);
    void fileUnCached(int itemIndex);
    void fileDeleted(QString fileName);

private:
    int _currentIndex;
    int _listSize;
    QString _title;
    QString _artist;
    Status _status;
    bool _shuffle;
    bool _repeat;
    bool _downloadPlayListMode;
};

#endif // AUDIOPLAYERHELPER_H

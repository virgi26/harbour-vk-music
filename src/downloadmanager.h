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
#ifndef DOWNLOADMANAGER_H
#define DOWNLOADMANAGER_H

#include <QtGlobal>
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFile>
#include <QTimer>
#include <QStandardPaths>


class DownloadManager : public QObject
{
    Q_OBJECT

public:
    explicit DownloadManager(QObject *parent = 0);
    virtual ~DownloadManager();
    Q_PROPERTY(QString filePath READ filePath)
    QString filePath(){return _filePath;}
    Q_PROPERTY(bool downloading READ downloading NOTIFY downloadingChanged)
    bool downloading(){return _downloading;}

signals:
//    void addLine(QString qsLine);
    void downloadComplete();
    void progress(int nPercentage);
    void downloadStarted();
    void downloadingChanged();
    void downloadUnsuccessful();

public slots:
    void download(QUrl url, QString fileName, QString localDirPath);
    void pause();
    void resume();

private slots:
    void download();
    void finishedHead();
    void finished();
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void error(QNetworkReply::NetworkError code);
    void timeout();

private:
    QUrl _URL;
    QString _qsFileName;
    QNetworkAccessManager* _pManager;
    QNetworkRequest _CurrentRequest;
    QNetworkReply* _pCurrentReply;
    QFile* _pFile;
    int _nDownloadTotal;
    bool _bAcceptRanges;
    int _nDownloadSize;
    int _nDownloadSizeAtPause;
    QTimer _Timer;
    QString _filePath;
    bool _downloading;
};

#endif // DOWNLOADMANAGER_H

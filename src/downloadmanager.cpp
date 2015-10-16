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
#include "downloadmanager.h"
#include "utils.h"

#include <QFileInfo>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>


DownloadManager::DownloadManager(QObject *parent) :
    QObject(parent)
    , _pManager(NULL)
    , _pCurrentReply(NULL)
    , _pFile(NULL)
    , _nDownloadTotal(0)
    , _bAcceptRanges(false)
    , _nDownloadSize(0)
    , _nDownloadSizeAtPause(0)
    , _downloading(false)
{
}


DownloadManager::~DownloadManager()
{
    if (_pCurrentReply != NULL)
    {
        pause();
    }
}


void DownloadManager::download(QUrl url, QString fileName, QString localDirPath)
{
    qDebug() << "download: URL = " <<url.toString();

    if (_pCurrentReply != NULL)
    {
        pause();
    }

    _URL = url;
    _fileName = fileName;
    {
        if (!localDirPath.isNull() && !localDirPath.isEmpty()) {
            _path = localDirPath;
        } else {
            _path = Utils().getDefaultCacheDirPath();
        }

        QString extension = "mp3";//vk only allows mp3

        QFileInfo fileInfo(_path.append("/").append(fileName).append(".").append(extension));

        _qsFileAbsPath = fileInfo.absoluteFilePath();
        qDebug() << "download: local path =" << _qsFileAbsPath;
    }
    _nDownloadSize = 0;
    _nDownloadSizeAtPause = 0;

    _pManager = new QNetworkAccessManager(this);
    _CurrentRequest = QNetworkRequest(url);

    _pCurrentReply = _pManager->head(_CurrentRequest);
    emit downloadStarted();
    _downloading =true;
    emit downloadingChanged();

    _Timer.setInterval(5000);
    _Timer.setSingleShot(true);
    connect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    _Timer.start();

    connect(_pCurrentReply, SIGNAL(finished()), this, SLOT(finishedHead()));
    connect(_pCurrentReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));
}


void DownloadManager::pause()
{
    qDebug() << "pause() = " << _nDownloadSize;
    if (_pCurrentReply == NULL)
    {
        return;
    }
    _Timer.stop();
    disconnect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    disconnect(_pCurrentReply, SIGNAL(finished()), this, SLOT(finished()));
    disconnect(_pCurrentReply, SIGNAL(downloadProgress(qint64,qint64)), this, SLOT(downloadProgress(qint64,qint64)));
    disconnect(_pCurrentReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));

    _pCurrentReply->abort();
//    _pFile->write( _pCurrentReply->readAll());
    _pFile->flush();
    _pCurrentReply = 0;
    _nDownloadSizeAtPause = _nDownloadSize;
    _nDownloadSize = 0;
}


void DownloadManager::resume()
{
    qDebug() << "resume() = " << _nDownloadSizeAtPause;

    download();
}


void DownloadManager::download()
{
    qDebug() << "download()";

    if (_bAcceptRanges)
    {
        QByteArray rangeHeaderValue = "bytes=" + QByteArray::number(_nDownloadSizeAtPause) + "-";
        if (_nDownloadTotal > 0)
        {
            rangeHeaderValue += QByteArray::number(_nDownloadTotal);
        }
        _CurrentRequest.setRawHeader("Range", rangeHeaderValue);
    }

    _pCurrentReply = _pManager->get(_CurrentRequest);

    _Timer.setInterval(5000);
    _Timer.setSingleShot(true);
    connect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    _Timer.start();

    connect(_pCurrentReply, SIGNAL(finished()), this, SLOT(finished()));
    connect(_pCurrentReply, SIGNAL(downloadProgress(qint64,qint64)), this, SLOT(downloadProgress(qint64,qint64)));
    connect(_pCurrentReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));
}


void DownloadManager::finishedHead()
{
    _Timer.stop();
    _bAcceptRanges = false;

    QList<QByteArray> list = _pCurrentReply->rawHeaderList();
    foreach (QByteArray header, list)
    {
        QString qsLine = QString(header) + " = " + _pCurrentReply->rawHeader(header);
//        emit addLine(qsLine);
    }

    if (_pCurrentReply->hasRawHeader("Accept-Ranges"))
    {
        QString qstrAcceptRanges = _pCurrentReply->rawHeader("Accept-Ranges");
        _bAcceptRanges = (qstrAcceptRanges.compare("bytes", Qt::CaseInsensitive) == 0);
        qDebug() << "Accept-Ranges = " << qstrAcceptRanges << _bAcceptRanges;
    }

    _nDownloadTotal = _pCurrentReply->header(QNetworkRequest::ContentLengthHeader).toInt();

//    _CurrentRequest = QNetworkRequest(url);
    _CurrentRequest.setRawHeader("Connection", "Keep-Alive");
    _CurrentRequest.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, true);
    _pFile = new QFile(_qsFileAbsPath + ".part");
    if (!_bAcceptRanges)
    {
        _pFile->remove();
    }
    _pFile->open(QIODevice::ReadWrite | QIODevice::Append);

    _nDownloadSizeAtPause = _pFile->size();
    download();
}


void DownloadManager::finished()
{
    qDebug() << __FUNCTION__;

    _Timer.stop();
    _pFile->close();
    QFile::remove(_qsFileAbsPath);
    QFile::rename(_qsFileAbsPath + ".part", _qsFileAbsPath);
    _pCurrentReply = 0;
    if (QFile(_qsFileAbsPath).size() > 1000){
        emit downloadComplete(_qsFileAbsPath);
    } else {
        QFile::remove(_qsFileAbsPath);
        emit downloadUnsuccessful();
    }
    _pFile = NULL;
    _downloading = false;
    emit downloadingChanged();
}


void DownloadManager::downloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    _Timer.stop();
    _nDownloadSize = _nDownloadSizeAtPause + bytesReceived;
    qDebug() << "Download Progress: Received=" << _nDownloadSize <<": Total=" << _nDownloadSizeAtPause + bytesTotal;

    _pFile->write(_pCurrentReply->readAll());
    int nPercentage = static_cast<int>((static_cast<float>(_nDownloadSizeAtPause + bytesReceived) * 100.0) / static_cast<float>(_nDownloadSizeAtPause + bytesTotal));
    qDebug() << nPercentage;
    emit progress(nPercentage);

    _Timer.start(5000);
}


void DownloadManager::error(QNetworkReply::NetworkError code)
{
    qDebug() << __FUNCTION__ << "(" << code << ")";
    emit downloadUnsuccessful();
}


void DownloadManager::timeout()
{
    qDebug() << __FUNCTION__;
}

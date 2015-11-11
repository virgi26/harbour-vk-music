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
    , _pReply(NULL)
    , _pFile(NULL)
    , _configManager()
    , _nDownloadTotal(0)
    , _bAcceptRanges(false)
    , _nDownloadSize(0)
    , _nDownloadSizeAtPause(0)
    , _downloading(false)
{
    _pManager = new QNetworkAccessManager(this);
    connect(&_configManager, SIGNAL(updateCompleted()), this, SLOT(configurationUpdated()));
}

DownloadManager::~DownloadManager()
{
    if (_pReply != NULL)
    {
        abort();
    }
}

void DownloadManager::networkAccessibleChanged(QNetworkAccessManager::NetworkAccessibility accessible){
    if (accessible != QNetworkAccessManager::Accessible){
        _configManager.updateConfigurations();
    }
}

void DownloadManager::configurationUpdated(){
    qDebug() << "configurationUpdated";
    QList<QNetworkConfiguration> activeConfigs = _configManager.allConfigurations(QNetworkConfiguration::Active);

    if (activeConfigs.count() > 0) {
        _pManager->setConfiguration(activeConfigs.at(0));
        qDebug() << "QNetworkConfiguration = " << activeConfigs.at(0).name();

        _pManager = new QNetworkAccessManager(this);
        _pManager->clearAccessCache();
    }

}

void DownloadManager::download(QUrl url, QString fileName, QString localDirPath)
{
    qDebug() << "download: URL = " <<url.toString();

    if (_pReply != NULL)
    {
        abort();
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

//    _pManager = new QNetworkAccessManager(this);
    _request = QNetworkRequest(url);

    _pReply = _pManager->head(_request);
    emit downloadStarted();
    setDownloading(true);

    _Timer.setInterval(5000);
    _Timer.setSingleShot(true);
    connect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    _Timer.start();

    connect(_pReply, SIGNAL(finished()), this, SLOT(finishedHead()));
    connect(_pReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));
}


void DownloadManager::pause()
{
    qDebug() << "pause() = " << _nDownloadSize;
    if (_pReply == NULL)
    {
        return;
    }
    _Timer.stop();
    disconnect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    disconnect(_pReply, SIGNAL(finished()), this, SLOT(finished()));
    disconnect(_pReply, SIGNAL(downloadProgress(qint64,qint64)), this, SLOT(downloadProgress(qint64,qint64)));
    disconnect(_pReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));

    _pReply->abort();
//    _pFile->write( _pCurrentReply->readAll());
    _pFile->flush();
    _pReply = 0;
    _nDownloadSizeAtPause = _nDownloadSize;
    _nDownloadSize = 0;

    setDownloading(false);
}

void DownloadManager::abort() {
    qDebug() << "abort()";
    if (_pReply == NULL)
    {
        return;
    }
    _Timer.stop();
    disconnect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    disconnect(_pReply, SIGNAL(finished()), this, SLOT(finished()));
    disconnect(_pReply, SIGNAL(downloadProgress(qint64,qint64)), this, SLOT(downloadProgress(qint64,qint64)));
    disconnect(_pReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));

    _pReply->abort();
    _pFile->flush();
    _pFile->remove();
    _pReply = 0;
    _nDownloadSizeAtPause = 0;
    _nDownloadSize = 0;

    emit downloadCanceled();

    setDownloading(false);
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
        _request.setRawHeader("Range", rangeHeaderValue);
    }

    _pReply = _pManager->get(_request);

    _Timer.setInterval(5000);
    _Timer.setSingleShot(true);
    connect(&_Timer, SIGNAL(timeout()), this, SLOT(timeout()));
    _Timer.start();

    connect(_pReply, SIGNAL(finished()), this, SLOT(finished()));
    connect(_pReply, SIGNAL(downloadProgress(qint64,qint64)), this, SLOT(downloadProgress(qint64,qint64)));
    connect(_pReply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));
}


void DownloadManager::finishedHead()
{
    _Timer.stop();
    _bAcceptRanges = false;

    QList<QByteArray> list = _pReply->rawHeaderList();
    foreach (QByteArray header, list)
    {
        QString qsLine = QString(header) + " = " + _pReply->rawHeader(header);
//        emit addLine(qsLine);
    }

    if (_pReply->hasRawHeader("Accept-Ranges"))
    {
        QString qstrAcceptRanges = _pReply->rawHeader("Accept-Ranges");
        _bAcceptRanges = (qstrAcceptRanges.compare("bytes", Qt::CaseInsensitive) == 0);
        qDebug() << "Accept-Ranges = " << qstrAcceptRanges << _bAcceptRanges;
    }

    _nDownloadTotal = _pReply->header(QNetworkRequest::ContentLengthHeader).toInt();

//    _CurrentRequest = QNetworkRequest(url);
    _request.setRawHeader("Connection", "Keep-Alive");
    _request.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, true);
//    _pFile = new QFile(_qsFileAbsPath + ".part");
    _pFile = new QFile(_qsFileAbsPath);
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
//    QFile::remove(_qsFileAbsPath);
//    QFile::rename(_qsFileAbsPath + ".part", _qsFileAbsPath);
    _pReply = 0;
    if (QFile(_qsFileAbsPath).size() > 1000){
        emit downloadComplete(_qsFileAbsPath);
    } else {
        QFile::remove(_qsFileAbsPath);
        error(QNetworkReply::NetworkError(0));
    }
    _pFile = NULL;
    setDownloading(false);
}


void DownloadManager::downloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    _Timer.stop();
    _nDownloadSize = _nDownloadSizeAtPause + bytesReceived;
    qDebug() << "Download Progress: Received=" << _nDownloadSize <<": Total=" << _nDownloadSizeAtPause + bytesTotal;

    _pFile->write(_pReply->readAll());
    int nPercentage = static_cast<int>((static_cast<float>(_nDownloadSizeAtPause + bytesReceived) * 100.0) / static_cast<float>(_nDownloadSizeAtPause + bytesTotal));
    qDebug() << nPercentage;
    emit progress(nPercentage);

    _Timer.start(5000);
}


void DownloadManager::error(QNetworkReply::NetworkError code)
{
    qDebug() << __FUNCTION__ << "(" << code << ")";
    qDebug() << "configuration = " << _pManager->configuration().name();
    emit downloadUnsuccessful();
    _configManager.updateConfigurations();
}


void DownloadManager::timeout()
{
    qDebug() << __FUNCTION__;
}

void DownloadManager::setDownloading(bool downloading){
    if (downloading == _downloading){
        return;
    }

    _downloading = downloading;
    emit downloadingChanged();
}

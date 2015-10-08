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
#include "utils.h"
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QUrl>

/* Return codes:
 * 0 - success
 * 1 - cache doesn't exist
 * -1 - cannot delete cache
 * -2 - failed to find cache directory
 */
int Utils::clearCookies() {
    QStringList dataPaths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
    if(dataPaths.size()) {
        QDir webData(QDir(dataPaths.at(0)).filePath(".QtWebKit"));
        if(webData.exists()) {
            if(webData.removeRecursively())
                return 0;
            else
                return -1;
        }
        else
            return 1;
    }
    return -2;
}

QString Utils::encodeURL(QString url){
    return QUrl::toPercentEncoding(url);
}

QString Utils::getCacheDirSize(QString dirPath){
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }
    qDebug() << "Calculating dir size for: " << dirPath;

    qint64 size(0);
    QDir qDir(dirPath);
    QStringList list;
    list.append("*.mp3");
    qDir.setNameFilters(list);
    foreach (QFileInfo fileInfo, qDir.entryInfoList(list)){
        qDebug() << "Found file '" << fileInfo.fileName() << "', size: " << fileInfo.size();
        size += fileInfo.size();
    }
    qDebug() << "Dir size: " << size << " bytes";
    int mbSize = int(int(size / 1024) / 1024);

    return QString::number(mbSize).append(" MB") ;
}

void Utils::clearCacheDir(QString dirPath) {
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }
    qDebug() << "Clearing content of dir: " << dirPath;

    int count = 0;
    QDir qDir(dirPath);
    QStringList list;
    list.append("*.mp3");
    qDir.setNameFilters(list);
    foreach (QFileInfo fileInfo, qDir.entryInfoList(list)){
        qDebug() << "Deleting file '" << fileInfo.fileName();
        QFile::remove(fileInfo.absoluteFilePath());
        count++;
    }
    qDebug() << "Deleted " << count << " files";
}

void Utils::clearCacheDirFromGarbage(QString dirPath, QString userId) {
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }
    qDebug() << "Clearing garbage of dir: " << dirPath;
    qDebug() << "User Id: " << userId;

    int count = 0;
    QDir qDir(dirPath);
    QStringList list;
    list << "*.mp3" << "*.mp3.part";
    qDir.setNameFilters(list);
    foreach (QFileInfo fileInfo, qDir.entryInfoList(list)){
        if (!fileInfo.fileName().startsWith(userId + "_")
                || fileInfo.fileName().endsWith(".part")){
            qDebug() << "Deleting file '" << fileInfo.fileName();
            QFile::remove(fileInfo.absoluteFilePath());
            count++;
        }
    }
    qDebug() << "Deleted " << count << " files";
}

QString Utils::getDefaultCacheDirPath() {

    QString dirPath;
    QStringList location = QStandardPaths::standardLocations(QStandardPaths::CacheLocation);
    if (location.isEmpty()) {
        dirPath = QString("$XDG_CACHE_HOME/harbour-vk-music/");
    } else {
        dirPath = location.first();
    }

    return dirPath;
}

QString Utils::getFilePath(QString dirPath, QString fileName){
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }

    QFileInfo fileInfo(dirPath + "/" + fileName + ".mp3");

    QString filePath = fileInfo.absoluteFilePath();
    if (!fileInfo.exists() || !fileInfo.isReadable() || fileInfo.size() == 0){
//        qDebug() << "Cached file not found: " << filePath;
        return "";
    }

//    qDebug() << "Found cached file: " + filePath;

    return filePath;
}

Utils::Utils(QObject *parent) :
    QObject(parent){
//    mceReqInterface("com.nokia.mce",
//                    "/com/nokia/mce/request",
//                    "com.nokia.mce.request",
//                    QDBusConnection::connectToBus(QDBusConnection::SystemBus, "system")) {
//    pauseRefresher = new QTimer();
//    connect(pauseRefresher, SIGNAL(timeout()), this, SLOT(refreshPause()));
}
Utils::~Utils() { }

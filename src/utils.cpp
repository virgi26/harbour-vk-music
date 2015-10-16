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
#include "utils.h"
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QUrl>
#include <QVariant>
#include <QList>
#include <QVariantList>
#include <QException>
#include <QIODevice>

bool Utils::checkCacheDir(QString dirPath){
    qDebug() << "checkCacheDir: " + dirPath;

    if (dirPath.isNull() || dirPath.isEmpty()){
        qDebug() << "checkCacheDir: dirPath is empty";
        return false;
    }

    QDir dir(dirPath);
    if (!dir.exists()){
        qDebug() << "checkCacheDir: dirPath does not exist, will try to create";
        QString dirName = dir.dirName();
        if (!dir.cdUp()){
            qDebug() << "checkCacheDir: dirPath's parent does not exist";
            return false;
        }
        if (!dir.mkdir(dirName)){
            qDebug() << "checkCacheDir: can not create dirPath";
            return false;
        }
    }
    QFile tempFile(dirPath + "/.vk-music-temp");
    if (!tempFile.open(QIODevice::ReadWrite)){
        qDebug() << "checkCacheDir: dirPath is not writable";
        return false;
    }
    tempFile.close();
    qDebug() << "checkCacheDir: dirPath is OK";
    return true;
}

void Utils::getFreeSpace(QString dirPath){
    qDebug() << "getFreeSpace: " + dirPath;
    m_process = new QProcess(this);
    QObject::connect(m_process, SIGNAL(finished(int)), SLOT(freeSpaceResponse(int)));
    m_process->start("df " + dirPath);
}

void Utils::freeSpaceResponse( int signum )
{
    qDebug() << "freeSpaceResponse: " + signum;
    QTextStream stream(m_process);
    m_process->deleteLater();

    QString responseText = stream.readAll();
    qDebug() << responseText;

    if (responseText.isNull() || responseText.isEmpty()){
        return;
    }

    try {
        emit freeSpaceUpdated(responseText.split(QRegExp("\\n+")).at(1).split(QRegExp("[\\s\\t]+")).at(3).toInt());
    } catch (QException &ex) {
        qDebug() << "Error while parsing 'df' output ";
        emit freeSpaceUpdated(-1);
    }
}

QString Utils::sdcardPath() const//from FileBrowser
{
    // get sdcard dir candidates
    QDir dir("/media/sdcard");
    if (!dir.exists())
        return QString();
    dir.setFilter(QDir::AllDirs | QDir::NoDotAndDotDot);
    QStringList sdcards = dir.entryList();
    if (sdcards.isEmpty())
        return QString();

    // remove all directories which are not mount points
    QStringList mps = mountPoints();
    QMutableStringListIterator i(sdcards);
    while (i.hasNext()) {
        QString dirname = i.next();
        QString abspath = dir.absoluteFilePath(dirname);
        if (!mps.contains(abspath))
            i.remove();
    }

    // none found, return empty string
    if (sdcards.isEmpty())
        return QString();

    // if only one directory, then return it
    if (sdcards.count() == 1)
        return dir.absoluteFilePath(sdcards.first());

    // if multiple directories, then return "/media/sdcard", which is the parent for them
//    return "/media/sdcard";
    return QString();
}

QStringList Utils::mountPoints() const//from FileBrowser
{
    // read /proc/mounts and return all mount points for the filesystem
    QFile file("/proc/mounts");
    if (!file.open(QFile::ReadOnly | QFile::Text))
        return QStringList();

    QTextStream in(&file);
    QString result = in.readAll();

    // split result to lines
    QStringList lines = result.split(QRegExp("[\n\r]"));

    // get columns
    QStringList dirs;
    foreach (QString line, lines) {
        QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        if (columns.count() < 6) // sanity check
            continue;

        QString dir = columns.at(1);
        dirs.append(dir);
    }

    return dirs;
}

int Utils::clearCookies() {
    QStringList dataPaths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
    if(dataPaths.size()) {
        QDir webData(QDir(dataPaths.at(0)).filePath(".QtWebKit"));
        if(webData.exists()) {
            if(webData.removeRecursively())
                return 0;//success
            else
                return -1;//cannot delete cache
        }
        else
            return 1;//cache doesn't exist
    }
    return -2;//failed to find cache directory
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

int Utils::deleteFile(QString dirPath, QString fileName){
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }
    QString file = dirPath + "/" + fileName + ".mp3";
    qDebug() << "Deleting file: " << file;
    QFileInfo fileInfo(file);
    int size = fileInfo.size();
    qDebug() << "File size: " << size;

    if (QFile::remove(file)){
        qDebug() << "Deleted " << file;
        return int(size / 1024);//return KB
    } else {
        qDebug() << "File " << file << " not found or can not be deleted";
        return 0;
    }
}

QVariantList Utils::getCachedFileNames(QString dirPath){
    if (dirPath.isNull() || dirPath.isEmpty()){
        dirPath = Utils::getDefaultCacheDirPath();
    }

    qDebug() << "getCachedFileNames for dir: " << dirPath;

    QVariantList retList;

    int count = 0;
    QDir qDir(dirPath);
    QStringList nameFilterList;
    nameFilterList.append("*.mp3");
    qDir.setNameFilters(nameFilterList);
    foreach (QFileInfo fileInfo, qDir.entryInfoList(nameFilterList)){
        qDebug() << "Found file: " << fileInfo.fileName();
        retList.append(QVariant(fileInfo.fileName().left(fileInfo.fileName().size() - 4)));//chopping ".mp3"
        count++;
    }
    qDebug() << "Found " << count << " files";

    return retList;
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
                || fileInfo.fileName().endsWith(".part")
                || fileInfo.size() < 1000){
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

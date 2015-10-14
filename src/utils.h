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
#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QProcess>
#include <QVariant>

class Utils : public QObject
{
    Q_OBJECT
public:
    explicit Utils(QObject *parent = 0);
    ~Utils();

    Q_INVOKABLE int clearCookies();
    Q_INVOKABLE QString getFilePath(QString dirPath, QString fileName);
    Q_INVOKABLE QString getDefaultCacheDirPath();
    Q_INVOKABLE QString getCacheDirSize(QString dirPath);
    Q_INVOKABLE void clearCacheDir(QString dirPath);
    Q_INVOKABLE int deleteFile(QString dirPath, QString fileName);
    Q_INVOKABLE void clearCacheDirFromGarbage(QString dirPath, QString userId);
    Q_INVOKABLE QString encodeURL(QString url);
    Q_INVOKABLE void getFreeSpace(QString dirPath);
    Q_INVOKABLE QString sdcardPath() const;
    Q_INVOKABLE QVariantList getCachedFileNames(QString dirPath);
    Q_INVOKABLE bool checkCacheDir(QString dirPath);

signals:
    void freeSpaceUpdated(const int freeSpace);

private slots:
    void freeSpaceResponse(int sugnalNum);

private:
    QStringList mountPoints() const;

    QProcess *m_process;

};

#endif // UTILS_H

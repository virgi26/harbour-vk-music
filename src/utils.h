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
#ifndef UTILS_H
#define UTILS_H

#include <QObject>

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
    Q_INVOKABLE void clearCacheDirFromGarbage(QString dirPath, QString userId);
    Q_INVOKABLE QString encodeURL(QString url);
};

#endif // UTILS_H

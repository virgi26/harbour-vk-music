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

//#ifdef QT_QML_DEBUG
#include <QtQuick>
//#endif

#include <sailfishapp.h>
#include "utils.h"
#include "downloadmanager.h"
#include "audioplayerinfo.h"

static QObject *audioplayerinfo_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    AudioPlayerInfo *audioplayerinfo = new AudioPlayerInfo();
    return audioplayerinfo;
}

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/template.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QGuiApplication *app(SailfishApp::application(argc, argv));
    QCoreApplication::setOrganizationName("harbour-vk-music");
    QCoreApplication::setApplicationName("harbour-vk-music");
    QQuickView *view(SailfishApp::createView());


    qmlRegisterType<DownloadManager>("harbour.vk.music.downloadmanager", 1, 0, "DownloadManager");
    qmlRegisterSingletonType<AudioPlayerInfo>("harbour.vk.music.audioplayerinfo", 1, 0, "AudioPlayerInfo", audioplayerinfo_provider);

    Utils *utils = new Utils();
    view->rootContext()->setContextProperty("Utils", utils);

    view->setSource(SailfishApp::pathTo("qml/harbour-vk-music.qml"));
    view->show();
    return app->exec();
}



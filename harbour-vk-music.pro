# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-vk-music

CONFIG += sailfishapp

SOURCES += src/harbour-vk-music.cpp \
    src/utils.cpp \
    src/downloadmanager.cpp \
    src/audioplayerinfo.cpp

OTHER_FILES += qml/harbour-vk-music.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-vk-music.spec \
    rpm/harbour-vk-music.yaml \
    translations/*.ts \
    harbour-vk-music.desktop \
    qml/pages/MusicList.qml \
    qml/utils/database.js \
    qml/pages/SongItem.qml \
    qml/pages/Settings.qml \
    qml/pages/LoginPage.qml \
    qml/utils/vkapi.js \
    qml/pages/ControlsPanel.qml \
    qml/utils/misc.js \
    qml/images/logo.png \
    rpm/harbour-vk-music.changes \
    README.md \
    qml/pages/AlbumsPage.qml \
    qml/pages/CacheDirDialog.qml \
    qml/pages/About.qml \
    qml/pages/Notification.qml

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-vk-music-ru.ts

HEADERS += \
    src/utils.h \
    src/downloadmanager.h \
    src/audioplayerinfo.h


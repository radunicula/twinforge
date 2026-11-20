QT += core gui qml quick quickcontrols2 concurrent dbus network

CONFIG += c++20 release
TARGET = twinforge
TEMPLATE = app

HEADERS += \
    src/backend.h \
    src/cli.h \
    src/commandlogmodel.h \
    src/fileoperation.h \
    src/panelmodel.h \
    src/singleinstance.h \
    src/theme.h \
    src/thumbnailprovider.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/cli.cpp \
    src/commandlogmodel.cpp \
    src/fileoperation.cpp \
    src/panelmodel.cpp \
    src/singleinstance.cpp \
    src/theme.cpp \
    src/thumbnailprovider.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc

LIBS += -larchive

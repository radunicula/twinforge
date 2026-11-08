QT += core gui qml quick quickcontrols2 concurrent dbus

CONFIG += c++20 release
TARGET = omapanel
TEMPLATE = app

HEADERS += \
    src/backend.h \
    src/fileoperation.h \
    src/panelmodel.h \
    src/theme.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/fileoperation.cpp \
    src/panelmodel.cpp \
    src/theme.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc

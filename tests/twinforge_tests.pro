QT += core gui quick quickcontrols2 testlib dbus concurrent network
CONFIG += c++20 testcase
TARGET = twinforge_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += \
    ../src/backend.h \
    ../src/cli.h \
    ../src/commandlogmodel.h \
    ../src/fileoperation.h \
    ../src/panelmodel.h \
    ../src/singleinstance.h \
    ../src/theme.h \
    ../src/thumbnailprovider.h \
    ../src/translator.h

SOURCES += \
    twinforge_tests.cpp \
    ../src/backend.cpp \
    ../src/cli.cpp \
    ../src/commandlogmodel.cpp \
    ../src/fileoperation.cpp \
    ../src/panelmodel.cpp \
    ../src/singleinstance.cpp \
    ../src/theme.cpp \
    ../src/thumbnailprovider.cpp \
    ../src/translator.cpp

RESOURCES += ../src/resources.qrc

LIBS += -larchive

QT += core gui quick quickcontrols2 testlib dbus concurrent
CONFIG += c++20 testcase
TARGET = omapanel_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += \
    ../src/backend.h \
    ../src/fileoperation.h \
    ../src/panelmodel.h \
    ../src/theme.h \
    ../src/translator.h

SOURCES += \
    omapanel_tests.cpp \
    ../src/backend.cpp \
    ../src/fileoperation.cpp \
    ../src/panelmodel.cpp \
    ../src/theme.cpp \
    ../src/translator.cpp

RESOURCES += ../src/resources.qrc

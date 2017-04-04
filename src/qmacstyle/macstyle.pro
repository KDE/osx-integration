TEMPLATE = lib
CONFIG += plugin
QT += core widgets widgets-private core-private

TARGET = qaltmacstyle

OBJECTIVE_SOURCES += \
    main.mm \
    qmacstyle_mac.mm

HEADERS += \
    qmacstyle_mac_p.h \
    qmacstyle_mac_p_p.h

include(private/private.pri)

LIBS_PRIVATE += -framework AppKit -framework Carbon

DISTFILES += macstyle.json

PLUGIN_TYPE = styles
PLUGIN_CLASS_NAME = QAltMacStylePlugin
#load(qt_plugin)

QT += widgets-private

TARGET = qmacstyle

OBJECTIVE_SOURCES += \
    main.mm \
    qmacstyle_mac.mm

HEADERS += \
    qmacstyle_mac_p.h \
    qmacstyle_mac_p_p.h

LIBS_PRIVATE += -framework AppKit -framework Carbon

DISTFILES += macstyle.json

PLUGIN_TYPE = styles
PLUGIN_CLASS_NAME = QMacStylePlugin
load(qt_plugin)

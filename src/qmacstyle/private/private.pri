INCLUDEPATH += $$PWD
DEPENDPATH += $$PWD

HEADERS += \
    $$PWD/qcombobox.h $$PWD/qcombobox_p.h \
    $$PWD/qcommonstyle.h $$PWD/qcommonstyle_p.h \
    $$PWD/qstyle_p.h \
    $$PWD/qstyleanimation_p.h \
    $$PWD/qstylehelper_p.h

SOURCES += \
    $$PWD/qcombobox.cpp \
    $$PWD/qcommonstyle.cpp \
    $$PWD/qstyleanimation.cpp \
    $$PWD/qstylehelper.cpp \
    $$PWD/qoperatingsystemversion.cpp \
    $$PWD/qoperatingsystemversion_darwin.mm

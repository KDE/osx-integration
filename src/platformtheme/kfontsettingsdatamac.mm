/* This file is part of the KDE libraries
   Copyright (C) 2000, 2006 David Faure <faure@kde.org>
   Copyright 2008 Friedrich W. H. Kossebau <kossebau@kde.org>
   Copyright 2013 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
   Copyright 2015 René J.V. Bertin <rjvbertin@gmail.com>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License version 2 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#include "kfontsettingsdatamac.h"

#include <QDebug>
#include <QCoreApplication>
#include <QFontDatabase>
#include <QFont>
#include <QString>
#include <QVariant>
#include <QApplication>
#include <QDBusMessage>
#include <QDBusConnection>
#include <qpa/qwindowsysteminterface.h>

#include <ksharedconfig.h>
#include <kconfiggroup.h>

// NOTE: keep in sync with plasma-desktop/kcms/fonts/fonts.cpp
static const char GeneralId[] =      "General";
// NOTE: the default system font changed with OS X 10.11, from Lucida Grande to
// San Francisco. With luck this will be caught by QFontDatabase::GeneralFont
static const char DefaultFont[] =    "Lucida Grande";
static char *LocalDefaultFont = NULL;

/* Default fonts on OS X <= 10.9 :
    System: Lucida Grande 13pt
    System headlines: <System>,Bold
    Application: Helvetica 12pt
    Fixed width: Monaco 10pt
    Messages: <system>
    Labels: <system>,11pt
    Help tags: <system>,11pt
    Window title bars: <system>
    Utility window title bars: <system>,11pt
    --- Dumped from the native QPlatformTheme::themeFont() function:
    (themeFont QPlatformTheme::Font : CoreText font role)
    themeFont 0 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 1 : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    themeFont 2 : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    themeFont 3 : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    themeFont 4 : 3 = ".Lucida Grande UI" style "Bold" NSFont weight@12pt= 9 QFont= ".Lucida Grande UI,13,-1,5,75,0,0,0,0,0"
    themeFont 5 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 6 : 25 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    themeFont 7 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 8 : 15 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 9 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 10 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 11 : 16 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 12 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 13 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 14 : 22 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,10,-1,5,50,0,0,0,0,0"
    themeFont 15 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 16 : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    themeFont 17 : 4 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    themeFont 18 : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    themeFont 19 : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    themeFont 20 : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    themeFont 21 : 4 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    themeFont 22 : 6 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,9,-1,5,50,0,0,0,0,0"
    themeFont 23 : 1 = "Monaco" style "Regular" NSFont weight@12pt= 5 QFont= "Monaco,10,-1,5,50,0,0,0,0,0"
 */

static KFontData DefaultFontData[KFontSettingsDataMac::FontTypesCount] = {
    // Note: we use 
    { GeneralId, "font",                 DefaultFont,  12, -1, QFont::SansSerif },
    { GeneralId, "fixed",                "Monaco",     10, -1, QFont::Monospace },
    { GeneralId, "toolBarFont",          DefaultFont,  11, -1, QFont::SansSerif },
    { GeneralId, "menuFont",             DefaultFont,  14, -1, QFont::SansSerif },
    { "WM",      "activeFont",           DefaultFont,  13, -1, QFont::SansSerif },
    { GeneralId, "taskbarFont",          DefaultFont,   9, -1, QFont::SansSerif },
    { GeneralId, "smallestReadableFont", DefaultFont,   9, -1, QFont::SansSerif },
    // this one is to accomodate for the MessageBoxFont which should be bold on OS X
    // when using the native theme fonts.
    { GeneralId, "messageBoxFont",       DefaultFont,  13, QFont::Bold, QFont::SansSerif }
};

static const char *fontNameFor(QFontDatabase::SystemFont role)
{
    QFont qf = QFontDatabase::systemFont(role);
    const char *fn = qf.defaultFamily().toLocal8Bit().constData();
    if (role == QFontDatabase::FixedFont && !qf.fixedPitch()) {
        fn = "Monaco";
    }
    if (strcmp(fn, ".Lucida Grande UI") == 0) {
        return "Lucida Grande";
    } else {
        return fn;
    }
}

KFontSettingsDataMac::KFontSettingsDataMac()
{
    QMetaObject::invokeMethod(this, "delayedDBusConnects", Qt::QueuedConnection);
    if (!LocalDefaultFont) {
        LocalDefaultFont = strdup(fontNameFor(QFontDatabase::GeneralFont));
    }
    for (int i = 0 ; i < KFontSettingsDataMac::FontTypesCount ; ++i) {
        const char *fn;
        switch(i) {
            case FixedFont:
                fn = strdup(fontNameFor(QFontDatabase::FixedFont));
                break;
            case WindowTitleFont:
                fn = strdup(fontNameFor(QFontDatabase::TitleFont));
                break;
            case SmallestReadableFont:
                fn = strdup(fontNameFor(QFontDatabase::SmallestReadableFont));
                break;
            default:
                fn = LocalDefaultFont;
                break;
        }
        DefaultFontData[i].FontName = fn;
    }
    for (int i = 0; i < FontTypesCount; ++i) {
        // remove any information that already have been cached by our parent
        // IFF we don't have our own mFonts copy
        // delete mFonts[i];
        mFonts[i] = 0;
    }
}

KFontSettingsDataMac::~KFontSettingsDataMac()
{
    for (int i = 0 ; i < KFontSettingsDataMac::FontTypesCount ; ++i) {
        if (DefaultFontData[i].FontName != DefaultFont) {
            if (DefaultFontData[i].FontName != LocalDefaultFont) {
                delete DefaultFontData[i].FontName;
            }
            DefaultFontData[i].FontName = DefaultFont;
        }
    }
    delete LocalDefaultFont;
    LocalDefaultFont = NULL;
}

QFont *KFontSettingsDataMac::font(FontTypes fontType)
{
    QFont *cachedFont = mFonts[fontType];

    if (!cachedFont) {
        const KConfigGroup configGroup(kdeGlobals(), DefaultFontData[fontType].ConfigGroupKey);
        QString fontInfo;
        bool forceBold = false;

        if (fontType == MessageBoxFont) {
            // OS X special: the MessageBoxFont is by default a bold version of the GeneralFont
            // and that's what is cached in DefaultFontData[MessageBoxFont].
            // NB: we can use a single configGroup for this hack as long as MessageBoxFont and
            // GeneralFont share the same ConfigGroupKey (or MessageBoxFont cannot be configured).
            fontInfo = configGroup.readEntry(DefaultFontData[GeneralFont].ConfigKey, QString());
            if (!fontInfo.isEmpty()) {
                // However, if the user has configured a GeneralFont (MessageBoxFont cannot be configured),
                // we respect his/her choice but maintain the bold aspect dictated by the platform.
                fontType = GeneralFont;
                forceBold = true;
            }
        }

        const KFontData &fontData = DefaultFontData[fontType];

        cachedFont = new QFont(QLatin1String(fontData.FontName), fontData.Size, forceBold? QFont::Bold : fontData.Weight);
        cachedFont->setStyleHint(fontData.StyleHint);

        fontInfo = configGroup.readEntry(fontData.ConfigKey, QString());

        if (!fontInfo.isEmpty()) {
            cachedFont->fromString(fontInfo);
        }

        mFonts[fontType] = cachedFont;
    }

    return cachedFont;
}

void KFontSettingsDataMac::dropFontSettingsCache()
{
    if (qobject_cast<QApplication *>(QCoreApplication::instance())) {
        QApplication::setFont(*font(KFontSettingsDataMac::GeneralFont));
    } else {
        QGuiApplication::setFont(*font(KFontSettingsDataMac::GeneralFont));
    }
}

void KFontSettingsDataMac::delayedDBusConnects()
{
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KDEPlatformTheme"), QStringLiteral("org.kde.KDEPlatformTheme"),
                                          QStringLiteral("refreshFonts"), this, SLOT(dropFontSettingsCache()));
}

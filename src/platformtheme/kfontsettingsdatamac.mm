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
#include "platformtheme_logging.h"

#include <QDebug>
#include <QCoreApplication>
#include <QFontDatabase>
#include <QFont>
#include <QString>
#include <QVariant>
#include <QApplication>
#ifdef DBUS_SUPPORT_ENABLED
#include <QDBusMessage>
#include <QDBusConnection>
#endif
#include <qpa/qwindowsysteminterface.h>

#include <ksharedconfig.h>
#include <kconfiggroup.h>

// NOTE: keep in sync with plasma-desktop/kcms/fonts/fonts.cpp
static const char GeneralId[] =      "General";
// NOTE: the default system font changed with OS X 10.11, from Lucida Grande to
// San Francisco. With luck this will be caught by QFontDatabase::GeneralFont
const char DefaultFont[] =    "Lucida Grande";
static const char DefaultFixedFont[] = "Monaco";
static const char *LocalDefaultFont = NULL;

// See README.fonts.txt for information and thoughts about native/default fonts

KFontData DefaultFontData[KFontSettingsDataMac::FontTypesCount] = {
    { GeneralId, "font",                 DefaultFont,       12, -1, QFont::SansSerif, "Medium" },
    { GeneralId, "fixed",                DefaultFixedFont,  10, -1, QFont::Monospace, "Regular" },
    { GeneralId, "toolBarFont",          DefaultFont,       10, -1, QFont::SansSerif, "Medium" },
    { GeneralId, "menuFont",             DefaultFont,       14, -1, QFont::SansSerif, "Medium" },
    // applications don't control the window titlebar fonts
    { "WM",      "activeFont",           DefaultFont,       13, -1, QFont::SansSerif, "Medium" },
    { GeneralId, "taskbarFont",          DefaultFont,        9, -1, QFont::SansSerif, "Medium" },
    { GeneralId, "smallestReadableFont", DefaultFont,        9, -1, QFont::SansSerif, "Medium" },
    // this one is to accomodate for the MessageBoxFont which should be bold on OS X
    // when using the native theme fonts.
    { GeneralId, "messageBoxFont",       DefaultFont,       13, QFont::Bold, QFont::SansSerif, "Bold" }
};

static const char *fontNameFor(QFontDatabase::SystemFont role)
{
    QFont qf = QFontDatabase::systemFont(role);
    if (!qf.defaultFamily().isEmpty()) {
        char *fn;
        if (role == QFontDatabase::FixedFont && !qf.fixedPitch()) {
            fn = strdup("Monaco");
        } else if (qf.defaultFamily() == QStringLiteral(".Lucida Grande UI")) {
            fn = strdup("Lucida Grande");
        } else {
            fn = strdup(qf.defaultFamily().toLocal8Bit().data());
        }
        if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
            qCWarning(PLATFORMTHEME) << "fontNameFor" << role << "font:" << qf << "name:" << fn;
        }
        return fn;
    } else {
        return NULL;
    }
}

void initDefaultFonts()
{
    const char *fn;
    static bool active = false;

    // we must protect ourselves from being called recursively
    if (active) {
        return;
    }
    active = true;

    if (!LocalDefaultFont) {
        fn = fontNameFor(QFontDatabase::GeneralFont);
        LocalDefaultFont = fn;
    }
    for (int i = 0 ; i < KFontSettingsDataMac::FontTypesCount ; ++i) {
        switch(i) {
            case KFontSettingsDataMac::FixedFont:
                fn = fontNameFor(QFontDatabase::FixedFont);
                break;
            case KFontSettingsDataMac::WindowTitleFont:
                fn = fontNameFor(QFontDatabase::TitleFont);
                break;
            case KFontSettingsDataMac::SmallestReadableFont:
                fn = fontNameFor(QFontDatabase::SmallestReadableFont);
                break;
            default:
                fn = LocalDefaultFont;
                break;
        }
        if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
            qCWarning(PLATFORMTHEME) << "Default font for type" << i << ":" << fn << "; currently:" << DefaultFontData[i].FontName;
        }
        if (fn) {
            if (DefaultFontData[i].FontName != DefaultFont
                    && DefaultFontData[i].FontName != DefaultFixedFont
                    && DefaultFontData[i].FontName != LocalDefaultFont) {
                free((void*)DefaultFontData[i].FontName);
            }
            DefaultFontData[i].FontName = fn;
        }
    }

    active = false;
}

KFontSettingsDataMac::KFontSettingsDataMac()
{
#ifdef DBUS_SUPPORT_ENABLED
    QMetaObject::invokeMethod(this, "delayedDBusConnects", Qt::QueuedConnection);
#endif
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
        if (DefaultFontData[i].FontName != DefaultFont
                && DefaultFontData[i].FontName != DefaultFixedFont) {
            if (DefaultFontData[i].FontName
                    && DefaultFontData[i].FontName != LocalDefaultFont) {
                free((void*)(DefaultFontData[i].FontName));
            }
            DefaultFontData[i].FontName = (i == FixedFont)? DefaultFixedFont : DefaultFont;
        }
    }
    if (LocalDefaultFont) {
        free((void*)(LocalDefaultFont));
    }
    LocalDefaultFont = NULL;
}

QFont *KFontSettingsDataMac::font(FontTypes fontType)
{
    QFont *cachedFont = mFonts[fontType];

    if (!cachedFont) {
        // check if we have already initialised our local database mapping font types to fonts
        // if not, we do it here, at the latest possible moment. Doing it in the KFontSettingsDataMac
        // ctor is bound for failure as our instance is likely to be created before Qt's own
        // font database has been populated. That's expectable: the font database also represents
        // platform (theme) specific fonts for various roles, and our ctor is called as part of the
        // platform theme creation procedure.
        if (!LocalDefaultFont) {
            static bool active = false;
            // NB: initDefaultFonts() queries Qt's font database which in turn can call us
            // again. Protection against this is built into initDefaultFonts(), but in practice
            // we prefer to return NULL if called through recursively.
            if (!active) {
                active = true;
                initDefaultFonts();
                active = false;
            } else {
                // our caller must handle NULL, preferably by relaying the font request
                // to the native platform theme (see KdeMacTheme::font()).
                return NULL;
            }
        }
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
        // ignore the default stylehint; works better converting medium -> bold
//         cachedFont->setStyleName(QLatin1String(fontData.StyleName));
//         if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
//             qCWarning(PLATFORMTHEME) << "Requested font type" << fontType << "name=" << fontData.FontName << "forceBold=" << forceBold << "styleHint=" << fontData.StyleHint;
//             qCWarning(PLATFORMTHEME) << "\t->" << *cachedFont;
//         }

        fontInfo = configGroup.readEntry(fontData.ConfigKey, QString());

        if (!fontInfo.isEmpty()) {
            cachedFont->fromString(fontInfo);
//             if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
//                 qCWarning(PLATFORMTHEME) << "\tfontInfo=" << fontInfo << "->" << *cachedFont;
//             }
        } else {
            QString fName = cachedFont->toString();
            cachedFont->setStyleName(QLatin1String(fontData.StyleName));
            if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
                qCWarning(PLATFORMTHEME) << "\t" << fName << "+ styleName" << fontData.StyleName << "->" << *cachedFont;
            }
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
#ifdef DBUS_SUPPORT_ENABLED
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KDEPlatformTheme"), QStringLiteral("org.kde.KDEPlatformTheme"),
                                          QStringLiteral("refreshFonts"), this, SLOT(dropFontSettingsCache()));
#endif
}

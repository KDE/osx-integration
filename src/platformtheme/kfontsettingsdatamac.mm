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
#include "kdemactheme.h"
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

const char *KFontSettingsDataMac::fontNameFor(QFontDatabase::SystemFont role) const
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
        if (mTheme->verbose) {
            qCWarning(PLATFORMTHEME) << "fontNameFor" << role << "font:" << qf << "name:" << fn;
        }
        return fn;
    } else {
        return NULL;
    }
}

void initDefaultFonts(KFontSettingsDataMac *instance)
{
    const char *fn;
    static bool active = false;

    // we must protect ourselves from being called recursively
    if (active) {
        return;
    }
    active = true;

    if (!LocalDefaultFont) {
        fn = instance->fontNameFor(QFontDatabase::GeneralFont);
        LocalDefaultFont = fn;
    }
    for (int i = 0 ; i < KFontSettingsDataMac::FontTypesCount ; ++i) {
        switch(i) {
            case KFontSettingsDataMac::FixedFont:
                fn = instance->fontNameFor(QFontDatabase::FixedFont);
                break;
            case KFontSettingsDataMac::WindowTitleFont:
                fn = instance->fontNameFor(QFontDatabase::TitleFont);
                break;
            case KFontSettingsDataMac::SmallestReadableFont:
                fn = instance->fontNameFor(QFontDatabase::SmallestReadableFont);
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

KFontSettingsDataMac::KFontSettingsDataMac(KdeMacTheme *theme)
    : mTheme(theme)
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

    if (QGuiApplication::platformName().contains(QLatin1String("cocoa"))) {
        KConfigGroup general(kdeGlobals(), "General");
        const QString fontEngine = general.readEntry("fontEngine", QString());
        // don't do anything if no instructions are given in kdeglobals or the environment
        bool useFreeType = false, useFontConfig = false;
        mUseCoreText = false;
        if (!fontEngine.isEmpty()) {
            useFreeType = fontEngine.compare(QLatin1String("FreeType"), Qt::CaseInsensitive) == 0;
            useFontConfig = fontEngine.compare(QLatin1String("FontConfig"), Qt::CaseInsensitive) == 0;
            // fontEngine=CoreText is the default and only handled so we can warn appropriately
            // when the user tries to activate another, unknown font engine.
            mUseCoreText = fontEngine.compare(QLatin1String("CoreText"), Qt::CaseInsensitive) == 0;
        }
        if (qgetenv("QT_MAC_FONTENGINE").toLower() == "freetype") {
            useFontConfig = false;
            useFreeType = true;
        }
        if (qgetenv("QT_MAC_FONTENGINE").toLower() == "fontconfig") {
            useFreeType = false;
            useFontConfig = true;
        }
        if (qgetenv("QT_MAC_FONTENGINE").toLower() == "coretext") {
            // CoreText overrides all
            mUseCoreText = true;
        }
        QString desired;
        bool result = false;
        const auto ftptr = mTheme->platformFunction("qt_mac_use_freetype");
        const auto fcptr = mTheme->platformFunction("qt_mac_use_fontconfig");
        typedef bool (*fontengineEnabler)(bool enabled);
        if (mUseCoreText) {
            desired = QStringLiteral("CoreText");
            if (fcptr) {
                reinterpret_cast<fontengineEnabler>(fcptr)(false);
            }
            if (ftptr) {
                result = reinterpret_cast<fontengineEnabler>(ftptr)(false);
                if (!result) {
                    // at this point failure *probably* means that:
                    qCWarning(PLATFORMTHEME) << "The" << desired << "fontengine was probably still enabled";
                }
            }
        } else if (useFontConfig) {
            desired = QStringLiteral("FontConfig");
            if (fcptr) {
                result = reinterpret_cast<fontengineEnabler>(fcptr)(useFontConfig);
            } else {
                qCWarning(PLATFORMTHEME) << "Cannot use the FontConfig fontengine/fontdatabase:\n"
                    "\tthis probably means Qt was built without FontConfig support or\n"
                    "\tthat you're not using the QAltCocoa QPA plugin.";
            }
        } else if (useFreeType) {
            desired = QStringLiteral("FreeType");
            if (ftptr) {
                result = reinterpret_cast<fontengineEnabler>(ftptr)(useFreeType);
            } else {
                qCWarning(PLATFORMTHEME) << "Cannot use the FreeType fontdatabase:\n"
                    "\tthis probably means Qt was built without FreeType support or\n"
                    "\tthat you're not using the QAltCocoa QPA plugin.";
            }
        }
    } else {
        mUseCoreText = false;
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
                initDefaultFonts(this);
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

        // experimental: force outline mode when not using CoreText. This should prevent the FreeType
        // font engine from picking up and using X11 bitmap fonts, should those be installed.
        if (mUseCoreText) {
            cachedFont->setStyleHint(fontData.StyleHint);
        } else {
            cachedFont->setStyleHint(fontData.StyleHint, QFont::ForceOutline);
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

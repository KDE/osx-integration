/*  This file is part of the KDE libraries
 *  Copyright 2013 Kevin Ottens <ervin+bluesystems@kde.org>
 *  Copyright 2013 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
 *  Copyright 2014 Lukáš Tinkl <ltinkl@redhat.com>
 *  Copyright 2015 René J.V. Bertin <rjvbertin@gmail.com>
 *
 *  This library is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation; either version 2 of the License or ( at
 *  your option ) version 3 or, at the discretion of KDE e.V. ( which shall
 *  act as a proxy as in section 14 of the GPLv3 ), any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

#include "kdemactheme.h"
#include "kfontsettingsdatamac.h"
#include "khintssettingsmac.h"
#include "kdeplatformfiledialoghelper.h"
#include "kdeplatformsystemtrayicon.h"

#include <QCoreApplication>
#include <QMessageBox>
#include <QFont>
#include <QPalette>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QDebug>

// instantiating the native platform theme requires the use of private APIs
#include <QtGui/private/qguiapplication_p.h>
#include <QtGui/qpa/qplatformintegration.h>


#include <kiconengine.h>
#include <kiconloader.h>
#include <kstandardshortcut.h>
#include <KStandardGuiItem>
#include <KLocalizedString>

#include <AppKit/AppKit.h>

static void warnNoNativeTheme()
{
    const char *msg = "The KdePlatformThemePlugin is being used and the native Cocoa theme failed to load.\n"
                    "Applications will function but lack functionality available only through the native theme,\n"
                    "including the menu bar at the top of the screen(s).";
    // Make sure the warning appears somewhere. qWarning() isn't guaranteed to be of use when we're
    // not called from a terminal session.
    NSLog(@"%s", msg);
}

KdeMacTheme::KdeMacTheme()
{
    if (strcasecmp(QT_VERSION_STR, qVersion())) {
        NSLog(@"Warning: the KDE Platform Plugin for Mac was built against Qt %s but is running with Qt %s!",
            QT_VERSION_STR, qVersion());
    }
    // first things first: instruct Qt not to use the Mac-style toplevel menubar
    // if we are not using the Cocoa QPA plugin (but the XCB QPA instead).
    if (!QGuiApplication::platformName().contains(QLatin1String("cocoa"))) {
        QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar);
    }
    QPlatformIntegration *pi = QGuiApplicationPrivate::platformIntegration();
    if (pi) {
        nativeTheme = pi->createPlatformTheme(QString::fromLatin1("cocoa"));
    } else {
        nativeTheme = Q_NULLPTR;
    }
    if (!nativeTheme) {
        warnNoNativeTheme();
    }
    m_fontsData = Q_NULLPTR;
    m_hints = Q_NULLPTR;
    loadSettings();
}

KdeMacTheme::~KdeMacTheme()
{
//     delete m_fontsData;
//     delete m_hints;
    delete nativeTheme;
}

QPlatformMenuItem* KdeMacTheme::createPlatformMenuItem() const
{
    if (nativeTheme) {
        return nativeTheme->createPlatformMenuItem();
    } else {
        warnNoNativeTheme();
        return QPlatformTheme::createPlatformMenuItem();
    }
}

QPlatformMenu* KdeMacTheme::createPlatformMenu() const
{
    if (nativeTheme) {
        return nativeTheme->createPlatformMenu();
    } else {
        warnNoNativeTheme();
        return QPlatformTheme::createPlatformMenu();
    }
}

QPlatformMenuBar* KdeMacTheme::createPlatformMenuBar() const
{
    if (nativeTheme) {
        return nativeTheme->createPlatformMenuBar();
    } else {
        warnNoNativeTheme();
        return QPlatformTheme::createPlatformMenuBar();
    }
}

QVariant KdeMacTheme::themeHint(QPlatformTheme::ThemeHint hintType) const
{
    QVariant hint = m_hints->hint(hintType);
    if (hint.isValid()) {
        return hint;
    } else {
        if (nativeTheme) {
            return nativeTheme->themeHint(hintType);
        }
        return QPlatformTheme::themeHint(hintType);
    }
}

const QPalette *KdeMacTheme::palette(Palette type) const
{
    QPalette *palette = m_hints->palette(type);
    if (palette) {
        return palette;
    } else {
        if (nativeTheme) {
            return nativeTheme->palette(type);
        }
        return QPlatformTheme::palette(type);
    }
}

KFontSettingsDataMac::FontTypes KdeMacTheme::fontType(QPlatformTheme::Font type) const
{
    KFontSettingsDataMac::FontTypes ftype;
    switch (type) {
        default:
            ftype = KFontSettingsDataMac::FontTypes(KdePlatformTheme::fontType(type));
            break;
        case MessageBoxFont:
            ftype = KFontSettingsDataMac::MessageBoxFont;
            break;
    }
    return ftype;
}

const QFont *KdeMacTheme::font(Font type) const
{
    // when using the platform-default fonts, try returning a bold version of the 
    // standard system font; it's the only one where Qt/OS X really deviates.
    const QFont *qf = m_fontsData->font(fontType(type));
    if (!qf && nativeTheme) {
        qf = nativeTheme->font(type);
//         if (qf) {
//             qWarning() << "native font for type" << type << "=role" << fontType(type) << ":" << *qf;
//         } else {
//             qWarning() << "native font for type" << type << "=role" << fontType(type) << ": NULL";
//         }
    }
    return qf;
}

void KdeMacTheme::loadSettings()
{
    if (!m_fontsData) {
        m_fontsData = new KFontSettingsDataMac;
    }
    if (!m_hints) {
        m_hints = new KHintsSettingsMac;
    }
}

QList<QKeySequence> KdeMacTheme::keyBindings(QKeySequence::StandardKey key) const
{
    // return a native keybinding if we can determine what that is
    if (nativeTheme) {
        return nativeTheme->keyBindings(key);
    }
    // or else we return whatever KDE applications expect elsewhere
    return KdePlatformTheme::keyBindings(key);
}

bool KdeMacTheme::usePlatformNativeDialog(QPlatformTheme::DialogType type) const
{
    if (nativeTheme) {
        return nativeTheme->usePlatformNativeDialog(type);
    }
    return type == QPlatformTheme::FileDialog;
}

QString KdeMacTheme::standardButtonText(int button) const
{
    // assume that button text is a domain where cross-platform application
    // coherence primes over native platform look and feel. IOW, function over form.
    // It's impossible to use the parent's method since we use
    // the nativeTheme in the default case
    switch (static_cast<QPlatformDialogHelper::StandardButton>(button)) {
        case QPlatformDialogHelper::NoButton:
            qWarning() << Q_FUNC_INFO << "Unsupported standard button:" << button;
            return QString();
        case QPlatformDialogHelper::Ok:
            return KStandardGuiItem::ok().text();
        case QPlatformDialogHelper::Save:
            return KStandardGuiItem::save().text();
        case QPlatformDialogHelper::SaveAll:
            return i18nc("@action:button", "Save All");
        case QPlatformDialogHelper::Open:
            return KStandardGuiItem::open().text();
        case QPlatformDialogHelper::Yes:
            return KStandardGuiItem::yes().text();
        case QPlatformDialogHelper::YesToAll:
            return i18nc("@action:button", "Yes to All");
        case QPlatformDialogHelper::No:
            return KStandardGuiItem::no().text();
        case QPlatformDialogHelper::NoToAll:
            return i18nc("@action:button", "No to All");
        case QPlatformDialogHelper::Abort:
            // FIXME KStandardGuiItem::stop() doesn't seem right here
            return i18nc("@action:button", "Abort");
        case QPlatformDialogHelper::Retry:
            return i18nc("@action:button", "Retry");
        case QPlatformDialogHelper::Ignore:
            return i18nc("@action:button", "Ignore");
        case QPlatformDialogHelper::Close:
            return KStandardGuiItem::close().text();
        case QPlatformDialogHelper::Cancel:
            return KStandardGuiItem::cancel().text();
        case QPlatformDialogHelper::Discard:
            return KStandardGuiItem::discard().text();
        case QPlatformDialogHelper::Help:
            return KStandardGuiItem::help().text();
        case QPlatformDialogHelper::Apply:
            return KStandardGuiItem::apply().text();
        case QPlatformDialogHelper::Reset:
            return KStandardGuiItem::reset().text();
        case QPlatformDialogHelper::RestoreDefaults:
            return KStandardGuiItem::defaults().text();
        default:
            if (nativeTheme) {
                // something not foreseen by Qt/KDE: now see if OS X
                // has an opinion about the text.
                return nativeTheme->standardButtonText(button);
            }
            return QPlatformTheme::defaultStandardButtonText(button);
    }
}

QPlatformDialogHelper *KdeMacTheme::createPlatformDialogHelper(QPlatformTheme::DialogType type) const
{
    // always prefer native dialogs
    // NOTE: somehow, the "don't use native dialog" option that Qt's example "standarddialogs"
    // provides does not modify our usePlatformNativeDialog() return value, but *does* cause
    // a Qt dialog to be created instead of the native one. Weird.
    if (nativeTheme) {
        return nativeTheme->createPlatformDialogHelper(type);
    }
    QPlatformDialogHelper *helper = KdePlatformTheme::createPlatformDialogHelper(type);
    if (helper) {
        return helper;
    } else {
        return QPlatformTheme::createPlatformDialogHelper(type);
    }
}

QPlatformSystemTrayIcon *KdeMacTheme::createPlatformSystemTrayIcon() const
{
    if (nativeTheme) {
        return nativeTheme->createPlatformSystemTrayIcon();
    }
    // TODO: figure out if it makes sense to return something other than 
    // nativeTheme->createPlatformSystemTrayIcon() or even NULL
    return KdePlatformTheme::createPlatformSystemTrayIcon();
}

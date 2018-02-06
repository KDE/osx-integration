/*  This file is part of the KDE libraries
 *  Copyright 2013 Kevin Ottens <ervin+bluesystems@kde.org>
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

#ifndef KDEMACTHEME_H
#define KDEMACTHEME_H

#include "kdeplatformtheme.h"
#include "kfontsettingsdatamac.h"

#ifdef ADD_MENU_KEY
#include <QAbstractNativeEventFilter>
#endif

class KHintsSettingsMac;
class QIconEngine;
class KdeMacThemeEventFilter;
class QPlatformNativeInterface;

class KdeMacTheme : public KdePlatformTheme
{
public:
    KdeMacTheme();
    ~KdeMacTheme();

    // KdeMacTheme must provide platform menu methods or else there will be no menus
    QPlatformMenuItem* createPlatformMenuItem() const override;
    QPlatformMenu* createPlatformMenu() const override;
    QPlatformMenuBar* createPlatformMenuBar() const override;

    QVariant themeHint(ThemeHint hint) const override;
    const QPalette *palette(Palette type = SystemPalette) const override;
    const QFont *font(Font type) const override;
    QList<QKeySequence> keyBindings(QKeySequence::StandardKey key) const override;

    QPlatformDialogHelper *createPlatformDialogHelper(DialogType type) const override;
    bool usePlatformNativeDialog(DialogType type) const override;

    QString standardButtonText(int button) const override;

    QPlatformSystemTrayIcon *createPlatformSystemTrayIcon() const override;

    QPlatformNativeInterface *nativeInterface();
    typedef void * (*PlatformFunctionPtr)();
    PlatformFunctionPtr platformFunction(const QByteArray &functionName);

    bool verbose;

protected:
    void loadSettings();
    KFontSettingsDataMac::FontTypes fontType(Font type) const;

private:
    KHintsSettingsMac *m_hints;
    KFontSettingsDataMac *m_fontsData;
    // this will hold the instance of the native theme that will be used as a fallback
    QPlatformTheme *nativeTheme;

    // this will hold an instance of a class with Qt and/or native event filters:
    KdeMacThemeEventFilter *m_eventFilter;
    QPlatformNativeInterface *m_nativeInterface;

    bool m_isCocoa;
};

#endif // KDEMACTHEME_H

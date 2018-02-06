/*  This file is part of the KDE libraries
 *  Copyright 2013 Alejandro Fiestas Olivares <afiestas@kde.org>
 *  Copyright 2015 René J.V. Bertin <rjvbertin@gmail.com
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

#ifndef KHINTS_SETTINGS_MAC_H
#define KHINTS_SETTINGS_MAC_H

#include "khintssettings.h"

class KConfigGroup;

class QPalette;
class KdeProxyStyle;
class KdeMacTheme;

class KHintsSettingsMac : public KHintsSettings
{
    Q_OBJECT
public:
    explicit KHintsSettingsMac(KdeMacTheme *theme);
    virtual ~KHintsSettingsMac();

    QStringList xdgIconThemePaths() const;

protected Q_SLOTS:
    void delayedDBusConnects();
    void slotNotifyChange(int type, int arg);

protected:
    void loadPalettes();
    void iconChanged(int group);
    Qt::ToolButtonStyle toolButtonStyle(const KConfigGroup &cg) const;
    void updateCursorTheme();
    void checkNativeTheme(const QString &theme);
private:
    KHintsSettingsMac();

    KdeMacTheme *mTheme;
    KdeProxyStyle *styleProxy;
};

#endif //KHINTS_SETTINGS_MAC_H

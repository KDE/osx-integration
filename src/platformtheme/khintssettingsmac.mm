/*  This file is part of the KDE libraries
 *  Copyright 2013 Kevin Ottens <ervin+bluesystems@kde.org>
 *  Copyright 2013 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
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

#include "khintssettingsmac.h"

#include <QDebug>
#include <QDir>
#include <QString>
#include <QFileInfo>
#include <QToolBar>
#include <QPalette>
#include <QToolButton>
#include <QMainWindow>
#include <QApplication>
#include <QGuiApplication>
#include <QDialogButtonBox>
#include <QScreen>
#include <QProxyStyle>

#include <QDBusConnection>
#include <QDBusInterface>

#include <kiconloader.h>
#include <kconfiggroup.h>
#include <ksharedconfig.h>
#include <kcolorscheme.h>

#include <config-platformtheme.h>

class KdeProxyStyle : public QProxyStyle
{
public:
    KdeProxyStyle(const QString &styleName)
        : QProxyStyle(styleName)
    {
        ;
    }

    int layoutSpacing(QSizePolicy::ControlType control1, QSizePolicy::ControlType control2,
                        Qt::Orientation orientation, const QStyleOption *option = 0, const QWidget *widget = 0) const
    {
        int spacing = QProxyStyle::layoutSpacing(control1, control2, orientation, option, widget);
        qWarning() << "layoutSpacing=" << spacing;
        if (spacing > 2) {
            spacing /= 2;
        }
        return spacing;
    }
};

KHintsSettingsMac::KHintsSettingsMac()
    : styleProxy(0)
{
    KSharedConfigPtr mKdeGlobals = kdeGlobals();

    KConfigGroup cg(mKdeGlobals, "KDE");
    // we're overriding whatever the parent class configured
    hints().clear();
    KConfigGroup cgToolbar(mKdeGlobals, "Toolbar style");
    hints()[QPlatformTheme::ToolButtonStyle] = toolButtonStyle(cgToolbar);

    KConfigGroup cgToolbarIcon(mKdeGlobals, "MainToolbarIcons");
    hints()[QPlatformTheme::ToolBarIconSize] = cgToolbarIcon.readEntry("Size", 22);

    hints()[QPlatformTheme::ItemViewActivateItemOnSingleClick] = cg.readEntry("SingleClick", true);

    // The new default Breeze icon theme is svg based and looks more out of place than the older Oxygen theme
    // which is PNG-based, and thus easier to use with/in the Finder.
    hints()[QPlatformTheme::SystemIconThemeName] = readConfigValue(QStringLiteral("Icons"), QStringLiteral("Theme"), QStringLiteral("oxygen"));

    hints()[QPlatformTheme::IconThemeSearchPaths] = xdgIconThemePaths();

    QStringList styleNames;
    styleNames << QStringLiteral("macintosh")
               << QStringLiteral("fusion")
               << QStringLiteral("windows");
    const QString configuredStyle = cg.readEntry("widgetStyle", QString());
    if (!configuredStyle.isEmpty()) {
        styleNames.removeOne(configuredStyle);
        styleNames.prepend(configuredStyle);
    }
    const QString lnfStyle = readConfigValue(QStringLiteral("KDE"), QStringLiteral("widgetStyle"), QString()).toString();
    if (!lnfStyle.isEmpty()) {
        styleNames.removeOne(lnfStyle);
        styleNames.prepend(lnfStyle);
    }
    hints()[QPlatformTheme::StyleNames] = styleNames;
    checkNativeTheme(configuredStyle);

    hints()[QPlatformTheme::DialogButtonBoxLayout] = QDialogButtonBox::MacLayout;
    hints()[QPlatformTheme::DialogButtonBoxButtonsHaveIcons] = cg.readEntry("ShowIconsOnPushButtons", false);
    hints()[QPlatformTheme::UseFullScreenForPopupMenu] = true;
    hints()[QPlatformTheme::KeyboardScheme] = QPlatformTheme::MacKeyboardScheme;
    hints()[QPlatformTheme::UiEffects] = cg.readEntry("GraphicEffectsLevel", 0) != 0 ? QPlatformTheme::GeneralUiEffect : 0;
// this would be what we should return for IconPixmapSizes if we wanted to copy the system defaults:
//     qreal devicePixelRatio = qGuiApp->devicePixelRatio();
//     QList<int> sizes;
//     sizes << 16 * devicePixelRatio
//           << 32 * devicePixelRatio
//           << 64 * devicePixelRatio
//           << 128 * devicePixelRatio;
//     hints()[QPlatformTheme::IconPixmapSizes] = QVariant::fromValue(sizes);

    hints()[QPlatformTheme::WheelScrollLines] = cg.readEntry("WheelScrollLines", 3);
    if (qobject_cast<QApplication *>(QCoreApplication::instance())) {
        QApplication::setWheelScrollLines(cg.readEntry("WheelScrollLines", 3));
    }

    bool showIcons = cg.readEntry("ShowIconsInMenuItems", !QApplication::testAttribute(Qt::AA_DontShowIconsInMenus));
    QCoreApplication::setAttribute(Qt::AA_DontShowIconsInMenus, !showIcons);

    QMetaObject::invokeMethod(this, "delayedDBusConnects", Qt::QueuedConnection);

    loadPalettes();
}

KHintsSettingsMac::~KHintsSettingsMac()
{
}

// adapted from QGenericUnixTheme::xdgIconThemePaths()
QStringList KHintsSettingsMac::xdgIconThemePaths() const
{
    QStringList paths;
    // Add home directory first in search path
    const QFileInfo homeIconDir(QDir::homePath() + QStringLiteral("/.icons"));
    if (homeIconDir.isDir()) {
        paths.prepend(homeIconDir.absoluteFilePath());
    }

    QStringList xdgDirs = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);
    if (xdgDirs.isEmpty()) {
        xdgDirs << QStringLiteral("/opt/local/share")
            << QStringLiteral("/usr/local/share")
            << QStringLiteral("/usr/share");
    }
    foreach (const QString &xdgDir, xdgDirs) {
        const QFileInfo xdgIconsDir(xdgDir + QStringLiteral("/icons"));
        if (xdgIconsDir.isDir()) {
            paths.append(xdgIconsDir.absoluteFilePath());
        }
        const QFileInfo pixmapsIconsDir(xdgDir + QStringLiteral("/pixmaps"));
        if (pixmapsIconsDir.isDir()) {
            paths.append(pixmapsIconsDir.absoluteFilePath());
        }
    }
    return paths;
}

void KHintsSettingsMac::delayedDBusConnects()
{
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KToolBar"), QStringLiteral("org.kde.KToolBar"),
                                          QStringLiteral("styleChanged"), this, SLOT(toolbarStyleChanged()));
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KGlobalSettings"), QStringLiteral("org.kde.KGlobalSettings"),
                                          QStringLiteral("notifyChange"), this, SLOT(slotNotifyChange(int,int)));
}

void KHintsSettingsMac::checkNativeTheme(const QString &theme)
{
#if 0
    // using a QStyleProxy messes up the colour palette for some reason, so this feature is deactivated for now
    if (theme.isEmpty() || theme.compare(QStringLiteral("macintosh"), Qt::CaseInsensitive) == 0) {
        if (qApp) {
            if (!styleProxy) {
                styleProxy = new KdeProxyStyle(QStringLiteral("macintosh"));
            }
            // styleProxy will be owned by QApplication after this, so no point deleting it
            qApp->setStyle(styleProxy);
            loadPalettes();
        }
    }
#endif
}

void KHintsSettingsMac::slotNotifyChange(int type, int arg)
{
    KHintsSettings::slotNotifyChange(type,arg);
    KSharedConfigPtr mKdeGlobals = kdeGlobals();
    KConfigGroup cg(mKdeGlobals, "KDE");

    switch (type) {
    case SettingsChanged: {

        SettingsCategory category = static_cast<SettingsCategory>(arg);
        if (category == SETTINGS_STYLE) {
            hints()[QPlatformTheme::DialogButtonBoxButtonsHaveIcons] = cg.readEntry("ShowIconsOnPushButtons", false);
        }
        break;
    }
    case StyleChanged: {
        QApplication *app = qobject_cast<QApplication *>(QCoreApplication::instance());
        if (!app) {
            return;
        }

        const QString theme = cg.readEntry("widgetStyle", QString());
        checkNativeTheme(theme);

        if (theme.isEmpty()) {
            return;
        }

        QStringList styleNames;
        styleNames << cg.readEntry("widgetStyle", QString())
                << QStringLiteral("macintosh")
                << QStringLiteral("fusion")
                << QStringLiteral("windows");
        const QString lnfStyle = readConfigValue(QStringLiteral("KDE"), QStringLiteral("widgetStyle"), QString()).toString();
        if (!lnfStyle.isEmpty() && !styleNames.contains(lnfStyle)) {
            styleNames.prepend(lnfStyle);
        }
        hints()[QPlatformTheme::StyleNames] = styleNames;

        break;
    }
    }
}

void KHintsSettingsMac::iconChanged(int group)
{
    KIconLoader::Group iconGroup = (KIconLoader::Group) group;
    if (iconGroup != KIconLoader::MainToolbar) {
        hints()[QPlatformTheme::SystemIconThemeName] = readConfigValue(QStringLiteral("Icons"), QStringLiteral("Theme"), QStringLiteral("oxygen"));
        return;
    }
    return KHintsSettings::iconChanged(group);
}

Qt::ToolButtonStyle KHintsSettingsMac::toolButtonStyle(const KConfigGroup &cg) const
{
    const QString buttonStyle = cg.readEntry("ToolButtonStyle", "TextUnderIcon").toLower();
    return buttonStyle == QLatin1String("textbesideicon") ? Qt::ToolButtonTextBesideIcon
           : buttonStyle == QLatin1String("icontextright") ? Qt::ToolButtonTextBesideIcon
           : buttonStyle == QLatin1String("textundericon") ? Qt::ToolButtonTextUnderIcon
           : buttonStyle == QLatin1String("icontextbottom") ? Qt::ToolButtonTextUnderIcon
           : buttonStyle == QLatin1String("textonly") ? Qt::ToolButtonTextOnly
           : Qt::ToolButtonIconOnly;
}

void KHintsSettingsMac::loadPalettes()
{
    qDeleteAll(palettes());
    palettes().clear();

    KSharedConfigPtr mKdeGlobals = kdeGlobals();
    if (mKdeGlobals->hasGroup("Colors:View")) {
        palettes()[QPlatformTheme::SystemPalette] = new QPalette(KColorScheme::createApplicationPalette(mKdeGlobals));
    } else {
        const QString scheme = readConfigValue(QStringLiteral("General"), QStringLiteral("ColorScheme"), QStringLiteral("Mac OSX Graphite")).toString();
        const QString path = QStandardPaths::locate(QStandardPaths::GenericDataLocation, QStringLiteral("color-schemes/") + scheme + QStringLiteral(".colors"));

        if (!path.isEmpty()) {
            palettes()[QPlatformTheme::SystemPalette] = new QPalette(KColorScheme::createApplicationPalette(KSharedConfig::openConfig(path)));
        }
    }
}

void KHintsSettingsMac::updateCursorTheme()
{
}

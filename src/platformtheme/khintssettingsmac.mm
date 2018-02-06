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
#include "kdemactheme.h"
#include "platformtheme_logging.h"

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
#include <QStyle>

#ifdef DBUS_SUPPORT_ENABLED
#include <QDBusConnection>
#include <QDBusInterface>
#endif

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
        qCWarning(PLATFORMTHEME) << "layoutSpacing=" << spacing;
        if (spacing > 2) {
            spacing /= 2;
        }
        return spacing;
    }
};

KHintsSettingsMac::KHintsSettingsMac(KdeMacTheme *theme)
    : mTheme(theme)
    , styleProxy(0)
{
    KSharedConfigPtr mKdeGlobals = kdeGlobals();
    if (mTheme->verbose) {
        if (!mKdeGlobals->name().isEmpty()) {
            qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "config file:" << mKdeGlobals->name()
                << "(" << QStandardPaths::locate(mKdeGlobals->locationType(), mKdeGlobals->name()) << ")";
        } else {
            qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "config file:" << mKdeGlobals << "has no known name";
        }
    }

    KConfigGroup cg(mKdeGlobals, "KDE");
    if (mTheme->verbose) {
        qCWarning(PLATFORMTHEME) << "config group" << mKdeGlobals->name() << "." << cg.name()
            << "exists=" << cg.exists()
            << "valid=" << cg.isValid()
            << "groups=" << cg.groupList()
            << "keys=" << cg.keyList();
    }

    // we're overriding whatever the parent class configured
    hints().clear();

    KConfigGroup cgToolbar(mKdeGlobals, "Toolbar style");
    if (mTheme->verbose) {
        qCWarning(PLATFORMTHEME) << "config group" << mKdeGlobals->name() << "." << cgToolbar.name()
            << "exists=" << cgToolbar.exists()
            << "valid=" << cgToolbar.isValid()
            << "groups=" << cgToolbar.groupList()
            << "keys=" << cgToolbar.keyList();
    }
    hints()[QPlatformTheme::ToolButtonStyle] = toolButtonStyle(cgToolbar);

    KConfigGroup cgToolbarIcon(mKdeGlobals, "MainToolbarIcons");
    if (mTheme->verbose) {
        qCWarning(PLATFORMTHEME) << "config group" << mKdeGlobals->name() << "." << cgToolbarIcon.name()
            << "exists=" << cgToolbarIcon.exists()
            << "valid=" << cgToolbarIcon.isValid()
            << "groups=" << cgToolbarIcon.groupList()
            << "keys=" << cgToolbarIcon.keyList();
    }
    hints()[QPlatformTheme::ToolBarIconSize] = cgToolbarIcon.readEntry("Size", 22);

    hints()[QPlatformTheme::ItemViewActivateItemOnSingleClick] = cg.readEntry("SingleClick", true);

#ifdef KDEMACTHEME_ADD_ICONTHEMESETTINGS
    // The new default Breeze icon theme is svg based and looks more out of place than the older Oxygen theme
    // which is PNG-based, and thus easier to use with/in the Finder.
    hints()[QPlatformTheme::SystemIconThemeName] = readConfigValue(QStringLiteral("Icons"), QStringLiteral("Theme"), QStringLiteral("oxygen"));
    hints()[QPlatformTheme::IconThemeSearchPaths] = xdgIconThemePaths();
#endif

    QStringList styleNames;
    styleNames << QStringLiteral("aqua")
               << QStringLiteral("macintosh")
               << QStringLiteral("fusion")
               << QStringLiteral("windows");
    if (mTheme->verbose) {
        qCWarning(PLATFORMTHEME) << "initial widget style list:" << styleNames;
    }
    const QString configuredStyle = cg.readEntry("widgetStyle", QString());
    if (!configuredStyle.isEmpty()) {
        styleNames.removeOne(configuredStyle);
        styleNames.prepend(configuredStyle);
        if (mTheme->verbose) {
            qCWarning(PLATFORMTHEME) << "Found widgetStyle" << configuredStyle << "in config file";
        }
    }
    const QString lnfStyle = readConfigValue(QStringLiteral("KDE"), QStringLiteral("widgetStyle"), QString()).toString();
    if (!lnfStyle.isEmpty() && lnfStyle != configuredStyle) {
        styleNames.removeOne(lnfStyle);
        styleNames.prepend(lnfStyle);
        if (mTheme->verbose) {
            qCWarning(PLATFORMTHEME) << "Found widgetStyle" << lnfStyle << "look-and-feel definition"
                << (LnfConfig() ? LnfConfig()->name() : QStringLiteral("???"));
        }
    }
    if (mTheme->verbose) {
        qCWarning(PLATFORMTHEME) << "final widget style list:" << styleNames;
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

    updateShowIconsInMenuItems(cg);

#if QT_VERSION >= QT_VERSION_CHECK(5, 10, 0)
    m_hints[QPlatformTheme::ShowShortcutsInContextMenus] = true;
#endif

#ifdef DBUS_SUPPORT_ENABLED
    QMetaObject::invokeMethod(this, "delayedDBusConnects", Qt::QueuedConnection);
#endif

    loadPalettes();
}

KHintsSettingsMac::~KHintsSettingsMac()
{
}

// adapted from QGenericUnixTheme::xdgIconThemePaths()
QStringList KHintsSettingsMac::xdgIconThemePaths() const
{
    QStringList paths;

    // make sure we have ~/.local/share/icons in paths if it exists
    paths << QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, QStringLiteral("icons"), QStandardPaths::LocateDirectory);

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
#ifdef DBUS_SUPPORT_ENABLED
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KToolBar"), QStringLiteral("org.kde.KToolBar"),
                                          QStringLiteral("styleChanged"), this, SLOT(toolbarStyleChanged()));
    QDBusConnection::sessionBus().connect(QString(), QStringLiteral("/KGlobalSettings"), QStringLiteral("org.kde.KGlobalSettings"),
                                          QStringLiteral("notifyChange"), this, SLOT(slotNotifyChange(int,int)));
#endif
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
// do this only when certain that there's a QApplication instance:
//         QApplication *app = qobject_cast<QApplication *>(QCoreApplication::instance());
//         if (app) {
//             qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "platform theme:" << app->style()->objectName();
//         }
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
            updateShowIconsInMenuItems(cg);
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
                << QStringLiteral("aqua")
                << QStringLiteral("macintosh")
                << QStringLiteral("fusion")
                << QStringLiteral("windows");
        if (mTheme->verbose) {
            qCWarning(PLATFORMTHEME) << "initial widget style list:" << styleNames;
        }
        const QString lnfStyle = readConfigValue(QStringLiteral("KDE"), QStringLiteral("widgetStyle"), QString()).toString();
        if (!lnfStyle.isEmpty() && !styleNames.contains(lnfStyle)) {
            styleNames.prepend(lnfStyle);
            if (mTheme->verbose) {
                qCWarning(PLATFORMTHEME) << "Found widgetStyle" << lnfStyle << "look-and-feel definition"
                    << (LnfConfig() ? LnfConfig()->name() : QStringLiteral("???"));
            }
        }
        if (mTheme->verbose) {
            qCWarning(PLATFORMTHEME) << "final widget style list:" << styleNames;
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

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

#include <qpa/qplatformthemeplugin.h>
#include <QChildEvent>
#include <QWidget>
#include <QApplication>
#include <QDebug>
#include <QPluginLoader>

#include "kdemactheme.h"
#include "platformtheme_logging.h"

#include <config-platformtheme.h>

// We call ourselves the "cocoa" platform theme plugin. Doing that means we replace
// the native platform theme. That is not a problem because the KdeMacTheme class proxies
// the native theme. It just means that the native theme inherits a number of KDE
// extensions, which are loaded automatically without user intervention like setting
// an env. variable.

// NB NB
// This file should be kept in sync with main_kde.cpp !!
// NB NB

static QPluginLoader unloadProtection;

class CocoaPlatformThemePlugin : public QPlatformThemePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1" FILE "cocoaplatformtheme.json")
public:
    CocoaPlatformThemePlugin(QObject *parent = Q_NULLPTR)
        : QPlatformThemePlugin(parent)
    {
        if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_DISABLED")) {
            qCWarning(PLATFORMTHEME) << "The Cocoa platform theme plugin has been disabled because of QT_QPA_PLATFORMTHEME_DISABLED";
        }
        if (qEnvironmentVariableIsSet("KDE_LAYOUT_USES_WIDGET_RECT")) {
            qApp->installEventFilter(this);
        }
    }
    ~CocoaPlatformThemePlugin()
    {
        if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
            qCWarning(PLATFORMTHEME) << Q_FUNC_INFO;
        }
    }

    QPlatformTheme *create(const QString &key, const QStringList &paramList) override
    {
        Q_UNUSED(key)
        Q_UNUSED(paramList)
        if (!qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_DISABLED")) {
            if (unloadProtection.fileName().isEmpty()) {
                unloadProtection.setFileName(QStringLiteral("platformthemes/" PLATFORM_PLUGIN_FILE_NAME));
                if (unloadProtection.fileName().isEmpty()) {
                    // try with the non-standard extension - probably redundant but I won't
                    // count on Qt to try the .so extension on Mac forever.
                    unloadProtection.setFileName(QStringLiteral("platformthemes/" PLATFORM_PLUGIN_FILE_NAME ".so"));
                }
                // using a global static loader instance should already prevent us from being unloaded
                // too early; add an additional layer of protection:
                unloadProtection.setLoadHints(QLibrary::PreventUnloadHint);
                bool success = unloadProtection.load();
                if (qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE")) {
                    qCWarning(PLATFORMTHEME) << "loaded from:"
                        << unloadProtection.fileName() << "unload protection:" << success;
                }
            }
            return new KdeMacTheme;
        } else {
            return nullptr;
        }
    }
protected:
    bool eventFilter(QObject *object, QEvent *event) override
    {
        switch (event->type()) {
            case QEvent::ChildAdded: {
                QChildEvent *childEvent = static_cast<QChildEvent*>(event);
                if (childEvent->child()->isWidgetType()) {
                    QWidget* theChildWidget = qobject_cast<QWidget*>(childEvent->child());
                    theChildWidget->setAttribute(Qt::WA_LayoutUsesWidgetRect, true);
                }
            }
        }
        return qApp->eventFilter(object, event);
    }
};

#include "main_cocoa.moc"

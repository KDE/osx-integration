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

#include "kdemactheme.h"

#include <config-platformtheme.h>

// We use a different internal class name for the Mac KDE platform theme plugin, but it will still
// identify itself as "KDE" to Qt. This ensures that it will also be picked up when using
// the XCB platform plugin (without patching it).

// NB NB
// This file should be kept in sync with main_kde.cpp !!
// NB NB

class KdePlatformThemePlugin : public QPlatformThemePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QPA.QPlatformThemeFactoryInterface.5.1" FILE "kdeplatformtheme.json")
public:
    KdePlatformThemePlugin(QObject *parent = Q_NULLPTR)
        : QPlatformThemePlugin(parent)
    {
        if (qEnvironmentVariableIsSet("KDE_LAYOUT_USES_WIDGET_RECT")) {
            qApp->installEventFilter(this);
        }
    }

    QPlatformTheme *create(const QString &key, const QStringList &paramList) Q_DECL_OVERRIDE
    {
        Q_UNUSED(key)
        Q_UNUSED(paramList)
        return new KdeMacTheme;
    }
protected:
    bool eventFilter(QObject *object, QEvent *event)
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

#include "main_kde.moc"

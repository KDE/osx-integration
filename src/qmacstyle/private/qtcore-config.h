/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtWidgets module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include <QtCore/qtcore-config.h>

#ifndef QT_FEATURE_style_mac
#   define QT_FEATURE_style_mac 1
#endif

#ifndef QT_FEATURE_checkbox
#   define QT_FEATURE_checkbox 1
#endif

#ifndef QT_FEATURE_dialogbuttonbox
#   define QT_FEATURE_dialogbuttonbox 1
#endif

#ifndef QT_FEATURE_pushbutton
#   define QT_FEATURE_pushbutton 1
#endif

#ifndef QT_FEATURE_formlayout
#   define QT_FEATURE_formlayout 1
#endif

/*
 * These QT_[REQUIRE_]CONFIG features already exist as QT_NO_foo in 5.8 and earlier:
 */

#ifndef QT_FEATURE_columnview
#   ifdef QT_NO_QCOLUMNVIEW
#       warning "No support for QColumnView"
#       define QT_FEATURE_columnview -1
#   else
#       define QT_FEATURE_columnview 1
#   endif
#endif

#ifndef QT_FEATURE_wheelevent
#   ifdef QT_NO_WHEELEVENT
#       warning "No support for wheel events"
#       define QT_FEATURE_wheelevent -1
#   else
#       define QT_FEATURE_wheelevent 1
#   endif
#endif

#ifndef QT_FEATURE_wizard
#   ifdef QT_NO_WIZARD
#       warning "No support for QWizard"
#       define QT_FEATURE_wizard -1
#   else
#       define QT_FEATURE_wizard 1
#   endif
#endif

#ifndef QT_FEATURE_tabbar
#   ifdef QT_NO_TABBAR
#       warning "No support for QTabBar"
#       define QT_FEATURE_tabbar -1
#   else
#       define QT_FEATURE_tabbar 1
#   endif
#endif

#ifndef QT_FEATURE_dockwidget
#   ifdef QT_NO_DOCKWIDGET
#       warning "No support for QDockWidget"
#       define QT_FEATURE_dockwidget -1
#   else
#       define QT_FEATURE_dockwidget 1
#   endif
#endif

#ifndef QT_FEATURE_tabwidget
#   ifdef QT_NO_TABWIDGET
#       warning "No support for QTabWidget"
#       define QT_FEATURE_tabwidget -1
#   else
#       define QT_FEATURE_tabwidget 1
#   endif
#endif

#ifndef QT_FEATURE_itemviews
#   ifdef QT_NO_ITEMVIEWS
#       warning "No support for QItemViews"
#       define QT_FEATURE_itemviews -1
#   else
#       define QT_FEATURE_itemviews 1
#   endif
#endif

#ifndef QT_FEATURE_combobox
#   ifdef QT_NO_COMBOBOX
#       warning "No support for QComboBox"
#       define QT_FEATURE_combobox -1
#   else
#       define QT_FEATURE_combobox 1
#   endif
#endif

#ifndef QT_FEATURE_treeview
#   ifdef QT_NO_TREEVIEW
#       warning "No support for QTreeView"
#       define QT_FEATURE_treeview -1
#   else
#       define QT_FEATURE_treeview 1
#   endif
#endif

#ifndef QT_FEATURE_tableview
#   ifdef QT_NO_TABLEVIEW
#       warning "No support for QTableView"
#       define QT_FEATURE_tableview -1
#   else
#       define QT_FEATURE_tableview 1
#   endif
#endif

#ifndef QT_FEATURE_rubberband
#   ifdef QT_NO_RUBBERBAND
#       warning "No support for QRubberBand"
#       define QT_FEATURE_rubberband -1
#   else
#       define QT_FEATURE_rubberband 1
#   endif
#endif

#ifndef QT_FEATURE_listview
#   ifdef QT_NO_LISTVIEW
#       warning "No support for QListView"
#       define QT_FEATURE_listview -1
#   else
#       define QT_FEATURE_listview 1
#   endif
#endif

#ifndef QT_FEATURE_datetimeedit
#   ifdef QT_NO_DATETIMEEDIT
#       warning "No support for QDateTimeEdit"
#       define QT_FEATURE_datetimeedit -1
#   else
#       define QT_FEATURE_datetimeedit 1
#   endif
#endif

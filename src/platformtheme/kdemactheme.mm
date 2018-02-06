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

// #define ADD_MENU_KEY

#include "config-platformtheme.h"
#include "kdemactheme.h"
#include "kfontsettingsdatamac.h"
#include "khintssettingsmac.h"
#include "kdeplatformfiledialoghelper.h"
#include "kdeplatformsystemtrayicon.h"
#include "platformtheme_logging.h"

#include <qglobal.h>
#include <QObject>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QApplication>
#include <QKeyEvent>
#include <QMessageBox>
#include <QFont>
#include <QPalette>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QDebug>

#include <QEvent>
#include <QAbstractNativeEventFilter>
#ifndef QT_NO_GESTURES
#include <QMouseEvent>
#include <QGesture>
#include <QTapAndHoldGesture>
#include <QToolButton>
#include <QPushButton>
#include <QMenu>
#include <QMenuBar>
#include <QTabBar>
#include <QTabWidget>
#include <QMdiSubWindow>
#include <QTextEdit>
#include <QScrollBar>
#endif

// instantiating the native platform theme requires the use of private APIs
#include <QtGui/private/qguiapplication_p.h>
#include <QtGui/qpa/qplatformintegration.h>
#include <QtGui/qpa/qplatformnativeinterface.h>


#include <kiconengine.h>
#include <kiconloader.h>
#include <kstandardshortcut.h>
#include <KStandardGuiItem>
#include <KLocalizedString>

#include <AppKit/AppKit.h>
#include <IOKit/hidsystem/ev_keymap.h>

#ifdef USE_PLCRASHREPORTER
#include <CrashReporter/CrashReporter.h>
#endif

// [NSEvent modifierFlags] keycodes:
// LeftShift=131330
// RightShift=131332
// LeftAlt=524576
// RightAlt=524608
// LeftCommand=1048840
// RightCommand=1048848
// RightCommand+RightAlt=1573200

static QString platformName = QStringLiteral("<unset>");

// #define TAPANDHOLD_DEBUG

class KdeMacThemeEventFilter : public QObject
{
    Q_OBJECT
public:
    KdeMacThemeEventFilter(QObject *parent=nullptr)
        : QObject(parent)
    {
        qtNativeFilter = new QNativeEventFilter;
    }
    virtual ~KdeMacThemeEventFilter()
    {
        delete qtNativeFilter;
        qtNativeFilter = nullptr;
    }

    class QNativeEventFilter : public QAbstractNativeEventFilter
    {
    public:
        virtual bool nativeEventFilter(const QByteArray &eventType, void *message, long *result) override;
    };

    QNativeEventFilter *qtNativeFilter;

#ifdef ADD_MENU_KEY
    const static int keyboardMonitorMask = NSKeyDownMask | NSKeyUpMask | NSFlagsChangedMask;

    NSEvent *nativeEventHandler(void *message);
    id m_keyboardMonitor;
    bool enabled;
    NSTimeInterval disableTime;
#endif

#ifndef QT_NO_GESTURES
    inline bool handleGestureForObject(const QObject *obj) const
    {
        // this function is called with an <obj> that is or inherits a QWidget
        const QPushButton *btn = qobject_cast<const QPushButton*>(obj);
        const QToolButton *tbtn = qobject_cast<const QToolButton*>(obj);
        if (tbtn) {
            return !tbtn->menu();
        } else if (btn) {
            return !btn->menu();
        } else {
            return (qobject_cast<const QTabBar*>(obj) || qobject_cast<const QTabWidget*>(obj)
//                 || obj->inherits("QTabBar") || obj->inherits("QTabWidget")
                || qobject_cast<const QMdiSubWindow*>(obj)
                || qobject_cast<const QTextEdit*>(obj)
                || qobject_cast<const QScrollBar*>(obj)
                // this catches items in directory lists and the like
                || obj->objectName() == QStringLiteral("qt_scrollarea_viewport")
                || obj->inherits("KateViewInternal"));
            // Konsole windows can be found as obj->inherits("Konsole::TerminalDisplay") but
            // for some reason Konsole doesn't respond to synthetic ContextMenu events
        }
    }
#endif

    int pressedMouseButtons()
    {
        return [NSEvent pressedMouseButtons];
    }

    bool eventFilter(QObject *obj, QEvent *event) override
    {
#ifndef QT_NO_GESTURES
        static QVariant qTrue(true), qFalse(false);
// #ifdef TAPANDHOLD_DEBUG
//         if (qEnvironmentVariableIsSet("TAPANDHOLD_CONTEXTMENU_DEBUG")) {
//             QVariant isGrabbed = obj->property("OurTaHGestureActive");
//             if (isGrabbed.isValid() && isGrabbed.toBool()) {
//                 qCWarning(PLATFORMTHEME) << "event=" << event << "grabbed obj=" << obj;
//             }
//         }
// #endif
        switch (event->type()) {
            case QEvent::MouseButtonPress: {
                QMouseEvent *me = dynamic_cast<QMouseEvent*>(event);
                if (me->button() == Qt::LeftButton && me->modifiers() == Qt::NoModifier) {
                    QWidget *w = qobject_cast<QWidget*>(obj);
                    if (w && handleGestureForObject(obj)) {
                        QVariant isGrabbed = obj->property("OurTaHGestureActive");
                        if (!(isGrabbed.isValid() && isGrabbed.toBool())) {
                            // ideally we'd check first - if we could.
                            // storing all grabbed QObjects is potentially dangerous since we won't
                            // know when they go stale.
                            w->grabGesture(Qt::TapAndHoldGesture);
                            // accept this event but resend it so that the 1st mousepress
                            // can also trigger a tap-and-hold!
                            obj->setProperty("OurTaHGestureActive", qTrue);
#ifdef TAPANDHOLD_DEBUG
                            if (qEnvironmentVariableIsSet("TAPANDHOLD_CONTEXTMENU_DEBUG")) {
                                qCWarning(PLATFORMTHEME) << "event=" << event << "grabbing obj=" << obj << "parent=" << obj->parent();
                            }
#endif
                            if (!m_grabbing.contains(obj)) {
                                QMouseEvent relay(*me);
                                me->accept();
                                m_grabbing.insert(obj);
                                int ret = QCoreApplication::sendEvent(obj, &relay);
                                m_grabbing.remove(obj);
                                return ret;
                            }
                        }
                    }
#ifdef TAPANDHOLD_DEBUG
                    else if (w && qEnvironmentVariableIsSet("TAPANDHOLD_CONTEXTMENU_DEBUG")) {
                        qCWarning(PLATFORMTHEME) << "event=" << event << "obj=" << obj << "parent=" << obj->parent();
                    }
#endif
                }
                // NB: don't "eat" the event if no action was taken!
                break;
            }
//             case QEvent::Paint:
//                 if (pressedMouseButtons() == 1) {
//                     // ignore QPaintEvents when the left mouse button (1<<0) is being held
//                     break;
//                 } else {
//                     // not holding the left mouse button; fall through to check if
//                     // maybe we should cancel a click-and-hold-opens-contextmenu process.
//                 }
            case QEvent::MouseMove:
            case QEvent::MouseButtonRelease: {
                QVariant isGrabbed = obj->property("OurTaHGestureActive");
                if (isGrabbed.isValid() && isGrabbed.toBool()) {
#ifdef TAPANDHOLD_DEBUG
                    qCWarning(PLATFORMTHEME) << "event=" << event << "obj=" << obj << "parent=" << obj->parent()
                        << "grabbed=" << obj->property("OurTaHGestureActive");
#endif
                    obj->setProperty("OurTaHGestureActive", qFalse);
                }
                break;
            }
            case QEvent::Gesture: {
                QGestureEvent *gEvent = static_cast<QGestureEvent*>(event);
                if (QTapAndHoldGesture *heldTap = static_cast<QTapAndHoldGesture*>(gEvent->gesture(Qt::TapAndHoldGesture))) {
                    if (heldTap->state() == Qt::GestureFinished) {
                        QVariant isGrabbed = obj->property("OurTaHGestureActive");
                        if (isGrabbed.isValid() && isGrabbed.toBool() && pressedMouseButtons() == 1) {
                            QWidget *w = qobject_cast<QWidget*>(obj);
                            // user clicked and held a button, send it a simulated ContextMenuEvent
                            // but send a simulated buttonrelease event first.
                            QPoint localPos = w->mapFromGlobal(heldTap->position().toPoint());
                            QContextMenuEvent ce(QContextMenuEvent::Mouse, localPos, heldTap->hotSpot().toPoint());
                            // don't send a ButtonRelease event to Q*Buttons because we don't want to trigger them
                            if (QPushButton *btn = qobject_cast<QPushButton*>(obj)) {
                                btn->setDown(false);
                                obj->setProperty("OurTaHGestureActive", qFalse);
                            } else if (QToolButton *tbtn = qobject_cast<QToolButton*>(obj)) {
                                tbtn->setDown(false);
                                obj->setProperty("OurTaHGestureActive", qFalse);
                            } else {
                                QMouseEvent me(QEvent::MouseButtonRelease, localPos, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
#ifdef TAPANDHOLD_DEBUG
                                qCWarning(PLATFORMTHEME) << "Sending" << &me;
#endif
                                // we'll be unsetting OurTaHGestureActive in the MouseButtonRelease handler above
                                QCoreApplication::sendEvent(obj, &me);
                            }
                            qCWarning(PLATFORMTHEME) << "Sending" << &ce << "to" << obj << "because of" << gEvent << "isGrabbed=" << isGrabbed;
                            bool ret = QCoreApplication::sendEvent(obj, &ce);
                            gEvent->accept();
                            qCWarning(PLATFORMTHEME) << "\tsendEvent" << &ce << "returned" << ret;
                            return true;
                        }
                    }
                }
                break;
            }
#ifdef TAPANDHOLD_DEBUG
            case QEvent::ContextMenu:
                if (qEnvironmentVariableIsSet("TAPANDHOLD_CONTEXTMENU_DEBUG")) {
                    qCWarning(PLATFORMTHEME) << "event=" << event << "obj=" << obj << "parent=" << obj->parent()
                        << "grabbed=" << obj->property("OurTaHGestureActive");
                }
                break;
#endif
            default:
                break;
        }
#endif
        return false;
    }
#ifndef QT_NO_GESTURES
    QSet<QObject*> m_grabbing;
#endif
};

bool KdeMacThemeEventFilter::QNativeEventFilter::nativeEventFilter(const QByteArray&, void *message, long *)
{
    NSEvent *event = static_cast<NSEvent *>(message);
    switch ([event type]) {
#if defined(MAC_OS_X_VERSION_10_12) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_12)
        case NSEventTypeSystemDefined:
#else
        case NSSystemDefined:
#endif
        {
            // borrowed with thanks from QMPlay2
            const int  keyCode   = ([event data1] & 0xFFFF0000) >> 16;
            const int  keyFlags  = ([event data1] & 0x0000FFFF);
            const int  keyState  = (((keyFlags & 0xFF00) >> 8) == 0xA);

//             qCWarning(PLATFORMTHEME) << QStringLiteral("NSSystemDefined event keyCode=%1 keyFlags=%2 keyState=%3").arg(keyCode).arg(keyFlags).arg(keyState);
            if (keyState == 1) {
                int qtKey = 0;
                switch (keyCode) {
                    case NX_KEYTYPE_PLAY:
                        qtKey = Qt::Key_MediaTogglePlayPause;
                        break;
                    case NX_KEYTYPE_NEXT:
                    case NX_KEYTYPE_FAST:
                        qtKey = Qt::Key_MediaNext;
                        break;
                    case NX_KEYTYPE_PREVIOUS:
                    case NX_KEYTYPE_REWIND:
                        qtKey = Qt::Key_MediaPrevious;
                        break;
                }
                if (qtKey) {
                    QKeyEvent mediaKeyEvent(QEvent::KeyPress, qtKey, Qt::NoModifier);
                    qCWarning(PLATFORMTHEME) << "Sending mediaKeyEvent" << &mediaKeyEvent;
                    QCoreApplication::sendEvent(qApp, &mediaKeyEvent);
                    return false;
                }
            }
            break;
        }
    }
    return false;
}

#ifdef ADD_MENU_KEY
NSEvent *KdeMacThemeEventFilter::nativeEventHandler(void *message)
{
    NSEvent *event = static_cast<NSEvent *>(message);
    switch ([event type]) {
        case NSFlagsChanged: {
            switch ([event modifierFlags]) {
                case 524608:
                case 1048848:
                    enabled = false;
                    disableTime = [event timestamp];
                    break;
                case 1573200:
                    // simultaneous press (i.e. within <= 0.1s) of just the right Command and Option keys:
                    if (enabled || [event timestamp] - disableTime <= 0.1) {
                        enabled = true;
//                         qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "event=" << QString::fromNSString([event description])
//                             << "modifierFlags=" << [event modifierFlags] << "keyCode=" << [event keyCode];
                        const unichar menuKeyCode = static_cast<unichar>(NSMenuFunctionKey);
                        NSString *menuKeyString = [NSString stringWithCharacters:&menuKeyCode length:1];
                        NSEvent *menuKeyEvent = [NSEvent keyEventWithType:NSKeyDown
                            location:[event locationInWindow]
                            modifierFlags:([event modifierFlags] & ~(NSCommandKeyMask|NSAlternateKeyMask))
                            timestamp:[event timestamp] windowNumber:[event windowNumber]
                            context:nil characters:menuKeyString charactersIgnoringModifiers:menuKeyString isARepeat:NO
                            // the keyCode must be an 8-bit value so not to be confounded with the Unicode value.
                            // Judging from Carbon/Events.h 0x7f is unused.
                            keyCode:0x7f];
//                         qCWarning(PLATFORMTHEME) << "new event:" << QString::fromNSString([menuKeyEvent description]);
                        return menuKeyEvent;
                    }
                    // fall through!
                default:
                    // any other flag change reenables the menukey emulation.
                    enabled = true;
                    break;
            }
            break;
        }
//         case NSKeyDown: {
//             qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "event=" << QString::fromNSString([event description])
//                 << "key=" << [event keyCode] 
//                 << "modifierFlags=" << [event modifierFlags] << "chars=" << QString::fromNSString([event characters])
//                 << "charsIgnMods=" << QString::fromNSString([event charactersIgnoringModifiers]);
//             break;
//         }
    }
    // standard event processing
    return event;
}
#endif //ADD_MENU_KEY

static void warnNoNativeTheme()
{
    // Make sure the warning appears somewhere. qCWarning(PLATFORMTHEME) isn't guaranteed to be of use when we're
    // not called from a terminal session and it's probably too early to try an alert dialog.
    // NSLog() will log to system.log, but also to the terminal.
    if (platformName.contains(QLatin1String("cocoa"))) {
        NSLog(@"The %s platform theme plugin is being used and the native theme for the %@ platform failed to load.\n"
            "Applications will function but lack functionality available only through the native theme,\n"
            "including the menu bar at the top of the screen(s).", PLATFORM_PLUGIN_THEME_NAME, platformName.toNSString());
    } else {
        NSLog(@"The %s platform theme plugin is being used and the native theme for the %@ platform failed to load.\n"
            "Applications will function but lack functionality available only through the native theme.",
            PLATFORM_PLUGIN_THEME_NAME, platformName.toNSString());
    }
}

/* ============
How we get here:
(lldb) bt
* thread #1: tid = 0x2e3a6be, 0x000000010a481454 KDEPlatformTheme.so`KdeMacTheme::KdeMacTheme(this=0x0000000103a3d830) + 4 at kdemactheme.mm:72, queue = 'com.apple.main-thread', stop reason = breakpoint 1.2
  * frame #0: 0x000000010a481454 KDEPlatformTheme.so`KdeMacTheme::KdeMacTheme(this=0x0000000103a3d830) + 4 at kdemactheme.mm:72
    frame #1: 0x000000010a48686b KDEPlatformTheme.so`CocoaPlatformThemePlugin::create(this=<unavailable>, key=<unavailable>, paramList=<unavailable>) + 27 at main_mac.cpp:53
    frame #2: 0x00000001008c85b8 QtGui`QPlatformThemeFactory::create(QString const&, QString const&) [inlined] QPlatformTheme* qLoadPlugin<QPlatformTheme, QPlatformThemePlugin, QStringList&>(loader=<unavailable>, key=0x0000000103a406b0, args=0x0000000103a3d710) + 60 at qfactoryloader_p.h:103
    frame #3: 0x00000001008c857c QtGui`QPlatformThemeFactory::create(key=<unavailable>, platformPluginPath=<unavailable>) + 396 at qplatformthemefactory.cpp:73
    frame #4: 0x00000001008d31bb QtGui`QGuiApplicationPrivate::createPlatformIntegration() [inlined] QLatin1String::QLatin1String(this=0x0000000103b17a00, pluginArgument=0x0000000103b17a00, this=0x0000000103b17a00, platformPluginPath=0x000000010134fa90, s=0x0000000103b19e50, platformThemeName=0x000000010134fa90, argc=<unavailable>, argv=<unavailable>) + 1357 at qguiapplication.cpp:1135
    frame #5: 0x00000001008d2c6e QtGui`QGuiApplicationPrivate::createPlatformIntegration(this=0x0000000103c0a6a0) + 1950 at qguiapplication.cpp:1257
    frame #6: 0x00000001008d3adb QtGui`QGuiApplicationPrivate::createEventDispatcher(this=<unavailable>) + 27 at qguiapplication.cpp:1274
    frame #7: 0x00000001010e0098 QtCore`QCoreApplicationPrivate::init(this=0x0000000103c0a6a0) + 1832 at qcoreapplication.cpp:794
    frame #8: 0x00000001008cfce1 QtGui`QGuiApplicationPrivate::init(this=0x0000000103c0a6a0) + 49 at qguiapplication.cpp:1297
    frame #9: 0x000000010001e90e QtWidgets`QApplicationPrivate::init(this=0x0000000103c0a6a0) + 14 at qapplication.cpp:583
============ */

KdeMacTheme::KdeMacTheme()
    : m_nativeInterface(nullptr)
    , verbose(qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME_VERBOSE"))
{
    if (strcasecmp(QT_VERSION_STR, qVersion())) {
        NSLog(@"Warning: the %s platform theme plugin for Mac was built against Qt %s but is running with Qt %s!",
            PLATFORM_PLUGIN_THEME_NAME, QT_VERSION_STR, qVersion());
    }
    // first things first: instruct Qt not to use the Mac-style toplevel menubar
    // if we are not using the Cocoa QPA plugin (but the XCB QPA instead).
    platformName = QGuiApplication::platformName();
    QString platformThemeName;
    if (!platformName.contains(QLatin1String("cocoa"))) {
        QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar, true);
        QCoreApplication::setAttribute(Qt::AA_MacDontSwapCtrlAndMeta, true);
        m_isCocoa = false;
        // we will almost certainly be using the xcb QPA ("X11"). We'll proxy
        // the generic Unix theme, *not* the KDE theme. That'd be redundant.
        platformThemeName = QStringLiteral("generic");
    } else {
        m_isCocoa = true;
        platformThemeName = platformName;
    }
    QPlatformIntegration *pi = QGuiApplicationPrivate::platformIntegration();
    if (pi) {
        nativeTheme = pi->createPlatformTheme(platformThemeName);
    } else {
        nativeTheme = Q_NULLPTR;
    }
    if (!nativeTheme) {
        warnNoNativeTheme();
    } else if (verbose) {
        qCWarning(PLATFORMTHEME) << Q_FUNC_INFO
            << "loading platform theme plugin" << QLatin1String(PLATFORM_PLUGIN_THEME_NAME) << "for platform" << platformName;
    }
    m_fontsData = Q_NULLPTR;
    m_hints = Q_NULLPTR;
    loadSettings();

    m_eventFilter = new KdeMacThemeEventFilter;
#ifndef QT_NO_GESTURES
    qApp->installEventFilter(m_eventFilter);
#endif
#ifdef ADD_MENU_KEY
    m_eventFilter->m_keyboardMonitor = 0;
    @autoreleasepool {
        // set up a keyboard event monitor
        m_eventFilter->m_keyboardMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:KdeMacThemeEventFilter::keyboardMonitorMask
            handler:^(NSEvent* event) { return m_eventFilter->nativeEventHandler(event); }];
    }
    if (m_eventFilter->m_keyboardMonitor) {
        m_eventFilter->enabled = true;
    } else {
        qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "Could not create a global keyboard monitor";
    }
#endif
    // for some reason our Qt native event filter is apparently never called.
    qApp->installNativeEventFilter(m_eventFilter->qtNativeFilter);

#ifdef USE_PLCRASHREPORTER
    static PLCrashReporter *crashReporter = nil;
    if (!crashReporter) {
        crashReporter = [[PLCrashReporter alloc]
            initWithConfiguration:[PLCrashReporterConfig defaultConfiguration]];
    }
    NSError *error;
    if ([crashReporter hasPendingCrashReport]) @autoreleasepool {
        NSData *crashData;
        PLCrashReport *report = nil;
        crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
        if (crashData) {
            report = [[[PLCrashReport alloc] initWithData:crashData error:&error] autorelease];
        }
        if (report) {
            // report could be sent to KAboutData::applicationData().bugAddress()
            // using QDesktopServices::openUrl("mailto:<etc>")
            qCWarning(PLATFORMTHEME) << qApp->applicationName() << "crashed on" << QString::fromNSString([report.systemInfo.timestamp description]);
            qCWarning(PLATFORMTHEME) << "\twith signal" << QString::fromNSString(report.signalInfo.name)
                << "code" << QString::fromNSString(report.signalInfo.code)
                << "at address" << report.signalInfo.address;
        }
        [crashReporter purgePendingCrashReport];
    }
    if (![crashReporter enableCrashReporterAndReturnError: &error]) {
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
    }
#endif
}

KdeMacTheme::~KdeMacTheme()
{
    delete nativeTheme;
    if (m_eventFilter) {
        qApp->removeNativeEventFilter(m_eventFilter->qtNativeFilter);
#ifdef ADD_MENU_KEY
        m_eventFilter->enabled = false;
        if (m_eventFilter->m_keyboardMonitor) {
            @autoreleasepool {
                 [NSEvent removeMonitor:m_eventFilter->m_keyboardMonitor];
            }
        }
#endif
    }
    delete m_eventFilter;
    m_eventFilter = 0;
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
        if (verbose) {
            qCWarning(PLATFORMTHEME) << "themeHint" << hintType << ":" << hint;
        }
        return hint;
    } else {
        if (nativeTheme) {
            if (verbose) {
                qCWarning(PLATFORMTHEME) << "Using native theme for themeHint" << hintType << ":" << nativeTheme->themeHint(hintType);
            }
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
//             qCWarning(PLATFORMTHEME) << "native font for type" << type << "=role" << fontType(type) << ":" << *qf;
//         } else {
//             qCWarning(PLATFORMTHEME) << "native font for type" << type << "=role" << fontType(type) << ": NULL";
//         }
    }
    return qf;
}

void KdeMacTheme::loadSettings()
{
    if (!m_fontsData) {
        m_fontsData = new KFontSettingsDataMac(this);
    }
    if (!m_hints) {
        m_hints = new KHintsSettingsMac(this);
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
#ifdef KDEMACTHEME_PREFER_NATIVE_DIALOGS
    if (nativeTheme) {
        return nativeTheme->usePlatformNativeDialog(type);
    }
#endif
#ifndef KDEMACTHEME_NEVER_NATIVE_DIALOGS
    return type == QPlatformTheme::FileDialog && qobject_cast<QApplication*>(QCoreApplication::instance());
#else
    return false;
#endif
}

QString KdeMacTheme::standardButtonText(int button) const
{
    // assume that button text is a domain where cross-platform application
    // coherence primes over native platform look and feel. IOW, function over form.
    // It's impossible to use the parent's method since we use
    // the nativeTheme in the default case
    switch (static_cast<QPlatformDialogHelper::StandardButton>(button)) {
        case QPlatformDialogHelper::NoButton:
            qCWarning(PLATFORMTHEME) << Q_FUNC_INFO << "Unsupported standard button:" << button;
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
#ifdef KDEMACTHEME_PREFER_NATIVE_DIALOGS
    // always prefer native dialogs - when using the Cocoa QPA.
    // NOTE: somehow, the "don't use native dialog" option that Qt's example "standarddialogs"
    // provides does not modify our usePlatformNativeDialog() return value, but *does* cause
    // a Qt dialog to be created instead of the native one. Weird.
    if (nativeTheme && m_isCocoa
            && (!qEnvironmentVariableIsSet("PREFER_KDE_DIALOGS") || qEnvironmentVariableIsEmpty("PREFER_KDE_DIALOGS"))) {
        return nativeTheme->createPlatformDialogHelper(type);
    }
#endif
    QPlatformDialogHelper *helper = KdePlatformTheme::createPlatformDialogHelper(type);
    if (helper) {
        return helper;
    } else {
        if (nativeTheme) {
            helper = nativeTheme->createPlatformDialogHelper(type);
        }
        return helper ? helper : QPlatformTheme::createPlatformDialogHelper(type);
    }
}

QPlatformSystemTrayIcon *KdeMacTheme::createPlatformSystemTrayIcon() const
{
    if (nativeTheme) {
        const auto systray = nativeTheme->createPlatformSystemTrayIcon();
        if (!m_isCocoa && verbose) {
            qCWarning(PLATFORMTHEME) << "Created native systray icon" << systray << "for platform" << platformName;
        }
        return systray;
    }
    // TODO: figure out if it makes sense to return something other than 
    // nativeTheme->createPlatformSystemTrayIcon() or even NULL
    return KdePlatformTheme::createPlatformSystemTrayIcon();
}

QPlatformNativeInterface *KdeMacTheme::nativeInterface()
{
    if (!m_nativeInterface) {
        m_nativeInterface = QGuiApplication::platformNativeInterface();
    }
    return m_nativeInterface;
}

KdeMacTheme::PlatformFunctionPtr KdeMacTheme::platformFunction(const QByteArray &functionName)
{
    if (nativeInterface()) {
        return m_nativeInterface->nativeResourceFunctionForIntegration(functionName);
    }
    return nullptr;
}

#include "kdemactheme.moc"

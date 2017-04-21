# OS X Integration

Improved integration of Qt and KDE applications with the Mac OS X desktop

### KDEPlatformTheme

The plugin Mac KDE platform theme plugin make it possible to use KDE font
specifications and colour palettes, so that themes like Breeze, Oxygen or
QtCurve look like they should but above all that applications use the fonts
and font roles for which they were designed.
This does require a custom-built Qt incorporating a simple patch.

### QMacStyle
A modified fork of the native macintosh style from Qt 5.8.0 which doesn't
impose the Mac standard font for QComboBox menu items and provides support
for named menu sections in context menus and menus attached to a "non-native"
menubar.

### QCocoaQPA
A modified fork of the Cocoa platform plugin from Qt 5.8.0 which provides
support for named menu sections under the native menubar and also improves 
the basic fullscreen mode that works consistently across Mission Control
settings and platforms - i.e. it never blackens out other
attached monitors but keeps their content visible and accessible. It's also a
lot faster and supports opening new windows without side-effects when in
fullscreen mode. This mode is active for windows lacking Qt's fullscreen hint
window flag (and thus the fullscreen button in their titlebar).
This plugin installs next to and will be loaded instead of the stock plugin; it
will then give priority to the modified QMacStyle if that is installed.

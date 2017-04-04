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

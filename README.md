# OS X Integration

Improved integration of Qt and KDE applications with the Mac OS X desktop

### KDEPlatformTheme

The plugin Mac KDE platform theme plugin makes it possible to use KDE font
specifications and colour palettes, so that themes like Breeze, Oxygen or
QtCurve look like they should but above all that applications use the fonts
and font roles for which they were designed. This plugin functions as a
wrapper; any request it cannot handle authoritatively itself will be handed
off to the platform plugin, which means things like native menubars and Dock
menus continue to work.
Newer versions of the plugin introduced build-time preferences for file
dialog styles (native or KDE) and more generic convenience features like
click-and-hold to trigger a contextmenu and emulation of a Menu key (right
Command+Option key-combo).

Originally a custom-built Qt with a simple patch was required that would let
the plugin load automatically like in a KDE session (KDE_SESSION_VERSION set to
4 or 5). Setting QT_QPA_PLATFORMTHEME=kde will work with a stock Qt install,
and the plugin can now also be built to override the native Cocoa QPA plugin
(OVERRIDE_NATIVE_THEME CMake option). The Menu key emulation still requires
a Qt patch (or a dedicated event handler) to do anything useful though.

### QMacStyle
A modified fork of the native macintosh style from Qt 5.9.0 which doesn't
impose the Mac standard font for QComboBox menu items and provides support
for named menu sections in context menus and menus attached to a "non-native"
menubar. Also builds against Qt 5.8.0 .

### QCocoaQPA
A modified fork of the Cocoa platform plugin from Qt 5.9.0 (builds against Qt
5.8.0) which provides support for named menu sections under the native menubar
and also reintroduces a basic fullscreen mode that works consistently across
Mission Control settings and platforms - i.e. it never blackens out other
attached monitors but keeps their content visible and accessible. It's also a
lot faster and supports opening new windows without side-effects when in
fullscreen mode.
This plugin installs next to and will be loaded instead of the stock plugin; it
will then give priority to the modified QMacStyle if that is installed. If the
KDE platform theme plugin is built in override mode (see above) this plugin is
loaded instead (and will then load the modified or the stock cocoa platform
plugin).

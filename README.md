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

* Other useful env. variables:
- QT_QPA_PLATFORMTHEME_VERBOSE : activate verbose mode (logging category
  CocoaPlatformTheme or KDEPlatformTheme).
- QT_QPA_PLATFORMTHEME_CONFIG_FILE : load a different file instead of "kdeglobals"
  from ~/.config or ~/Library/Preferences
- QT_QPA_PLATFORMTHEME_DISABLED : disable the plugin completely.
- PREFER_KDE_DIALOGS : force KDE dialogs even when configured to prefer native
  file dialogs.

This component should still build against Qt 5.5.x; the other components need at
least Qt 5.8 .

### QMacStyle
A modified fork of the native macintosh style from Qt 5.9 (git) which doesn't
impose the Mac standard font for QComboBox menu items and provides support
for named menu sections in context menus and menus attached to a "non-native"
menubar. Also builds against Qt 5.8.0 .
A standalone build of this component can be done using the provided QMake file
(qmacstyle/macstyle.pro).

### QCocoaQPA
A modified fork of the Cocoa platform plugin from Qt 5.9 (git; builds against Qt
5.8.0) which provides support for named menu sections under the native menubar
and also reintroduces a basic fullscreen mode that works consistently across
Mission Control settings and platforms - i.e. it never blackens out other
attached monitors but keeps their content visible and accessible. It's also a
lot faster and supports opening new windows without side-effects when in
fullscreen mode. Selecting the FreeType engine has been made easier via an env.
variable (QT_MAC_USE_FREETYPE) as well as an integration function that can be
called from application code (see kfontsettingsdatamac.mm). There's also support
for activating the FontConfig fontengine/database (QT_MAC_USE_FONTCONFIG) but
this requires a patched QtBase configured to use FontConfig. Both use a font
gamma setting that determines font darkness and can be set via the env. var
QT_MAC_FREETYPE_FONT_GAMMA .
This plugin installs next to and will be loaded instead of the stock plugin; it
will then give priority to the modified QMacStyle if that is installed. If the
KDE platform theme plugin is built in override mode (see above) this plugin is
loaded instead (and will then load the modified or the stock cocoa platform
plugin).
A standalone build of this component can be done using the provided QMake file
(qcocoa-qpa/qcocoa-standalone.pro).

### Building
The preferred way of building this project is using CMake, and requires KDE's Extra
CMake Modules (http://projects.kde.org/projects/kdesupport/extra-cmake-modules) ;
this is also the only way to build the KDE platform theme plugin component.

* CMake options:
- BUILD_KDE_THEME_PLUGIN : should the KDE platform theme plugin be built?
- BUILD_QT_PLUGINS : should the Qt style and QPA plugin components be built?

* CMake options for the KDE platform theme plugin:
- DEFINE_ICONTHEME_SETTINGS : Should the theme plugin define a standard theme and
  add the standard locations for icon themes to the search path?
- PREFER_NATIVE_DIALOGS : Should native dialogs be preferred over Qt's cross-platform
  dialogs?
- NEVER_NATIVE_DIALOGS : Should native dialogs never be used (when not already preferred)?
- OVERRIDE_NATIVE_THEME : see above. NB: the Macintosh/Aqua widget style remains the
  default style!
- DISABLE_DBUS_SUPPORT : Don't build the D-Bus functionality. Experimental!
- EMULATE_MENU_KEY : emulate a Menu key (right Command+Option key-combo); requires
  BUILD_QT_PLUGINS to be set in order for that keypress to open the context menu.

* CMake options for QCocoaQPA :
- HAVE_INFINALITY : should be enabled when you have the Infinality+Ultimate patch-set
  applied to FreeType *and* FontConfig. Without this option fonts will probably look
  washed out.

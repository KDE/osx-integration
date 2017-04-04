This project provides a modified standalone version of the Macintosh "native" widget style as used in Qt 5.8.0.

It has a few modifications (in addition to those require for standalone building):
- assumes QComboBox menu items always use a custom font, so that other themes (with different font sets) can be used
- implements support for named menu sections in context menus and menus attached to non-native menubars.
  (NB: native menubar menus are not drawn by the style)

Patches are kept in the 'patches' subdir.

This contains the qmacstyle* sources from Qt 5.8.0 plus the .pro, and main.mm files from
https://codereview.qt-project.org/gitweb?p=qt%2Fqtbase.git;a=commit;h=cd3078e08b4cc7d293b206aa525c68cf1709c8ce

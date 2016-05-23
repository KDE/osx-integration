 Default fonts in Qt 5.6.0 on OS X <= 10.9 :
 
    System: Lucida Grande 13pt
    System headlines: <System>,Bold
    Application: Helvetica 12pt
    Fixed width: Monaco 10pt
    Messages: <system>
    Labels: <system>,11pt
    Help tags: <system>,11pt
    Window title bars: <system>
    Utility window title bars: <system>,11pt
    --- Dumped from the native QPlatformTheme::themeFont() function:

    (themeFont QPlatformTheme::Font : CoreText font role)
    QPT::SystemFont (#0) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::MenuFont (#1) : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    QPT::MenuBarFont (#2) : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    QPT::MenuItemFont (#3) : 12 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,14,-1,5,50,0,0,0,0,0"
    QPT::MessageBoxFont (#4) : 3 = ".Lucida Grande UI" style "Bold" NSFont weight@12pt= 9 QFont= ".Lucida Grande UI,13,-1,5,75,0,0,0,0,0"
    QPT::LabelFont (#5) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::TipLabelFont (#6) : 25 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    QPT::StatusBarFont (#7) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::TitleBarFont (#8) : 15 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::MdiSubWindowTitleFont (#9) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::DockWidgetTitleFont (#10) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::PushButtonFont (#11) : 16 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::CheckBoxFont (#12) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::RadioButtonFont (#13) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::ToolButtonFont (#14) : 22 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,10,-1,5,50,0,0,0,0,0"
    QPT::ItemViewFont (#15) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::ListViewFont (#16) : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    QPT::HeaderViewFont (#17) : 4 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    QPT::ListBoxFont (#18) : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    QPT::ComboMenuItemFont (#19) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::ComboLineEditFont (#20) : 8 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,12,-1,5,50,0,0,0,0,0"
    QPT::SmallFont (#21) : 4 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,11,-1,5,50,0,0,0,0,0"
    QPT::MiniFont (#22) : 6 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,9,-1,5,50,0,0,0,0,0"
    QPT::FixedFont (#23) : 1 = "Monaco" style "Regular" NSFont weight@12pt= 5 QFont= "Monaco,10,-1,5,50,0,0,0,0,0"
    QPT::GroupBoxTitleFont (#24) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
    QPT::TabButtonFont (#25) : 2 = ".Lucida Grande UI" style "Regular" NSFont weight@12pt= 5 QFont= ".Lucida Grande UI,13,-1,5,50,0,0,0,0,0"
 

We can thus use the following mapping for kfontsettings, where DefaultFont is
"Lucida Grande" on <=10.9 and "San Francisco" on later systems:

Generic font, "font"            -> DefaultFont,  12pt, QFont::SansSerif
FixedFont, "fixed"              -> "Monaco",     10pt, QFont::Monospace
Toolbutton "toolBarFont"        -> DefaultFont,  10pt, QFont::SansSerif
MenuItems "menuFont"            -> DefaultFont,  14pt, QFont::SansSerif
Window titlebars, "activeFont"  ->DefaultFont,  13pt, QFont::SansSerif  (UNUSED)
Determined from examples including the Finder:
Taskbars "taskbarFont"          -> DefaultFont,   9pt, QFont::SansSerif
Minifont "smallestReadableFont" -> DefaultFont,   9pt, QFont::SansSerif
And because the MessageBoxFont should be bold on OS X:
MessageBox "messageBoxFont"     ->DefaultFont,  13pt, QFont::Bold, QFont::SansSerif

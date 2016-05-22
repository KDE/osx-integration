configure_file(config-platformtheme.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config-platformtheme.h )

set(platformtheme_SRCS
    kdeplatformtheme.cpp
    kfontsettingsdata.cpp
    khintssettings.cpp
    kdeplatformfiledialoghelper.cpp
    kdeplatformfiledialogbase.cpp
    kdeplatformsystemtrayicon.cpp
    kfiletreeview.cpp
    kdirselectdialog.cpp
    kdemactheme.mm
    kfontsettingsdatamac.mm
    khintssettingsmac.mm
    main_mac.cpp
)

include_directories(
    ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
)

# Use the same name for the platform theme module. This makes it impossible
# to install both the plasma and the OS X integration modules, but that's
# intentional.
add_library(KDEPlatformTheme MODULE ${platformtheme_SRCS})

# add KF5:WindowSystem?
target_link_libraries(KDEPlatformTheme
    PRIVATE
        Qt5::DBus
        KF5::ConfigWidgets
        KF5::ConfigCore
        KF5::IconThemes
        KF5::KIOFileWidgets # KFileFilterCombo, KDirSortFilterProxyModel, KRecentDirs
        KF5::KIOWidgets
        KF5::XmlGui
        KF5::I18n
        KF5::Notifications
)

target_link_libraries(KDEPlatformTheme PRIVATE "-framework AppKit")

install(TARGETS KDEPlatformTheme DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/platformthemes)

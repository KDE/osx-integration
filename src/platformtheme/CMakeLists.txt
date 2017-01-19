if(DEFINE_ICONTHEME_SETTINGS)
    message(STATUS "The icon theme search path will be set")
    add_definitions(-DKDEMACTHEME_ADD_ICONTHEMESETTINGS)
endif()
if(PREFER_NATIVE_DIALOGS)
    message(STATUS "Native dialogs will be preferred")
    add_definitions(-DKDEMACTHEME_PREFER_NATIVE_DIALOGS)
else()
    if(NEVER_NATIVE_DIALOGS)
        message(STATUS "Native dialogs will be avoided")
        add_definitions(-DKDEMACTHEME_NEVER_NATIVE_DIALOGS)
    endif()
endif()

add_subdirectory(presets)

if(OVERRIDE_NATIVE_THEME)
    set(PLATFORM_PLUGIN_THEME_NAME "cocoa")
    set(PLUGIN_FILENAME "CocoaPlatformTheme")
else()
    set(PLATFORM_PLUGIN_THEME_NAME "kde")
    set(PLUGIN_FILENAME "KDEPlatformTheme")
endif()
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
)
if(OVERRIDE_NATIVE_THEME)
    set(platformtheme_SRCS ${platformtheme_SRCS} main_cocoa.cpp)
else()
    set(platformtheme_SRCS ${platformtheme_SRCS} main_kde.cpp)
endif()

include_directories(
    ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
)

# Use the same name for the platform theme module. This makes it impossible
# to install both the plasma and the OS X integration modules, but that's
# intentional.
add_library(${PLUGIN_FILENAME} MODULE ${platformtheme_SRCS})

# add KF5:WindowSystem?
target_link_libraries(${PLUGIN_FILENAME}
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

target_link_libraries(${PLUGIN_FILENAME} PRIVATE "-framework AppKit")

install(TARGETS ${PLUGIN_FILENAME} DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/platformthemes)

cmake_minimum_required(VERSION 3.0)

project(OSXIntegration)

option(BUILD_KDE_THEME_PLUGIN
        "Should the KDE theme plugin be built?"
        ON)
option(BUILD_QT_PLUGINS
        "Should the Qt Cocoa QPA and Aqua style plugins be built (they don't depend on KDE but become optional when the KDE theme plugin is built)"
        ON)

option(DEFINE_ICONTHEME_SETTINGS
        "Should the theme plugin define a standard theme and add the standard locations for icon themes to the search path?"
        OFF)
option(PREFER_NATIVE_DIALOGS
        "Should native dialogs be preferred?"
        ON)
option(NEVER_NATIVE_DIALOGS
        "Should native dialogs never be used (when not already preferred)?"
        OFF)
option(OVERRIDE_NATIVE_THEME
        "Should the platform theme plugin override the native theme? If ON it installs as the \"Cocoa\" instead of as the \"kde\" theme."
        OFF)
option(DISABLE_DBUS_SUPPORT
        "Don't build the D-Bus functionality. Experimental!"
        OFF)
option(EMULATE_MENU_KEY
        "Emulate the presence of a Menu key as on PC keyboards when the right Command+Option keys are pressed.
        BUILD_QT_PLUGINS must be set for this to have any effect."
        OFF)
option(HAVE_INFINALITY
        "The Infinality+Ultimate patch set has been applied to FreeType and FontConfig.
        (the FontConfig patches are determining). See https://github.com/archfan/infinality_bundle"
        OFF)

option(USE_PLCRASHREPORTER
        "Use the Plausible CrashReporter (https://www.plcrashreporter.org)"
        OFF)

include(FeatureSummary)
add_feature_info("KDE platform theme plugin" BUILD_KDE_THEME_PLUGIN "")
add_feature_info("Build the Qt plugins" BUILD_QT_PLUGINS
        "Should the Qt Cocoa QPA and Aqua style plugins be built")
add_feature_info("Override the Cocoa platform" OVERRIDE_NATIVE_THEME
        "Install the platform theme plugin so it overrides the native \"Cocoa\" platform")
add_feature_info("Icon theme settings" DEFINE_ICONTHEME_SETTINGS
        "Should the theme plugin define a standard theme and add the standard locations for icon themes to the search path?")
add_feature_info("Prefer native dialogs" PREFER_NATIVE_DIALOGS "")
add_feature_info("Never use native dialogs" NEVER_NATIVE_DIALOGS "")
add_feature_info("No DBus" DISABLE_DBUS_SUPPORT
        "Don't build the D-Bus functionality. Experimental!")
add_feature_info("Emulate a Menu key" EMULATE_MENU_KEY
        "Emulate the presence of a Menu key as on PC keyboards when the right Command+Option keys are pressed.")
add_feature_info("Build for use with the Infinality+Ultimate patch-set" HAVE_INFINALITY "")

find_package(ECM 5.20.0  NO_MODULE)
set_package_properties(ECM PROPERTIES TYPE REQUIRED DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
# feature_summary(WHAT REQUIRED_PACKAGES_NOT_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES)


set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR} ${CMAKE_SOURCE_DIR}/cmake)


include(GenerateExportHeader)
include(CMakePackageConfigHelpers)
include(ECMSetupVersion)
include(ECMGenerateHeaders)
include(ECMQtDeclareLoggingCategory)

include(KDEInstallDirs)
include(KDEFrameworkCompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

# for the optional Qt QPA and style plugins
# (note that they have not yet been tested against Qt 5.7)
set(QT_MIN_VERSION 5.7.0)
# minimum required version:
if(BUILD_KDE_THEME_PLUGIN)
    # require the minimum version for the KF5 theme plugin and
    # only build the Qt plugins if the install is recent enough
    set(REQUIRED_QT_VERSION 5.5.0)
else()
    # when we only build the Qt plugins we require their minimum version
    set(REQUIRED_QT_VERSION ${QT_MIN_VERSION})
endif()
include(FindQt5Components)

execute_process(COMMAND cmake/git_version.sh
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  OUTPUT_VARIABLE KF5_VERSION
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "KF5_VERSION=${KF5_VERSION}")

if(BUILD_KDE_THEME_PLUGIN)
    # 20170119: v5.30.0 is synced with plasma-integration 5.8.95
    set(KF5_DEP_VERSION "5.33.0") # handled by release scripts

    ecm_setup_version(${KF5_VERSION} VARIABLE_PREFIX OSXINTEGRATION
                      VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/osxintegration_version.h"
                      PACKAGE_VERSION_FILE "${CMAKE_CURRENT_BINARY_DIR}/KF5OSXIntegrationConfigVersion.cmake"
                      SOVERSION 5)

    find_package(KF5 ${KF5_DEP_VERSION} REQUIRED COMPONENTS
                Config ConfigWidgets I18n IconThemes KIO Notifications WidgetsAddons)
    if (NOT DISABLE_DBUS_SUPPORT)
        find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED DBus)
        add_definitions(-DDBUS_SUPPORT_ENABLED)
    endif()
    add_definitions(-DTRANSLATION_DOMAIN=\"osxintegration5\")
    if (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/po")
        ki18n_install(po)
    endif()
endif()

add_subdirectory(src)
if(BUILD_KDE_THEME_PLUGIN)
    add_subdirectory(autotests)
#     add_subdirectory(tests)

    # create a Config.cmake and a ConfigVersion.cmake file and install them
    set(CMAKECONFIG_INSTALL_DIR "${KDE_INSTALL_CMAKEPACKAGEDIR}/KF5OSXIntegration")

    configure_package_config_file("${CMAKE_CURRENT_SOURCE_DIR}/KF5OSXIntegrationConfig.cmake.in"
                                  "${CMAKE_CURRENT_BINARY_DIR}/KF5OSXIntegrationConfig.cmake"
                                  INSTALL_DESTINATION  ${CMAKECONFIG_INSTALL_DIR}
                                  )

    install(FILES  "${CMAKE_CURRENT_BINARY_DIR}/KF5OSXIntegrationConfig.cmake"
                   "${CMAKE_CURRENT_BINARY_DIR}/KF5OSXIntegrationConfigVersion.cmake"
            DESTINATION "${CMAKECONFIG_INSTALL_DIR}"
            COMPONENT Devel )

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/osxintegration_version.h
            DESTINATION ${KDE_INSTALL_INCLUDEDIR_KF5} COMPONENT Devel )

    install(FILES macosx_workspace.notifyrc DESTINATION ${KDE_INSTALL_KNOTIFY5RCDIR})
endif()

feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)
if(CMAKE_OSX_DEPLOYMENT_TARGET)
    message(STATUS "OS X Deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()
if(CMAKE_OSX_SYSROOT)
    message(STATUS "OS X SDK sysroot: ${CMAKE_OSX_SYSROOT}")
endif()

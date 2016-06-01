cmake_minimum_required(VERSION 2.8.12)

project(OSXIntegration)

include(FeatureSummary)
find_package(ECM 5.20.0  NO_MODULE)
set_package_properties(ECM PROPERTIES TYPE REQUIRED DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
feature_summary(WHAT REQUIRED_PACKAGES_NOT_FOUND FATAL_ON_MISSING_REQUIRED_PACKAGES)


set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})


include(GenerateExportHeader)
include(ECMPackageConfigHelpers)
include(ECMSetupVersion)
include(ECMGenerateHeaders)

include(KDEInstallDirs)
include(KDEFrameworkCompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

set(REQUIRED_QT_VERSION 5.5.0)
find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Widgets)

execute_process(COMMAND git describe
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  OUTPUT_VARIABLE KF5_VERSION
)
message(STATUS "KF5_VERSION=${KF5_VERSION}")
# is there a more streamlined way to include sub-patch level versioning info into KF5_VERSION?
set(KF5_VERSION "5.22.0-17")
set(KF5_DEP_VERSION "5.20.0") # handled by release scripts

ecm_setup_version(${KF5_VERSION} VARIABLE_PREFIX OSXINTEGRATION
                  VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/osxintegration_version.h"
                  PACKAGE_VERSION_FILE "${CMAKE_CURRENT_BINARY_DIR}/KF5OSXIntegrationConfigVersion.cmake"
                  SOVERSION 5)

find_package(KF5Config ${KF5_DEP_VERSION} REQUIRED)
find_package(KF5ConfigWidgets ${KF5_DEP_VERSION} REQUIRED)
find_package(KF5IconThemes ${KF5_DEP_VERSION} REQUIRED)
find_package(KF5Notifications ${KF5_DEP_VERSION} REQUIRED)
find_package(KF5WidgetsAddons ${KF5_DEP_VERSION} REQUIRED)
find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED DBus)
find_package(KF5I18n ${KF5_DEP_VERSION} REQUIRED)
find_package(KF5KIO ${KF5_DEP_VERSION} REQUIRED)
add_definitions(-DTRANSLATION_DOMAIN=\"osxintegration5\")
if (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/po")
    ki18n_install(po)
endif()

add_subdirectory(src)
add_subdirectory(autotests)
# add_subdirectory(tests)

# create a Config.cmake and a ConfigVersion.cmake file and install them
set(CMAKECONFIG_INSTALL_DIR "${KDE_INSTALL_CMAKEPACKAGEDIR}/KF5OSXIntegration")

ecm_configure_package_config_file("${CMAKE_CURRENT_SOURCE_DIR}/KF5OSXIntegrationConfig.cmake.in"
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

feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)

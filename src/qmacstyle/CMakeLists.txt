if(NOT DEFINED PROJECT_NAME)
    cmake_minimum_required(VERSION 3.3)
    project(QAltMacStyle)
    set(QAMS_standalone ON)
else()
    message(STATUS "Sub-project QAltMacStyle of project ${PROJECT_NAME}")
    set(QAMS_standalone OFF)
endif()

include(FeatureSummary)
find_package(ECM 5.30.0  NO_MODULE)
set_package_properties(ECM PROPERTIES TYPE OPTIONAL DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(GenerateExportHeader)
include(ExternalProject)
include(ECMPackageConfigHelpers)
include(ECMGenerateHeaders)

include(KDEInstallDirs)
include(KDEFrameworkCompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

set(QT_MIN_VERSION 5.7.0)
if (${QAMS_standalone})
    set(REQUIRED_QT_VERSION ${QT_MIN_VERSION})
endif()
find_package(Qt5 ${REQUIRED_QT_VERSION} OPTIONAL_COMPONENTS Core Widgets Gui)
if(Qt5_FOUND AND (NOT ${Qt5_VERSION} VERSION_LESS ${QT_MIN_VERSION}))

    set(qaltmacstyle_SRCS
        qmacstyle_mac.mm
        main.mm
        private/qcombobox.cpp
        private/qcommonstyle.cpp
        private/qstyleanimation.cpp
        private/qstylehelper.cpp
    )

    include_directories(
        ${CMAKE_CURRENT_LIST_DIR}/private
        ${Qt5Widgets_PRIVATE_INCLUDE_DIRS}
        ${Qt5Core_PRIVATE_INCLUDE_DIRS}
    )

    ExternalProject_Add(qaltmacstyle
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}
        CONFIGURE_COMMAND ${QMAKE_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/macstyle.pro
        BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}
    )

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libqaltmacstyle.dylib DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/styles)
else()
    message(STATUS "QAltMacStyle needs a more recent Qt5 version - skipping")
endif()

feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)

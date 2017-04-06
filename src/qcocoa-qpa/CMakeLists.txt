if(NOT DEFINED PROJECT_NAME)
    cmake_minimum_required(VERSION 3.3)
    project(QAltCocoa)
    set(QAMS_standalone ON)
else()
    message(STATUS "Sub-project QAltCocoa of project ${PROJECT_NAME}")
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
find_package(Qt5 ${REQUIRED_QT_VERSION} OPTIONAL_COMPONENTS Core Widgets Gui PrintSupport)
if(Qt5_FOUND AND (NOT ${Qt5_VERSION} VERSION_LESS ${QT_MIN_VERSION}))

    ExternalProject_Add(qaltcocoa_qmake
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}
        CONFIGURE_COMMAND ${QMAKE_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/qcocoa-standalone.pro
        BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/qmake
    )
    add_custom_target(qaltcocoa ALL
        DEPENDS qaltcocoa_qmake
        COMMAND ${CMAKE_MAKE_PROGRAM}
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltcocoa.dylib
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/qmake
    )

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltcocoa.dylib DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/platforms)
else()
    message(STATUS "QAltCocoa needs a more recent Qt5 version - skipping")
endif()

feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)

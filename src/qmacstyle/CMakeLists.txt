if(NOT DEFINED PROJECT_NAME)
    cmake_minimum_required(VERSION 3.3)
    project(QAltMacStyle)
    set(QAMS_standalone ON)

    find_package(ECM 5.30.0  NO_MODULE)
    set_package_properties(ECM PROPERTIES TYPE OPTIONAL DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
    set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})
else()
    message(STATUS "Sub-project QAltMacStyle of project ${PROJECT_NAME}")
    set(QAMS_standalone OFF)
endif()

include(FeatureSummary)

include(ExternalProject)

# find the required Qt packages if that hasn't been done yet
if(${QAMS_standalone})
    set(QT_MIN_VERSION 5.7.0)
    set(REQUIRED_QT_VERSION ${QT_MIN_VERSION})
    find_package(Qt5 ${REQUIRED_QT_VERSION} OPTIONAL_COMPONENTS Core Widgets Gui)
endif()
if(Qt5_FOUND AND (NOT ${Qt5_VERSION} VERSION_LESS ${QT_MIN_VERSION}))

#     set(qaltmacstyle_SRCS
#         qmacstyle_mac.mm
#         main.mm
#         private/qcombobox.cpp
#         private/qcommonstyle.cpp
#         private/qstyleanimation.cpp
#         private/qstylehelper.cpp
#     )

    # ExternalProject_Add is tricky to handle the configure (qmake) step
    # and subsequent build steps esp. during incremental builds
    ExternalProject_Add(qaltmacstyle_qmake
        DOWNLOAD_COMMAND ""
        SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}
        CONFIGURE_COMMAND ${QMAKE_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/macstyle.pro
        BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/qmake
    )
    # use add_custom_target to handle (incremental) builds
    add_custom_target(qaltmacstyle ALL
        DEPENDS qaltmacstyle_qmake
        COMMAND ${CMAKE_MAKE_PROGRAM}
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltmacstyle.dylib
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/qmake
    )

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltmacstyle.dylib DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/styles)
else()
    # we should only end up here if we're being built as an optional component
    message(STATUS "QAltMacStyle needs a more recent Qt5 version - skipping")
endif()

if(${QAMS_standalone})
    feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)
endif()

if(NOT DEFINED PROJECT_NAME)
    cmake_minimum_required(VERSION 3.3)
    project(QAltCocoa)
    set(QAQPA_standalone ON)
else()
    message(STATUS "Sub-project QAltCocoa of project ${PROJECT_NAME}")
    set(QAQPA_standalone OFF)
endif()

include(FeatureSummary)
find_package(ECM 5.30.0  NO_MODULE)
set_package_properties(ECM PROPERTIES TYPE OPTIONAL DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(ExternalProject)

# find the required Qt packages if that hasn't been done yet
if(${QAQPA_standalone})
    set(QT_MIN_VERSION 5.7.0)
    set(REQUIRED_QT_VERSION ${QT_MIN_VERSION})
    find_package(Qt5 ${REQUIRED_QT_VERSION} OPTIONAL_COMPONENTS Core Widgets Gui PrintSupport)
endif()
if(Qt5_FOUND AND (NOT ${Qt5_VERSION} VERSION_LESS ${QT_MIN_VERSION}))

    execute_process(COMMAND ${QMAKE_EXECUTABLE} -query QT_INSTALL_HEADERS OUTPUT_VARIABLE QT_INCLUDES_DIR ERROR_VARIABLE QMAKE_ERRORS OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${QMAKE_EXECUTABLE} -query QT_INSTALL_LIBS OUTPUT_VARIABLE QT_FRAMEWORKS_DIR ERROR_VARIABLE QMAKE_ERRORS OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(QT_INCLUDES_DIR AND QT_FRAMEWORKS_DIR)
        remove_definitions(-DQT_NO_SIGNALS_SLOTS_KEYWORDS
            -DQT_NO_CAST_FROM_ASCII
            -DQT_NO_CAST_FROM_BYTEARRAY
            -DQT_NO_CAST_TO_ASCII
            -DQT_NO_URL_CAST_FROM_STRING)
        add_definitions(-DQT_PLUGIN)
        set(qaltcocoa_SRCS main.mm 
            qcocoaintegration.mm 
            qcocoatheme.mm 
            qcocoabackingstore.mm 
            qcocoawindow.mm 
            qnsview.mm 
            qnsviewaccessibility.mm 
            qnswindowdelegate.mm 
            qcocoanativeinterface.mm 
            qcocoaeventdispatcher.mm 
            qcocoaapplicationdelegate.mm 
            qcocoaapplication.mm 
            qcocoamenu.mm 
            qcocoamenuitem.mm 
            qcocoamenubar.mm 
            qcocoamenuloader.mm 
            qcocoahelpers.mm 
            qmultitouch_mac.mm 
            qcocoaaccessibilityelement.mm 
            qcocoaaccessibility.mm 
            qcocoacolordialoghelper.mm 
            qcocoafiledialoghelper.mm 
            qcocoafontdialoghelper.mm 
            qcocoacursor.mm 
            qcocoaclipboard.mm 
            qcocoadrag.mm 
            qmacclipboard.mm 
            qcocoasystemsettings.mm 
            qcocoainputcontext.mm 
            qcocoaservices.mm 
            qcocoasystemtrayicon.mm 
            qcocoaintrospection.mm 
            qcocoakeymapper.mm 
            qcocoamimetypes.mm
            messages.cpp
            qcocoaglcontext.mm
            qpaintengine_mac.mm 
            qprintengine_mac.mm 
            qcocoaprintersupport.mm 
            qcocoaprintdevice.mm 
        )
        qt5_add_resources(qaltcocoa_SRCS qcocoaresources.qrc)
        add_library(qaltcocoa SHARED ${qaltcocoa_SRCS})
        target_include_directories(qaltcocoa PRIVATE
            ${Qt5Core_PRIVATE_INCLUDE_DIRS}
            ${Qt5Widgets_PRIVATE_INCLUDE_DIRS}
            ${Qt5Gui_PRIVATE_INCLUDE_DIRS}
            ${Qt5PrintSupport_PRIVATE_INCLUDE_DIRS}
            ${QT_INCLUDES_DIR}
            ${QT_INCLUDES_DIR}/QtClipboardSupport/${Qt5_VERSION}
            ${QT_INCLUDES_DIR}/QtFontDatabaseSupport/${Qt5_VERSION}
            ${QT_INCLUDES_DIR}/QtGraphicsSupport/${Qt5_VERSION}
            ${QT_INCLUDES_DIR}/QtThemeSupport/${Qt5_VERSION}
            ${QT_INCLUDES_DIR}/QtAccessibilitySupport/${Qt5_VERSION}
            ${QT_INCLUDES_DIR}/QtFontDatabaseSupport/${Qt5_VERSION}/QtFontDatabaseSupport
            ${QT_INCLUDES_DIR}/QtCglSupport/${Qt5_VERSION}
        )
        target_link_libraries(qaltcocoa  PRIVATE
            Qt5::Core
            Qt5::Gui
            Qt5::Widgets
            Qt5::PrintSupport
            ${QT_FRAMEWORKS_DIR}/libQt5CglSupport.a
            ${QT_FRAMEWORKS_DIR}/libQt5ClipboardSupport.a
            ${QT_FRAMEWORKS_DIR}/libQt5FontDatabaseSupport.a
            ${QT_FRAMEWORKS_DIR}/libQt5GraphicsSupport.a
            ${QT_FRAMEWORKS_DIR}/libQt5ThemeSupport.a
            ${QT_FRAMEWORKS_DIR}/libQt5AccessibilitySupport.a
            -lfontconfig -lfreetype
            "-framework OpenGL -framework AGL"
            "-framework AppKit -framework Carbon -framework IOKit -lcups")
        install(TARGETS qaltcocoa DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/platforms)
    else()
        # Generate a .qmake.cache file that coerce qmake to build more like we're building ourselves
        # Don't use CMAKE_C?_FLAGS because 1) that would require testing the build type and 2) KF5
        # likes to add -fno-exceptions which can break the Qt build.
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/qmake/.qmake.cache" "QMAKE_CC=${CMAKE_C_COMPILER}\n")
        file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/qmake/.qmake.cache" "QMAKE_CXX=${CMAKE_CXX_COMPILER}\n")
        file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/qmake/.qmake.cache" "QMAKE_CFLAGS+=$ENV{CFLAGS}\n")
        file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/qmake/.qmake.cache" "QMAKE_CXXFLAGS+=$ENV{CXXFLAGS}\n")
        file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/qmake/.qmake.cache" "QMAKE_MAC_SDK=macosx${CMAKE_OSX_DEPLOYMENT_TARGET}\n")

        # ExternalProject_Add is tricky to handle the configure (qmake) step
        # and subsequent build steps esp. during incremental builds
        ExternalProject_Add(qaltcocoa_qmake
            DOWNLOAD_COMMAND ""
            SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}
            CONFIGURE_COMMAND ${QMAKE_EXECUTABLE} -r ${CMAKE_CURRENT_LIST_DIR}/qcocoa-standalone.pro
            BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/qmake
        )
        # use add_custom_target to handle (incremental) builds
        add_custom_target(qaltcocoa ALL
            DEPENDS qaltcocoa_qmake
            COMMAND ${CMAKE_MAKE_PROGRAM}
            BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltcocoa.dylib
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/qmake
        )

        install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmake/libqaltcocoa.dylib DESTINATION ${KDE_INSTALL_QTPLUGINDIR}/platforms)
    endif()
else()
    # we should only end up here if we're being built as an optional component
    message(STATUS "QAltCocoa needs a more recent Qt5 version - skipping")
endif()

if(${QAQPA_standalone})
    feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)
endif()

find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Core Widgets)
if(BUILD_QT_PLUGINS)
    find_package(Qt5 ${REQUIRED_QT_VERSION} OPTIONAL_COMPONENTS Gui PrintSupport)
endif()

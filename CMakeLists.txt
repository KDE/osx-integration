cmake_minimum_required(VERSION 3.3)

project(QAltMacStyle)

include(FeatureSummary)
find_package(ECM 5.30.0  NO_MODULE)
set_package_properties(ECM PROPERTIES TYPE REQUIRED DESCRIPTION "Extra CMake Modules." URL "https://projects.kde.org/projects/kdesupport/extra-cmake-modules")
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(GenerateExportHeader)
include(ExternalProject)
include(ECMPackageConfigHelpers)
include(ECMGenerateHeaders)

include(KDEInstallDirs)
include(KDEFrameworkCompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

set(REQUIRED_QT_VERSION 5.7.0)
find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Core Widgets Gui)


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

# execute_process(
#     COMMAND ${QMAKE_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/macstyle.pro -o 
# )

ExternalProject_Add(qaltmacstyle
    DOWNLOAD_COMMAND ""
    SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}
    CONFIGURE_COMMAND ${QMAKE_EXECUTABLE} ${CMAKE_CURRENT_LIST_DIR}/macstyle.pro
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}
)

feature_summary(WHAT ALL   FATAL_ON_MISSING_REQUIRED_PACKAGES)

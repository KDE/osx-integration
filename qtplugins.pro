TEMPLATE = subdirs

contains(QT_VERSION, ^5\\.[0-7]\\..*) {
    message("Need at least Qt 5.8.0 to build QAltCocoa and QAltMacStyle")
    error("Qt 5.8.0 or higher is required")
}

SUBDIRS += src/qcocoa-qpa/qcocoa-standalone.pro \
           src/qmacstyle/macstyle.pro

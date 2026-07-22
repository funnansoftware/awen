#include <QGuiApplication>

#include <gtest/gtest.h>

// gtest_discover_tests executes this binary at build time on headless CI, so
// default to the minimal platform before QGuiApplication picks a real one.
auto main(int argc, char** argv) -> int
{
    // Point every test's QQmlEngine at the in-project modules under the build
    // output tree: each engine reads QML_IMPORT_PATH at construction, so this
    // one line resolves `import awen.input` for all tests without per-test setup.
    qputenv("QML_IMPORT_PATH", AWEN_QML_IMPORT_DIR);

    if (!qEnvironmentVariableIsSet("QT_QPA_PLATFORM"))
    {
        qputenv("QT_QPA_PLATFORM", "minimal");
    }

    auto app = QGuiApplication{argc, argv};
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

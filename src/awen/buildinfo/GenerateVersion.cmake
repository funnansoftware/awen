# Stamp the current date into the version header. Run at configure time (via
# include) to seed the header, and again on every build (via cmake -P) to keep it
# current. configure_file rewrites the output only when its content changes, so a
# same-day rebuild leaves the header — and thus BuildInfo.cpp — untouched. A build
# setting SOURCE_DATE_EPOCH gets a reproducible stamp: string(TIMESTAMP) honours it.
string(TIMESTAMP AWEN_BUILD_VERSION "%Y.%m.%d")
configure_file("${VERSION_TEMPLATE}" "${VERSION_HEADER}" @ONLY)

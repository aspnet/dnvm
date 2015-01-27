source $COMMON_HELPERS
source $dotnetsdk

# Get a runtime to use during these tests
dotnetsdk install "$KRE_TEST_VERSION"
dotnetsdk alias default "$KRE_TEST_VERSION"
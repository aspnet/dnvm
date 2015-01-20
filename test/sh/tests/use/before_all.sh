source $COMMON_HELPERS
source $dotnetsdk

# Get a runtime to use during these tests
dotnetsdk install "$DOTNET_TEST_VERSION"
dotnetsdk alias default "$DOTNET_TEST_VERSION"
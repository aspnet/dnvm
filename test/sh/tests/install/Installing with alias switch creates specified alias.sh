source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install "$DOTNET_TEST_VERSION" -a test

[ -f "$DOTNET_USER_HOME/alias/test.alias" ] || die "test alias was not created"
[ $(cat "$DOTNET_USER_HOME/alias/test.alias") == "dotnet-mono.$DOTNET_TEST_VERSION" ] || die "test alias was not set to expected value"
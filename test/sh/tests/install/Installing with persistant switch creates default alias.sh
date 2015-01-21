source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install "$DOTNET_TEST_VERSION" -p

[ -f "$DOTNET_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$DOTNET_USER_HOME/alias/default.alias") == "dotnet-mono.$DOTNET_TEST_VERSION" ] || die "default alias was not set to expected value"
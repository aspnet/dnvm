source $COMMON_HELPERS
source $dotnetsdk

# Alias the installed runtime
dotnetsdk alias test_alias_create "$DOTNET_TEST_VERSION"

# Check the alias file
[ -f "$DOTNET_USER_HOME/alias/test_alias_create.alias" ] || die "test alias was not created"
[ $(cat "$DOTNET_USER_HOME/alias/test_alias_create.alias") == "dotnet-mono.$DOTNET_TEST_VERSION" ] || die "test alias was not set to expected value"
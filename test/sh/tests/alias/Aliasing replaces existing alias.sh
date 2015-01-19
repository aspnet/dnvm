source $COMMON_HELPERS
source $dotnetsdk

echo "woozlewuzzle" > "$DOTNET_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed runtime
dotnetsdk alias test_alias_rename "$DOTNET_TEST_VERSION"

# Check the alias file
[ -f "$DOTNET_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$DOTNET_USER_HOME/alias/test_alias_rename.alias") == "dotnet-mono.$DOTNET_TEST_VERSION" ] || die "test alias was not set to expected value"
source $COMMON_HELPERS
source $dotnetsdk

# Alias the installed runtime
dotnetsdk alias test_alias_use "$DOTNET_TEST_VERSION"

# Remove runtime from the path
dotnetsdk use none

# 'use' the alias
dotnetsdk use test_alias_use

# Check that the path now has that Runtime on it
EXPECTED_ROOT="$DOTNET_USER_HOME/runtimes/dotnet-mono.$DOTNET_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the expected path!"
[ $(path_of dotnet) == "$EXPECTED_ROOT/dotnet" ] || die "'dotnet' was not available at the expected path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the expected path!"

# Clean up the path
dotnetsdk use none
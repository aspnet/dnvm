source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install "$DOTNET_TEST_VERSION"

EXPECTED_ROOT="$DOTNET_USER_HOME/runtimes/dotnet-mono.$DOTNET_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the expected path!"
[ $(path_of dotnet) == "$EXPECTED_ROOT/dotnet" ] || die "'dotnet' was not available at the expected path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the expected path!"
source $COMMON_HELPERS
source $dotnetsdk

# Clear the path
dotnetsdk use none

# Use the installed runtime
dotnetsdk use "$KRE_TEST_VERSION"

# Check paths
EXPECTED_ROOT="$KVM_USER_HOME/runtimes/dotnet-mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the specified path!"
[ $(path_of dotnet) == "$EXPECTED_ROOT/dotnet" ] || die "'dotnet' was not available at the specified path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the specified path!"

source $COMMON_HELPERS
source $dotnetsdk

# Use a runtime
dotnetsdk use "$KRE_TEST_VERSION"

# Use none
dotnetsdk use none

# Check paths
EXPECTED_ROOT="$KVM_USER_HOME/runtimes/dotnet-mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) != "$EXPECTED_ROOT/k" ] || die "'k' was still available at the expected path!"
[ $(path_of dotnet) != "$EXPECTED_ROOT/dotnet" ] || die "'dotnet' was still available at the expected path!"
[ $(path_of kpm) != "$EXPECTED_ROOT/kpm" ] || die "'kpm' was still available at the expected path!"
source $COMMON_HELPERS
source $dotnetsdk

# Clear the path
dotnetsdk use none

# Use the installed runtime
dotnetsdk use default

# Check paths
EXPECTED_ROOT="$KRE_USER_HOME/runtimes/dotnet-mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the specified path!"
[ $(path_of klr) == "$EXPECTED_ROOT/klr" ] || die "'klr' was not available at the specified path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the specified path!"

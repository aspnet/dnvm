source $COMMON_HELPERS
source $KVM

# Clear the path
kvm use none

# Use the installed KRE
kvm use "$KRE_TEST_VERSION"

# Check paths
EXPECTED_ROOT="$KRE_USER_HOME/packages/KRE-Mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the expected path!"
[ $(path_of klr) == "$EXPECTED_ROOT/klr" ] || die "'klr' was not available at the expected path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the expected path!"
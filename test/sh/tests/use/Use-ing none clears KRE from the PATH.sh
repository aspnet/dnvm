source $COMMON_HELPERS
source $KVM

# Use a KRE
kvm use "$KRE_TEST_VERSION"

# Use none
kvm use none

# Check paths
EXPECTED_ROOT="$KRE_USER_HOME/packages/KRE-Mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) != "$EXPECTED_ROOT/k" ] || die "'k' was still available at the expected path!"
[ $(path_of klr) != "$EXPECTED_ROOT/klr" ] || die "'klr' was still available at the expected path!"
[ $(path_of kpm) != "$EXPECTED_ROOT/kpm" ] || die "'kpm' was still available at the expected path!"
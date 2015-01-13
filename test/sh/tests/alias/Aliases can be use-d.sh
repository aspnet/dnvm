source $COMMON_HELPERS
source $KVM

# Alias the installed KRE
kvm alias test_alias_use "$KRE_TEST_VERSION"

# Remove KREs from the path
kvm use none

# 'use' the alias
kvm use test_alias_use

# Check that the path now has that KRE on it
EXPECTED_ROOT="$KRE_USER_HOME/packages/KRE-Mono.$KRE_TEST_VERSION/bin"

[ $(path_of k) == "$EXPECTED_ROOT/k" ] || die "'k' was not available at the expected path!"
[ $(path_of klr) == "$EXPECTED_ROOT/klr" ] || die "'klr' was not available at the expected path!"
[ $(path_of kpm) == "$EXPECTED_ROOT/kpm" ] || die "'kpm' was not available at the expected path!"

# Clean up the path
kvm use none
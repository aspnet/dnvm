source $COMMON_HELPERS
source $KVM

# Alias the installed KRE
kvm alias test_alias_create "$KRE_TEST_VERSION"

# Check the alias file
[ -f "$KRE_USER_HOME/alias/test_alias_create.alias" ] || die "test alias was not created"
[ $(cat "$KRE_USER_HOME/alias/test_alias_create.alias") == "KRE-Mono.$KRE_TEST_VERSION" ] || die "test alias was not set to expected value"
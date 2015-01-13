source $COMMON_HELPERS
source $KVM

kvm install "$KRE_TEST_VERSION" -a test

[ -f "$KRE_USER_HOME/alias/test.alias" ] || die "test alias was not created"
[ $(cat "$KRE_USER_HOME/alias/test.alias") == "KRE-Mono.$KRE_TEST_VERSION" ] || die "test alias was not set to expected value"
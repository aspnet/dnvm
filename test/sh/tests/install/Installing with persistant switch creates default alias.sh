source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install "$KRE_TEST_VERSION" -p

[ -f "$KVM_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$KVM_USER_HOME/alias/default.alias") == "dotnet-mono.$KRE_TEST_VERSION" ] || die "default alias was not set to expected value"
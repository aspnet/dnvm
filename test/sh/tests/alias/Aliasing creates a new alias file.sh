source $COMMON_HELPERS
source $dotnetsdk

# Alias the installed runtime
dotnetsdk alias test_alias_create "$KRE_TEST_VERSION"

# Check the alias file
[ -f "$KVM_USER_HOME/alias/test_alias_create.alias" ] || die "test alias was not created"
[ $(cat "$KVM_USER_HOME/alias/test_alias_create.alias") == "dotnet-mono.$KRE_TEST_VERSION" ] || die "test alias was not set to expected value"
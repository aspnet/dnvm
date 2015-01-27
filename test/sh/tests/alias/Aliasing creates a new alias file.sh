source $COMMON_HELPERS
source $_KVM_PATH

# Alias the installed runtime
$_KVM_COMMAND_NAME alias test_alias_create "$_TEST_VERSION"

# Check the alias file
[ -f "$KVM_USER_HOME/alias/test_alias_create.alias" ] || die "test alias was not created"
[ $(cat "$KVM_USER_HOME/alias/test_alias_create.alias") == "$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"
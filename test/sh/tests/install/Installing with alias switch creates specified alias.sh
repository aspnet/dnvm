source $COMMON_HELPERS
source $_KVM_PATH

$_KVM_COMMAND_NAME install "$_TEST_VERSION" -a test

[ -f "$KVM_USER_HOME/alias/test.alias" ] || die "test alias was not created"
[ $(cat "$KVM_USER_HOME/alias/test.alias") == "$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"
source $COMMON_HELPERS
source $_KVM_PATH

$_KVM_COMMAND_NAME install "$_TEST_VERSION" -p

[ -f "$KVM_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$KVM_USER_HOME/alias/default.alias") == "$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "default alias was not set to expected value"
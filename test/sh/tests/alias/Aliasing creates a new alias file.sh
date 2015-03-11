source $COMMON_HELPERS
source $_DNVM_PATH

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_create "$_TEST_VERSION"

# Check the alias file
[ -f "$DNX_USER_HOME/alias/test_alias_create.alias" ] || die "test alias was not created"
[ $(cat "$DNX_USER_HOME/alias/test_alias_create.alias") = "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"

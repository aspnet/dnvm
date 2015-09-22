source $COMMON_HELPERS
source $_DNVM_PATH

RUNTIME_PATH="$DNX_USER_HOME/runtimes/$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION"

$_DNVM_COMMAND_NAME install $_TEST_VERSION

touch "$RUNTIME_PATH/testFile"

$_DNVM_COMMAND_NAME install "$_TEST_VERSION" -f

[ ! -f "$RUNTIME_PATH/testFile" ] || die "Test file still exists in runtime path."
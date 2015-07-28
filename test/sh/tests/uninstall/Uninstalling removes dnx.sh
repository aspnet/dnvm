source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME install $_TEST_VERSION

[ -d $DNX_USER_HOME/runtimes/dnx-mono.$_TEST_VERSION ] || die "Nothing to uninstall"
OUTPUT=$($_DNVM_COMMAND_NAME uninstall $_TEST_VERSION)
[ -d $DNX_USER_HOME/runtimes/dnx-mono.$_TEST_VERSION ] && die "Uninstall didn't remove runtime"
echo $OUTPUT | grep "Removed $DNX_USER_HOME/runtimes/dnx-mono.$_TEST_VERSION" || die "expected message was not reported"

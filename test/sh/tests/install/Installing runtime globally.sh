source $COMMON_HELPERS
source $_DNVM_PATH

mv $DNX_USER_HOME/runtimes $DNX_USER_HOME/runtimes_backup
mv $DNX_GLOBAL_HOME/runtimes $DNX_GLOBAL_HOME/runtimes_backup

OUTPUT=$($_DNVM_COMMAND_NAME install $_TEST_VERSION -g -y)
echo $OUTPUT | grep -E "Installing to $DNX_GLOBAL_HOME/runtimes/dnx-mono.$_TEST_VERSION" || die "expected message was not reported"

rm -rf $DNX_GLOBAL_HOME/runtimes
mv $DNX_GLOBAL_HOME/runtimes_backup $DNX_GLOBAL_HOME/runtimes
mv $DNX_USER_HOME/runtimes_backup $DNX_USER_HOME/runtimes

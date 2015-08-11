source $COMMON_HELPERS
source $_DNVM_PATH

mv $DNX_USER_HOME/runtimes $DNX_USER_HOME/runtimes_backup
mv $DNX_GLOBAL_HOME/runtimes $DNX_GLOBAL_HOME/runtimes_backup

$_DNVM_COMMAND_NAME install $_TEST_VERSION

OUTPUT=$($_DNVM_COMMAND_NAME install $_TEST_VERSION -g)
echo $OUTPUT | grep -E "\salready installed in $DNX_USER_HOME" || die "expected message was not reported"

rm -Rf $DNX_USER_HOME/runtimes
mv $DNX_USER_HOME/runtimes_backup $DNX_USER_HOME/runtimes
mv $DNX_GLOBAL_HOME/runtimes_backup $DNX_GLOBAL_HOME/runtimes

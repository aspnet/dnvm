source $COMMON_HELPERS
source $_DNVM_PATH

# Clean all runtimes (temporarily)
mv $DNX_USER_HOME/runtimes $DNX_USER_HOME/runtimes_backup
mkdir -p $DNX_USER_HOME/runtimes

# List runtimes
OUTPUT=$($_DNVM_COMMAND_NAME list || die "failed at listing runtimes")
echo $OUTPUT | grep "^No runtimes installed" || die "expected message was not reported"

# Restore runtimes
rm -Rf $DNX_USER_HOME/runtimes
mv $DNX_USER_HOME/runtimes_backup $DNX_USER_HOME/runtimes
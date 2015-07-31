source $COMMON_HELPERS
source $_DNVM_PATH

# Clean all runtimes
rm -Rf $DNX_USER_HOME/runtimes/$_DNVM_RUNTIME_PACKAGE_NAME-*

# List runtimes
OUTPUT=$($_DNVM_COMMAND_NAME list || die "failed at listing runtimes")
echo $OUTPUT | grep "^No runtimes installed" || die "expected message was not reported"

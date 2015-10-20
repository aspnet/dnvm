source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME help

[ "$?" == "0" ] || die "expected exit code was not returned"
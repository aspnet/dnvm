source $COMMON_HELPERS

source $_DNVM_PATH || die "$_DNVM_COMMAND_NAME sourcing failed"

MATCHES=$(echo $PATH | grep -c "$DNX_USER_HOME/bin")
[[ $MATCHES -eq 1 ]] || die "sourcing $_DNVM_COMMAND_NAME did not put expected value on PATH: $DNX_USER_HOME/bin"

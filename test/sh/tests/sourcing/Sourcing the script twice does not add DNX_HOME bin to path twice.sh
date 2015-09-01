source $COMMON_HELPERS

source $_DNVM_PATH || die "$_DNVM_COMMAND_NAME sourcing failed"
source $_DNVM_PATH || die "$_DNVM_COMMAND_NAME sourcing failed"

MATCHES=$(echo $PATH | tr ":" "\n" | grep -c "$DNX_USER_HOME/bin")
[[ $MATCHES -eq 1 ]] || die "sourcing $_DNVM_COMMAND_NAME twice did put '$DNX_USER_HOME/bin' on PATH $MATCHES times"

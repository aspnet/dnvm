source $COMMON_HELPERS

source $_DNVM_PATH || die "$_DNVM_COMMAND_NAME sourcing failed"
has $_DNVM_COMMAND_NAME || die "$_DNVM_COMMAND_NAME command not found!"

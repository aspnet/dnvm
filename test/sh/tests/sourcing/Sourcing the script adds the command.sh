source $COMMON_HELPERS

source $_KVM_PATH || die "$_KVM_COMMAND_NAME sourcing failed"
has $_KVM_COMMAND_NAME || die "$_KVM_COMMAND_NAME command not found!"
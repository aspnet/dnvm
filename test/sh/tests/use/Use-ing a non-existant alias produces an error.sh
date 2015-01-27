source $COMMON_HELPERS
source $_KVM_PATH

if $_KVM_COMMAND_NAME use bogus_alias; then
	die "$_KVM_COMMAND_NAME didn't fail to use bogus alias"
fi
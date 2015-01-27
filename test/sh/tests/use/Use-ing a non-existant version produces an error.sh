source $COMMON_HELPERS
source $_KVM_PATH

if $_KVM_COMMAND_NAME use 0.1.0-not-real; then
	die "$_KVM_COMMAND_NAME didn't fail to use bogus runtime version"
fi
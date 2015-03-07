source $COMMON_HELPERS
source $_DNVM_PATH

if $_DNVM_COMMAND_NAME use bogus_alias; then
	die "$_DNVM_COMMAND_NAME didn't fail to use bogus alias"
fi

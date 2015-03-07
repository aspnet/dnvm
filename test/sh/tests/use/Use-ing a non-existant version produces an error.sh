source $COMMON_HELPERS
source $_DNVM_PATH

if $_DNVM_COMMAND_NAME use 0.1.0-not-real; then
	die "$_DNVM_COMMAND_NAME didn't fail to use bogus runtime version"
fi

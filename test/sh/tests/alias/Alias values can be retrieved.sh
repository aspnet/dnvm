source $COMMON_HELPERS
source $_DNVM_PATH

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_get "$_TEST_VERSION"

# Try to read it
[ $($_DNVM_COMMAND_NAME alias test_alias_get) = "$_NUPKG_NAME" ] || die "alias value was not the expected value"

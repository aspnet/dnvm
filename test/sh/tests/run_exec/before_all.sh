source $COMMON_HELPERS
source $_DNVM_PATH

# Get a runtime to use during these tests
$_DNVM_COMMAND_NAME install "$_TEST_VERSION"
$_DNVM_COMMAND_NAME alias default "$_TEST_VERSION"

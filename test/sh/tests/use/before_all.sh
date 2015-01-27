source $COMMON_HELPERS
source $_KVM_PATH

# Get a runtime to use during these tests
$_KVM_COMMAND_NAME install "$_TEST_VERSION"
$_KVM_COMMAND_NAME alias default "$_TEST_VERSION"
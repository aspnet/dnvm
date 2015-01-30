source $COMMON_HELPERS
source $_KVM_PATH

# Use a runtime
$_KVM_COMMAND_NAME use "$_TEST_VERSION"

# Use none
$_KVM_COMMAND_NAME use none

# Check paths
EXPECTED_ROOT="$KVM_USER_HOME/runtimes/$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION/bin"

[ "$(path_of $_KVM_RUNTIME_EXEC_NAME)" != "$EXPECTED_ROOT/$_KVM_RUNTIME_EXEC_NAME" ] || die "'$_KVM_RUNTIME_EXEC_NAME' was still available at the expected path!"
[ "$(path_of $_KVM_RUNTIME_HOST_NAME)" != "$EXPECTED_ROOT/$_KVM_RUNTIME_HOST_NAME" ] || die "'$_KVM_RUNTIME_HOST_NAME' was still available at the expected path!"
[ "$(path_of $_KVM_PACKAGE_MANAGER_NAME)" != "$EXPECTED_ROOT/$_KVM_PACKAGE_MANAGER_NAME" ] || die "'$_KVM_PACKAGE_MANAGER_NAME' was still available at the expected path!"
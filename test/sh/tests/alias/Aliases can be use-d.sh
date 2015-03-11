source $COMMON_HELPERS
source $_DNVM_PATH

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_use "$_TEST_VERSION"

# Remove runtime from the path
$_DNVM_COMMAND_NAME use none

# 'use' the alias
$_DNVM_COMMAND_NAME use test_alias_use

# Check that the path now has that Runtime on it
EXPECTED_ROOT="$DNX_USER_HOME/runtimes/$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION/bin"
echo "Expect runtime at $EXPECTED_ROOT"
echo "Actual at $(path_of $_DNVM_RUNTIME_EXEC_NAME)"
[ "$(path_of $_DNVM_RUNTIME_EXEC_NAME)" = "$EXPECTED_ROOT/$_DNVM_RUNTIME_EXEC_NAME" ] || die "'$_DNVM_RUNTIME_EXEC_NAME' was not available at the expected path!"
[ "$(path_of $_DNVM_RUNTIME_HOST_NAME)" = "$EXPECTED_ROOT/$_DNVM_RUNTIME_HOST_NAME" ] || die "'$_DNVM_RUNTIME_HOST_NAME' was not available at the expected path!"
[ "$(path_of $_DNVM_PACKAGE_MANAGER_NAME)" = "$EXPECTED_ROOT/$_DNVM_PACKAGE_MANAGER_NAME" ] || die "'$_DNVM_PACKAGE_MANAGER_NAME' was not available at the expected path!"

# Clean up the path
$_DNVM_COMMAND_NAME use none

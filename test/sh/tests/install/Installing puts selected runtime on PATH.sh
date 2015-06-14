#!/usr/bin/env bash
source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME install "$_TEST_VERSION"

EXPECTED_ROOT="$DNX_USER_HOME/runtimes/$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION/bin"

[ $(path_of $_DNVM_RUNTIME_HOST_NAME) = "$EXPECTED_ROOT/$_DNVM_RUNTIME_HOST_NAME" ] || die "'$_DNVM_RUNTIME_HOST_NAME' was not available at the expected path!"
[ $(path_of $_DNVM_PACKAGE_MANAGER_NAME) = "$EXPECTED_ROOT/$_DNVM_PACKAGE_MANAGER_NAME" ] || die "'$_DNVM_PACKAGE_MANAGER_NAME' was not available at the expected path!"

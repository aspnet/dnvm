#!/usr/bin/env bash
source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME install $_TEST_VERSION

# Resolve the name of the runtime directory
RUNTIME_PATH="$DNX_USER_HOME/runtimes/$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION"

[ -f "$RUNTIME_PATH/bin/$_DNVM_RUNTIME_HOST_NAME" ] || die "$_DNVM_COMMAND_NAME did not include '$_DNVM_RUNTIME_HOST_NAME' command!"
[ -f "$RUNTIME_PATH/bin/$_DNVM_PACKAGE_MANAGER_NAME" ] || die "$_DNVM_COMMAND_NAME did not include '$_DNVM_PACKAGE_MANAGER_NAME' command!"

[ ! -f "$DNX_USER_HOME/alias/default.alias" ] || die "default alias was created despite not setting --persistant"

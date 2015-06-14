#!/usr/bin/env bash
source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME install "$_TEST_VERSION" -p

[ -f "$DNX_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$DNX_USER_HOME/alias/default.alias") = "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "default alias was not set to expected value"

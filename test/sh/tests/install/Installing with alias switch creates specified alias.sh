#!/usr/bin/env bash
source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME install "$_TEST_VERSION" -a test

[ -f "$DNX_USER_HOME/alias/test.alias" ] || die "test alias was not created"
[ $(cat "$DNX_USER_HOME/alias/test.alias") = "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"

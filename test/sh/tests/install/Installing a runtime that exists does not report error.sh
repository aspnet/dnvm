#!/usr/bin/env bash
source $COMMON_HELPERS
source $_DNVM_PATH

# Install a runtime
$_DNVM_COMMAND_NAME install "$_TEST_VERSION" || die "failed initial install of runtime"

# Install it again and ensure it reports the message we expect
OUTPUT=$($_DNVM_COMMAND_NAME install "$_TEST_VERSION" || die "failed second attempt at installing runtime")
echo $OUTPUT | grep "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION already installed" || die "expected message was not reported"

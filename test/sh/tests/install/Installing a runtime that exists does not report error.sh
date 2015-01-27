source $COMMON_HELPERS
source $_KVM_PATH

# Install a runtime
$_KVM_COMMAND_NAME install "$_TEST_VERSION" || die "failed initial install of runtime"

# Install it again and ensure it reports the message we expect
OUTPUT=$($_KVM_COMMAND_NAME install "$_TEST_VERSION" || die "failed second attempt at installing runtime")
echo $OUTPUT | grep "$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION already installed" || die "expected message was not reported"
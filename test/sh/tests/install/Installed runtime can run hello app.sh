# Simple smoke test for the runtime fetched by $_KVM_COMMAND_NAME. To help ensure that it is unpacked correctly and such

source $COMMON_HELPERS
source $_KVM_PATH

# Get a runtime to use during these tests
$_KVM_COMMAND_NAME install latest

# Test the runtime
has $_KVM_RUNTIME_EXEC_NAME || die "$_KVM_RUNTIME_EXEC_NAME didn't install the runtime :("
has $_KVM_PACKAGE_MANAGER_NAME || die "installed runtime didn't have a package manager?"

pushd "$TEST_APPS_DIR/TestApp"
$_KVM_PACKAGE_MANAGER_NAME restore || die "failed to restore packages"
OUTPUT=$($_KVM_RUNTIME_EXEC_NAME run || die "failed to run hello application")
echo $OUTPUT | grep 'Runtime is sane!' || die "unexpected output from sample app: $OUTPUT"
popd
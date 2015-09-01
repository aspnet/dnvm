source $COMMON_HELPERS
source $_DNVM_PATH

$_DNVM_COMMAND_NAME alias test_alias_runexec $_TEST_VERSION
$_DNVM_COMMAND_NAME use none

pushd "$TEST_APPS_DIR/TestApp"
$_DNVM_COMMAND_NAME exec test_alias_runexec $_DNVM_PACKAGE_MANAGER_NAME restore || die "failed to restore packages"
OUTPUT=$($_DNVM_COMMAND_NAME run test_alias_runexec run || die "failed to run hello application")
echo $OUTPUT | grep 'Runtime is sane!' || die "unexpected output from sample app: $OUTPUT"
popd

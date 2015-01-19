# Simple smoke test for the runtime fetched by dotnetsdk. To help ensure that it is unpacked correctly and such

source $COMMON_HELPERS
source $dotnetsdk

# Get a runtime to use during these tests
dotnetsdk install latest

# Test the runtime
has k || die "dotnetsdk didn't install K :("
has kpm || die "installed k didn't have kpm?"

pushd "$TEST_APPS_DIR/HelloK"
kpm restore || die "failed to restore packages"
OUTPUT=$(k run || die "failed to run hello application")
echo $OUTPUT | grep 'Runtime is sane!' || die "unexpected output from sample app: $OUTPUT"
popd
# Simple smoke test for the kre fetched by kvm. To help ensure that it is unpacked correctly and such

source $COMMON_HELPERS
source $KVM

# Get a KRE to use during these tests
kvm install latest

# Test the KRE
has k || die "kvm didn't install K :("
has kpm || die "installed k didn't have kpm?"

pushd "$TEST_APPS_DIR/HelloK"
kpm restore || die "failed to restore packages"
OUTPUT=$(k run || die "failed to run hello application")
echo $OUTPUT | grep 'K is sane!' || die "unexpected output from sample app: $OUTPUT"
popd
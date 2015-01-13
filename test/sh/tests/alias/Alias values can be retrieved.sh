source $COMMON_HELPERS
source $KVM

# Alias the installed KRE
kvm alias test_alias_get "$KRE_TEST_VERSION"

# Try to read it
[ $(kvm alias test_alias_get) = "$KRE_NUPKG_NAME" ] || die "alias value was not the expected value"
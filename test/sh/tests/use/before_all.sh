source $COMMON_HELPERS
source $KVM

# Get a KRE to use during these tests
kvm install "$KRE_TEST_VERSION"
kvm alias default "$KRE_TEST_VERSION"
source $COMMON_HELPERS

source $KVM || die "kvm sourcing failed"
has kvm || die "kvm command not found!"
source $COMMON_HELPERS
source $KVM

# Install a KRE
kvm install 1.0.0-beta1 || die "failed initial install of KRE"

# Install it again and ensure it reports the message we expect
OUTPUT=$(kvm install 1.0.0-beta1 || die "failed second attempt at installing KRE")
echo $OUTPUT | grep 'KRE-Mono.1.0.0-beta1 already installed' || die "expected message was not reported"
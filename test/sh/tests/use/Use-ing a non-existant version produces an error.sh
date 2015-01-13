source $COMMON_HELPERS
source $KVM

# Use the installed KRE
if kvm use 0.1.0-not-real; then
	die "kvm didn't fail to use bogus kre version"
fi
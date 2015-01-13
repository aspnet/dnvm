source $COMMON_HELPERS
source $KVM

# Use the installed KRE
if kvm use bogus_kre; then
	die "kvm didn't fail to use bogus kre alias"
fi
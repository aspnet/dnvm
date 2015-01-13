source $COMMON_HELPERS
source $KVM

# Install the nupkg
kvm install $KRE_NUPKG_FILE

[ -d "$KRE_USER_HOME/packages/$KRE_NUPKG_NAME" ] || die "unable to find installed KRE"

pushd "$KRE_USER_HOME/packages/$KRE_NUPKG_NAME" 2>/dev/null 1>/dev/null
[ -f bin/k ] || die "KRE did not include 'k' command!"
[ -f bin/klr ] || die "KRE did not include 'klr' command!"
[ -f bin/kpm ] || die "KRE did not include 'kpm' command!"
popd 2>/dev/null 1>/dev/null
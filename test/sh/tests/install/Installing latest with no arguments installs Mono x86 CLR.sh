source $COMMON_HELPERS
source $KVM

kvm install latest

ls $KRE_USER_HOME/packages/KRE-Mono.* 2>/dev/null 1>/dev/null || die "unable to find installed KRE"

pushd $KRE_USER_HOME/packages/KRE-Mono.* 2>/dev/null 1>/dev/null
[ -f bin/k ] || die "KRE did not include 'k' command!"
[ -f bin/klr ] || die "KRE did not include 'klr' command!"
[ -f bin/kpm ] || die "KRE did not include 'kpm' command!"
popd 2>/dev/null 1>/dev/null

[ ! -f "$KRE_USER_HOME/alias/default.alias" ] || die "default alias was created despite not setting --persistant"
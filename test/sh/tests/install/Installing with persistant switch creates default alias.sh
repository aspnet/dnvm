source $COMMON_HELPERS
source $KVM

kvm install 1.0.0-beta1 -p

[ -f "$KRE_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$KRE_USER_HOME/alias/default.alias") == "KRE-Mono.1.0.0-beta1" ] || die "default alias was not set to expected value"
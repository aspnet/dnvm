source $COMMON_HELPERS
source $KVM

kvm install 1.0.0-beta1 -a test

[ -f "$KRE_USER_HOME/alias/test.alias" ] || die "test alias was not created"
[ $(cat "$KRE_USER_HOME/alias/test.alias") == "KRE-Mono.1.0.0-beta1" ] || die "test alias was not set to expected value"
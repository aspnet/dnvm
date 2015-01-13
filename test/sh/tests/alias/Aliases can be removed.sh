source $COMMON_HELPERS
source $KVM

# Alias the installed KRE
kvm alias test_alias_unalias "$KRE_TEST_VERSION"

# Unalias it
kvm unalias test_alias_unalias

# Check the alias file
[ ! -e "$KRE_USER_HOME/alias/test_alias_unalias.alias" ] || die "test alias was not removed"
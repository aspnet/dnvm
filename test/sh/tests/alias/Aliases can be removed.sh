source $COMMON_HELPERS
source $dotnetsdk

# Alias the installed runtime
dotnetsdk alias test_alias_unalias "$KRE_TEST_VERSION"

# Unalias it
dotnetsdk unalias test_alias_unalias

# Check the alias file
[ ! -e "$KVM_USER_HOME/alias/test_alias_unalias.alias" ] || die "test alias was not removed"
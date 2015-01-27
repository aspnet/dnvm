source $COMMON_HELPERS
source $_KVM_PATH

# Alias the installed runtime
$_KVM_COMMAND_NAME alias test_alias_unalias "$_TEST_VERSION"

# Unalias it
$_KVM_COMMAND_NAME unalias test_alias_unalias

# Check the alias file
[ ! -e "$KVM_USER_HOME/alias/test_alias_unalias.alias" ] || die "test alias was not removed"
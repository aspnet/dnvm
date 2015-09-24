source $COMMON_HELPERS
source $_DNVM_PATH

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_unalias "$_TEST_VERSION"

# Unalias it
$_DNVM_COMMAND_NAME alias -d test_alias_unalias

# Check the alias file
[ ! -e "$DNX_USER_HOME/alias/test_alias_unalias.alias" ] || die "test alias was not removed"

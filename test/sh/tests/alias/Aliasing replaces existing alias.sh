source $COMMON_HELPERS
source $_KVM_PATH

echo "woozlewuzzle" > "$KVM_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed runtime
$_KVM_COMMAND_NAME alias test_alias_rename "$_TEST_VERSION"

# Check the alias file
[ -f "$KVM_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$KVM_USER_HOME/alias/test_alias_rename.alias") == "$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"
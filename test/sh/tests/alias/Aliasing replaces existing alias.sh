source $COMMON_HELPERS
source $_DNVM_PATH

echo "woozlewuzzle" > "$DNVM_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_rename "$_TEST_VERSION"

# Check the alias file
[ -f "$DNVM_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$DNVM_USER_HOME/alias/test_alias_rename.alias") = "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"

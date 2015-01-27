source $COMMON_HELPERS
source $dotnetsdk

echo "woozlewuzzle" > "$KVM_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed runtime
dotnetsdk alias test_alias_rename "$KRE_TEST_VERSION"

# Check the alias file
[ -f "$KVM_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$KVM_USER_HOME/alias/test_alias_rename.alias") == "dotnet-mono.$KRE_TEST_VERSION" ] || die "test alias was not set to expected value"
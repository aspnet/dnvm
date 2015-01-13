source $COMMON_HELPERS
source $KVM

echo "woozlewuzzle" > "$KRE_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed KRE
kvm alias test_alias_rename "$KRE_TEST_VERSION"

# Check the alias file
[ -f "$KRE_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$KRE_USER_HOME/alias/test_alias_rename.alias") == "KRE-Mono.$KRE_TEST_VERSION" ] || die "test alias was not set to expected value"
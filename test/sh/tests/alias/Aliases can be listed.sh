source $COMMON_HELPERS
source $KVM

# Make some aliases
kvm alias test_alias_list_0 "$KRE_TEST_VERSION"
kvm alias test_alias_list_1 "$KRE_TEST_VERSION"
kvm alias test_alias_list_2 "$KRE_TEST_VERSION"
kvm alias test_alias_list_3 "$KRE_TEST_VERSION"

# Read them
LIST=$(kvm alias)

# Check the output
ESCAPED_VER=$(echo $KRE_TEST_VERSION | sed 's,\.,\\.,g')
echo $ESCAPED_VER

echo $LIST | grep -E "test_alias_list_0\s+KRE-Mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_1\s+KRE-Mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_2\s+KRE-Mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_3\s+KRE-Mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
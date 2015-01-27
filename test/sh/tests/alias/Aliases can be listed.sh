source $COMMON_HELPERS
source $_KVM_PATH

# Make some aliases
$_KVM_COMMAND_NAME alias test_alias_list_0 "$_TEST_VERSION"
$_KVM_COMMAND_NAME alias test_alias_list_1 "$_TEST_VERSION"
$_KVM_COMMAND_NAME alias test_alias_list_2 "$_TEST_VERSION"
$_KVM_COMMAND_NAME alias test_alias_list_3 "$_TEST_VERSION"

# Read them
LIST=$($_KVM_COMMAND_NAME alias)

# Check the output
ESCAPED_VER=$(echo $_TEST_VERSION | sed 's,\.,\\.,g')

echo $LIST | grep -E "test_alias_list_0\s+$_KVM_RUNTIME_PACKAGE_NAME-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_1\s+$_KVM_RUNTIME_PACKAGE_NAME-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_2\s+$_KVM_RUNTIME_PACKAGE_NAME-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_3\s+$_KVM_RUNTIME_PACKAGE_NAME-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
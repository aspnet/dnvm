source $COMMON_HELPERS
source $dotnetsdk

# Make some aliases
dotnetsdk alias test_alias_list_0 "$DOTNET_TEST_VERSION"
dotnetsdk alias test_alias_list_1 "$DOTNET_TEST_VERSION"
dotnetsdk alias test_alias_list_2 "$DOTNET_TEST_VERSION"
dotnetsdk alias test_alias_list_3 "$DOTNET_TEST_VERSION"

# Read them
LIST=$(dotnetsdk alias)

# Check the output
ESCAPED_VER=$(echo $DOTNET_TEST_VERSION | sed 's,\.,\\.,g')

echo $LIST | grep -E "test_alias_list_0\s+dotnet-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_1\s+dotnet-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_2\s+dotnet-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
echo $LIST | grep -E "test_alias_list_3\s+dotnet-mono\.$ESCAPED_VER" || die 'list did not include expected aliases'
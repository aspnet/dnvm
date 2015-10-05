source $COMMON_HELPERS
source $_DNVM_PATH

DUMMY_RUNTIME="coreclr"
DUMMY_OS="linux"
DUMMY_ARCH="x64"
DUMMY_VERSION="1.0.0-beta7"
DUMMY_PACKAGE="$_DNVM_RUNTIME_PACKAGE_NAME-$DUMMY_RUNTIME-$DUMMY_OS-$DUMMY_ARCH.$DUMMY_VERSION"

# Create dummy dir for testing if not exists
if [ ! -d "$DNX_USER_HOME/runtimes/$DUMMY_PACKAGE/bin" ]; then
    mkdir -p "$DNX_USER_HOME/runtimes/$DUMMY_PACKAGE/bin" > /dev/null
    CREATED="true"
fi

# Make the alias
$_DNVM_COMMAND_NAME alias not_case_sensitive "$DUMMY_VERSION" -r CoreCLR -OS Linux -a X64 || die 'could not create alias'

# Read them
LIST=$($_DNVM_COMMAND_NAME alias)

# Check the output
ESCAPED_DUMMY_PACKAGE=$(echo $DUMMY_PACKAGE | sed 's,\.,\\.,g')

echo $LIST | grep -E "not_case_sensitive\s+$ESCAPED_DUMMY_PACKAGE" || die 'list did not include expected alias'

# Cleanup of dummy package
[[ "$CREATED" == "true" ]] && rm -rf "$DNX_USER_HOME/runtimes/$DUMMY_PACKAGE"
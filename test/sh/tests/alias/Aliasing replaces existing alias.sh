source $COMMON_HELPERS
source $_DNVM_PATH

# Check which shell currently executing
if [ -n "$ZSH_VERSION" ]; then
    # assume Zsh
    setopt noclobber
elif [ -n "$BASH_VERSION" ]; then
    # assume Bash
    set -o noclobber
fi

echo "woozlewuzzle" > "$DNX_USER_HOME/alias/test_alias_rename.alias"

# Alias the installed runtime
$_DNVM_COMMAND_NAME alias test_alias_rename "$_TEST_VERSION"

# Check the alias file
[ -f "$DNX_USER_HOME/alias/test_alias_rename.alias" ] || die "test alias was removed"
[ $(cat "$DNX_USER_HOME/alias/test_alias_rename.alias") = "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION" ] || die "test alias was not set to expected value"

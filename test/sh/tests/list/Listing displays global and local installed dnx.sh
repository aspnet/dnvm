source $COMMON_HELPERS
source $_DNVM_PATH

# Clean all runtime (temporarily)
mv $DNX_USER_HOME/runtimes $DNX_USER_HOME/runtimes_backup
mv $DNX_GLOBAL_HOME/runtimes $DNX_GLOBAL_HOME/runtimes_backup
mv $DNX_USER_HOME/alias $DNX_USER_HOME/alias_backup

# Install runtimes
$_DNVM_COMMAND_NAME install "$_TEST_VERSION"
$_DNVM_COMMAND_NAME install "$_TEST_VERSION" -r coreclr -g
echo $($_DNVM_COMMAND_NAME list -detailed)
# List runtimes
OUTPUT=$($_DNVM_COMMAND_NAME list -detailed || die "failed at listing runtimes")
OS="$(__dnvm_current_os)"

echo $OUTPUT | grep -E "\s+$_TEST_VERSION\s+mono\s+linux/osx\s+$(echo $DNX_USER_HOME | sed s=$HOME=~=g)/runtimes" || die "expected message was not reported"
echo $OUTPUT | grep -E "\s+$_TEST_VERSION\s+coreclr\s+x64\s+$OS\s+$(echo $DNX_GLOBAL_HOME | sed s=$HOME=~=g)/runtimes" || die "expected message was not reported"

rm -rf $DNX_GLOBAL_HOME/runtimes
rm -rf $DNX_USER_HOME/runtimes
mv $DNX_USER_HOME/runtimes_backup $DNX_USER_HOME/runtimes
mv $DNX_GLOBAL_HOME/runtimes_backup $DNX_GLOBAL_HOME/runtimes
mv $DNX_USER_HOME/alias_backup $DNX_USER_HOME/alias

source $COMMON_HELPERS
source $_DNVM_PATH

# Install the nupkg
$_DNVM_COMMAND_NAME install $_NUPKG_FILE

[ -d "$DNX_USER_HOME/runtimes/$_NUPKG_NAME" ] || die "unable to find installed runtime"

pushd "$DNX_USER_HOME/runtimes/$_NUPKG_NAME" 2>/dev/null 1>/dev/null
[ -f bin/$_DNVM_RUNTIME_EXEC_NAME ] || die "$_DNVM_COMMAND_NAME did not include '$_DNVM_RUNTIME_EXEC_NAME' command!"
[ -f bin/$_DNVM_RUNTIME_HOST_NAME ] || die "$_DNVM_COMMAND_NAME did not include '$_DNVM_RUNTIME_HOST_NAME' command!"
[ -f bin/$_DNVM_PACKAGE_MANAGER_NAME ] || die "$_DNVM_COMMAND_NAME did not include '$_DNVM_PACKAGE_MANAGER_NAME' command!"
popd 2>/dev/null 1>/dev/null

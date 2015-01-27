source $COMMON_HELPERS
source $_KVM_PATH

# Install the nupkg
$_KVM_COMMAND_NAME install $_NUPKG_FILE

[ -d "$KVM_USER_HOME/runtimes/$_NUPKG_NAME" ] || die "unable to find installed runtime"

pushd "$KVM_USER_HOME/runtimes/$_NUPKG_NAME" 2>/dev/null 1>/dev/null
[ -f bin/$_KVM_RUNTIME_EXEC_NAME ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_RUNTIME_EXEC_NAME' command!"
[ -f bin/$_KVM_RUNTIME_HOST_NAME ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_RUNTIME_HOST_NAME' command!"
[ -f bin/$_KVM_PACKAGE_MANAGER_NAME ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_PACKAGE_MANAGER_NAME' command!"
popd 2>/dev/null 1>/dev/null
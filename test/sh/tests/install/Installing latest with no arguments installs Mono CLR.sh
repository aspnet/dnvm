source $COMMON_HELPERS
source $_KVM_PATH

$_KVM_COMMAND_NAME install $_TEST_VERSION

# Resolve the name of the runtime directory
RUNTIME_PATH="$KVM_USER_HOME/runtimes/$_KVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION"

[ -f "$RUNTIME_PATH/bin/$_KVM_RUNTIME_EXEC_NAME" ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_RUNTIME_EXEC_NAME' command!"
[ -f "$RUNTIME_PATH/bin/$_KVM_RUNTIME_HOST_NAME" ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_RUNTIME_HOST_NAME' command!"
[ -f "$RUNTIME_PATH/bin/$_KVM_PACKAGE_MANAGER_NAME" ] || die "$_KVM_COMMAND_NAME did not include '$_KVM_PACKAGE_MANAGER_NAME' command!"

[ ! -f "$KVM_USER_HOME/alias/default.alias" ] || die "default alias was created despite not setting --persistant"
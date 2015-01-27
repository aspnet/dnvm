source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install $KRE_TEST_VERSION

# Resolve the name of the runtime directory
RUNTIME_PATH="$KVM_USER_HOME/runtimes/dotnet-mono.$KRE_TEST_VERSION"

[ -f "$RUNTIME_PATH/bin/k" ] || die "dotnetsdk did not include 'k' command!"
[ -f "$RUNTIME_PATH/bin/dotnet" ] || die "dotnetsdk did not include 'dotnet' command!"
[ -f "$RUNTIME_PATH/bin/kpm" ] || die "dotnetsdk did not include 'kpm' command!"

[ ! -f "$KVM_USER_HOME/alias/default.alias" ] || die "default alias was created despite not setting --persistant"
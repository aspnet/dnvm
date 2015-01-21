source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install latest

ls $DOTNET_USER_HOME/runtimes/dotnet-mono.* 2>/dev/null 1>/dev/null || die "unable to find installed runtime"

pushd $DOTNET_USER_HOME/runtimes/dotnet-mono.* 2>/dev/null 1>/dev/null
[ -f bin/k ] || die "dotnetsdk did not include 'k' command!"
[ -f bin/dotnet ] || die "dotnetsdk did not include 'dotnet' command!"
[ -f bin/kpm ] || die "dotnetsdk did not include 'kpm' command!"
popd 2>/dev/null 1>/dev/null

[ ! -f "$DOTNET_USER_HOME/alias/default.alias" ] || die "default alias was created despite not setting --persistant"
source $COMMON_HELPERS
source $dotnetsdk

# Install the nupkg
dotnetsdk install $DOTNET_NUPKG_FILE

[ -d "$DOTNET_USER_HOME/packages/$DOTNET_NUPKG_NAME" ] || die "unable to find installed runtime"

pushd "$DOTNET_USER_HOME/packages/$DOTNET_NUPKG_NAME" 2>/dev/null 1>/dev/null
[ -f bin/k ] || die "dotnetsdk did not include 'k' command!"
[ -f bin/klr ] || die "dotnetsdk did not include 'klr' command!"
[ -f bin/kpm ] || die "dotnetsdk did not include 'kpm' command!"
popd 2>/dev/null 1>/dev/null
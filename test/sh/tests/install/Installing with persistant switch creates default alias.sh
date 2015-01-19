source $COMMON_HELPERS
source $dotnetsdk

dotnetsdk install 1.0.0-beta1 -p

[ -f "$DOTNET_USER_HOME/alias/default.alias" ] || die "default alias was not created"
[ $(cat "$DOTNET_USER_HOME/alias/default.alias") == "dotnet-mono.1.0.0-beta1" ] || die "default alias was not set to expected value"
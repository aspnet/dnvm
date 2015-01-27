source $COMMON_HELPERS
source $dotnetsdk

# Alias the installed runtime
dotnetsdk alias test_alias_get "$KRE_TEST_VERSION"

# Try to read it
[ $(dotnetsdk alias test_alias_get) = "$DOTNET_NUPKG_NAME" ] || die "alias value was not the expected value"
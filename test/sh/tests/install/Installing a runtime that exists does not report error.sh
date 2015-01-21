source $COMMON_HELPERS
source $dotnetsdk

# Install a runtime
dotnetsdk install "$DOTNET_TEST_VERSION" || die "failed initial install of runtime"

# Install it again and ensure it reports the message we expect
OUTPUT=$(dotnetsdk install "$DOTNET_TEST_VERSION" || die "failed second attempt at installing runtime")
echo $OUTPUT | grep "dotnet-mono.$DOTNET_TEST_VERSION already installed" || die "expected message was not reported"
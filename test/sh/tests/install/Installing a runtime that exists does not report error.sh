source $COMMON_HELPERS
source $dotnetsdk

# Install a runtime
dotnetsdk install 1.0.0-beta1 || die "failed initial install of runtime"

# Install it again and ensure it reports the message we expect
OUTPUT=$(dotnetsdk install 1.0.0-beta1 || die "failed second attempt at installing runtime")
echo $OUTPUT | grep 'dotnet-mono.1.0.0-beta1 already installed' || die "expected message was not reported"
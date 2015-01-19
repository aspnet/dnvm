source $COMMON_HELPERS
source $dotnetsdk

if dotnetsdk use 0.1.0-not-real; then
	die "dotnetsdk didn't fail to use bogus runtime version"
fi
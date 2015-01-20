source $COMMON_HELPERS
source $dotnetsdk

if dotnetsdk use bogus_alias; then
	die "dotnetsdk didn't fail to use bogus alias"
fi
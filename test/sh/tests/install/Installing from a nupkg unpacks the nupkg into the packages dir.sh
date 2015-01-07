source $COMMON_HELPERS
source $KVM

# Fetch the NuPkg to install
mkdir "$KRE_USER_HOME/temp"
mkdir "$KRE_USER_HOME/packages"
curl -L "https://www.myget.org/F/aspnetmaster/api/v2/package/KRE-Mono/1.0.0-alpha4" -o "$KRE_USER_HOME/temp/KRE-Mono.1.0.0-alpha4.nupkg"

kvm install "$KRE_USER_HOME/temp/KRE-Mono.1.0.0-alpha4.nupkg"

[ -d "$KRE_USER_HOME/packages/KRE-Mono.1.0.0-alpha4" ] || die "unable to find installed KRE"

pushd "$KRE_USER_HOME/packages/KRE-Mono.1.0.0-alpha4" 2>/dev/null 1>/dev/null
[ -f bin/k ] || die "KRE did not include 'k' command!"
[ -f bin/klr ] || die "KRE did not include 'klr' command!"
[ -f bin/kpm ] || die "KRE did not include 'kpm' command!"
popd 2>/dev/null 1>/dev/null
# kvm.sh
# Source this file from your .bash-profile or script to use

# "Constants"


K_DIR_NAME=".k"

_kvm_has() {
    type "$1" > /dev/null 2>&1
    return $?
}

if _kvm_has "unsetopt"; then
    unsetopt nomatch 2>/dev/null
fi

if [ -z "$KVM_USER_HOME" ]; then
    eval KVM_USER_HOME="~/$K_DIR_NAME"
fi

KRE_USER_PACKAGES="$KVM_USER_HOME/runtimes"
if [ -z "$KRE_FEED" ]; then
    KRE_FEED="https://www.myget.org/F/aspnetvnext/api/v2"
fi

_kvm_find_latest() {
    local platform="mono"

    if ! _kvm_has "curl"; then
        echo 'kvm needs curl to proceed.' >&2;
        return 1
    fi

    local url="$KRE_FEED/GetUpdates()?packageIds=%27kre-$platform%27&versions=%270.0%27&includePrerelease=true&includeAllVersions=false"
    xml="$(curl $url 2>/dev/null)"
    echo $xml | grep \<[a-zA-Z]:Version\>* >> /dev/null || return 1
    version="$(echo $xml | sed 's/.*<[a-zA-Z]:Version>\([^<]*\).*/\1/')"
    echo $version
}

_kvm_strip_path() {
    echo "$1" | sed -e "s#$KRE_USER_PACKAGES/[^/]*$2[^:]*:##g" -e "s#:$KRE_USER_PACKAGES/[^/]*$2[^:]*##g" -e "s#$KRE_USER_PACKAGES/[^/]*$2[^:]*##g"
}

_kvm_prepend_path() {
    if [ -z "$1" ]; then
        echo "$2"
    else
        echo "$2:$1"
    fi
}

_kvm_package_version() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/[^.]*.\(.*\)/\1/"
}

_kvm_package_name() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/\([^.]*\).*/\1/"
}

_kvm_package_runtime() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/KRE-\([^.-]*\).*/\1/"
}

_kvm_download() {
    local runtimeFullName="$1"
    local runtimeFolder="$2"

    local pkgName=$(_kvm_package_name "$runtimeFullName")
    local pkgVersion=$(_kvm_package_version "$runtimeFullName")
    local url="$KRE_FEED/package/$pkgName/$pkgVersion"
    local runtimeFile="$runtimeFolder/$runtimeFullName.nupkg"

    if [ -e "$runtimeFolder" ]; then
        echo "$runtimeFullName already installed."
        return 0
    fi

    echo "Downloading $runtimeFullName from $KRE_FEED"

    if ! _kvm_has "curl"; then
        echo "kvm needs curl to proceed." >&2;
        return 1
    fi

    mkdir -p "$runtimeFolder" > /dev/null 2>&1

    local httpResult=$(curl -L -D - "$url" -o "$runtimeFile" 2>/dev/null | grep "^HTTP/1.1" | head -n 1 | sed "s/HTTP.1.1 \([0-9]*\).*/\1/")

    [[ $httpResult == "404" ]] && echo "$runtimeFullName was not found in repository $KRE_FEED" && return 1
    [[ $httpResult != "302" && $httpResult != "200" ]] && echo "HTTP Error $httpResult fetching $runtimeFullName from $KRE_FEED" && return 1

    _kvm_unpack $runtimeFile $runtimeFolder
    return  $?
}

_kvm_unpack() {
    local runtimeFile="$1"
    local runtimeFolder="$2"

    echo "Installing to $runtimeFolder"

    if ! _kvm_has "unzip"; then
        echo "kvm needs unzip to proceed." >&2;
        return 1
    fi

    unzip $runtimeFile -d $runtimeFolder > /dev/null 2>&1

    [ -e "$runtimeFolder/[Content_Types].xml" ] && rm "$runtimeFolder/[Content_Types].xml"

    [ -e "$runtimeFolder/_rels/" ] && rm -rf "$runtimeFolder/_rels/"

    [ -e "$runtimeFolder/package/" ] && rm -rf "$runtimeFolder/_package/"

    #Set shell commands as executable
    find "$runtimeFolder/bin/" -type f \
        -exec sh -c "head -c 11 {} | grep '/bin/bash' > /dev/null"  \; -print | xargs chmod 775
}

_kvm_requested_version_or_alias() {
    local versionOrAlias="$1"
    local runtimeBin=$(_kvm_locate_runtime_bin_from_full_name "$versionOrAlias")

    # If the name specified is an existing package, just use it as is
    if [ -n "$runtimeBin" ]; then
        echo "$versionOrAlias"
    else
       if [ -e "$KVM_USER_HOME/alias/$versionOrAlias.alias" ]; then
           local runtimeFullName=$(cat "$KVM_USER_HOME/alias/$versionOrAlias.alias")
           local pkgName=$(echo $runtimeFullName | sed "s/\([^.]*\).*/\1/")
           local pkgVersion=$(echo $runtimeFullName | sed "s/[^.]*.\(.*\)/\1/")
           local pkgPlatform=$(echo "$pkgName" | sed "s/kre-\([^.-]*\).*/\1/")
        else
            local pkgVersion=$versionOrAlias
            local pkgPlatform="mono"
        fi

        echo "kre-$pkgPlatform.$pkgVersion"
    fi
}

# This will be more relevant if we support global installs
_kvm_locate_runtime_bin_from_full_name() {
    local runtimeFullName=$1
    [ -e "$KRE_USER_PACKAGES/$runtimeFullName/bin" ] && echo "$KRE_USER_PACKAGES/$runtimeFullName/bin" && return
}

kvm()
{
    if [ $# -lt 1 ]; then
        kvm help
        return
    fi

    case $1 in
        "help" )
            echo ""
            echo "K Version Manager - Build {{BUILD_NUMBER}}"
            echo ""
            echo "USAGE: kvm <command> [options]"
            echo ""
            echo "kvm upgrade"
            echo "install latest KRE from feed"
            echo "add KRE bin to path of current command line"
            echo "set installed version as default"
            echo ""
            echo "kvm install <semver>|<alias>|<nupkg>|latest [-a|-alias <alias>] [-p -persistent]"
            echo "<semver>|<alias>  install requested KRE from feed"
            echo "<nupkg>           install requested KRE from local package on filesystem"
            echo "latest            install latest version of KRE from feed"
            echo "-a|-alias <alias> set alias <alias> for requested KRE on install"
            echo "-p -persistent    set installed version as default"
            echo "add KRE bin to path of current command line"
            echo ""
            echo "kvm use <semver>|<alias>|<package>|none [-p -persistent]"
            echo "<semver>|<alias>|<package>  add KRE bin to path of current command line   "
            echo "none                        remove KRE bin from path of current command line"
            echo "-p -persistent              set selected version as default"
            echo ""
            echo "kvm list"
            echo "list KRE versions installed "
            echo ""
            echo "kvm alias"
            echo "list KRE aliases which have been defined"
            echo ""
            echo "kvm alias <alias>"
            echo "display value of the specified alias"
            echo ""
            echo "kvm alias <alias> <semver>|<alias>|<package>"
            echo "<alias>                      the name of the alias to set"
            echo "<semver>|<alias>|<package>   the KRE version to set the alias to. Alternatively use the version of the specified alias"
            echo ""
            echo "kvm unalias <alias>"
            echo "remove the specified alias"
            echo ""
        ;;

        "upgrade" )
            [ $# -ne 1 ] && kvm help && return
            kvm install latest -p
        ;;

        "install" )
            [ $# -lt 2 ] && kvm help && return
            shift
            local persistent=
            local versionOrAlias=
            local alias=
            while [ $# -ne 0 ]
            do
                if [[ $1 == "-p" || $1 == "-persistent" ]]; then
                    local persistent="-p"
                elif [[ $1 == "-a" || $1 == "-alias" ]]; then
                    local alias=$2
                    shift
                elif [[ -n $1 ]]; then
                    [[ -n $versionOrAlias ]] && echo "Invalid option $1" && kvm help && return 1
                    local versionOrAlias=$1
                fi
                shift
            done
            if [[ "$versionOrAlias" == "latest" ]]; then
                echo "Determining latest version"
                versionOrAlias=$(_kvm_find_latest)
                [[ $? == 1 ]] && echo "Error: Could not find latest version from feed $KRE_FEED" && return 1
                echo "Latest version is $versionOrAlias"
            fi
            if [[ "$versionOrAlias" == *.nupkg ]]; then
                local runtimeFullName=$(basename $versionOrAlias | sed "s/\(.*\)\.nupkg/\1/")
                local runtimeVersion=$(_kvm_package_version "$runtimeFullName")
                local runtimeFolder="$KRE_USER_PACKAGES/$runtimeFullName"
                local runtimeFile="$runtimeFolder/$runtimeFullName.nupkg"

                if [ -e "$runtimeFolder" ]; then
                  echo "$runtimeFullName already installed"
                else
                  mkdir "$runtimeFolder" > /dev/null 2>&1
                  cp -a "$versionOrAlias" "$runtimeFile"
                  _kvm_unpack "$runtimeFile" "$runtimeFolder"
                  [[ $? == 1 ]] && return 1
                fi
                kvm use "$runtimeVersion" "$persistent"
                [[ -n $alias ]] && kvm alias "$alias" "$runtimeVersion"
            else
                local runtimeFullName="$(_kvm_requested_version_or_alias $versionOrAlias)"
                local runtimeFolder="$KRE_USER_PACKAGES/$runtimeFullName"
                _kvm_download "$runtimeFullName" "$runtimeFolder"
                [[ $? == 1 ]] && return 1
                kvm use "$versionOrAlias" "$persistent"
                [[ -n $alias ]] && kvm alias "$alias" "$versionOrAlias"
            fi
        ;;

        "use" )
            [ $# -gt 3 ] && kvm help && return
            [ $# -lt 2 ] && kvm help && return

            shift
            local persistent=
            while [ $# -ne 0 ]
            do
                if [[ $1 == "-p" || $1 == "-persistent" ]]; then
                    local persistent="true"
                elif [[ -n $1 ]]; then
                    local versionOrAlias=$1
                fi
                shift
            done

            if [[ $versionOrAlias == "none" ]]; then
                echo "Removing KRE from process PATH"
                # Strip other version from PATH
                PATH=$(_kvm_strip_path "$PATH" "/bin")

                if [[ -n $persistent && -e "$KVM_USER_HOME/alias/default.alias" ]]; then
                    echo "Setting default KRE to none"
                    rm "$KVM_USER_HOME/alias/default.alias"
                fi
                return 0
            fi

            local runtimeFullName=$(_kvm_requested_version_or_alias "$versionOrAlias")
            local runtimeBin=$(_kvm_locate_runtime_bin_from_full_name "$runtimeFullName")

            if [[ -z $runtimeBin ]]; then
                echo "Cannot find $runtimeFullName, do you need to run 'kvm install $versionOrAlias'?"
                return 1
            fi

            echo "Adding" $runtimeBin "to process PATH"

            PATH=$(_kvm_strip_path "$PATH" "/bin")
            PATH=$(_kvm_prepend_path "$PATH" "$runtimeBin")

            if [[ -n $persistent ]]; then
                local runtimeVersion=$(_kvm_package_version "$runtimeFullName")
                kvm alias default "$runtimeVersion"
            fi
        ;;

        "alias" )
            [[ $# -gt 3 ]] && kvm help && return

            [[ ! -e "$KVM_USER_HOME/alias/" ]] && mkdir "$KVM_USER_HOME/alias/" > /dev/null

            if [[ $# == 1 ]]; then
                echo ""
                local format="%-20s %s\n"
                printf "$format" "Alias" "Name"
                printf "$format" "-----" "----"
                if [ -d "$KVM_USER_HOME/alias" ]; then
                    for _kvm_file in $(find "$KVM_USER_HOME/alias" -name *.alias); do
                        local alias="$(basename $_kvm_file | sed 's/\.alias//')"
                        local name="$(cat $_kvm_file)"
                        printf "$format" "$alias" "$name"
                    done
                fi
                echo ""
                return
            fi

            local name="$2"

            if [[ $# == 2 ]]; then
                [[ ! -e "$KVM_USER_HOME/alias/$name.alias" ]] && echo "There is no alias called '$name'" && return
                cat "$KVM_USER_HOME/alias/$name.alias"
                echo ""
                return
            fi

            local runtimeFullName=$(_kvm_requested_version_or_alias "$3")

            [[ ! -d "$KRE_USER_PACKAGES/$runtimeFullName" ]] && echo "$runtimeFullName is not an installed KRE version" && return 1

            local action="Setting"
            [[ -e "$KVM_USER_HOME/alias/$name.alias" ]] && action="Updating"
            echo "$action alias '$name' to '$runtimeFullName'"
            echo "$runtimeFullName" > "$KVM_USER_HOME/alias/$name.alias"
        ;;

        "unalias" )
            [[ $# -ne 2 ]] && kvm help && return

            local name=$2
            local aliasPath="$KVM_USER_HOME/alias/$name.alias"
            [[ ! -e  "$aliasPath" ]] && echo "Cannot remove alias, '$name' is not a valid alias name" && return 1
            echo "Removing alias $name"
            rm "$aliasPath" >> /dev/null 2>&1
        ;;

        "list" )
            [[ $# -gt 2 ]] && kvm help && return

            [[ ! -d $KRE_USER_PACKAGES ]] && echo "KRE is not installed." && return 1

            local searchGlob="kre-*"
            if [ $# == 2 ]; then
                local versionOrAlias=$2
                local searchGlob=$(_kvm_requested_version_or_alias "$versionOrAlias")
            fi
            echo ""

            # Separate empty array declaration from initialization
            # to avoid potential ZSH error: local:217: maximum nested function level reached
            local arr
            arr=()

            # Z shell array-index starts at one.
            local i=1
            local format="%-20s %s\n"
            if [ -d "$KVM_USER_HOME/alias" ]; then
                for _kvm_file in $(find "$KVM_USER_HOME/alias" -name *.alias); do
                    arr[$i]="$(basename $_kvm_file | sed 's/\.alias//')/$(cat $_kvm_file)"
                    let i+=1
                done
            fi

            local formatString="%-6s %-20s %-7s %-20s %s\n"
            printf "$formatString" "Active" "Version" "Runtime" "Location" "Alias"
            printf "$formatString" "------" "-------" "-------" "--------" "-----"

            local formattedHome=`(echo $KRE_USER_PACKAGES | sed s=$HOME=~=g)`
            for f in $(find $KRE_USER_PACKAGES -name "$searchGlob" \( -type d -or -type l \) -prune -exec basename {} \;); do
                local active=""
                [[ $PATH == *"$KRE_USER_PACKAGES/$f/bin"* ]] && local active="  *"
                local pkgName=$(_kvm_package_runtime "$f")
                local pkgVersion=$(_kvm_package_version "$f")

                local alias=""
                local delim=""
                for i in "${arr[@]}"; do
                    temp="kre-$pkgName.$pkgVersion"
                    temp2="kre-$pkgName-x86.$pkgVersion"
                    if [[ ${i#*/} == $temp || ${i#*/} == $temp2 ]]; then
                        alias+="$delim${i%/*}"
                        delim=", "
                    fi
                done

                printf "$formatString" "$active" "$pkgVersion" "$pkgName" "$formattedHome" "$alias"
                [[ $# == 2 ]] && echo "" &&  return 0
            done

            echo ""
            [[ $# == 2 ]] && echo "$versionOrAlias not found" && return 1
        ;;

        *)
            echo "Unknown command $1"
            return 1
    esac

    return 0
}

kvm list default >/dev/null && kvm use default >/dev/null || true

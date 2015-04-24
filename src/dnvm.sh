# dnvm.sh
# Source this file from your .bash-profile or script to use

# "Constants"
_DNVM_BUILDNUMBER="{{BUILD_VERSION}}"
_DNVM_AUTHORS="{{AUTHORS}}"
_DNVM_RUNTIME_PACKAGE_NAME="dnx"
_DNVM_RUNTIME_FRIENDLY_NAME=".NET Execution Environment"
_DNVM_RUNTIME_SHORT_NAME="DNX"
_DNVM_RUNTIME_FOLDER_NAME=".dnx"
_DNVM_COMMAND_NAME="dnvm"
_DNVM_PACKAGE_MANAGER_NAME="dnu"
_DNVM_VERSION_MANAGER_NAME=".NET Version Manager"
_DNVM_DEFAULT_FEED="https://www.myget.org/F/aspnetvnext/api/v2"
_DNVM_UPDATE_LOCATION="https://raw.githubusercontent.com/aspnet/Home/dev/dnvm.sh"
_DNVM_HOME_VAR_NAME="DNX_HOME"

if [ "$NO_COLOR" != "1" ]; then
    # ANSI Colors
    RCol='\e[0m'    # Text Reset

    # Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
    Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
    Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
    Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
    Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
    Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
    Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
    Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
    Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';
fi


[[ "$_DNVM_BUILDNUMBER" = {{* ]] && _DNVM_BUILDNUMBER="HEAD"

__dnvm_has() {
    type "$1" > /dev/null 2>&1
    return $?
}

if __dnvm_has "unsetopt"; then
    unsetopt nomatch 2>/dev/null
fi

if [ -z "$DNX_USER_HOME" ]; then
    eval DNX_USER_HOME="~/$_DNVM_RUNTIME_FOLDER_NAME"
fi

_DNVM_USER_PACKAGES="$DNX_USER_HOME/runtimes"
_DNVM_ALIAS_DIR="$DNX_USER_HOME/alias"
_DNVM_DNVM_DIR="$DNX_USER_HOME/dnvm"

if [ -z "$DNX_FEED" ]; then
    DNX_FEED="$_DNVM_DEFAULT_FEED"
fi

__dnvm_current_os()
{
    local uname=$(uname)
    if [[ $uname == "Darwin" ]]; then
        echo "darwin"
    else
        echo "linux"
    fi
}

__dnvm_find_latest() {
    local platform="mono"

    if ! __dnvm_has "curl"; then
        printf "%b\n" "${Red}$_DNVM_COMMAND_NAME needs curl to proceed. ${RCol}" >&2;
        return 1
    fi

    local url="$DNX_FEED/GetUpdates()?packageIds=%27$_DNVM_RUNTIME_PACKAGE_NAME-$platform%27&versions=%270.0%27&includePrerelease=true&includeAllVersions=false"
    xml="$(curl $url 2>/dev/null)"
    echo $xml | grep \<[a-zA-Z]:Version\>* >> /dev/null || return 1
    version="$(echo $xml | sed 's/.*<[a-zA-Z]:Version>\([^<]*\).*/\1/')"
    echo $version
}

__dnvm_strip_path() {
    echo "$1" | sed -e "s#$_DNVM_USER_PACKAGES/[^/]*$2[^:]*:##g" -e "s#:$_DNVM_USER_PACKAGES/[^/]*$2[^:]*##g" -e "s#$_DNVM_USER_PACKAGES/[^/]*$2[^:]*##g"
}

__dnvm_prepend_path() {
    if [ -z "$1" ]; then
        echo "$2"
    else
        echo "$2:$1"
    fi
}

__dnvm_package_version() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/[^.]*.\(.*\)/\1/"
}

__dnvm_package_name() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/\([^.]*\).*/\1/"
}

__dnvm_package_runtime() {
    local runtimeFullName="$1"
    echo "$runtimeFullName" | sed "s/$_DNVM_RUNTIME_PACKAGE_NAME-\([^.-]*\).*/\1/"
}

__dnvm_package_arch() {
    local runtimeFullName="$1"
    if [[ "$runtimeFullName" =~ $_DNVM_RUNTIME_PACKAGE_NAME-[^-.]*-[^-.]*-[^-.]*\..* ]];
    then
        echo "$runtimeFullName" | sed "s/$_DNVM_RUNTIME_PACKAGE_NAME-[^-.]*-[^-.]*-\([^-.]*\)\..*/\1/"
    fi
}

__dnvm_update_self() {
    local dnvmFileLocation="$_DNVM_DNVM_DIR/dnvm.sh"
    if [ ! -e $dnvmFileLocation ]; then
        local formattedDnvmFileLocation=`(echo $dnvmFileLocation | sed s=$HOME=~=g)`
        local formattedDnvmHome=`(echo $_DNVM_DNVM_DIR | sed s=$HOME=~=g)`
        printf "%b\n" "${Red}$formattedDnvmFileLocation doesn't exist. This command assumes you have installed dnvm in the usual location and are trying to update it. If you want to use update-self then dnvm.sh should be sourced from $formattedDnvmHome ${RCol}"
        return 1
    fi
    printf "%b\n" "${Cya}Downloading dnvm.sh from $_DNVM_UPDATE_LOCATION ${RCol}"
    local httpResult=$(curl -L -D - "$_DNVM_UPDATE_LOCATION" -o "$dnvmFileLocation" -# | grep "^HTTP/1.1" | head -n 1 | sed "s/HTTP.1.1 \([0-9]*\).*/\1/")

    [[ $httpResult == "404" ]] &&printf "%b\n" "${Red}404. Unable to download DNVM from $_DNVM_UPDATE_LOCATION ${RCol}" && return 1
    [[ $httpResult != "302" && $httpResult != "200" ]] && echo "${Red}HTTP Error $httpResult fetching DNVM from $_DNVM_UPDATE_LOCATION ${RCol}" && return 1

    source "$dnvmFileLocation"
}

__dnvm_download() {
    local runtimeFullName="$1"
    local runtimeFolder="$2"
    local force="$3"

    local pkgName=$(__dnvm_package_name "$runtimeFullName")
    local pkgVersion=$(__dnvm_package_version "$runtimeFullName")
    local url="$DNX_FEED/package/$pkgName/$pkgVersion"
    local runtimeFile="$runtimeFolder/$runtimeFullName.nupkg"

    if [ -n "$force" ]; then
        printf "%b\n" "${Yel}Forcing download by deleting $runtimeFolder directory ${RCol}"
        rm -rf "$runtimeFolder"
    fi

    if [ -e "$runtimeFolder" ]; then
       printf "%b\n" "${Gre}$runtimeFullName already installed. ${RCol}"
        return 0
    fi
    
    if ! __dnvm_has "curl"; then
       printf "%b\n" "${Red}$_DNVM_COMMAND_NAME needs curl to proceed. ${RCol}" >&2;
        return 1
    fi

    mkdir -p "$runtimeFolder" > /dev/null 2>&1

    echo "Downloading $runtimeFullName from $DNX_FEED"
    echo "Download: $url"

    local httpResult=$(curl -L -D - "$url" -o "$runtimeFile" -# | grep "^HTTP/1.1" | head -n 1 | sed "s/HTTP.1.1 \([0-9]*\).*/\1/")

    [[ $httpResult == "404" ]] &&printf "%b\n" "${Red}$runtimeFullName was not found in repository $DNX_FEED ${RCol}" && return 1
    [[ $httpResult != "302" && $httpResult != "200" ]] && echo "${Red}HTTP Error $httpResult fetching $runtimeFullName from $DNX_FEED ${RCol}" && return 1

    __dnvm_unpack $runtimeFile $runtimeFolder
    return $?
}

__dnvm_unpack() {
    local runtimeFile="$1"
    local runtimeFolder="$2"

    echo "Installing to $runtimeFolder"

    if ! __dnvm_has "unzip"; then
        echo "$_DNVM_COMMAND_NAME needs unzip to proceed." >&2;
        return 1
    fi

    unzip $runtimeFile -d $runtimeFolder > /dev/null 2>&1

    [ -e "$runtimeFolder/[Content_Types].xml" ] && rm "$runtimeFolder/[Content_Types].xml"

    [ -e "$runtimeFolder/_rels/" ] && rm -rf "$runtimeFolder/_rels/"

    [ -e "$runtimeFolder/package/" ] && rm -rf "$runtimeFolder/_package/"

    [ -e "$runtimeFile" ] && rm -f "$runtimeFile"

    #Set shell commands as executable
    find "$runtimeFolder/bin/" -type f \
        -exec sh -c "head -c 11 {} | grep '/bin/bash' > /dev/null"  \; -print | xargs chmod 775
}

__dnvm_requested_version_or_alias() {
    local versionOrAlias="$1"
    local runtime="$2"
    local arch="$3"
    local runtimeBin=$(__dnvm_locate_runtime_bin_from_full_name "$versionOrAlias")

    # If the name specified is an existing package, just use it as is
    if [ -n "$runtimeBin" ]; then
        echo "$versionOrAlias"
    else
        if [ -e "$_DNVM_ALIAS_DIR/$versionOrAlias.alias" ]; then
            local runtimeFullName=$(cat "$_DNVM_ALIAS_DIR/$versionOrAlias.alias")
            echo "$runtimeFullName"
        else
            local pkgVersion=$versionOrAlias

            if [[ -z $runtime || "$runtime" == "mono" ]]; then
                echo "$_DNVM_RUNTIME_PACKAGE_NAME-mono.$pkgVersion"
            elif [[ "$runtime" == "coreclr" ]]; then
                local pkgArchitecture="x64"
                local pkgSystem=$(__dnvm_current_os)

                if [ "$arch" != "" ]; then
                    local pkgArchitecture="$arch"
                fi

                echo "$_DNVM_RUNTIME_PACKAGE_NAME-coreclr-$pkgSystem-$pkgArchitecture.$pkgVersion"
            fi
        fi
    fi
}

# This will be more relevant if we support global installs
__dnvm_locate_runtime_bin_from_full_name() {
    local runtimeFullName=$1
    [ -e "$_DNVM_USER_PACKAGES/$runtimeFullName/bin" ] && echo "$_DNVM_USER_PACKAGES/$runtimeFullName/bin" && return
}

__echo_art() {
  printf "%b" "${Cya}"
    echo "    ___  _  ___   ____  ___"
    echo "   / _ \/ |/ / | / /  |/  /"
    echo "  / // /    /| |/ / /|_/ / "
    echo " /____/_/|_/ |___/_/  /_/  "
   printf "%b" "${RCol}"
}

__dnvm_help() {
    __echo_art
    echo ""
    echo "$_DNVM_VERSION_MANAGER_NAME - Version 1.0.0-$_DNVM_BUILDNUMBER"
    [[ "$_DNVM_AUTHORS" != {{* ]] && echo "By $_DNVM_AUTHORS"
    echo ""
   printf "%b\n" "${Cya}USAGE:${Yel} $_DNVM_COMMAND_NAME <command> [options] ${RCol} \n"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME upgrade [-f|-force] ${RCol}"
    echo "  install latest $_DNVM_RUNTIME_SHORT_NAME from feed"
    echo "  adds $_DNVM_RUNTIME_SHORT_NAME bin to path of current command line"
    echo "  set installed version as default"
    echo "  -f|forces         force upgrade. Overwrite existing version of $_DNVM_RUNTIME_SHORT_NAME if already installed"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME install <semver>|<alias>|<nupkg>|latest [-a|-alias <alias>] [-p|-persistent] [-f|-force] ${RCol}"
    echo "  <semver>|<alias>  install requested $_DNVM_RUNTIME_SHORT_NAME from feed"
    echo "  <nupkg>           install requested $_DNVM_RUNTIME_SHORT_NAME from local package on filesystem"
    echo "  latest            install latest version of $_DNVM_RUNTIME_SHORT_NAME from feed"
    echo "  -a|-alias <alias> set alias <alias> for requested $_DNVM_RUNTIME_SHORT_NAME on install"
    echo "  -p|-persistent    set installed version as default"
    echo "  -f|force          force install. Overwrite existing version of $_DNVM_RUNTIME_SHORT_NAME if already installed"
    echo ""
    echo "  adds $_DNVM_RUNTIME_SHORT_NAME bin to path of current command line"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME use <semver>|<alias>|<package>|none [-p|-persistent] [-r|-runtime <runtime>] [-a|-arch <architecture>] ${RCol}"
    echo "  <semver>|<alias>|<package>  add $_DNVM_RUNTIME_SHORT_NAME bin to path of current command line   "
    echo "  none                        remove $_DNVM_RUNTIME_SHORT_NAME bin from path of current command line"
    echo "  -p|-persistent              set selected version as default"
    echo "  -r|-runtime                 runtime to use (mono, coreclr)"
    echo "  -a|-arch                    architecture to use (x64)"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME run <semver>|<alias> <args...> ${RCol}"
    echo "  <semver>|<alias>            the version or alias to run"
    echo "  <args...>                   arguments to be passed to $_DNVM_RUNTIME_SHORT_NAME"
    echo ""
    echo "  runs the $_DNVM_RUNTIME_SHORT_NAME command from the specified version of the runtime without affecting the current PATH"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME exec <semver>|<alias> <command> <args...> ${RCol}"
    echo "  <semver>|<alias>            the version or alias to execute in"
    echo "  <command>                   the command to run"
    echo "  <args...>                   arguments to be passed to the command"
    echo ""
    echo "  runs the specified command in the context of the specified version of the runtime without affecting the current PATH"
    echo "  example: $_DNVM_COMMAND_NAME exec 1.0.0-beta4 $_DNVM_PACKAGE_MANAGER_NAME build"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME list ${RCol}"
    echo "  list $_DNVM_RUNTIME_SHORT_NAME versions installed "
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME alias ${RCol}"
    echo "  list $_DNVM_RUNTIME_SHORT_NAME aliases which have been defined"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME alias <alias> ${RCol}"
    echo "  display value of the specified alias"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME alias <alias> <semver>|<alias>|<package> ${RCol}"
    echo "  <alias>                      the name of the alias to set"
    echo "  <semver>|<alias>|<package>   the $_DNVM_RUNTIME_SHORT_NAME version to set the alias to. Alternatively use the version of the specified alias"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME unalias <alias> ${RCol}"
    echo "  remove the specified alias"
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME [help|-h|-help|--help] ${RCol}"
    echo "  displays this help text."
    echo ""
   printf "%b\n" "${Yel}$_DNVM_COMMAND_NAME update-self ${RCol}"
    echo "  updates dnvm itself."
}

dnvm()
{
    if [ $# -lt 1 ]; then
        __dnvm_help
        return
    fi

    case $1 in
        "help"|"-h"|"-help"|"--help" )
            __dnvm_help
        ;;

        "update-self" )
            __dnvm_update_self
        ;;

        "upgrade" )
            shift
            $_DNVM_COMMAND_NAME install latest -p $1
        ;;

        "install" )
            [ $# -lt 2 ] && __dnvm_help && return
            shift
            local persistent=
            local versionOrAlias=
            local alias=
            local force=
            while [ $# -ne 0 ]
            do
                if [[ $1 == "-p" || $1 == "-persistent" ]]; then
                    local persistent="-p"
                elif [[ $1 == "-a" || $1 == "-alias" ]]; then
                    local alias=$2
                    shift
                elif [[ $1 == "-f" || $1 == "-force" ]]; then
                    local force="-f"
                elif [[ -n $1 ]]; then
                    [[ -n $versionOrAlias ]] && echo "Invalid option $1" && __dnvm_help && return 1
                    local versionOrAlias=$1
                fi
                shift
            done

            if ! __dnvm_has "mono"; then
               printf "%b\n" "${Yel}It appears you don't have Mono available. Remember to get Mono before trying to run $DNVM_RUNTIME_SHORT_NAME application. ${RCol}" >&2;
            fi

            if [[ "$versionOrAlias" == "latest" ]]; then
                echo "Determining latest version"
                versionOrAlias=$(__dnvm_find_latest)
                [[ $? == 1 ]] && echo "Error: Could not find latest version from feed $DNX_FEED" && return 1
               printf "%b\n" "Latest version is ${Cya}$versionOrAlias ${RCol}"
            fi

            if [[ "$versionOrAlias" == *.nupkg ]]; then
                local runtimeFullName=$(basename $versionOrAlias | sed "s/\(.*\)\.nupkg/\1/")
                local runtimeVersion=$(__dnvm_package_version "$runtimeFullName")
                local runtimeFolder="$_DNVM_USER_PACKAGES/$runtimeFullName"
                local runtimeFile="$runtimeFolder/$runtimeFullName.nupkg"

                if [ -e "$runtimeFolder" ]; then
                  echo "$runtimeFullName already installed"
                else
                  mkdir "$runtimeFolder" > /dev/null 2>&1
                  cp -a "$versionOrAlias" "$runtimeFile"
                  __dnvm_unpack "$runtimeFile" "$runtimeFolder"
                  [[ $? == 1 ]] && return 1
                fi
                $_DNVM_COMMAND_NAME use "$runtimeVersion" "$persistent"
                [[ -n $alias ]] && $_DNVM_COMMAND_NAME alias "$alias" "$runtimeVersion"
            else
                local runtimeFullName="$(__dnvm_requested_version_or_alias $versionOrAlias)"
                local runtimeFolder="$_DNVM_USER_PACKAGES/$runtimeFullName"
                __dnvm_download "$runtimeFullName" "$runtimeFolder" "$force"
                [[ $? == 1 ]] && return 1
                $_DNVM_COMMAND_NAME use "$versionOrAlias" "$persistent"
                [[ -n $alias ]] && $_DNVM_COMMAND_NAME alias "$alias" "$versionOrAlias"
            fi
        ;;

        "use"|"run"|"exec" )
            [[ $1 == "use" && $# -lt 2 ]] && __dnvm_help && return

            local cmd=$1
            local persistent=
            local arch=
            local runtime=

            shift
            if [ $cmd == "use" ]; then
                local versionOrAlias=
                while [ $# -ne 0 ]
                do
                    if [[ $1 == "-p" || $1 == "-persistent" ]]; then
                        local persistent="true"
                    elif [[ $1 == "-a" || $1 == "-arch" ]]; then
                        local arch=$2
                        shift
                    elif [[ $1 == "-r" || $1 == "-runtime" ]]; then
                        local runtime=$2
                        shift
                    elif [[ $1 == -* ]]; then
                        echo "Invalid option $1" && __dnvm_help && return 1
                    elif [[ -n $1 ]]; then
                        [[ -n $versionOrAlias ]] && echo "Invalid option $1" && __dnvm_help && return 1
                        local versionOrAlias=$1
                    fi
                    shift
                done
            else
                local versionOrAlias=$1
                shift
            fi

            if [[ $cmd == "use" && $versionOrAlias == "none" ]]; then
                echo "Removing $_DNVM_RUNTIME_SHORT_NAME from process PATH"
                # Strip other version from PATH
                PATH=$(__dnvm_strip_path "$PATH" "/bin")

                if [[ -n $persistent && -e "$_DNVM_ALIAS_DIR/default.alias" ]]; then
                    echo "Setting default $_DNVM_RUNTIME_SHORT_NAME to none"
                    rm "$_DNVM_ALIAS_DIR/default.alias"
                fi
                return 0
            fi

            local runtimeFullName=$(__dnvm_requested_version_or_alias "$versionOrAlias" "$runtime" "$arch")
            local runtimeBin=$(__dnvm_locate_runtime_bin_from_full_name "$runtimeFullName")

            if [[ -z $runtimeBin ]]; then
                echo "Cannot find $runtimeFullName, do you need to run '$_DNVM_COMMAND_NAME install $versionOrAlias'?"
                return 1
            fi

            case $cmd in
                "run")
                    local hostpath="$runtimeBin/dnx"
                    if [[ -e $hostpath ]]; then
                        $hostpath $@
                    else
                        echo "Cannot find $_DNVM_RUNTIME_SHORT_NAME in $runtimeBin. It may have been corrupted. Use '$_DNVM_COMMAND_NAME install $versionOrAlias -f' to attempt to reinstall it"
                    fi
                ;;
                "exec") 
                    (
                        PATH=$(__dnvm_strip_path "$PATH" "/bin")
                        PATH=$(__dnvm_prepend_path "$PATH" "$runtimeBin")
                        $@
                    )
                ;;
                "use") 
                    echo "Adding" $runtimeBin "to process PATH"

                    PATH=$(__dnvm_strip_path "$PATH" "/bin")
                    PATH=$(__dnvm_prepend_path "$PATH" "$runtimeBin")

                    if [[ -n $persistent ]]; then
                        $_DNVM_COMMAND_NAME alias default "$runtimeFullName"
                    fi
                ;;
            esac
        ;;

        "alias" )
            [[ $# -gt 3 ]] && __dnvm_help && return

            [[ ! -e "$_DNVM_ALIAS_DIR/" ]] && mkdir "$_DNVM_ALIAS_DIR/" > /dev/null

            if [[ $# == 1 ]]; then
                echo ""
                local format="%-25s %s\n"
                printf "$format" "Alias" "Name"
                printf "$format" "-----" "----"
                if [ -d "$_DNVM_ALIAS_DIR" ]; then
                    for __dnvm_file in $(find "$_DNVM_ALIAS_DIR" -name *.alias); do
                        local alias="$(basename $__dnvm_file | sed 's/\.alias//')"
                        local name="$(cat $__dnvm_file)"
                        printf "$format" "$alias" "$name"
                    done
                fi
                echo ""
                return
            fi

            local name="$2"

            if [[ $# == 2 ]]; then
                [[ ! -e "$_DNVM_ALIAS_DIR/$name.alias" ]] && echo "There is no alias called '$name'" && return
                cat "$_DNVM_ALIAS_DIR/$name.alias"
                echo ""
                return
            fi

            local runtimeFullName=$(__dnvm_requested_version_or_alias "$3")

            [[ ! -d "$_DNVM_USER_PACKAGES/$runtimeFullName" ]] && echo "$runtimeFullName is not an installed $_DNVM_RUNTIME_SHORT_NAME version" && return 1

            local action="Setting"
            [[ -e "$_DNVM_ALIAS_DIR/$name.alias" ]] && action="Updating"
            echo "$action alias '$name' to '$runtimeFullName'"
            echo "$runtimeFullName" > "$_DNVM_ALIAS_DIR/$name.alias"
        ;;

        "unalias" )
            [[ $# -ne 2 ]] && __dnvm_help && return

            local name=$2
            local aliasPath="$_DNVM_ALIAS_DIR/$name.alias"
            [[ ! -e  "$aliasPath" ]] && echo "Cannot remove alias, '$name' is not a valid alias name" && return 1
            echo "Removing alias $name"
            rm "$aliasPath" >> /dev/null 2>&1
        ;;

        "list" )
            [[ $# -gt 2 ]] && __dnvm_help && return

            [[ ! -d $_DNVM_USER_PACKAGES ]] && echo "$_DNVM_RUNTIME_FRIENDLY_NAME is not installed." && return 1

            local searchGlob="$_DNVM_RUNTIME_PACKAGE_NAME-*"
            if [ $# == 2 ]; then
                local versionOrAlias=$2
                local searchGlob=$(__dnvm_requested_version_or_alias "$versionOrAlias")
            fi
            echo ""

            # Separate empty array declaration from initialization
            # to avoid potential ZSH error: local:217: maximum nested function level reached
            local arr
            arr=()

            # Z shell array-index starts at one.
            local i=1
            local format="%-20s %s\n"
            if [ -d "$_DNVM_ALIAS_DIR" ]; then
                for __dnvm_file in $(find "$_DNVM_ALIAS_DIR" -name *.alias); do
                    arr[$i]="$(basename $__dnvm_file | sed 's/\.alias//')/$(cat $__dnvm_file)"
                    let i+=1
                done
            fi

            local formatString="%-6s %-20s %-7s %-4s %-20s %s\n"
            printf "$formatString" "Active" "Version" "Runtime" "Arch" "Location" "Alias"
            printf "$formatString" "------" "-------" "-------" "----" "--------" "-----"

            local formattedHome=`(echo $_DNVM_USER_PACKAGES | sed s=$HOME=~=g)`
            for f in $(find $_DNVM_USER_PACKAGES -name "$searchGlob" \( -type d -or -type l \) -prune -exec basename {} \;); do
                local active=""
                [[ $PATH == *"$_DNVM_USER_PACKAGES/$f/bin"* ]] && local active="  *"
                local pkgRuntime=$(__dnvm_package_runtime "$f")
                local pkgName=$(__dnvm_package_name "$f")
                local pkgVersion=$(__dnvm_package_version "$f")
                local pkgArch=$(__dnvm_package_arch "$f")

                local alias=""
                local delim=""
                for i in "${arr[@]}"; do
                    if [[ ${i#*/} == "$pkgName.$pkgVersion" ]]; then
                        alias+="$delim${i%/*}"
                        delim=", "
                    fi
                done

                printf "$formatString" "$active" "$pkgVersion" "$pkgRuntime" "$pkgArch" "$formattedHome" "$alias"
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

# Generate the command function using the constant defined above.
$_DNVM_COMMAND_NAME list default >/dev/null && $_DNVM_COMMAND_NAME use default >/dev/null || true

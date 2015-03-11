# A bunch of helper functions and variables!

# "Constants"
_DNVM_BUILDNUMBER="{{BUILD_VERSION}}"
_DNVM_RUNTIME_PACKAGE_NAME="dnx"
_DNVM_RUNTIME_FRIENDLY_NAME=".NET Execution Environment"
_DNVM_RUNTIME_SHORT_NAME="DNX"
_DNVM_RUNTIME_FOLDER_NAME=".dnx"
_DNVM_COMMAND_NAME="dnvm"
_DNVM_VERSION_MANAGER_NAME=".NET Version Manager"
_DNVM_DEFAULT_FEED="https://www.myget.org/F/aspnetvnext/api/v2"
_DNVM_HOME_VAR_NAME="DNX_HOME"

_DNVM_RUNTIME_EXEC_NAME="k"
_DNVM_PACKAGE_MANAGER_NAME="kpm"
_DNVM_RUNTIME_HOST_NAME="dnx"

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

INDENT=0
INDENT_STRING="  "
indent() {
	INDENT=$((INDENT+1))
}
unindent() {
	INDENT=$((INDENT-1))
}

log_lines() {
    local level="$1"
    shift
    echo "$@" | while IFS= read -r line; do
        log "$level" "$line"
    done
}

log() {
	local level="$1"
	shift
	local message="$@"

	local color=""
	case "$level" in
		warn) color="${BIYel}";;
		error) color="${BIRed}";;
		info) color="${BIGre}";;
		trace) color="${BBla}";;
	esac

	local indentation=""
    if [ "$INDENT" -ne "0" ]; then
    	for i in $(seq 0 $INDENT); do
    		local indentation="$indentation$INDENT_STRING"
    	done
    fi

	local format="${color}%-5s${RCol}: $indentation%s\n"
    if [ $level == "trace" ]; then
        format="${color}%-5s${RCol}: $indentation${color}%s${RCol}\n"
    fi

	if [ $level == "error" ]; then
		printf "$format" "$level" "$message" 1>&2
	else
		printf "$format" "$level" "$message"
	fi
}

# Echo to stderr
error() {
	log error $@
}

info() {
	log info $@
}

warn() {
	log warn $@
}

die() {
	error $@
	exit 1
}

teamcity() {
	[ "$TEAMCITY" == "1" ] && echo "##teamcity[$1]"
}

verbose() {
	[ "$VERBOSE" == "1" ] && log trace $@
}

path_of() {
	local CMD=$1
	type $CMD | sed "s/$CMD is //g"
}

has() {
	type "$1" > /dev/null 2>&1
    return $?
}

requires() {
	if ! has $1; then
		die "Missing required command: $1"
	fi
}

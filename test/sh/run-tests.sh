#!/bin/bash

# Determine my directory
SCRIPT_DIR=$(dirname $0)
pushd $SCRIPT_DIR > /dev/null
SCRIPT_DIR=$(pwd)
popd > /dev/null

# Determine root
pushd $SCRIPT_DIR/../.. > /dev/null
REPO_ROOT=$(pwd)
popd > /dev/null

# Default variable values
[ -z "$TEST_WORK_DIR" ]     && export TEST_WORK_DIR="$(pwd)/testwork"
[ -z "$TEST_SHELLS" ]       && export TEST_SHELLS="bash zsh"
[ -z "$TEST_DIR" ]          && export TEST_DIR="$SCRIPT_DIR/tests"
[ -z "$URCHIN" ]            && export URCHIN="$SCRIPT_DIR/urchin.sh"
[ -z "$KRE_FEED" ]          && export KRE_FEED="https://www.myget.org/F/aspnetmaster/api/v2" # doesn't really matter what the feed is, just that it is a feed
[ -z "$TEST_APPS_DIR" ]     && export TEST_APPS_DIR="$REPO_ROOT/test/apps"

# This is a KRE to use for testing various commands. It doesn't matter what version it is
[ -z "$KRE_TEST_VERSION"]   && export KRE_TEST_VERSION="1.0.0-beta1"
[ -z "$KRE_NUPKG_HASH" ]    && export KRE_NUPKG_HASH="5fb3d472166f89898631f2a996f79de727f5815f"
[ -z "$KRE_NUPKG_URL" ]     && export KRE_NUPKG_URL="https://www.myget.org/F/aspnetmaster/api/v2/package/KRE-Mono/$KRE_TEST_VERSION"
[ -z "$KRE_NUPKG_NAME" ]    && export KRE_NUPKG_NAME="KRE-Mono.$KRE_TEST_VERSION"
[ -z "$KRE_NUPKG_FILE" ]    && export KRE_NUPKG_FILE="$TEST_WORK_DIR/${KRE_NUPKG_NAME}.nupkg"

# Load helper functions
export COMMON_HELPERS="$SCRIPT_DIR/common.sh"
source $COMMON_HELPERS

requires curl
requires sh
requires bash
requires zsh
requires awk

USAGE="usage: $0 [<options>] <test directory>"

runtests_help() {
    cat <<EOF

$USAGE

-t          Writes TeamCity status messages to the output.
-v          Write stdout for tests that succeed.
-h          This help.

EOF
}

# Read arguments
while [ $# -gt 0 ]
do
    case "$1" in
        -t) TEAMCITY=1;;
        -v) VERBOSE=1;;
        -h|--help) runtests_help
          exit 0;;
        -*) runtests_help >&2
            exit 1;;
        *)  break;;
    esac
    shift
done

verbose "Running in $SCRIPT_DIR"

# Set up a test environment
info "Using Working Directory path: $TEST_WORK_DIR"

if [ -e "$TEST_WORK_DIR" ]; then
    if [ ! -d "$TEST_WORK_DIR" ]; then
        die "Working directory path exists and is not a directory!"
    else
        warn "Working directory path exists. Cleaning..."
        rm -Rf "$TEST_WORK_DIR"
    fi
fi

info "Creating working directory."
mkdir -p "$TEST_WORK_DIR"

# Fetch the nupkg we use for testing
info "Fetching test dependencies..."
[ ! -e $KRE_NUPKG_FILE ] || rm $KRE_NUPKG_FILE

curl -L -o $KRE_NUPKG_FILE $KRE_NUPKG_URL
[ -e $KRE_NUPKG_FILE ] || die "failed to fetch test nupkg"
[ $(shasum $KRE_NUPKG_FILE | awk '{ print $1 }') = "$KRE_NUPKG_HASH" ] || die "downloaded nupkg does not match expected file"

# Set up useful variables for the test
pushd "$SCRIPT_DIR/../../src" > /dev/null
export KVM=$(pwd)/kvm.sh
popd > /dev/null

if [ ! -e $KVM ]; then
    die "Couldn't find KVM at $KVM"
elif [ ! -f $KVM ]; then
    die "KVM at $KVM is not a file?!"
fi

info "Using KVM at $KVM"

# Run urchin in each test shell
FAILED=
SUCCEEDED=
for shell in $TEST_SHELLS; do
    [ "$TEAMCITY" == "1" ] && echo "##teamcity[testSuiteStarted name='$shell']"
    info "Testing kvm.sh in $shell"
    
    export KRE_USER_HOME="$TEST_WORK_DIR/$shell"
    [ -d $KRE_USER_HOME ] || mkdir $KRE_USER_HOME

    TEAMCITY=$TEAMCITY VERBOSE=$VERBOSE $URCHIN -s $shell $TEST_DIR

    unset KRE_USER_HOME

    if [ $? -eq 0 ]; then
        SUCCEEDED="$SUCCEEDED $shell"
    else
        FAILED="$FAILED $shell"
    fi
    info "Tests completed in $shell"
    [ "$TEAMCITY" == "1" ] && echo "##teamcity[testSuiteFinished name='$shell']"
done

FAILED_COUNT=$(echo $FAILED | wc -w | tr -d ' ' | tr -d '\r' | tr -d '\n')
SUCCEEDED_COUNT=$(echo $SUCCEEDED | wc -w | tr -d ' ' | tr -d '\r' | tr -d '\n')

if [ -z "$FAILED" ]; then
    exit 0
else
    exit 1
fi
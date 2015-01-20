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
[ -z "$CHESTER" ]           && export CHESTER="$SCRIPT_DIR/chester"
[ -z "$DOTNET_FEED" ]       && export DOTNET_FEED="https://www.myget.org/F/aspnetvnext/api/v2" # doesn't really matter what the feed is, just that it is a feed
[ -z "$TEST_APPS_DIR" ]     && export TEST_APPS_DIR="$REPO_ROOT/test/apps"

# This is a KRE to use for testing various commands. It doesn't matter what version it is
[ -z "$DOTNET_TEST_VERSION"]   && export DOTNET_TEST_VERSION="1.0.0-beta1"
[ -z "$DOTNET_NUPKG_HASH" ]    && export DOTNET_NUPKG_HASH="5fb3d472166f89898631f2a996f79de727f5815f"
[ -z "$DOTNET_NUPKG_URL" ]     && export DOTNET_NUPKG_URL="https://www.myget.org/F/aspnetvnext/api/v2/package/dotnet-mono/$DOTNET_TEST_VERSION"
[ -z "$DOTNET_NUPKG_NAME" ]    && export DOTNET_NUPKG_NAME="dotnet-mono.$DOTNET_TEST_VERSION"
[ -z "$DOTNET_NUPKG_FILE" ]    && export DOTNET_NUPKG_FILE="$TEST_WORK_DIR/${DOTNET_NUPKG_NAME}.nupkg"

# Load helper functions
export COMMON_HELPERS="$SCRIPT_DIR/common.sh"
source $COMMON_HELPERS

requires curl
requires awk

for shell in $TEST_SHELLS; do
    requires $shell
done

# Set up a test environment
info "Using Working Directory path: $TEST_WORK_DIR"

if [ ! -e "$TEST_WORK_DIR" ]; then
    info "Creating working directory."
    mkdir -p "$TEST_WORK_DIR"
fi

if [ -f "$DOTNET_NUPKG_FILE" ]; then
    # Remove the file if it doesn't match the expected hash
    if [ $(shasum $DOTNET_NUPKG_FILE | awk '{ print $1 }') = "$DOTNET_NUPKG_HASH" ]; then
        info "Test package already exists and matches expected hash"
    else
        warn "Test package does not match expected hash, removing and redownloading."
        rm "$DOTNET_NUPKG_FILE"
    fi
fi

if [ ! -f "$DOTNET_NUPKG_FILE" ]; then
    # Fetch the nupkg we use for testing
    info "Fetching test dependencies..."

    curl -L -o $DOTNET_NUPKG_FILE $DOTNET_NUPKG_URL >/dev/null 2>&1
    [ -e $DOTNET_NUPKG_FILE ] || die "failed to fetch test nupkg"
    [ $(shasum $DOTNET_NUPKG_FILE | awk '{ print $1 }') = "$DOTNET_NUPKG_HASH" ] || die "downloaded nupkg does not match expected file"
fi

# Set up useful variables for the test
pushd "$SCRIPT_DIR/../../src" > /dev/null
export dotnetsdk=$(pwd)/dotnetsdk.sh
popd > /dev/null

if [ ! -e $dotnetsdk ]; then
    die "Couldn't find dotnetsdk at $dotnetsdk"
elif [ ! -f $dotnetsdk ]; then
    die "dotnetsdk at $dotnetsdk is not a file?!"
fi

info "Using dotnetsdk at $dotnetsdk"

# Run the test runner in each test shell
FAILED=()
SUCCEEDED=()
for shell in $TEST_SHELLS; do
    info "Testing dotnetsdk.sh in $shell"

    if [ -e "$TEST_WORK_DIR/$shell" ]; then
        if [ ! -d "$TEST_WORK_DIR/$shell" ]; then
            die "Working directory path exists and is not a directory!"
        else
            warn "Working directory path exists. Cleaning..."
            rm -Rf "$TEST_WORK_DIR/$shell"
        fi
    fi
    mkdir "$TEST_WORK_DIR/$shell"

    export DOTNET_USER_HOME="$TEST_WORK_DIR/$shell"
    [ -d $DOTNET_USER_HOME ] || mkdir $DOTNET_USER_HOME

    pushd tests >/dev/null 2>&1
    $CHESTER $@ -s $shell -n $shell "*"
    err_code="$?"
    popd >/dev/null 2>&1

    unset DOTNET_USER_HOME

    if [ "$err_code" -eq 0 ]; then
        SUCCEEDED+=("$shell")
        info "Tests completed in $shell"
    else
        FAILED+=("$shell")
        error "Tests failed in $shell"
    fi
done

exit "${#FAILED[@]}"
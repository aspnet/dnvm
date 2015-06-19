#!/usr/bin/env bash

# Determine my directory
SCRIPT_DIR=$(dirname $0)
pushd $SCRIPT_DIR > /dev/null
SCRIPT_DIR=$(pwd)
popd > /dev/null

# Determine root
pushd $SCRIPT_DIR/../.. > /dev/null
REPO_ROOT=$(pwd)
popd > /dev/null

# Load helper functions
export COMMON_HELPERS="$SCRIPT_DIR/common.sh"
source $COMMON_HELPERS

# Default variable values
[ -z "$TEST_WORK_DIR" ]     && export TEST_WORK_DIR="$(pwd)/testwork"
[ -z "$TEST_SHELLS" ]       && export TEST_SHELLS="bash zsh"
[ -z "$TEST_DIR" ]          && export TEST_DIR="$SCRIPT_DIR/tests"
[ -z "$CHESTER" ]           && export CHESTER="$SCRIPT_DIR/chester"
[ -z "$DNX_FEED" ]          && export DNX_FEED="https://www.myget.org/F/aspnetrelease/api/v2" # doesn't really matter what the feed is, just that it is a feed
[ -z "$TEST_APPS_DIR" ]     && export TEST_APPS_DIR="$REPO_ROOT/test/apps"

export DNX_FEED

# This is a DNX to use for testing various commands. It doesn't matter what version it is
[ -z "$_TEST_VERSION" ]     && export _TEST_VERSION="1.0.0-beta5-12087"
[ -z "$_NUPKG_HASH" ]       && export _NUPKG_HASH='1d28c7b3524deacb22050db8e3b339f27a7f43b8'
[ -z "$_NUPKG_URL" ]        && export _NUPKG_URL="$DNX_FEED/package/$_DNVM_RUNTIME_PACKAGE_NAME-mono/$_TEST_VERSION"
[ -z "$_NUPKG_NAME" ]       && export _NUPKG_NAME="$_DNVM_RUNTIME_PACKAGE_NAME-mono.$_TEST_VERSION"
[ -z "$_NUPKG_FILE" ]       && export _NUPKG_FILE="$TEST_WORK_DIR/${_NUPKG_NAME}.nupkg"

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

if [ -f "$_NUPKG_FILE" ]; then
    # Remove the file if it doesn't match the expected hash
    if [ $(shasum $_NUPKG_FILE | awk '{ print $1 }') = "$_NUPKG_HASH" ]; then
        info "Test package already exists and matches expected hash"
    else
        warn "Test package does not match expected hash, removing and redownloading."
        rm "$_NUPKG_FILE"
    fi
fi

if [ ! -f "$_NUPKG_FILE" ]; then
    # Fetch the nupkg we use for testing
    info "Fetching test dependencies..."

    curl -L -o $_NUPKG_FILE $_NUPKG_URL >/dev/null 2>&1
    ACTUAL_HASH=$(shasum $_NUPKG_FILE | awk '{ print $1 }')
    [ -e $_NUPKG_FILE ] || die "failed to fetch test nupkg"
    [ "$ACTUAL_HASH" = "$_NUPKG_HASH" ] || die "downloaded nupkg hash '$ACTUAL_HASH' for '$_NUPKG_URL' does not match expected value"
fi

# Set up useful variables for the test
pushd "$SCRIPT_DIR/../../src" > /dev/null
export _DNVM_PATH=$(pwd)/$_DNVM_COMMAND_NAME.sh
popd > /dev/null

if [ ! -e $_DNVM_PATH ]; then
    die "Couldn't find $_DNVM_COMMAND_NAME at $_DNVM_PATH"
elif [ ! -f $_DNVM_PATH ]; then
    die "$_DNVM_COMMAND_NAME at $_DNVM_PATH is not a file?!"
fi

info "Using $_DNVM_COMMAND_NAME at $_DNVM_PATH"

# Run the test runner in each test shell
FAILED=()
SUCCEEDED=()
for shell in $TEST_SHELLS; do
    info "Testing $_DNVM_COMMAND_NAME.sh in $shell"

    if [ -e "$TEST_WORK_DIR/$shell" ]; then
        if [ ! -d "$TEST_WORK_DIR/$shell" ]; then
            die "Working directory path exists and is not a directory!"
        else
            warn "Working directory path exists. Cleaning..."
            rm -Rf "$TEST_WORK_DIR/$shell"
        fi
    fi
    mkdir "$TEST_WORK_DIR/$shell"

    export DNX_USER_HOME="$TEST_WORK_DIR/$shell"
    [ -d $DNX_USER_HOME ] || mkdir $DNX_USER_HOME

    pushd "$SCRIPT_DIR/tests" >/dev/null 2>&1
    $CHESTER $@ -s $shell -n $shell "*"
    err_code="$?"
    popd >/dev/null 2>&1

    unset DNVM_USER_HOME

    if [ "$err_code" -eq 0 ]; then
        SUCCEEDED+=("$shell")
        info "Tests completed in $shell"
    else
        FAILED+=("$shell")
        error "Tests failed in $shell"
    fi
done

exit "${#FAILED[@]}"

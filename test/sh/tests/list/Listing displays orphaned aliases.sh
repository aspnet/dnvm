source $COMMON_HELPERS
source $_DNVM_PATH

# Clean all aliases
rm -Rf $DNX_USER_HOME/alias/*.alias

# Set default alias to any runtime
echo $(ls $DNX_USER_HOME/runtimes | head -n1) > $DNX_USER_HOME/alias/default.alias

# Create orphaned alias
echo dnx-foo-bar.1.0.0-beta7 > $DNX_USER_HOME/alias/foobar.alias

# List runtimes
OUTPUT=$($_DNVM_COMMAND_NAME list -detailed || die "failed at listing runtimes")
echo $OUTPUT | grep -E "\s+1\.0\.0-beta7\s+foo\s+bar\s+foobar\s\(missing\)" || die "expected message was not reported"
echo $OUTPUT | grep -E "default\s+.*?\/runtimes" || die "expected message was not reported"

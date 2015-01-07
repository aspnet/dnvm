#!/bin/sh

# Our fork of urchin to add some useful stuff for teamcity. We'll contribute it back eventually :).
# Used under the BSD license: https://github.com/tlevine/urchin/blob/f01869fb97687794cc415bc7a5357b03a2afc467/LICENCE

# Make sure that CDPATH isn't set, as it causes `cd` to behave unpredictably - notably, it can produce output,
# which breaks fullpath().
unset CDPATH

[ -z "$verbose" ] && verbose=0

teamcity() {
  [ "$TEAMCITY" == "1" ] && echo "##teamcity[$@]"
}

fullpath() {
  (
    cd -- "$1"
    pwd
  )
}

indent() {
  level="$1"
  printf "%$((2 * ${level}))s"
}

run_setup_teardown() {
  local FILE=$1
  local OUTFILE=$2
  if [ -f "$FILE" ] && [ -x "$FILE" ]
    then
      "./$FILE" >> "$OUTFILE"
  elif [ -f "$FILE.sh" ] && [ -x "$FILE.sh" ]
    then
      "./$FILE.sh" >> "$OUTFILE"
  fi
}

recurse() {
  potential_test="$1"
  indent_level="$2"
  shell_for_sh_tests="$3"

  [ "$potential_test" = 'setup_dir' ] && return
  [ "$potential_test" = 'teardown_dir' ] && return
  [ "$potential_test" = 'setup' ] && return
  [ "$potential_test" = 'teardown' ] && return
  [ "$potential_test" = 'setup_dir.sh' ] && return
  [ "$potential_test" = 'teardown_dir.sh' ] && return
  [ "$potential_test" = 'setup.sh' ] && return
  [ "$potential_test" = 'teardown.sh' ] && return

  [ $indent_level -eq 0 ] && : > "$stdout_file"

  TEST_NAME=$(echo $potential_test | sed -e 's|^\./||g' -e 's|\.sh$||g')
      
  if [ -d "$potential_test" ]
    then
    (
      indent $indent_level
      echo "  ${potential_test}"
      cd -- "$potential_test"

      run_setup_teardown "setup_dir" "$stdout_file"
      
      if [ -n "$ZSH_VERSION" ]; then
        # avoid "no matches found: *" error when directories are empty
        setopt NULL_GLOB
      fi

      teamcity "testSuiteStarted name='$TEST_NAME'"
      for test in *
        do
          run_setup_teardown "setup" "$stdout_file"
          
          # $2 instead of $indent_level so it doesn't clash
          recurse "${test}" $(( $2 + 1 )) "$shell_for_sh_tests"

          run_setup_teardown "teardown" "$stdout_file"
      done
      teamcity "testSuiteFinished name='$TEST_NAME'"

      run_setup_teardown "teardown_dir" "$stdout_file"
      echo
    )
  elif [ -x "$potential_test" ]
    then

    run_setup_teardown "setup" "$stdout_file"
    
    # Write to TeamCity if enabled
    teamcity "testStarted name='$TEST_NAME'"
    
    # Run the test
    if [ -n "$shell_for_sh_tests" ] && has_sh_or_no_shebang_line ./"$potential_test"
      then    
      TEST_SHELL="$TEST_SHELL" "$shell_for_sh_tests" ./"$potential_test" > "$stdout_file" 2>&1
    else
      TEST_SHELL="$TEST_SHELL" ./"$potential_test" > "$stdout_file" 2>&1
    fi
    exit_code="$?"

    run_setup_teardown "teardown" "$stdout_file"
    
    indent $indent_level
    if [ $exit_code -eq 0 ]
      then
      # On success, print a green '✓'
      printf '\033[32m✓ \033[0m'
      printf '%s\n' "${TEST_NAME}"
      printf '%s\n' "${TEST_NAME} passed" >> "$logfile"
      [ "$verbose" -eq 1 ] && cat "$stdout_file"
    else
      # On fail, print a red '✗'
      printf '\033[31m✗ \033[0m'
      printf '%s\n' "${TEST_NAME} (${duration}ms)"
      printf '%s\n' "${TEST_NAME} failed" >> "$logfile"
      printf '\033[31m' # Print output captured from failed test in red.
      cat "$stdout_file"
      printf '\033[0m'
      teamcity "testFailed name='$TEST_NAME'"
    fi

    teamcity "testFinished name='$TEST_NAME'"
  fi
  
  
  [ $indent_level -eq 0 ] && rm "$stdout_file"
}

has_sh_or_no_shebang_line() {
  head -n 1 "$1" | grep -vqE '^#!' && return 0 # no shebang line at all
  head -n 1 "$1" | grep -qE '^#![[:blank:]]*/bin/sh($|[[:blank:]])' && return 0  # shebang line is '#!/bin/sh' or legal variations thereof
  return 1
}

USAGE="usage: $0 [<options>] <test directory>"

urchin_help() {
  cat <<EOF

$USAGE

-s <shell>  Invoke test scripts that either have no shebang line at all or
            have shebang line "#!/bin/sh" with the specified shell.
-f          Force running even if the test directory's name does not
            contain the word "test".
-tc         Write out status messages for TeamCity to parse. (This is noisy
            and should only be used when running on TeamCity build servers.)
-v          Write out stdout for tests that succeed.
-h          This help.

Go to https://github.com/tlevine/urchin for documentation on writing tests.

EOF
  # [Experimental -x option left undocumented for now.]
  # -x          [Experimental; not meant for direct invocation, but for use in
  #             the shebang line of test scripts]
  #             Run with "\$TEST_SHELL", falling back on /bin/sh.
}

plural () {
  # Make $1 a plural according to the number $2.
  # If $3 is supplied, use that instead of "${1}s".
  # Result is written to stdout.
  if [ "$2" = 1 ]
  then
    printf '%s\n' "$1"
  else
    printf '%s\n' "${3-${1}s}"
  fi
}

urchin_go() {
  echo Running tests at $(date +%Y-%m-%dT%H:%M:%S) | tee "$logfile"
  start=$(date +%s)

  # Determine the environment variable to define for test scripts
  # that reflects the specified or implied shell to use for shell-code tests.
  #  - Set it to the shell specified via -s, if any.
  #  - Otherwise, use its present value, if non-empty.
  #  - Otherwise, default to '/bin/sh'.
  if [ -n "$2" ]
    then
    TEST_SHELL="$2"
  elif [ -z "$TEST_SHELL" ]
    then
    TEST_SHELL='/bin/sh'
  fi

  recurse "$1" 0 "$2"  # test folder -- indentation level -- [shell to invoke test scripts with]
  
  finish=$(date +%s)
  elapsed=$(($finish - $start))
  echo "Done, took $elapsed $(plural second $elapsed)."
  set -- $(grep -e 'passed$' "$logfile"|wc -l) $(grep -e 'failed$' "$logfile"|wc -l)
  printf '%s\n' "$1 $(plural test "$1") passed."
  [ $2 -gt 0 ] && printf '\033[31m' || printf '\033[32m' # If tests failed, print the message in red, otherwise in green.
  printf '%s\n' "$2 $(plural test "$2") failed."
  printf '\033[m'

  return "$2"
}

urchin_molly_guard() {
  {
    echo
    echo 'The name of the directory on which you are running urchin'
    echo 'does not contain the word "test", so I am not running,'
    echo 'in case that was an accident. Use the -f flag if you really'
    echo 'want to run urchin on that directory.'
    echo
  } >&2
  exit 1
}

shell_for_sh_tests=
force=false
while [ $# -gt 0 ]
do
    case "$1" in
        -f) force=true;;
        -s)
          shift
          shell_for_sh_tests=$1
          which "$shell_for_sh_tests" >/dev/null || { echo "Cannot find specified shell: '$shell_for_sh_tests'" >&2; urchin_help >&2; exit 2; }
          ;;
        -x) # [EXPERIMENTAL; UNDOCUMENTED FOR NOW] `urchin -x <test-script>` in a test script's shebang line is equivalent to invoking that script with `"$TEST_SHELL" <test-script>`
          shift
          urchinsh=${TEST_SHELL:-/bin/sh}
          "$urchinsh" "$@"
          exit $?;;
        -h|--help) urchin_help
          exit 0;;
        -*) urchin_help >&2
            exit 1;;
        *)  break;;
    esac
    shift
done

# Verify argument for main stuff
if [ "$#" != '1' ] || [ ! -d "$1" ]
  then
  [ -n "$1" ] && [ ! -d "$1" ] && echo "Not a directory: '$1'" >&2
  echo "$USAGE" >&2
  exit 2
fi

# Constants
logfile=$(fullpath "$1")/.urchin.log
stdout_file=$(fullpath "$1")/.urchin_stdout

# Run or present the Molly guard.
if basename "$(fullpath "$1")" | grep -Fi 'test' > /dev/null || $force
  then
  urchin_go "$1" "$shell_for_sh_tests"
else
  urchin_molly_guard
fi
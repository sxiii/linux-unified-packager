#!/bin/bash
# Minimal, dependency-free test harness (no bats/shunit2 needed).
# Usage: source this file, define tests, call run_test "name" test_fn, then finish_tests.

TESTS_RUN=0
TESTS_FAILED=0
CURRENT_TEST=""
FAILED_TESTS=()

SCRIPT_UNDER_TEST="${SCRIPT_UNDER_TEST:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/makealias.sh}"

fail() {
  echo "    FAIL: $1"
  TEST_OK=0
}

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-values differ}"
  if [ "$expected" != "$actual" ]; then
    fail "$msg
      expected: '$expected'
      actual:   '$actual'"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-substring not found}"
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "$msg
      expected to contain: '$needle'
      in:                  '$haystack'" ;;
  esac
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-unexpected substring}"
  case "$haystack" in
    *"$needle"*) fail "$msg
      unexpected: '$needle'
      in:         '$haystack'" ;;
  esac
}

assert_file_exists() {
  [ -f "$1" ] || fail "${2:-expected file to exist: $1}"
}

assert_file_missing() {
  [ ! -e "$1" ] || fail "${2:-expected file to be absent: $1}"
}

run_test() {
  local name="$1" fn="$2"
  CURRENT_TEST="$name"
  TESTS_RUN=$((TESTS_RUN + 1))
  TEST_OK=1
  echo "  - $name"
  # Each test gets its own fake HOME so the real environment is never touched.
  TEST_HOME="$(mktemp -d)"
  "$fn"
  rm -rf "$TEST_HOME"
  if [ "$TEST_OK" != "1" ]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$name")
  fi
}

finish_tests() {
  echo
  echo "ran $TESTS_RUN test(s), $TESTS_FAILED failed"
  if [ "$TESTS_FAILED" -ne 0 ]; then
    printf 'failed: %s\n' "${FAILED_TESTS[@]}"
    exit 1
  fi
  exit 0
}

# --- helpers specific to makealias.sh ------------------------------------------

# One placeholder command per alias, in the order mkaliases expects them.
SAMPLE_CMDS=(c-i c-ii c-r c-up c-ug c-s c-li c-rl c-ra c-rr)

# Source the script (functions only, main() is not executed) inside the caller's
# shell with HOME pointed at the test sandbox.
load_script() {
  HOME="$TEST_HOME"
  # shellcheck source=/dev/null
  source "$SCRIPT_UNDER_TEST"
  afile="$HOME/.bash_aliases"
}

# Run a package-manager function in a subshell, printing its stdout.
run_pm_function() {
  local fn="$1"
  (
    load_script >/dev/null
    "$fn" 2>&1
  )
}

# Generate the aliases file for one package-manager function and print the file.
aliases_for() {
  local fn="$1"
  (
    load_script >/dev/null
    "$fn" >/dev/null 2>&1
    cat "$HOME/.bash_aliases"
  )
}

# Generate an aliases file from SAMPLE_CMDS and print it.
sample_aliases() {
  (
    load_script >/dev/null
    mkaliases "${SAMPLE_CMDS[@]}" >/dev/null
    cat "$HOME/.bash_aliases"
  )
}

# Print the command of a single alias, e.g. alias_value "$file_contents" i
alias_value() {
  local contents="$1" name="$2"
  printf '%s\n' "$contents" | sed -n "s/^alias $name=\"\(.*\)\"$/\1/p"
}

# Names of all f<package-manager> functions defined in the script source.
pm_functions() {
  sed -n -e 's/^function \(f[a-z0-9.-]*\) .*/\1/p' \
         -e 's/^\(f[a-z0-9.-]*\)() .*/\1/p' "$SCRIPT_UNDER_TEST" | sort
}

# The checkarray list from the script.
pm_names() {
  (
    load_script >/dev/null
    printf '%s\n' "${checkarray[@]}" | sort
  )
}

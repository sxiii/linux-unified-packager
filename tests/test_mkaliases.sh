#!/bin/bash
# Unit tests for the alias-writing core of makealias.sh (mkaliases) and for
# sourcing safety.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=tests/lib.sh
source ./lib.sh

echo "tests/test_mkaliases.sh"

test_script_has_valid_syntax() {
  local out
  if ! out="$(bash -n "$SCRIPT_UNDER_TEST" 2>&1)"; then
    fail "makealias.sh is not valid bash: $out"
  fi
}

test_sourcing_does_not_touch_home() {
  (
    load_script >/dev/null
    rm -f "$HOME/.bash_aliases"
  )
  assert_file_missing "$TEST_HOME/.bash_aliases" \
    "sourcing the script must not create ~/.bash_aliases"
  assert_file_missing "$TEST_HOME/.bashrc" \
    "sourcing the script must not create ~/.bashrc"
}

test_sourcing_does_not_run_detection() {
  local out
  out="$( (load_script) 2>&1 )"
  assert_not_contains "$out" "Aliases added" \
    "sourcing the script must not execute main()"
  assert_not_contains "$out" "You're using" \
    "sourcing the script must not run package manager detection"
}

test_mkaliases_writes_all_documented_aliases() {
  local contents name
  contents="$(
    load_script >/dev/null
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  for name in i ii r up ug s li rl ra rr lsb; do
    assert_contains "$contents" "alias $name=" "alias '$name' is missing"
  done
  assert_eq 11 "$(printf '%s\n' "$contents" | grep -c '^alias ')" \
    "mkaliases should write exactly 11 aliases"
}

test_mkaliases_maps_positional_arguments_in_order() {
  local contents
  contents="$(
    load_script >/dev/null
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_eq "sudo a1 a2"   "$(alias_value "$contents" i)"  "alias i uses \$1 \$2"
  assert_eq "sudo a3 a4"   "$(alias_value "$contents" ii)" "alias ii uses \$3 \$4"
  assert_eq "sudo a5 a6"   "$(alias_value "$contents" r)"  "alias r uses \$5 \$6"
  assert_eq "sudo a7 a8"   "$(alias_value "$contents" up)" "alias up uses \$7 \$8"
  assert_eq "sudo a9 a10"  "$(alias_value "$contents" ug)" "alias ug uses \$9 \$10"
  assert_eq "sudo a11 a12" "$(alias_value "$contents" s)"  "alias s uses \$11 \$12"
  assert_eq "sudo a13 a14" "$(alias_value "$contents" li)" "alias li uses \$13 \$14"
  assert_eq "sudo a15 a16" "$(alias_value "$contents" rl)" "alias rl uses \$15 \$16"
  assert_eq "sudo a17 a18" "$(alias_value "$contents" ra)" "alias ra uses \$17 \$18"
  assert_eq "sudo a19 a20" "$(alias_value "$contents" rr)" "alias rr uses \$19 \$20"
}

test_lsb_alias_is_independent_of_package_manager() {
  local contents
  contents="$(
    load_script >/dev/null
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_eq 'echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*' \
    "$(alias_value "$contents" lsb)" "alias lsb content changed"
}

test_mkaliases_respects_empty_sudo_override() {
  local contents
  contents="$(
    load_script >/dev/null
    sn=''
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_contains "$(alias_value "$contents" i)" "a1 a2" \
    "clearing \$sn should keep the package manager command"
  assert_not_contains "$contents" "sudo" "no alias should mention sudo when \$sn is empty"
}

test_first_call_resets_the_file_and_later_calls_append() {
  local contents
  contents="$(
    load_script >/dev/null
    echo "# pre-existing" > "$HOME/.bash_aliases"
    exec 2>/dev/null # the backup warning is asserted elsewhere
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    mkaliases b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 b16 b17 b18 b19 b20 >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_not_contains "$contents" "# pre-existing" \
    "the first mkaliases call should reset the aliases file"
  assert_eq 22 "$(printf '%s\n' "$contents" | grep -c '^alias ')" \
    "later calls should append their aliases"
  assert_eq 1 "$(printf '%s\n' "$contents" | grep -c '^__lup_unsupported() {')" \
    "the file should only be reset once"
}

test_debug_mode_prints_instead_of_writing() {
  local out contents
  out="$(
    load_script >/dev/null
    rm -f "$HOME/.bash_aliases"
    debug='yes'
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 2>&1
  )"
  assert_contains "$out" 'alias i="sudo a1 a2"' "debug mode should print the aliases"
  assert_file_missing "$TEST_HOME/.bash_aliases" \
    "debug mode must not write the aliases file"
}

test_mkaliases_rejects_a_wrong_argument_count() {
  local out status
  out="$(
    load_script >/dev/null
    mkaliases a1 a2 a3 2>&1
  )"
  status=$?
  assert_contains "$out" "mkaliases needs 20 arguments (got 3)" \
    "a dropped argument must be reported"
  if [ "$status" -eq 0 ]; then
    fail "mkaliases should fail on a wrong argument count"
  fi
}

test_unsupported_operations_become_failing_stubs() {
  local contents
  contents="$(
    load_script >/dev/null
    mkaliases a1 a2 "$unsup" '' a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 '' '' >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_contains "$contents" '__lup_unsupported() {' \
    "the unsupported-operation helper should be defined"
  assert_eq "__lup_unsupported ii" "$(alias_value "$contents" ii)" \
    "an unsupported operation should not run a package manager"
  assert_eq "__lup_unsupported rr" "$(alias_value "$contents" rr)" \
    "an empty command should also become a stub"
  assert_eq "sudo a1 a2" "$(alias_value "$contents" i)" \
    "supported operations should be unaffected"
}

test_generated_aliases_file_is_sourceable() {
  local out
  out="$(
    load_script >/dev/null
    mkaliases a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20 >/dev/null
    bash -n "$HOME/.bash_aliases" 2>&1
  )"
  assert_eq "" "$out" "generated aliases file must be valid bash"
}

run_test "makealias.sh has valid bash syntax" test_script_has_valid_syntax
run_test "debug mode prints aliases instead of writing them" test_debug_mode_prints_instead_of_writing
run_test "mkaliases rejects a wrong argument count" test_mkaliases_rejects_a_wrong_argument_count
run_test "unsupported operations become failing stubs" test_unsupported_operations_become_failing_stubs
run_test "sourcing the script does not touch \$HOME" test_sourcing_does_not_touch_home
run_test "sourcing the script does not run detection" test_sourcing_does_not_run_detection
run_test "mkaliases writes all 11 documented aliases" test_mkaliases_writes_all_documented_aliases
run_test "mkaliases maps its 20 positional arguments in order" test_mkaliases_maps_positional_arguments_in_order
run_test "lsb alias content is fixed" test_lsb_alias_is_independent_of_package_manager
run_test "mkaliases respects an empty \$sn" test_mkaliases_respects_empty_sudo_override
run_test "first call resets the aliases file, later calls append" test_first_call_resets_the_file_and_later_calls_append
run_test "generated aliases file is valid bash" test_generated_aliases_file_is_sourceable

finish_tests

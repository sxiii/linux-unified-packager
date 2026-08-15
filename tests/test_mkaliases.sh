#!/bin/bash
# Unit tests for the alias-writing core of makealias.sh (mkalias/mkaliases) and
# for sourcing safety.
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

test_script_runs_without_unbound_variables() {
  local out
  out="$( (load_script) 2>&1 )"
  assert_not_contains "$out" "unbound variable" \
    "the script must not reference undefined variables under 'set -u'"
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
  contents="$(sample_aliases)"
  for name in i ii r up ug s li rl ra rr lsb; do
    assert_contains "$contents" "alias $name=" "alias '$name' is missing"
  done
  assert_eq 11 "$(printf '%s\n' "$contents" | grep -c '^alias ')" \
    "mkaliases should write exactly 11 aliases"
}

test_mkaliases_maps_its_arguments_in_order() {
  local contents name i=0
  contents="$(sample_aliases)"
  for name in i ii r up ug s li rl ra rr; do
    assert_eq "sudo ${SAMPLE_CMDS[$i]}" "$(alias_value "$contents" "$name")" \
      "alias $name should use argument $((i + 1))"
    i=$((i + 1))
  done
}

test_lsb_alias_is_independent_of_package_manager() {
  local contents
  contents="$(sample_aliases)"
  assert_eq 'echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*' \
    "$(alias_value "$contents" lsb)" "alias lsb content changed"
}

test_mkaliases_respects_empty_sudo_override() {
  local contents
  contents="$(
    load_script >/dev/null
    sn=''
    mkaliases "${SAMPLE_CMDS[@]}" >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_contains "$(alias_value "$contents" i)" "${SAMPLE_CMDS[0]}" \
    "clearing \$sn should keep the package manager command"
  assert_not_contains "$contents" "sudo" "no alias should mention sudo when \$sn is empty"
}

test_first_call_resets_the_file_and_later_calls_append() {
  local contents
  contents="$(
    load_script >/dev/null
    echo "# pre-existing" > "$HOME/.bash_aliases"
    exec 2>/dev/null # the backup warning is asserted elsewhere
    mkaliases "${SAMPLE_CMDS[@]}" >/dev/null
    mkaliases "${SAMPLE_CMDS[@]}" >/dev/null
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
  local out
  out="$(
    load_script >/dev/null
    rm -f "$HOME/.bash_aliases"
    debug='yes'
    mkaliases "${SAMPLE_CMDS[@]}" 2>&1
  )"
  assert_contains "$out" "alias i=\"sudo ${SAMPLE_CMDS[0]}\"" \
    "debug mode should print the aliases"
  assert_contains "$out" 'alias lsb="echo /etc/*_ver*' \
    "debug mode should also print the lsb alias"
  assert_file_missing "$TEST_HOME/.bash_aliases" \
    "debug mode must not write the aliases file"
}

test_mkaliases_rejects_a_wrong_argument_count() {
  local out status
  out="$(
    load_script >/dev/null
    mkaliases c1 c2 c3 2>&1
  )"
  status=$?
  assert_contains "$out" "mkaliases needs 10 commands (got 3)" \
    "a dropped argument must be reported"
  if [ "$status" -eq 0 ]; then
    fail "mkaliases should fail on a wrong argument count"
  fi
}

test_unsupported_operations_become_failing_stubs() {
  local contents
  contents="$(
    load_script >/dev/null
    mkaliases c-i "$unsup" c-r c-up c-ug c-s c-li c-rl c-ra '' >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_contains "$contents" '__lup_unsupported() {' \
    "the unsupported-operation helper should be defined"
  assert_eq "__lup_unsupported ii" "$(alias_value "$contents" ii)" \
    "an unsupported operation should not run a package manager"
  assert_eq "__lup_unsupported rr" "$(alias_value "$contents" rr)" \
    "an empty command should also become a stub"
  assert_eq "sudo c-i" "$(alias_value "$contents" i)" \
    "supported operations should be unaffected"
}

test_repository_helpers_produce_single_sudo_commands() {
  local contents
  contents="$(
    load_script >/dev/null
    mkaliases c-i c-ii c-r c-up c-ug c-s c-li \
      "$(show_conf /etc/pm.conf)" "$(edit_conf /etc/pm.conf)" \
      "$(list_dir /etc/pm.d/)" >/dev/null
    cat "$HOME/.bash_aliases"
  )"
  assert_eq "sudo cat /etc/pm.conf" "$(alias_value "$contents" rl)" \
    "show_conf should print a configuration file"
  assert_eq "sudo nano /etc/pm.conf" "$(alias_value "$contents" ra)" \
    "edit_conf should open the editor exactly once, with one sudo"
  assert_eq "sudo ls /etc/pm.d/" "$(alias_value "$contents" rr)" \
    "list_dir should list a configuration directory"
}

test_generated_aliases_file_is_sourceable() {
  local out
  out="$(
    load_script >/dev/null
    mkaliases "${SAMPLE_CMDS[@]}" >/dev/null
    bash -n "$HOME/.bash_aliases" 2>&1
  )"
  assert_eq "" "$out" "generated aliases file must be valid bash"
}

run_test "makealias.sh has valid bash syntax" test_script_has_valid_syntax
run_test "makealias.sh has no unbound variables" test_script_runs_without_unbound_variables
run_test "debug mode prints aliases instead of writing them" test_debug_mode_prints_instead_of_writing
run_test "mkaliases rejects a wrong argument count" test_mkaliases_rejects_a_wrong_argument_count
run_test "unsupported operations become failing stubs" test_unsupported_operations_become_failing_stubs
run_test "repository helpers produce a single sudo command" test_repository_helpers_produce_single_sudo_commands
run_test "sourcing the script does not touch \$HOME" test_sourcing_does_not_touch_home
run_test "sourcing the script does not run detection" test_sourcing_does_not_run_detection
run_test "mkaliases writes all 11 documented aliases" test_mkaliases_writes_all_documented_aliases
run_test "mkaliases maps its 10 commands in order" test_mkaliases_maps_its_arguments_in_order
run_test "lsb alias content is fixed" test_lsb_alias_is_independent_of_package_manager
run_test "mkaliases respects an empty \$sn" test_mkaliases_respects_empty_sudo_override
run_test "first call resets the aliases file, later calls append" test_first_call_resets_the_file_and_later_calls_append
run_test "generated aliases file is valid bash" test_generated_aliases_file_is_sourceable

finish_tests

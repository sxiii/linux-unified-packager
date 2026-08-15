#!/bin/bash
# Tests for main(): package manager detection and the files it writes.
# The script is executed with a stubbed PATH so that only fake package managers
# are "installed" and nothing real is ever invoked.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=tests/lib.sh
source ./lib.sh

echo "tests/test_main.sh"

# Build a PATH containing only the coreutils the script needs plus the given
# fake package managers.
make_stub_path() {
  local bin="$TEST_HOME/bin" tool pm
  mkdir -p "$bin"
  for tool in rm touch mv date grep cat; do
    ln -sf "$(command -v "$tool")" "$bin/$tool"
  done
  for pm in "$@"; do
    printf '#!/bin/sh\nexit 0\n' > "$bin/$pm"
    chmod +x "$bin/$pm"
  done
  printf '%s' "$bin"
}

# Run makealias.sh with the sandboxed HOME and stubbed PATH; prints its output.
run_script_with_managers() {
  local bin; bin="$(make_stub_path "$@")"
  env -i HOME="$TEST_HOME" PATH="$bin" /bin/bash "$SCRIPT_UNDER_TEST" 2>&1
}

test_detects_installed_manager_only() {
  local out contents
  out="$(run_script_with_managers pacman)"
  assert_contains "$out" "You're using pacman on Arch/Manjaro" "pacman should be detected"
  assert_contains "$out" "Aliases added" "final message should be printed"
  assert_not_contains "$out" "apt-get" "absent managers must not be configured"

  contents="$(cat "$TEST_HOME/.bash_aliases")"
  assert_eq "sudo pacman -S" "$(alias_value "$contents" i)" "install alias for pacman"
  assert_eq 11 "$(printf '%s\n' "$contents" | grep -c '^alias ')" "one alias set expected"
}

test_no_manager_installed_is_an_error() {
  local bin out status
  bin="$(make_stub_path)"
  out="$(env -i HOME="$TEST_HOME" PATH="$bin" /bin/bash "$SCRIPT_UNDER_TEST" 2>&1)"
  status=$?
  assert_eq 1 "$status" "script should fail when no package manager is found"
  assert_contains "$out" "none of the supported package managers" \
    "the failure should be explained"
  assert_not_contains "$out" "Aliases added" "success message must not be printed"
  assert_file_missing "$TEST_HOME/.bash_aliases" "no aliases file should be written"
  assert_file_missing "$TEST_HOME/.bashrc" ".bashrc must not be touched"
}

test_multiple_managers_are_all_configured() {
  local out contents
  out="$(run_script_with_managers pacman apk)"
  assert_contains "$out" "You're using pacman on" "pacman should be detected"
  assert_contains "$out" "You're using apk on" "apk should be detected"
  assert_contains "$out" "2 package managers were found" \
    "the ambiguity should be reported"
  contents="$(cat "$TEST_HOME/.bash_aliases")"
  assert_eq 22 "$(printf '%s\n' "$contents" | grep -c '^alias ')" "two alias sets expected"
}

test_stale_aliases_are_replaced_and_backed_up() {
  local contents out backups
  echo 'alias i="stale command"' > "$TEST_HOME/.bash_aliases"
  out="$(run_script_with_managers pacman)"
  contents="$(cat "$TEST_HOME/.bash_aliases")"
  assert_not_contains "$contents" "stale command" "old aliases file must be recreated"
  assert_contains "$out" "previous version saved to" "the backup should be reported"

  backups=("$TEST_HOME"/.bash_aliases.backup-*)
  assert_eq 1 "${#backups[@]}" "exactly one backup should be created"
  assert_contains "$(cat "${backups[0]}")" "stale command" "backup must hold the old aliases"
}

test_no_backup_when_no_aliases_file() {
  local out
  out="$(run_script_with_managers pacman)"
  assert_not_contains "$out" "previous version saved" "nothing to back up on a first run"
  assert_eq "" "$(ls "$TEST_HOME" | grep '^.bash_aliases.backup' || true)" "no backup expected"
}

test_bashrc_sources_the_aliases_file() {
  run_script_with_managers pacman >/dev/null
  assert_file_exists "$TEST_HOME/.bashrc" ".bashrc should be created"
  assert_contains "$(cat "$TEST_HOME/.bashrc")" 'source ~/.bash_aliases' \
    ".bashrc should source the aliases file"
}

test_bashrc_source_line_is_added_only_once() {
  local out
  run_script_with_managers pacman >/dev/null
  out="$(run_script_with_managers pacman)"
  assert_eq 1 "$(grep -cxF 'source ~/.bash_aliases' "$TEST_HOME/.bashrc")" \
    "repeated runs must not duplicate the .bashrc source line"
  assert_contains "$out" "already sources" "the skipped edit should be reported"
}

test_debug_run_changes_nothing() {
  local bin out
  bin="$(make_stub_path pacman)"
  out="$(env -i HOME="$TEST_HOME" PATH="$bin" /bin/bash -c \
    "debug=yes; source '$SCRIPT_UNDER_TEST'; debug=yes; main" 2>&1)"
  assert_contains "$out" 'alias i="sudo pacman -S"' "debug run should print the aliases"
  assert_contains "$out" 'source ~/.bash_aliases' "debug run should print the .bashrc line"
  assert_file_missing "$TEST_HOME/.bash_aliases" "debug run must not write the aliases file"
  assert_file_missing "$TEST_HOME/.bashrc" "debug run must not touch .bashrc"
}

test_existing_bashrc_is_preserved() {
  echo '# my settings' > "$TEST_HOME/.bashrc"
  run_script_with_managers pacman >/dev/null
  assert_contains "$(cat "$TEST_HOME/.bashrc")" '# my settings' \
    "existing .bashrc content must not be lost"
}

test_exit_status_is_success() {
  local bin; bin="$(make_stub_path pacman)"
  if ! env -i HOME="$TEST_HOME" PATH="$bin" /bin/bash "$SCRIPT_UNDER_TEST" >/dev/null 2>&1; then
    fail "script should exit 0"
  fi
}

run_test "detects only installed package managers" test_detects_installed_manager_only
run_test "fails when no known package manager is installed" test_no_manager_installed_is_an_error
run_test "configures every installed package manager" test_multiple_managers_are_all_configured
run_test "backs up and recreates a stale aliases file" test_stale_aliases_are_replaced_and_backed_up
run_test "no backup is made on a first run" test_no_backup_when_no_aliases_file
run_test ".bashrc sources the aliases file" test_bashrc_sources_the_aliases_file
run_test ".bashrc source line is added only once" test_bashrc_source_line_is_added_only_once
run_test "debug mode changes no files" test_debug_run_changes_nothing
run_test "existing .bashrc content is preserved" test_existing_bashrc_is_preserved
run_test "script exits successfully" test_exit_status_is_success

finish_tests

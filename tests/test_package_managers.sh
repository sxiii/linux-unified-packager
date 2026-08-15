#!/bin/bash
# Unit tests for the per-package-manager functions of makealias.sh.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=tests/lib.sh
source ./lib.sh

echo "tests/test_package_managers.sh"

ALIAS_NAMES=(i ii r up ug s li rl ra rr lsb)

# Every package manager listed in checkarray must have a function, and vice versa.
test_checkarray_matches_functions() {
  local names functions expected
  names="$(pm_names)"
  functions="$(pm_functions)"
  expected="$(printf '%s\n' "$names" | sed 's/^/f/' | sort)"
  assert_eq "$expected" "$functions" \
    "checkarray entries and f<manager> functions are out of sync"
}

test_checkarray_has_no_duplicates() {
  local names
  names="$(pm_names)"
  assert_eq "$(printf '%s\n' "$names" | wc -l)" "$(printf '%s\n' "$names" | uniq | wc -l)" \
    "checkarray contains duplicate package managers"
}

test_readme_claim_of_twenty_managers() {
  assert_eq 20 "$(pm_names | wc -l)" "expected 20 supported package managers"
}

# Invariants that must hold for every single package manager function.
test_every_function_reports_its_own_manager() {
  local pm out
  while read -r pm; do
    out="$(run_pm_function "f$pm")"
    assert_contains "$out" "You're using $pm on" \
      "f$pm should announce the '$pm' package manager"
  done < <(pm_names)
}

test_every_function_writes_the_full_alias_set() {
  local pm contents name count
  while read -r pm; do
    contents="$(aliases_for "f$pm")"
    count="$(printf '%s\n' "$contents" | grep -c '^alias ')"
    assert_eq 11 "$count" "f$pm should write 11 aliases"
    for name in "${ALIAS_NAMES[@]}"; do
      assert_contains "$contents" "alias $name=" "f$pm is missing alias '$name'"
    done
  done < <(pm_names)
}

test_every_function_produces_sourceable_aliases() {
  local pm out
  while read -r pm; do
    out="$(
      HOME="$TEST_HOME"
      # shellcheck source=/dev/null
      source "$SCRIPT_UNDER_TEST"
      "f$pm" >/dev/null 2>&1
      bash -n "$HOME/.bash_aliases" 2>&1
    )"
    assert_eq "" "$out" "f$pm generated an aliases file that is not valid bash"
  done < <(pm_names)
}

test_no_alias_has_an_empty_command() {
  local pm contents name value
  while read -r pm; do
    contents="$(aliases_for "f$pm")"
    for name in i ii r up ug s li rl ra rr; do
      value="$(alias_value "$contents" "$name")"
      value="${value#sudo}"
      value="${value// /}"
      if [ -z "$value" ]; then
        fail "f$pm produced an empty command for alias '$name' (missing argument?)"
      fi
    done
  done < <(pm_names)
}

# Operations a package manager cannot perform must fail loudly rather than
# quietly running something else.
test_unsupported_operations_fail_when_used() {
  local pm contents out status
  while read -r pm; do
    contents="$(aliases_for "f$pm")"
    printf '%s\n' "$contents" | grep -q '__lup_unsupported ' || continue
    out="$(
      load_script >/dev/null
      "f$pm" >/dev/null 2>&1
      # shellcheck source=/dev/null
      source "$HOME/.bash_aliases"
      __lup_unsupported ii 2>&1
    )"
    status=$?
    assert_contains "$out" "not supported by your package manager" \
      "f$pm: unsupported operations should explain themselves"
    if [ "$status" -eq 0 ]; then
      fail "f$pm: an unsupported operation must not report success"
    fi
  done < <(pm_names)
}

# Exact expectations for a representative subset, one per package manager family.
assert_alias_set() {
  local fn="$1"; shift
  local contents; contents="$(aliases_for "$fn")"
  local pair name expected
  for pair in "$@"; do
    name="${pair%%=*}"
    expected="${pair#*=}"
    assert_eq "$expected" "$(alias_value "$contents" "$name")" "$fn: alias '$name'"
  done
}

test_apt_get_aliases() {
  assert_alias_set fapt-get \
    'i=sudo apt-get install' \
    'ii=sudo dpkg -i' \
    'r=sudo apt-get remove' \
    'up=sudo apt-get update' \
    'ug=sudo apt-get upgrade' \
    's=sudo apt-cache search' \
    'li=sudo dpkg -l' \
    'rl=sudo cat /etc/apt/sources.list' \
    'rr=sudo apt-add-repository -r'
}

test_pacman_aliases() {
  assert_alias_set fpacman \
    'i=sudo pacman -S' \
    'ii=sudo pacman -U' \
    'r=sudo pacman -R' \
    'up=sudo pacman -Sy' \
    'ug=sudo pacman -Su' \
    's=sudo pacman -Ss' \
    'li=sudo pacman -Q' \
    'rl=sudo cat /etc/pacman.conf' \
    'ra=sudo nano /etc/pacman.conf' \
    'rr=sudo nano /etc/pacman.conf'
}

test_zypper_aliases() {
  assert_alias_set fzypper \
    'i=sudo zypper install' \
    'ii=sudo zypper install' \
    'r=sudo zypper remove' \
    'up=sudo zypper refresh' \
    'ug=sudo zypper update' \
    's=sudo zypper search' \
    'li=sudo zypper search -is' \
    'rl=sudo zypper repos' \
    'ra=sudo zypper addrepo' \
    'rr=sudo zypper removerepo'
}

test_yum_aliases() {
  assert_alias_set fyum \
    'i=sudo yum install' \
    'ii=sudo yum localinstall' \
    'r=sudo yum erase' \
    'up=sudo yum check-update' \
    'ug=sudo yum update' \
    's=sudo yum list' \
    'li=sudo rpm -qa' \
    'rl=sudo yum repolist' \
    'ra=sudo cd /etc/yum.repos.d/ && ls'
}

test_apk_aliases() {
  assert_alias_set fapk \
    'i=sudo apk add' \
    'ii=sudo apk add --force' \
    'r=sudo apk del' \
    'up=sudo apk update' \
    'ug=sudo apk upgrade' \
    's=sudo apk search' \
    'li=sudo apk info' \
    'rl=sudo cat /etc/apk/repositories' \
    'rr=sudo nano /etc/apk/repositories'
}

test_emerge_aliases() {
  assert_alias_set femerge \
    'r=sudo emerge -aC' \
    'up=sudo emerge --sync' \
    'ug=sudo emerge -NuDa world' \
    's=sudo emerge --search' \
    'li=sudo qlist -I' \
    'rl=sudo layman -L' \
    'ra=sudo layman -a' \
    'rr=sudo layman -d' \
    'ii=__lup_unsupported ii'
}

test_nix_env_aliases() {
  assert_alias_set fnix-env \
    'i=sudo nix-env -i' \
    'r=sudo nix-env -e' \
    'up=sudo nix-channel --update' \
    'ug=sudo nix-env -u' \
    's=sudo nix-env -qa' \
    'li=sudo nix-env -q' \
    'rl=sudo nix-channel --list' \
    'ra=sudo nix-channel --add' \
    'rr=sudo nix-channel --remove'
}

test_pkg_aliases() {
  assert_alias_set fpkg \
    'i=sudo pkg install' \
    'ii=sudo pkg add' \
    'r=sudo pkg remove' \
    'up=sudo pkg update' \
    'ug=sudo pkg upgrade' \
    's=sudo pkg search' \
    'li=sudo pkg info' \
    'rl=__lup_unsupported rl'
}

test_cast_aliases() {
  assert_alias_set fcast \
    'r=sudo dispel ' \
    'up=sudo scribe update' \
    'ug=sudo sorcery upgrade' \
    's=sudo gaze search' \
    'li=sudo gaze installed' \
    'rl=sudo scribe index' \
    'ra=sudo scribe add' \
    'rr=sudo scribe remove'
}

run_test "checkarray and f<manager> functions are in sync" test_checkarray_matches_functions
run_test "checkarray has no duplicates" test_checkarray_has_no_duplicates
run_test "20 package managers are supported" test_readme_claim_of_twenty_managers
run_test "every function announces its own package manager" test_every_function_reports_its_own_manager
run_test "every function writes the full alias set" test_every_function_writes_the_full_alias_set
run_test "every function produces a sourceable aliases file" test_every_function_produces_sourceable_aliases
run_test "no generated alias has an empty command" test_no_alias_has_an_empty_command
run_test "unsupported operations fail when used" test_unsupported_operations_fail_when_used
run_test "apt-get aliases" test_apt_get_aliases
run_test "pacman aliases" test_pacman_aliases
run_test "zypper aliases" test_zypper_aliases
run_test "yum aliases" test_yum_aliases
run_test "apk aliases" test_apk_aliases
run_test "emerge aliases" test_emerge_aliases
run_test "nix-env aliases" test_nix_env_aliases
run_test "pkg aliases" test_pkg_aliases
run_test "cast aliases" test_cast_aliases

finish_tests

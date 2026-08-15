#!/bin/bash
###############################################################################
# Universal Multi-Distro Mostly Used Aliases Script ###########################
########################################## More than 20 pkg managers supported!
# What is this script for? It creates aliases that can be used as simple as:
# i = install package, up = update repos, ug = upgrade sytem, r = remove, etc.
# This scripts works with any distro (it knows more than 20 package managers).
# It also adds "lsb" command which shows you info about your distro & packages.
# And you don't have to look which actual package manager your system uses.
###############################################################################
# Based on package management article from distrowatch which is here:
# http://distrowatch.com/package-management
###############################################################################
# This script was written in the idea of uniting several package management
# system into one single command that can be issued easily.
# This script DOES NOT detect your distros because it is not so important
# while we just want to see if you have any package managers installed.
# That wouldn't be a problem because small amount of people uses more than one
# package managers (guys you will have to fix this script in this case)
# ################## Currently supported package managers #####################
# Main distributions: Ubuntu, Debian (apt-get), OpenSUSE (zypper),
# Fedora, CentOS, RedHat (yum/dnf), Mandriva, Mageia (urpmi).
# Slackware distros: Slackware (slackpkg), Vector (slapt-get), Zenwalk (netpkg),
# Independent distros: Sabayon (equo), Arch/Manjaro (pacman),
# Foresight, rPath (conary), Alpine (apk).
# Multi-distro (distro-agnostic) package managers: Mandria, OpenSUSE (smart),
# Fedora, Ubuntu, openSUSE, Mandriva (pkcon).
# Source package managers: Gentoo (emerge), Lunar (lin), Source Mage (cast),
# New, binary pac.-man. systems: NixOS (nix), Void (xbps), Ubuntu (snappy).
# FreeBSD: 10.0+ (pkg).
# Totally this script supports 6 categories of package managers, 20+ pcs.
###############################################################################
# Written by Security XIII at Gmail Dot Com.
# v 0.05 alpha, has to check it on many distros ! but probably usable somehow #
###############################################################################
set -u -o pipefail

progname="${0##*/}"

# Reports a fatal problem and stops the script
die() {
  echo "$progname: error: $*" >&2
  exit 1
}

# Reports a problem the user should know about, without stopping the script
warn() {
  echo "$progname: warning: $*" >&2
}

# Bash aliases file this script generates
afile="$HOME/.bash_aliases"
# Shell startup file which sources the aliases file
bashrc="$HOME/.bashrc"
# Line added to the shell startup file
rcline='source ~/.bash_aliases'
# If your distro/user doesen't need sudo just comment the following line:
sn='sudo'
# Choose your editor (to open mirror files)
ed='nano'
# Distro founded
df="You're using"
# Set debug="yes" to turn on debug mode (prints aliases, makes no syschanges)
debug=""
# Marker for operations a package manager does not support
unsup='__lup_unsupported'

# Keeps a copy of an existing aliases file before it gets overwritten
backup_afile() {
  local backup
  [ -e "$afile" ] || return 0
  backup="$afile.backup-$(date +%Y%m%d%H%M%S)"
  mv -- "$afile" "$backup" || die "cannot back up existing '$afile' to '$backup'"
  warn "existing '$afile' was replaced, previous version saved to '$backup'"
}

# Re-creates empty bash aliases file for you (fix if needed)
resetdone=""
resetaliases() {
  [ -n "$debug" ] && return 0
  [ -z "$resetdone" ] || return 0
  resetdone="yes"
  backup_afile
  : > "$afile" || die "cannot write to '$afile'"
  # Aliases for operations the package manager cannot do fail loudly instead of
  # pretending the operation succeeded.
  cat >> "$afile" <<EOF || die "cannot write to '$afile'"
$unsup() {
  echo "\$1: this operation is not supported by your package manager" >&2
  return 1
}
EOF
}

# Writes a single alias, or an unsupported-operation stub when no command exists
mkalias() {
  local name="$1" cmd="$2" line
  if [ "$cmd" = "$unsup" ] || [ -z "$cmd" ]; then
    line="alias $name=\"$unsup $name\""
  else
    line="alias $name=\"$sn $cmd\""
  fi
  if [ -n "$debug" ]; then
    echo "$line"
  else
    echo "$line" >> "$afile" || die "cannot write alias '$name' to '$afile'"
  fi
}

# Aliases created by this script, in the order mkaliases expects its arguments:
# i   installing packages (from repo)     ug  upgrading packages (themselves)
# ii  installing packages (from file)     s   searching packages
# r   removing packages                   li  list installed packages
# up  updating packages (list)            rl  list your repositories
# ra  add new repository or PPA           rr  removes repository or PPA
alias_names=(i ii r up ug s li rl ra rr)

# Takes one command per alias, in the order of alias_names above
mkaliases() {
  local name lsb
  [ "$#" -eq "${#alias_names[@]}" ] ||
    die "mkaliases needs ${#alias_names[@]} commands (got $#) for package manager '${s:-unknown}'"
  shopt -s expand_aliases
  resetaliases
  for name in "${alias_names[@]}"; do
    mkalias "$name" "$1"; shift
  done
  lsb='echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*' # info
  if [ -n "$debug" ]; then
    echo "alias lsb=\"$lsb\""
  else
    echo "alias lsb=\"$lsb\"" >> "$afile" || die "cannot write alias 'lsb' to '$afile'"
    # shellcheck source=/dev/null
    source "$afile" || warn "'$afile' was written but could not be sourced"
  fi
}

# Shared building blocks for the package manager commands below
show_conf() { echo "cat $1"; }     # print a configuration file
edit_conf() { echo "$ed $1"; }     # open a configuration file in the editor
list_dir() { echo "ls $1"; }       # list a repository configuration directory

# Reports the detected package manager and exports its name as $s
pm() { s="$1"; echo "$df $s on $2"; }

# Command to check existence of package manager (can also be command or type)
checkcmd='hash'

# To add your own package manager, write function for it similar to
# the following functions, adding "f" letter in the front of package
# manager name, and add it to the end of checkarray list.
# Example: your package manager is "zeta", write function with the name
# "fzeta" similar to others. Last step, add it to the end of 'checkarray' array.
# When writing functions, pass one command per alias to mkaliases, in the same
# order as the alias_names array above (10 arguments, each one quoted).
# Use "$unsup" for operations your package manager cannot do (the resulting
# alias then explains the problem and returns 1 when it is used), and the
# show_conf/edit_conf/list_dir helpers for repository configuration commands.

  # Writing own function help sample
fapt-get() { pm apt-get "Debian/Ubuntu"
  mkaliases "$s install" "dpkg -i" "$s remove" "$s update" "$s upgrade" \
    "apt-cache search" "dpkg -l" "$(show_conf /etc/apt/sources.list)" \
    "apt-add-repository" "apt-add-repository -r"
  # ^i         ^ii        ^r         ^up         ^ug
  # ^s                ^li      ^rl                                  ^ra ^rr
}

fzypper() { pm zypper "OpenSUSE"
  mkaliases "$s install" "$s install" "$s remove" "$s refresh" "$s update" \
    "$s search" "$s search -is" "$s repos" "$s addrepo" "$s removerepo"
}

fyum() { pm yum "Fedora/CentOS"
  mkaliases "$s install" "$s localinstall" "$s erase" "$s check-update" \
    "$s update" "$s list" "rpm -qa" "$s repolist" \
    "$(list_dir /etc/yum.repos.d/)" "$(list_dir /etc/yum.repos.d/)"
}

furpmi() { pm urpmi "Mandriva/Mageia"
  mkaliases "$s" "$s" "urpme" "$s.update -a" "$s --auto-select" \
    "urpmq" "rpm -qa" "urpmq --list-media" "$s.addmedia" "$s.removemedia"
}

fslackpkg() { pm slackpkg "Slackware"
  mkaliases "$s install" "$s install" "$s remove" "$s update" "$s upgrade-all" \
    "$s search" "ls /var/log/packages/" "$(show_conf /etc/slackpkg/mirrors)" \
    "$(edit_conf /etc/slackpkg/mirrors)" "$(edit_conf /etc/slackpkg/mirrors)"
}

fslapt-get() { pm slapt-get "Vector"
  mkaliases "$s --install" "$s --install" "$s --remove" "$s --update" \
    "$s --upgrade" "$s --search" "$s --installed" \
    "$(show_conf /etc/slapt-get/slapt-getrc)" \
    "$(edit_conf /etc/slapt-get/slapt-getrc)" \
    "$(edit_conf /etc/slapt-get/slapt-getrc)"
}

fnetpkg() { pm netpkg "Zenwalk"
  mkaliases "$s" "$s" "$s remove" "$unsup" "$s upgrade" \
    "$s list | grep" "$s list I" "$s mirror" \
    "$(edit_conf /etc/netpkg.conf)" "$(edit_conf /etc/netpkg.conf)"
}

fequo() { pm equo "Sabayon"
  mkaliases "$s install" "$s install" "$s remove" "$s update" "$s upgrade" \
    "$s search" "$s list" "$s repoinfo" \
    "$(list_dir /etc/entropy/repositories.conf.d)" \
    "$(list_dir /etc/entropy/repositories.conf.d)"
}

fpacman() { pm pacman "Arch/Manjaro"
  mkaliases "$s -S" "$s -U" "$s -R" "$s -Sy" "$s -Su" "$s -Ss" "$s -Q" \
    "$(show_conf /etc/pacman.conf)" "$ed /etc/pacman.conf" "$ed /etc/pacman.conf"
}

fconary() { pm conary "Foresight/rPath"
  mkaliases "$s update" "$s update" "$s erase" "$unsup" "$s updateall" \
    "$s query" "$s query" "$unsup" "$unsup" "$unsup"
}

fapk() { pm apk "Alpine"
  mkaliases "$s add" "$s add --force" "$s del" "$s update" "$s upgrade" \
    "$s search" "$s info" "$(show_conf /etc/apk/repositories)" \
    "setup-apkrepos" "$ed /etc/apk/repositories"
}

fsmart() { pm smart "Mandriva/OpenSUSE"
  mkaliases "$s install" "$s install" "$s remove" "$s update" "$s upgrade" \
    "$s search" "$s query --installed" "$s channel --show" \
    "$s channel --add" "$s channel --remove"
}

fpkcon() { pm pkcon "Fedora/Ubuntu/OpenSUSE/Mandriva"
  mkaliases "$s install" "$s install-file" "$s remove" "$s refresh" \
    "$s upgrade" "$s search" "$s search" "$s repo-list" \
    "$unsup" "$unsup"
}

femerge() { pm emerge "Gentoo"
  mkaliases "$s" "$unsup" "$s -aC" "$s --sync" "$s -NuDa world" \
    "$s --search" "qlist -I" "layman -L" "layman -a" "layman -d"
}

flin() { pm lin "Lunar"
  mkaliases "$s" "$unsup" "lrm" "$s moonbase" "lunar update" \
    "lvu search" "lvu installed" "$unsup" "$unsup" "$unsup"
}

fcast() { pm cast "Source Mage"
  mkaliases "$s" "$unsup" "dispel" "scribe update" "sorcery upgrade" \
    "gaze search" "gaze installed" "scribe index" "scribe add" "scribe remove"
}

fnix-env() { pm nix-env "NixOS"
  mkaliases "$s -i" "$unsup" "$s -e" "nix-channel --update" \
    "nix-env -u" "nix-env -qa" "nix-env -q" "nix-channel --list" \
    "nix-channel --add" "nix-channel --remove"
}

fxbps-install() { pm xbps-install "Void"
  mkaliases "$s" "$unsup" "xbps-remove" "$s -S" "$s -u" \
    "xbps-query -Rs" "xbps-query -l" "xbps-query -L" \
    "$(list_dir /etc/xbps/repo.d/)" "$(list_dir /etc/xbps/repo.d/)"
}

fsnappy() { pm snappy "Ubuntu Snappy"
  mkaliases "$s install" "$unsup" "$s remove" "$unsup" \
    "$s update" "$s search" "$s list" \
    "$unsup" "$unsup" "$unsup"
}

fpkg() { pm pkg "FreeBSD 10.0+"
  mkaliases "$s install" "$s add" "$s remove" "$s update" "$s upgrade" \
    "$s search" "$s info" "$unsup" "$unsup" "$unsup"
}

checkarray=(apt-get zypper yum urpmi slackpkg slapt-get netpkg equo pacman conary apk smart pkcon emerge lin cast nix-env xbps-install snappy pkg)

main() {
  found=0
  for i in "${checkarray[@]}"
  do
    "$checkcmd" "$i" >/dev/null 2>&1 || continue
    "f$i" || die "found '$i' but failed to create aliases for it"
    found=$((found + 1))
  done

  [ "$found" -gt 0 ] ||
    die "none of the supported package managers (${checkarray[*]}) was found, no aliases were created"

  [ "$found" -eq 1 ] ||
    warn "$found package managers were found, aliases were created for the last one only"

  echo "Aliases added. If you don't know them just open this script to find out."

  # Load the aliases from .bashrc, but only add the line once
  if [ -n "$debug" ]; then
    echo "$rcline"
  elif grep -qxF "$rcline" "$bashrc" 2>/dev/null; then
    echo "'$bashrc' already sources '$afile', leaving it as it is."
  else
    echo "$rcline" >> "$bashrc" || die "cannot add '$rcline' to '$bashrc'"
  fi
}

# Only run when executed directly, so the functions above can be sourced (tests)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi

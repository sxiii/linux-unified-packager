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
# Re-creates empty bash aliases file for you (fix if needed)
afile="$HOME/.bash_aliases"
rm -f "$afile"; touch "$afile"
# If your distro/user doesen't need sudo just comment the following line:
sn='sudo'
# Choose your editor (to open mirror files)
ed='nano'
# Distro founded
df="You're using"
# Set debug="echo" to turn on debug mode (does not make any syschanges)
debug=""
# Error handling
err1="echo"
err2="not needed"

# Aliases created by this script, in the order mkaliases expects its arguments:
# i   installing packages (from repo)     ug  upgrading packages (themselves)
# ii  installing packages (from file)     s   searching packages
# r   removing packages                   li  list installed packages
# up  updating packages (list)            rl  list your repositories
# ra  add new repository or PPA           rr  removes repository or PPA
alias_names=(i ii r up ug s li rl ra rr)

# Writes a single alias into the aliases file
add_alias() {
  $debug echo "alias $1=\"$2\"" >> "$afile"
}

# Takes one command per alias, in the order of alias_names above
mkaliases() {
  shopt -s expand_aliases
  if [ "$#" -ne "${#alias_names[@]}" ]; then
    echo "mkaliases: expected ${#alias_names[@]} commands, got $#" >&2
    return 1
  fi
  local name
  for name in "${alias_names[@]}"; do
    add_alias "$name" "$sn $1"; shift
  done
  add_alias lsb 'echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*'
  source "$afile"
}

# Shared building blocks for the package manager commands below
unsupported="$err1 $err2"          # operation the package manager has no command for
show_conf() { echo "cat $1"; }     # print a configuration file
edit_conf() { echo "$sn $ed $1"; } # open a configuration file in the editor
list_dir() { echo "cd $1 && ls"; } # list a repository configuration directory

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
# Use "$unsupported" for operations your package manager cannot do, and the
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
  mkaliases "$s" "$s" "$s remove" "$unsupported" "$s upgrade" \
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
  mkaliases "$s update" "$s update" "$s erase" "$unsupported" "$s updateall" \
    "$s query" "$s query" "$unsupported" "$unsupported" "$unsupported"
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
    "$unsupported" "$unsupported"
}

femerge() { pm emerge "Gentoo"
  mkaliases "$s" "$unsupported" "$s -aC" "$s --sync" "$s -NuDa world" \
    "$s --search" "qlist -I" "layman -L" "layman -a" "layman -d"
}

flin() { pm lin "Lunar"
  mkaliases "$s" "$unsupported" "lrm" "$s moonbase" "lunar update" \
    "lvu search" "lvu installed" "$unsupported" "$unsupported" "$unsupported"
}

fcast() { pm cast "Source Mage"
  mkaliases "$s" "$unsupported" "dispel" "scribe update" "sorcery upgrade" \
    "gaze search" "gaze installed" "scribe index" "scribe add" "scribe remove"
}

fnix-env() { pm nix-env "NixOS"
  mkaliases "$s -i" "$unsupported" "$s -e" "nix-channel --update" \
    "nix-env -u" "nix-env -qa" "nix-env -q" "nix-channel --list" \
    "nix-channel --add" "nix-channel --remove"
}

fxbps-install() { pm xbps-install "Void"
  mkaliases "$s" "$unsupported" "xbps-remove" "$s -S" "$s -u" \
    "xbps-query -Rs" "xbps-query -l" "xbps-query -L" \
    "$(list_dir /etc/xbps/repo.d/)" "$(list_dir /etc/xbps/repo.d/)"
}

fsnappy() { pm snappy "Ubuntu Snappy"
  mkaliases "$s install" "$unsupported" "$s remove" "$unsupported" \
    "$s update" "$s search" "$s list" \
    "$unsupported" "$unsupported" "$unsupported"
}

fpkg() { pm pkg "FreeBSD 10.0+"
  mkaliases "$s install" "$s add" "$s remove" "$s update" "$s upgrade" \
    "$s search" "$s info" "$unsupported" "$unsupported" "$unsupported"
}

checkarray=(apt-get zypper yum urpmi slackpkg slapt-get netpkg equo pacman conary apk smart pkcon emerge lin cast nix-env xbps-install snappy pkg)

for i in ${checkarray[@]};
do
  ($checkcmd $i &>/dev/null) && f$i
done

echo "Aliases added. If you don't know them just open this script to find out."

echo "source ~/.bash_aliases" >> ~/.bashrc

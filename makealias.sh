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
rcfile="$HOME/.bashrc"
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
  [ -e "$afile" ] || return 0
  cp -- "$afile" "$afile.bak" ||
    die "cannot back up existing '$afile' to '$afile.bak'"
  warn "existing '$afile' was replaced, previous version kept as '$afile.bak'"
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
  local name="$1" cmd="$2" args="$3" line
  if [ "$cmd" = "$unsup" ] || [ -z "$cmd" ]; then
    line="alias $name=\"$unsup $name\""
  else
    line="alias $name=\"$sn $cmd $args\""
  fi
  if [ -n "$debug" ]; then
    echo "$line"
  else
    echo "$line" >> "$afile" || die "cannot write alias '$name' to '$afile'"
  fi
}

# Aliases (you can edit them to your like)
mkaliases() {
[ "$#" -eq 20 ] ||
  die "mkaliases needs 20 arguments (got $#) for package manager '${s:-unknown}'"
shopt -s expand_aliases
resetaliases
mkalias i "$1" "$2"          # installing packages (from repo)
mkalias ii "$3" "$4"         # installing packages (from file)
mkalias r "$5" "$6"          # removing packages
mkalias up "$7" "$8"         # updating packages (list)
mkalias ug "$9" "${10}"      # upgrading packages (themselves)
mkalias s "${11}" "${12}"    # searching packages
mkalias li "${13}" "${14}"   # list installed packages
mkalias rl "${15}" "${16}"   # list your repositories
mkalias ra "${17}" "${18}"   # add new repository or PPA
mkalias rr "${19}" "${20}"   # removes repository or PPA
lsb="alias lsb=\"echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*\"" # info
if [ -n "$debug" ]; then
  echo "$lsb"
else
  echo "$lsb" >> "$afile" || die "cannot write alias 'lsb' to '$afile'"
  # shellcheck source=/dev/null
  source "$afile" || warn "'$afile' was written but could not be sourced"
fi
}

# Command to check existence of package manager (can also be command or type)
checkcmd='hash'

# To add your own package manager, write function for it similar to
# the following functions, adding "f" letter in the front of package
# manager name, and add it to the end of checkarray list.
# Example: your package manager is "zeta", write function with the name
# "fzeta" similar to others. Last step, add it to the end of 'checkarray' array.
# When writing functions, include options from mkaliases one after another
# (!) Don't forget to include empty places '' if no variable is needed (!)
# (!) You should pass total of 20 variables, most of which shouldn't be empty.
# (!) For operations your package manager can't do, pass "$unsup" '' - the
# (!) resulting alias then explains the problem and returns 1 when it is used.

  # Writing own function help sample
fapt-get() { s='apt-get'; echo "$df $s on Debian/Ubuntu"
  mkaliases $s install dpkg -i $s remove $s update $s upgrade apt-cache search dpkg -l cat /etc/apt/sources.list apt-add-repository '' apt-add-repository -r
  # ^funct  ^$1  ^$2   ^$3  ^$4 ^$5  ^$6 ^$7  ^$8   ^$9  ^$10   ^$11    ^$12   ^$13 ^$14 ^$15      ^$16          ^$17               ^$18    ^$19          ^$20
  # Variables just go one by one, one after another, from mkaliases list.
}

function fzypper { s='zypper'; echo "$df $s on OpenSUSE"
  mkaliases $s install $s install $s remove $s refresh $s update $s search $s 'search -is' $s repos $s addrepo $s removerepo
}

function fyum { s='yum'; echo "$df $s on Fedora/CentOS"
  mkaliases $s install $s localinstall $s erase $s check-update $s update $s list rpm -qa $s repolist 'cd /etc/yum.repos.d/' '&& ls' 'cd /etc/yum.repos.d/' '&& ls'
}

function furpmi { s='urpmi'; echo "$df $s on Mandriva/Mageia"
  mkaliases $s '' $s '' urpme '' $s.update -a $s '--auto-select' urpmq '' rpm -qa urpmq --list-media $s.addmedia '' $s.removemedia ''
}

function fslackpkg { s='slackpkg'; echo "$df $s on Slackware"
  mkaliases $s install $s install $s remove $s update $s upgrade-all $s search ls /var/log/packages/ cat /etc/slackpkg/mirrors "$sn $ed" '/etc/slackpkg/mirrors' "$sn $ed" '/etc/slackpkg/mirrors'
}

function fslapt-get { s='slapt-get'; echo "$df $s on Vector"
  mkaliases $s --install $s --install $s --remove $s --update $s --upgrade $s --search $s --installed cat /etc/slapt-get/slapt-getrc "$sn $ed" '/etc/slapt-get/slapt-getrc' "$sn $ed" '/etc/slapt-get/slapt-getrc'
}

function fnetpkg { s='netpkg'; echo "$df $s on Zenwalk"
  mkaliases $s '' $s '' $s remove "$unsup" '' $s upgrade $s 'list | grep' $s 'list I' $s mirror "$sn $ed" '/etc/netpkg.conf' "$sn $ed" '/etc/netpkg.conf'
}

function fequo { s='equo'; echo "$df $s on Sabayon"
  mkaliases $s install $s install $s remove $s update $s upgrade $s search $s list $s repoinfo 'cd /etc/entropy/repositories.conf.d' '&& ls' 'cd /etc/entropy/repositories.conf.d' '&& ls'
}

function fpacman { s='pacman'; echo "$df $s on Arch/Manjaro"
  mkaliases $s -S $s -U $s -R $s -Sy $s -Su $s -Ss $s -Q cat /etc/pacman.conf $ed /etc/pacman.conf $ed /etc/pacman.conf
}

function fconary { s='conary'; echo "$df $s on Foresight/rPath"
  mkaliases $s update $s update $s erase "$unsup" '' $s updateall $s query $s query "$unsup" '' "$unsup" '' "$unsup" ''
}

function fapk { s='apk'; echo "$df $s on Alpine"
  mkaliases $s add $s 'add --force' $s del $s update $s upgrade $s search $s info cat /etc/apk/repositories setup-apkrepos '' $ed /etc/apk/repositories
}

function fsmart { s='smart'; echo "$df $s on Mandriva/OpenSUSE"
  mkaliases $s install $s install $s remove $s update $s upgrade $s search $s 'query --installed' $s 'channel --show' $s 'channel --add' $s 'channel --remove'
}

function fpkcon { s='pkcon'; echo "$df $s on Fedora/Ubuntu/OpenSUSE/Mandriva"
  mkaliases $s install $s install-file $s remove $s refresh $s upgrade $s search $s search $s repo-list "$unsup" '' "$unsup" ''
}

function femerge { s='emerge'; echo "$df $s on Gentoo"
  mkaliases $s '' "$unsup" '' $s '-aC' $s '--sync' $s '-NuDa world' $s '--search' qlist -I layman -L layman -a layman -d
}

function flin { s='lin'; echo "$df $s on Lunar"
  mkaliases $s '' "$unsup" '' lrm '' $s moonbase lunar update lvu search lvu installed "$unsup" '' "$unsup" '' "$unsup" ''
}

function fcast { s='cast'; echo "$df $s on Source Mage"
  mkaliases cast '' "$unsup" '' dispel '' scribe update sorcery upgrade gaze search gaze installed scribe index scribe add scribe remove
}

function fnix-env { s='nix-env'; echo "$df $s on NixOS"
  mkaliases $s -i "$unsup" '' $s -e nix-channel --update nix-env -u nix-env -qa nix-env -q nix-channel --list nix-channel --add nix-channel --remove
}

function fxbps-install { s='xbps-install'; echo "$df $s on Void"
  mkaliases $s '' "$unsup" '' xbps-remove '' $s -S $s -u xbps-query -Rs xbps-query -l xbps-query -L 'cd /etc/xbps/repo.d/' '&& ls' 'cd /etc/xbps/repo.d/' '&& ls'
}

function fsnappy { s='snappy'; echo "$df $s on Ubuntu Snappy"
  mkaliases $s install "$unsup" '' $s remove "$unsup" '' $s update $s search $s list "$unsup" '' "$unsup" '' "$unsup" ''
}

function fpkg { s='pkg'; echo "$df $s on FreeBSD 10.0+"
  mkaliases $s install $s add $s remove $s update $s upgrade $s search $s info "$unsup" '' "$unsup" '' "$unsup" ''
}

checkarray=(apt-get zypper yum urpmi slackpkg slapt-get netpkg equo pacman conary apk smart pkcon emerge lin cast nix-env xbps-install snappy pkg)

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

if [ -n "$debug" ]; then
  echo "source $afile"
elif grep -qF -e "source $afile" -e 'source ~/.bash_aliases' "$rcfile" 2>/dev/null; then
  echo "'$rcfile' already sources '$afile', leaving it as it is."
else
  echo "source $afile" >> "$rcfile" || die "cannot add 'source $afile' to '$rcfile'"
fi

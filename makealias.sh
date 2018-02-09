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
rm $afile; touch $afile
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

# Aliases (you can edit them to your like)
mkaliases() {
shopt -s expand_aliases
$debug echo "alias i=\"$sn $1 $2\"" >> $afile        # installing packages (from repo)
$debug echo "alias ii=\"$sn $3 $4\"" >> $afile       # installing packages (from file)
$debug echo "alias r=\"$sn $5 $6\"" >> $afile        # removing packages
$debug echo "alias up=\"$sn $7 $8\"" >> $afile       # updating packages (list)
$debug echo "alias ug=\"$sn $9 ${10}\"" >> $afile    # upgrading packages (themselves)
$debug echo "alias s=\"$sn ${11} ${12}\"" >> $afile  # searching packages
$debug echo "alias li=\"$sn ${13} ${14}\"" >> $afile # list installed packages
$debug echo "alias rl=\"$sn ${15} ${16}\"" >> $afile   # list your repositories
$debug echo "alias ra=\"$sn ${17} ${18}\"" >> $afile # add new repository or PPA
$debug echo "alias rr=\"$sn ${19} ${20}\"" >> $afile # removes repository or PPA
$debug echo "alias lsb=\"echo /etc/*_ver* /etc/*-rel*; cat /etc/*_ver* /etc/*-rel*\"" >> $afile # info
source ~/.bash_aliases
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
  mkaliases $s '' $s '' $s remove "$err1" "$err2" $s upgrade $s 'list | grep' $s 'list I' $s mirror "$sn $ed" '/etc/netpkg.conf' "$sn $ed" '/etc/netpkg.conf'
}

function fequo { s='equo'; echo "$df $s on Sabayon"
  mkaliases $s install $s install $s remove $s update $s upgrade $s search $s list $s repoinfo 'cd /etc/entropy/repositories.conf.d' '&& ls' 'cd /etc/entropy/repositories.conf.d' '&& ls'
}

function fpacman { s='pacman'; echo "$df $s on Arch/Manjaro"
  mkaliases $s -S $s -U $s -R $s -Sy $s -Su $s -Ss $s -Q cat /etc/pacman.conf $ed /etc/pacman.conf $ed /etc/pacman.conf
}

function fconary { s='conary'; echo "$df $s on Foresight/rPath"
  mkaliases $s update $s update $s erase "$err1" "$err2" $s updateall $s query $s query "$err1" "$err2" "$err1" "$err2" "$err1" "$err2"
}

function fapk { s='apk'; echo "$df $s on Alpine"
  mkaliases $s add $s 'add --force' $s del $s update $s upgrade $s search $s info cat /etc/apk/repositories setup-apkrepos '' $ed /etc/apk/repositories
}

function fsmart { s='smart'; echo "$df $s on Mandriva/OpenSUSE"
  mkaliases $s install $s install $s remove $s update $s upgrade $s search $s 'query --installed' $s 'channel --show' $s 'channel --add' $s 'channel --remove'
}

function fpkcon { s='pkcon'; echo "$df $s on Fedora/Ubuntu/OpenSUSE/Mandriva"
  mkaliases $s install $s install-file $s remove $s refresh $s upgrade $s search $s search $s repo-list "$err1" "$err2" "$err1" "$err2"
}

function femerge { s='emerge'; echo "$df $s on Gentoo"
  mkaliases $s '' "$err1" "$err2" $s '-aC' $s '--sync' $s '-NuDa world' $s '--search' qlist -I layman -L layman -a layman -d
}

function flin { s='lin'; echo "$df $s on Lunar"
  mkaliases $s '' "$err1" "$err2" lrm '' $s moonbase lunar update lvu search lvu installed "$err1" "$err2" "$err1" "$err2" "$err1" "$err2"
}

function fcast { echo "$df $s on Source Mage"
  mkaliases cast '' "$err1" "$err2" dispel '' scribe update sorcery upgrade gaze search gaze installed scribe index scribe add scribe remove
}

function fnix-env { s='nix-env'; echo "$df $s on NixOS"
  mkaliases $s -i "$err1" "$err2" $s -e nix-channel --update nix-env -u nix-env -qa nix-env -q nix-channel --list nix-channel --add nix-channel --remove
}

function fxbps-install { s='xbps-install'; echo "$df $s on Void"
  mkaliases $s '' "$err1" "$err2" xbps-remove '' $s -S $s -u xbps-query -Rs xbps-query -l xbps-query -L 'cd /etc/xbps/repo.d/' '&& ls' 'cd /etc/xbps/repo.d/' '&& ls'
}

function fsnappy { s='snappy'; echo "$df $s on Ubuntu Snappy"
  mkaliases $s install "$err1" "$err2" $s remove "$err1" "$err2" $s update $s search $s list "$err1" "$err2" "$err1" "$err2" "$err1" "$err2"
}

function fpkg { s='pkg'; echo "$df $s on FreeBSD 10.0+"
  mkaliases $s install $s add $s remove $s update $s upgrade $s search $s info "$err1" "$err2" "$err1" "$err2" "$err1" "$err2"
}

checkarray=(apt-get zypper yum urpmi slackpkg slapt-get netpkg equo pacman conary apk smart pkcon emerge lin cast nix-env xbps-install snappy pkg)

for i in ${checkarray[@]};
do
  ($checkcmd $i &>/dev/null) && f$i
done

echo "Aliases added. If you don't know them just open this script to find out."

echo "source ~/.bash_aliases" >> ~/.bashrc 

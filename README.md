## Linux unified packager

Alias manager. It helps you to install, update, remove and work with the software in the same manner in any linux distro.

## Why this is important? Who needs this?

* If you would like to test new distro but don't wont to search for new commands (hobby)
* If you're professional tester or developer (work)
* If you're distrohopper (change distributions from time to time)
* Just if you're curious
* If you would like to learn, how to work with distribution package managers from the scripts
* If you want to learn how to write bash scripts
* Your personal reason? Make an issue or pull request :)

## How to make this script work?

Note: you need to download & run the script only once. 
1. At first, you have to use either wget, curl, git (only one of them) or manually copy-paste the internals of .SH script.
`sudo apt install git`
2. Download the script with the software of your choice (I choose git, if you choose other the command changes of course):
`git clone https://github.com/sxiii/linux-unified-packager`
3. Open the terminal & go to directory where you did download the script.
`cd linux-unified*`
4. Make the script executable
`chmod +x *sh`
5. Execute the script
`./

## Supported linux distributions (and package managers)

Totally this script supports 10 categories of package managers, 20 pcs.

* Debian family: Ubuntu, Debian (apt-get), etc.
* SUSE family: OpenSUSE (zypper),
* RedHat family: Fedora, CentOS, RedHat (yum/dnf), 
* Mandriva family: Mandriva, Mageia (urpmi).
* Slackware distros: Slackware (slackpkg), Vector (slapt-get), Zenwalk (netpkg),
* Independent distros: Sabayon (equo), Arch/Manjaro (pacman), Foresight, rPath (conary), Alpine (apk).
* Multi-distro (distro-agnostic) package managers: Mandria, OpenSUSE (smart), Fedora, Ubuntu, openSUSE, Mandriva (pkcon).
* Source package managers: Gentoo (emerge), Lunar (lin), Source Mage (cast),
* New, binary pac.-man. systems: NixOS (nix), Void (xbps), Ubuntu (snappy),
* FreeBSD: 10.0+ (pkg).

## But still who needs this? And how does it work?
You ask, what is this script for? It creates short aliases (cli commands) that can be used as simple as:

Alias (short cmd) | Actual action/result (what this command does)
| - | - |
i | install package
ii | install package (from file)
r | remove
up | update repos (repositories; it means update list of available packages from the server)
ug | upgrade package or system
li | list installed packages (warning: may be large!)
rl | list repositories (list packages that are available in repositories - "repo list")
ra | add new repository or PPA ("repository add")
rr | remove repository or PPA ("repository remove")
lsb | system information ("linux standard base")

Of course, you have to ensure you don't have these short programs or aliases in your system already. But in the most cases (I believe, 99.9%) they won't be such, as I choosed them wisely. Only if you added themselves :) At least these commands are free on basic installations of Ubuntu and ArchLinux.

Note: in Linux world, words "program" or "software" usually replaced by more correct word "package". But it's synonyms.

As already was said, this scripts works with most distros (it knows at least 20 package managers). You may think about it as an abstruction layer between you and package manager, which works predictably the same in any distro (even tho some distros has specific package management logic).

It also adds "lsb" command which shows you info about your distro & packages. And you don't have to look which actual package manager your system uses! Comfortable? Indeed!

## Base of Universal Multi-Distro Mostly Used Aliases Script
The script was based on package management article from distrowatch which is here:
* http://distrowatch.com/package-management

## Working details
This script was written in the idea of uniting several package management system into one single command that can be issued easily. This script DOES NOT detect your distros because it is not so important, while we just want to see if you have any package managers installed. That wouldn't be a problem because small amount of people uses more than one package managers (guys you might have to fix this script in this case)

## Developers & testers needed
If you just tested the script on your local PC and it works well, you can write an issue about that or commit here exact name & version of your system. More importantly, if the script DOES NOT work well, you should commit the issue to this repo with all details on your system, please. It will help whole community.

#!/bin/bash

set -o posix

clear && reset

showPacmanCheckBanner()
{
    clear
    notifyUser "${CYAN_FG_COLOR}+-+-+-+-+-+-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    notifyUser "${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLACK_FG_COLOR}p a c m a n${CLEAR_ALL_TEXT_STYLES}${CYAN_FG_COLOR}|  |${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLACK_FG_COLOR}c h e c k${CLEAR_ALL_TEXT_STYLES}${CYAN_FG_COLOR}|" 0 'dontClear' 'no_newline'
    notifyUser "${CLEAR_ALL_TEXT_STYLES}${CYAN_FG_COLOR}+-+-+-+-+-+-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    [[ -z "${1}" ]] || notifyUser "${CLEAR_ALL_TEXT_STYLES}${CYAN_BG_COLOR}${BLACK_FG_COLOR}${1}" 0 'dontClear' 'no_newline'
}

[[ ! -f ./darlingui.sh ]] && printf "\n\n\e[31m darlingui.sh is required for this script to run.\n\n\e[0m" && exit 1

. ./darlingui.sh

showPacmanCheckBanner "Packages explicitly installed by user"
notifyUser "Updating list of ${CLEAR_ALL_TEXT_STYLES}${RED_FG_COLOR}explicitly${NOTIFYCOLOR} installed packages" 0 'dontClear'
pacman -Qqetn > ~/.explicitlyinstalledpkgs
notifyUser "${YELLOW_FG_COLOR}$(wc -l ${HOME}/.explicitlyinstalledpkgs | sed "s,\/home, packages listed in ${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLACK_FG_COLOR}\/home,g")" 0 'dontClear'
notifyUser "${RED_FG_COLOR}Note: This list ${YELLOW_FG_COLOR}does not include foriegn packages${RED_FG_COLOR}, i.e., packages installed from the AUR." 0 'dontClear'
notifyUser "${RED_FG_COLOR}Note: This list ${YELLOW_FG_COLOR}does not include packages required by explicitly installed packages" 0 'dontClear'
notifyUser "${RED_FG_COLOR}      as such packages would be installed as dependencies of the packages listed in:" 0 'dontClear'
notifyUser "      ${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLACK_FG_COLOR}${HOME}/.explicitlyinstalledpkgs" 0 'dontClear'
sleep 5

showPacmanCheckBanner "Orphaned packages"
notifyUser "Updating list of orphaned packages" 0 'dontClear'
pacman -Qdt > ~/.orphanedpkgs
notifyUser "${YELLOW_FG_COLOR}$(wc -l ${HOME}/.orphanedpkgs | sed "s,\/home, orphaned packages listed in ${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLACK_FG_COLOR}\/home,g")" 0 'dontClear'
notifyUser "${RED_FG_COLOR}This is a list of packages that were installed as dependencies, but are no longer required." 0 'dontClear'
sleep 5


[[ -z "$(command -v pacdiff)" ]] && showLoadingBar "Installing pacman-contrib package so pacdiff can be used to check for .pac* files" && sudo pacman -Syy pacman-contrib

showPacmanCheckBanner "Checking for .pac* files via pacdiff"

pacdiff

notifyUser "To further manage your .pac* files run ${GREEN_FG_COLOR} pacdiff"
showPacmanCheckBanner "Finished"
notifyUser "System checks related to pacman are complete." 0 'dontClear'
sleep 2


[[ -z "$(command -v reflector)" ]] && showLoadingBar "Installing ${GREEN_FG_COLOR}reflector${CLEAR_ALL_TEXT_STYLES} package so mirror list can be properly updated." && sudo pacman -Syy reflector


reset

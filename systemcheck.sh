#!/bin/bash

set -o posix

clear && reset

showSysCheckBanner()
{
    clear
    notifyUser "+-+-+-+-+-+-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    notifyUser "|S|y|s|t|e|m| |C|h|e|c|k|" 0 'dontClear' 'no_newline'
    notifyUser "+-+-+-+-+-+-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    showLoadingBar "${1}" 'dontClear'
}

[[ ! -f ./darlingui.sh ]] && printf "\n\n\e[31m darlingui.sh is required for this script to run.\n\n\e[0m" && exit 1

. ./darlingui.sh

showSysCheckBanner "Running ${GREEN_FG_COLOR}./systemdcheck.sh"
[[ -f ./systemdcheck.sh ]] && ./systemdcheck.sh

showSysCheckBanner "Running ${GREEN_FG_COLOR}./pacmancheck.sh"
[[ -f ./pacmancheck.sh ]] && ./pacmancheck.sh


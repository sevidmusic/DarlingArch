#!/bin/bash

set -o posix
clear && reset
showSysDCheckBanner()
{
    clear
    notifyUser "+-+-+-+-+-+-+ +-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    notifyUser "|S|y|s|t|e|m| |D| |C|h|e|c|k|" 0 'dontClear' 'no_newline'
    notifyUser "+-+-+-+-+-+-+ +-+ +-+-+-+-+-+" 0 'dontClear' 'no_newline'
    [[ -z "${1}" ]] || notifyUser "${YELLOW_FG_COLOR}${1}" 0 'dontClear' 'no_newline'
}

[[ ! -f ./darlingui.sh ]] && printf "\n\n\e[31m darlingui.sh is required for this script to run.\n\n\e[0m" && exit 1

. ./darlingui.sh
showSysDCheckBanner "systemd service check"
showLoadingBar "Checking for failed systemd services via ${GREEN_FG_COLOR}systemctl --failed" 'dontClear'
systemctl --failed
sleep 2

showSysDCheckBanner
showLoadingBar "Compiling list of errors logged in /var/log/* as well as high priority errors in the systemd journal" 'dontClear'
journalctl -p 3 -xb
sleep 2

showSysDCheckBanner "systemd check complete"
showLoadingBar "Finished"

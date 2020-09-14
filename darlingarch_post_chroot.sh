#!/bin/bash

set -o posix

setTextStyleCode() {
  printf "\e[%sm" "${1}"
}

# NOTE: Some text styles may not work on some terminals, for a good compatibility
#       overview @see:
# https://misc.flogisoft.com/bash/tip_colors_and_formatting#terminals_compatibility
initTextStyles() {
  # Formatting On
  BOLD_TEXT_ON=$(setTextStyleCode 1)
  DIM_TEXT_ON=$(setTextStyleCode 2)
  UNDERLINE_TEXT_ON=$(setTextStyleCode 4)
  BLINK_TEXT_ON=$(setTextStyleCode 5)
  INVERT_FGBG_TEXT_ON=$(setTextStyleCode 7)
  HIDDEN_TEXT_ON=$(setTextStyleCode 8)
  # Formatting Off
  CLEAR_ALL_TEXT_STYLES=$(setTextStyleCode 0)
  BOLD_TEXT_OFF=$(setTextStyleCode 21)
  DIM_TEXT_OFF=$(setTextStyleCode 22)
  UNDERLINE_TEXT_OFF=$(setTextStyleCode 24)
  BLINK_TEXT_OFF=$(setTextStyleCode 25)
  INVERT_FGBG_TEXT_OFF=$(setTextStyleCode 27)
  HIDDEN_TEXT_OFF=$(setTextStyleCode 28)
  # Foreground Colors
  DEFAULT_FG_COLOR=$(setTextStyleCode 39)
  BLACK_FG_COLOR=$(setTextStyleCode 30)
  RED_FG_COLOR=$(setTextStyleCode 31)
  GREEN_FG_COLOR=$(setTextStyleCode 32)
  YELLOW_FG_COLOR=$(setTextStyleCode 33)
  BLUE_FG_COLOR=$(setTextStyleCode 34)
  MAGENTA_FG_COLOR=$(setTextStyleCode 35)
  CYAN_FG_COLOR=$(setTextStyleCode 36)
  LIGHT_GRAY_FG_COLOR=$(setTextStyleCode 37)
  DARK_GRAY_FG_COLOR=$(setTextStyleCode 90)
  LIGHT_RED_FG_COLOR=$(setTextStyleCode 91)
  LIGHT_GREEN_FG_COLOR=$(setTextStyleCode 92)
  LIGHT_YELLOW_FG_COLOR=$(setTextStyleCode 93)
  LIGHT_BLUE_FG_COLOR=$(setTextStyleCode 94)
  LIGHT_MAGENTA_FG_COLOR=$(setTextStyleCode 95)
  LIGHT_CYAN_FG_COLOR=$(setTextStyleCode 96)
  WHITE_FG_COLOR=$(setTextStyleCode 97)
  # BackgroundColors
  DEFAULT_BG_COLOR=$(setTextStyleCode 49)
  BLACK_BG_COLOR=$(setTextStyleCode 40)
  RED_BG_COLOR=$(setTextStyleCode 41)
  GREEN_BG_COLOR=$(setTextStyleCode 42)
  YELLOW_BG_COLOR=$(setTextStyleCode 43)
  BLUE_BG_COLOR=$(setTextStyleCode 44)
  MAGENTA_BG_COLOR=$(setTextStyleCode 45)
  CYAN_BG_COLOR=$(setTextStyleCode 46)
  LIGHT_GRAY_BG_COLOR=$(setTextStyleCode 47)
  DARK_GRAY_BG_COLOR=$(setTextStyleCode 100)
  LIGHT_RED_BG_COLOR=$(setTextStyleCode 101)
  LIGHT_GREEN_BG_COLOR=$(setTextStyleCode 102)
  LIGHT_YELLOW_BG_COLOR=$(setTextStyleCode 103)
  LIGHT_BLUE_BG_COLOR=$(setTextStyleCode 104)
  LIGHT_MAGENTA_BG_COLOR=$(setTextStyleCode 105)
  LIGHT_CYAN_BG_COLOR=$(setTextStyleCode 106)
  WHITE_BG_COLOR=$(setTextStyleCode 107)
  # Niche Colors
  WARNINGCOLOR="${CLEAR_ALL_TEXT_STYLES}${BOLD_TEXT_ON}${YELLOW_BG_COLOR}${BLACK_FG_COLOR}"
  NOTIFYCOLOR="${CLEAR_ALL_TEXT_STYLES}${LIGHT_BLUE_FG_COLOR}"
  HIGHLIGHTCOLOR="${CLEAR_ALL_TEXT_STYLES}${LIGHT_BLUE_BG_COLOR}${BLACK_FG_COLOR}"
  BANNER_MSG_COLOR="${CLEAR_ALL_TEXT_STYLES}${GREEN_BG_COLOR}${BLINK_TEXT_ON}${BLACK_FG_COLOR}"
}

animatedPrint()
{
  local _charsToAnimate _speed _currentChar _charCount
  # For some reason spaces get mangled using ${VAR:POS:LIMIT}. so replace spaces with _ here,
  # then add spaces back when needed.
  _charsToAnimate=$( printf "%s" "${1}" | sed -E "s/ /_/g;")
  _speed="${2:-0.05}"
  _charCount=0
  for (( i=0; i< ${#_charsToAnimate}; i++ )); do
      ((_charCount++))
      [[ $_charCount == $((_slb_adjustedNumChars - 10)) ]] && _charCount=0 && printf "\n\n "
      # Replace placeholder _ with space | i.e., fix spaces that were replaced
      _currentChar=$(printf "%s" "${_charsToAnimate:$i:1}" | sed -E "s/_/ /g;")
      printf "%s" "${_currentChar}"
      sleep $_speed
  done
}

showLoadingBar() {
  local _slb_inc _slb_windowWidth _slb_numChars _slb_adjustedNumChars _slb_loadingBarLimit
  printf "\n"
  animatedPrint "${1}" .05
  printf "%s" "${HIGHLIGHTCOLOR}"
  _slb_inc=0
  _slb_windowWidth=$(tput cols)
  _slb_numChars="${#1}"
  _slb_adjustedNumChars=$((_slb_windowWidth - _slb_numChars))
  _slb_loadingBarLimit=$((_slb_adjustedNumChars - 10))
  while [[ ${_slb_inc} -le "${_slb_loadingBarLimit}" ]]; do
    animatedPrint ":" .007
    _slb_inc=$((_slb_inc + 1))
  done
  printf " %s\n" "${CLEAR_ALL_TEXT_STYLES}${BLINK_TEXT_ON}${LIGHT_BLUE_BG_COLOR}[100%]${CLEAR_ALL_TEXT_STYLES}"
  sleep 0.23
  [[ "${2}" != "dontClear" ]] && clear
}

exitOrContinue()
{
    [[ "${2}" == "forceExit" ]] && exit "${1:-0}"
    [[ -n "${CONTINUE}" ]] && return
    exit "${1:-0}"
}

notifyUser()
{
    [[ "${4}" != 'no_newline' ]] && printf "\n"
    printf "${NOTIFYCOLOR}"
    animatedPrint "${1}" 0.009
    sleep ${2:-2}
    [[ "${3}" == "dontClear" ]] || clear
    printf "${CLEAR_ALL_TEXT_STYLES}\n"
    printf "\n%s%s%s\n" "${NOTIFYCOLOR}" "${1}" "${CLEAR_ALL_TEXT_STYLES}" >> ~/.cache/darlingarch/.installer_msg_log
}

notifyUserAndExit()
{
    notifyUser "${1}" "${2:-1}" "${3:-CLEAR}"
    exitOrContinue "${4:-0}" "${5:-default}"
}

initMessages() {
    NEWLINE="\n\n"
    SCRIPT=`basename "$(realpath $0)"`
    SCRIPTNAME="${HIGHLIGHTCOLOR}${BOLD_TEXT_ON}${SCRIPT}${CLEAR_ALL_TEXT_STYLES}"
    OPENSSH="${HIGHLIGHTCOLOR}${BOLD_TEXT_ON}openssh${CLEAR_ALL_TEXT_STYLES}"
    BANNER_1='   ___           ___             ___           __ '
    BANNER_2='  / _ \___ _____/ (_)__  ___ _  / _ | ________/ / '
    BANNER_3=' / // / _ \/ __/ / / _ \/ _  / / __ |/ __/ __/ _ \'
    BANNER_4='/____/\_._/_/ /_/_/_//_/\_. / /_/ |_/_/  \__/_//_/'
    BANNER_5='                       /___/                      '
    DISTRO="${HIGHLIGHTCOLOR}Arch Linux"
}

showBanner()
{
    clear
    printf "\n%s\n" "${BANNER}"
    printf "\n%s" "${BANNER_MSG_COLOR}${BOLD_TEXT_ON}${BLINK_TEXT_ON}${BANNER_1}"
    printf "\n%s" "${BANNER_MSG_COLOR}${BOLD_TEXT_ON}${BLINK_TEXT_ON}${BANNER_2}"
    printf "\n%s" "${BANNER_MSG_COLOR}${BOLD_TEXT_ON}${BLINK_TEXT_ON}${BANNER_3}"
    printf "\n%s" "${BANNER_MSG_COLOR}${BOLD_TEXT_ON}${BLINK_TEXT_ON}${BANNER_4}"
    printf "\n%s" "${BANNER_MSG_COLOR}${BOLD_TEXT_ON}${BLINK_TEXT_ON}${BANNER_5}"
    printf "\n"
    notifyUser "${CLEAR_ALL_TEXT_STYLES}${BANNER_MSG_COLOR}${1:- }${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
}

showFlagInfo()
{
      showLoadingBar "Loading flag info"
      showBanner "Help: Flags"
      # -h
      notifyUser "The -h flag will cause ${SCRIPTNAME}${NOTIFYCOLOR} to show help info for ${SCRIPTNAME}" 0 'dontClear'
      notifyUser "${SCRIPTNAME}${HIGHLIGHTCOLOR} -s${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      # -l
      notifyUser "The -l flag will cause ${SCRIPTNAME}${NOTIFYCOLOR} to print a log of all the messages shown while the script was running." 0 'dontClear'
      notifyUser "${SCRIPTNAME}${HIGHLIGHTCOLOR} -l${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      notifyUser "The -l flag is helpful if you need to review what ${SCRIPTNAME}${NOTIFYCOLOR} has done so far." 3 'dontClear'
}

showWelcomeMessage()
{
    [[ "$(command -v neofetch | wc -l)" -gt 0 ]] || showBanner "Welcome to ${DISTRO}${BANNER_MSG_COLOR}"
    [[ "$(command -v neofetch | wc -l)" -gt 0 ]] && neofetch && notifyUser "Welcome to ${DISTRO}${BANNER_MSG_COLOR}" 0 'dontClear'
    notifyUser "If your running this script it is assumed that you successflly performed the ${DISTRO}${NOTIFYCOLOR} installation and succesfully used ${HIGHLIGHTCOLOR}arch-chroot${NOTIFYCOLOR} to login to the new installation as root." 0 'dontClear'
    notifyUser "This script will perform the necessary post installation steps. Once it is complete you should be able to ${HIGHLIGHTCOLOR}exit${NOTIFYCOLOR} out of the new installation, ${HIGHLIGHTCOLOR}unmount${NOTIFYCOLOR} the new installation, ${HIGHLIGHTCOLOR}poweroff${NOTIFYCOLOR} the computer, ${HIGHLIGHTCOLOR}remove the installation media${NOTIFYCOLOR}, ${HIGHLIGHTCOLOR}turn the computer back on${NOTIFYCOLOR}, and begin enjoying your new ${DISTRO}${NOTIFYCOLOR} installation." 3 'dontClear'
}

showHelpMsg()
{
    showBanner "Help"
    showLoadingBar "Loading help"
    showWelcomeMessage
    [[ "${1}" == 'noFlags' ]] || showFlagInfo
    showBanner "Help"
    notifyUser "${SCRIPTNAME}${NOTIFYCOLOR} will now exit." 0 'dontClear'
    notifyUser "Tip: Run ${SCRIPTNAME}${HIGHLIGHTCOLOR} -l${NOTIFYCOLOR} to quickly view the preivous help messages, as well as any other messages output by ${SCRIPTNAME}" 0 'dontClear'
    showLoadingBar "Exiting installer"
}

configureTime()
{
    showBanner "${SCRIPTNAME}${BANNER_MSG_COLOR}: Configure Time"
    [[ -f ~/.cache/darlingarch/.config_time ]] && notifyUser "Time was aleady configured." && return
    notifyUser "Setting timezone" 0 'dontClear'
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
    notifyUser "Syncing hardware clock" 0 'dontClear'
    hwclock --systohc
    showLoadingBar "Time is configured, moving on."
    printf "time_already_configured" >> ~/.cache/darlingarch/.config_time
}

configureLocale()
{
    showBanner "Localization"
    [[ -f ~/.cache/darlingarch/.installer_locale ]] && notifyUser "Localization was already configured." && return
    notifyUser "Setting up localization" 0 'dontClear'
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    showLoadingBar "Localization was configured, moving on"
    printf "" >> ~/.cache/darlingarch/.installer_locale
}

configureNetwork()
{
    showBanner "Network Configuration | ${HIGHLIGHTCOLOR}User Input Required"
    [[ -f ~/.cache/darlingarch/.installer_network_configured ]] && notifyUser "Network was already configured." && return
    notifyUser "Setting up network" 0 'dontClear'
    notifyUser "Plese enter the name you wish to assign to you computer, i.e. the hostname:" 0 'dontClear'
    notifyUser "${WARNINGCOLOR}The hostname MUST be alphanumeric, all lowercase, and contain no spaces, ${SCRIPTNAME}${WARNINGCOLOR} does not validate your input, get this right or your Network configuration will be invalid!" 0 'dontClear'
    read -p "Desired hostname (${WARNINGCOLOR}alphanumeric, all lowercase, no spaces${NOTIFYCOLOR}): " HOST_NAME
    [[ -f /etc/hostname ]] && notifyUser "Deleteing old /etc/hostname file" 0 'dontClear' && rm /etc/hostname
    [[ -f /etc/hosts ]] && notifyUser "Deleteing old /etc/hosts file" 0 'dontClear' && rm /etc/hosts
    echo "${HOST_NAME}" >> /etc/hostname
    echo "127.0.0.1        localhost" >> /etc/hosts
    echo "::1              localhost" >> /etc/hosts
    echo "127.0.1.1        ${HOST_NAME}.localdomain ${HOST_NAME}" >> /etc/hosts
    notifyUser "Current /etc/hostname file:" 0 'dontClear'
    cat /etc/hostname
    notifyUser "Current /etc/hosts file:" 0 'dontClear'
    cat /etc/hosts
    sleep 3
    notifyUser "Enabling NetworkManager" 0 'dontClear'
    systemctl enable NetworkManager
    showLoadingBar "Network is configured, and NetworkManager is enabled, moving on"
    printf "" >> ~/.cache/darlingarch/.installer_network_configured
}

configureRootPassword()
{
    showBanner "Set ${HIGHLIGHTCOLOR}root${BANNER_MSG_COLOR} password"
    [[ -f ~/.cache/darlingarch/.installer_root_pwd ]] && notifyUser "Root password was already set, to reset run: ${HIGHLIGHTCOLOR}passwd" && return
    notifyUser "Setting root password" 0 'dontClear'
    passwd
    showLoadingBar "Root password was set, moving on"
    printf "" >> ~/.cache/darlingarch/.installer_root_pwd
}

showDiskListing()
{
    fdisk -l | grep 'dev' | awk "/dev.*/{i++}i==${1}{print; exit}"
}

showDiskInfo()
{
    local _sdi_limit _sdi_inc _sdi_listing
    _sdi_limit="$(fdisk -l | grep 'dev' | wc -l)"
    _sdi_inc=1
    notifyUser "The following is an overview of the available disks, and their respective partitions." 0 'dontClear'
    while [[ "${_sdi_inc}" -le "${_sdi_limit}" ]]
    do
        _sdi_listing="$(showDiskListing $_sdi_inc)"
        notifyUser "${_sdi_listing/Disk/${HIGHLIGHTCOLOR}Disk}" 0 'dontClear'
        _sdi_inc=$(( $_sdi_inc + 1 ))
    done
    sleep 5
}

configureGrub()
{
    showBanner "Install and configure ${HIGHLIGHTCOLOR}grub"
    [[ -f ~/.cache/darlingarch/.installer_grub ]] && notifyUser "Grub was already installed and configured on: ${HIGHLIGHTCOLOR}$(cat ~/.cache/darlingarch/.installer_grub)" && return
    notifyUser "Setting up ${HIGHLIGHTCOLOR}grub${NOTIFYCOLOR} bootloader" 0 'dontClear'
    pacman -S grub --noconfirm
    showBanner "Configure Grub | Enter Disk Name | ${HIGHLIGHTCOLOR}User input required"
    notifyUser "Please enter the name of the disk ${DISTRO}${NOTIFYCOLOR} is being installed on. (e.g., ${HIGHLIGHTCOLOR}sdb${NOTIFYCOLOR})" 0 'dontClear'
    showDiskInfo
    read -p "Disk name (e.g., ${HIGHLIGHTCOLOR}sdb${CLEAR_ALL_TEXT_STYLES}): " DISK_NAME
    grub-install -v --target=i386-pc "/dev/${DISK_NAME}"
    grub-mkconfig -o /boot/grub/grub.cfg
    showLoadingBar "Grub was installed and configured on ${HIGHLIGHTCOLOR}${DISK_NAME}${NOTIFYCOLOR}, moving on"
    printf "${DISK_NAME}" >> ~/.cache/darlingarch/.installer_grub
}


configureUser()
{
    [[ -f ~/.cache/darlingarch/.installer_user ]] && showBanner "Configure User" && notifyUser "$(cat ~/.cache/darlingarch/.installer_user)'s account was already configured. Additional changes will need to be made manually." && return
    notifyUser "" 0 'dontClear'
    showBanner "Configure User | ${HIGHLIGHTCOLOR}User input required"
    notifyUser "Please enter a username:" 0 'dontClear'
    read -p "Desired user name: " USER_NAME
    showLoadingBar "Creating new user"
    useradd -m -U -G wheel,audio,video,optical,storage -s /bin/bash "${USER_NAME}"
    showBanner "Configure User | Set new user's password | ${HIGHLIGHTCOLOR}User Input Required"
    notifyUser "Please set a password for the new user:" 0 'dontClear'
    passwd "${USER_NAME}"
    showLoadingBar "Password was set for new user, moving on"
    showBanner "Configure User | Install and configure sudo"
    pacman -S sudo --noconfirm
    showLoadingBar "${HIGHLIGHTCOLOR}sudo${CLEAR_ALL_TEXT_STYLES} is installed, moving on"
    showBanner "Configure User | Install and configure sudo"
    showLoadingBar "Enableing members of the wheel group to use sudo"
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
    showBanner "Configure User | Done"
    showLoadingBar "New user ${USER_NAME} was created, and given sudo privleges, additional changes will need to be made manually, moving on"
    printf "${USER_NAME}" >> ~/.cache/darlingarch/.installer_user
}


########################## PROGRAM #######################
[[ -d ~/.cache/darlingarch ]] || mkdir -p ~/.cache/darlingarch


clear
initTextStyles
initMessages
# For a great article on getopts, and other approaches to handling bash arguments:
# @see https://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":lh" OPTION; do
  case "${OPTION}" in
  l)
      [[ -f ~/.cache/darlingarch/.installer_msg_log ]] || notifyUserAndExit "There are no logged messages" 0 'dontClear'
      cat ~/.cache/darlingarch/.installer_msg_log | more
      exitOrContinue 0 "forceExit"
    ;;
  h)
      showHelpMsg
      exitOrContinue 0 "forceExit"
    ;;
  \?)
     animatedPrint "Invalid argument: -${OPTARG}" && exitOrContinue 1 "forceExit"
    ;;
  esac
done
clear

showWelcomeMessage

configureTime

configureLocale

configureNetwork

configureRootPassword

configureGrub

configureUser

showLoadingBar "Finishing up"

showBanner "Finishing up"

notifyUserAndExit "If no errors occured, then you can safely ${HIGHLIGHTCOLOR}exit${NOTIFYCOLOR}, ${HIGHLIGHTCOLOR}umount ${DISK_NAME:-DISKNAME}${NOTIFYCOLOR}, ${HIGHLIGHTCOLOR}poweroff${NOTIFYCOLOR} the computer, ${HIGHLIGHTCOLOR}remove the installation media${NOTIFYCOLOR}, and reboot into your new ${DISTRO}${NOTIFYCOLOR} installation." 5


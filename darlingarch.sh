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

initVars()
{
    CACHE_DIR=~/.cache/darlingarch
    DEFAULT_PACKAGE_FILE="$(pwd)/pacstrap.dap"
    PACKAGE_FILE="${DEFAULT_PACKAGE_FILE}"
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
    printf "\n%s%s%s\n" "${NOTIFYCOLOR}" "${1}" "${CLEAR_ALL_TEXT_STYLES}" >> "${CACHE_DIR}/.installer_msg_log"
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
    HELP_MSG_WELCOME1="I developed ${SCRIPTNAME}${CLEAR_ALL_TEXT_STYLES}${NOTIFYCOLOR} as a guide for myself."
    HELP_MSG_WELCOME2="${SCRIPTNAME}${NOTIFYCOLOR} is a simple installer that will guide you through process of installing ${DISTRO}${NOTIFYCOLOR} on a ${HIGHLIGHTCOLOR}Legacy BIOS${NOTIFYCOLOR} using ${HIGHLIGHTCOLOR}ext4${NOTIFYCOLOR} for a filesystem."
    HELP_MSG_WELCOME3="Feel free to modify the script to suit your needs."
    HELP_MSG_WELCOME4="-Sevi D | https://github.com/sevidmusic | sdmwebsdm@gmail.com"
    LB_PRE_INSTALL_MSG='Pre-installation will begin in a moment'
    LB_INSTALL_MSG="Installation of ${DISTRO}${CLEAR_ALL_TEXT_STYLES} will begin in a moment"
    LB_POST_INSTALL_MSG='Post-installation will being in a moment'
    PWD_IS_ALREADY_SET="Root password was already set, to reset run: ${HIGHLIGHTCOLOR}passwd${CLEAR_ALL_TEXT_STYLES}"
    PLS_SET_PWD="Please set the root password:"
    PWD_ERROR_OCCURED="${WARNINGCOLOR}An error occured, please re-run ${SCRIPTNAME}${CLEAR_ALL_TEXT_STYLES}"
    PWD_SET_FOR_ISO_WONT_PERSIST="${WARNINGCOLOR}The password you just set will NOT persist onto the actual installation.${CLEAR_ALL_TEXT_STYLES}"
    PWD_SET_FOR_ISO_IS_PWD_FOR_SSH="If the ${HIGHLIGHTCOLOR}-s${NOTIFYCOLOR} flag was supplied, then the password you just set will be the password you use to login to the installation media as root via ssh."
    IP_INFO_MSG="The following is your ip info (obtained via ${HIGHLIGHTCOLOR}ip a${CLEAR_ALL_TEXT_STYLES}${NOTIFYCOLOR}):"
    STARTING_SSH_MSG="Attempting to start sshd via ${HIGHLIGHTCOLOR}systemctl start sshd"
    POST_SSH_SETUP_EXIT_MSG="Exiting installer, re-run ${SCRIPTNAME} WTIHOUT the -s flag to continue the installation process"
    SSH_IS_INSTALLED_MSG="SSH is running."
    SSH_LOGIN_AVAILABLE="You can now log into the installation media as root via ssh."
    GETTING_IP_INFO="Getting ip info via ${HIGHLIGHTCOLOR}ip a${CLEAR_ALL_TEXT_STYLES}"
    POST_SSH_SETUP_MSG="The installer will now exit to give you an oppurtunity to login via ssh."
    SSH_SERVICE_LOCATION_MSG="${SSH:-${OPENSSH}} location and sshd service info:"
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

showIpInfoMsg() {
    notifyUser "${IP_INFO_MSG}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}$(ip a | grep -E '[0-9][0-9][.][0-9][.][0-9][.][0-9][0-9][0-9]')${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}$(ip a | grep -E '[0-9][0-9][0-9][.][0-9][.][0-9][.][0-9]')${CLEAR_ALL_TEXT_STYLES}" 3 'dontClear'
}

showPostSSHInstallMsg() {
    notifyUser "${SSH_LOGIN_AVAILABLE}" 0 'dontClear'
    notifyUser "${POST_SSH_SETUP_MSG}" 0 'dontClear'
}

showSSHLocationService() {
    notifyUser "${SSH_SERVICE_LOCATION_MSG}" 0 'dontClear'
    notifyUser "Location: ${HIGHLIGHTCOLOR}$(which ssh)${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
    notifyUser "Service:  ${HIGHLIGHTCOLOR}$(systemctl list-units --type=service | grep ssh | awk '{ print $1 }')${CLEAR_ALL_TEXT_STYLES}" 3 'dontClear'
}

showStartSSHExitMsg()
{
    showSSHLocationService
    showIpInfoMsg
    showPostSSHInstallMsg
    showLoadingBar "${POST_SSH_SETUP_EXIT_MSG}" 'dontClear'
    exitOrContinue 0 "forceExit"
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

showDiskModificationWarning()
{
    notifyUser "${WARNINGCOLOR}Get this right, ${SCRIPTNAME}${CLEAR_ALL_TEXT_STYLES}${WARNINGCOLOR} does not check this for you, if you mis-type this you may loose data!${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
    showDiskInfo
}

showTimeSettings()
{
    notifyUser "${HIGHLIGHTCOLOR}$(timedatectl status | grep 'Local')${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}$(timedatectl status | grep 'Universal')${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
    notifyUser "${CLEAR_ALL_TEXT_STYLES}${HIGHLIGHTCOLOR}$(timedatectl status | grep 'RTC' | sed 's/[[:space:]]*$//g')${CLEAR_ALL_TEXT_STYLES}" 2 'dontClear'
}

installWhich()
{
    showBanner "Pre-installation: Installing which"
    [[ -f "${CACHE_DIR}/.installer_which" ]] && notifyUser "${HIGHLIGHTCOLOR}which${CLEAR_ALL_TEXT_STYLES}${NOTIFYCOLOR} is already installed: ${HIGHLIGHTCOLOR}$(which which)${CLEAR_ALL_TEXT_STYLES}" && return
    showLoadingBar "Installing \"which\" so program locations can be determined"
    pacman -S which --noconfirm
    notifyUser "${HIGHLIGHTCOLOR}which${NOTIFYCOLOR} is now installed on the installation media, this ${WARNINGCOLOR}will NOT persist${NOTIFYCOLOR} onto the actual installation." 0 'dontClear'
    showLoadingBar "'which' is installed, moving on"
    printf "which_already_installed" >> "${CACHE_DIR}/.installer_which"
}

installReflector()
{
    showBanner "Pre-installation: Installing reflector"
    [[ -f "${CACHE_DIR}/.installer_reflector" ]] && notifyUser "${HIGHLIGHTCOLOR}reflector${CLEAR_ALL_TEXT_STYLES}${NOTIFYCOLOR} is already installed: ${HIGHLIGHTCOLOR}$(which reflector)${CLEAR_ALL_TEXT_STYLES}" && return
    showLoadingBar "Installing \"reflector\" to automate configuration of mirrors used by ${HIGHLIGHTCOLOR}pacman${CLEAR_ALL_TEXT_STYLES}"
    pacman -S reflector --noconfirm
    notifyUser "${HIGHLIGHTCOLOR}reflector${NOTIFYCOLOR} is now installed on the installation media, this ${WARNINGCOLOR}will NOT persist${NOTIFYCOLOR} onto the actual installation." 0 'dontClear'
    showLoadingBar "'reflector' is installed, moving on"
    printf "reflector_already_installed" >> "${CACHE_DIR}/.installer_reflector"
}


setRootPassword()
{
    showBanner "Pre-installation: Set root password for installation media"
    [[ -f "${CACHE_DIR}/.installer_pwd" ]] && notifyUser "${PWD_IS_ALREADY_SET}" && return
    notifyUser "${PLS_SET_PWD}" 0 'dontClear'
    passwd || notifyUserAndExit "${PWD_ERROR_OCCURED}" 0 'dontClear' 1
    notifyUser "${PWD_SET_FOR_ISO_WONT_PERSIST}" 0 'dontClear'
    notifyUser "${PWD_SET_FOR_ISO_IS_PWD_FOR_SSH}" 0 'dontClear'
    showLoadingBar "Root password for installation media is set, moving on"
    printf "password_already_set" >> "${CACHE_DIR}/.installer_pwd"
}

startSSH()
{
    showBanner "Pre-installation: SSH"
    if [[ "$(systemctl list-units --type=service | grep ssh | wc -l)" -gt 0 ]]; then
        notifyUser "${SSH} is already running:" 0 'dontClear'
        showStartSSHExitMsg
    fi
    showLoadingBar "${STARTING_SSH_MSG}"
    systemctl start sshd
    [[ "$(systemctl list-units --type=service | grep ssh | wc -l)" -lt 1 ]] && notifyUser "Failed to start sshd. You may need to install/re-install/configure ${SSH}." 0 'dontClear' && exitOrContinue 1 "forceExit"
    showBanner "Pre-installation: SSH is installed and running"
    notifyUser "${SSH_IS_INSTALLED_MSG}" 0 'dontClear'
    showStartSSHExitMsg
}

installPKGSRequiredByInstaller()
{
    showBanner "Pre-installation: Installing packages required by ${SCRIPTNAME}" 0 'dontClear'
    notifyUser "-- Note: These packages will not persist onto actual installation --"
    installWhich
    installReflector
}

syncInstallationMediaTime()
{
    showBanner "Pre-installation: Sync installtion media's time"
    [[ -f "${CACHE_DIR}/.installer_im_time_sync" ]] && notifyUser "Installation media time is already synced:" 0 'dontClear' && showTimeSettings && clear && return
    showLoadingBar "Syncing time settings for installation media" 'dontClear'
    timedatectl set-ntp true || notifyUser "Time seetinggs for installation media were not synced, please re-run ${SCRIPTNAME}" 0 'dontClear'
    notifyUser "Time settings have been updated for installation media:" 2 'dontClear'
    showTimeSettings
    showLoadingBar "Time settings synced for isntallation media, moving on"
    printf "installation_media_time_already_synced" >> "${CACHE_DIR}/.installer_im_time_sync"
}

partitionDisk()
{
    showBanner "Pre-installtion: Partition disk"
    [[ -f "${CACHE_DIR}/.installer_cfdisk" ]] && notifyUser "Disks were already partitioned with ${HIGHLIGHTCOLOR}cfdisk${NOTIFYCOLOR}, to make additional changes run cfdisk again manually." 0 'dontClear' && showDiskInfo && return
    notifyUser "In a moment, cfdisk will start so you can partition the disk. This step is really important, so get it right." 0 'dontClear'
    notifyUser "You will want to partition the disk as follows: (Remember, ${SCRIPTNAME}${NOTIFYCOLOR} is designed to install Arch on an ext4 filesystem)" 0 'dontClear'
    notifyUser "Create one partition for SWAP, size should no more than double your available RAM, and at least as much as available RAM." 0 'dontClear'
    notifyUser "Create one partition for root. This should take up the remiander of the available disk space." 0 'dontClear'
    showLoadingBar "Loading cfdisk so you can partition the disk, you will be given an oppurtunity to review the partitions before moving on with the installtion"
    showBanner "Pre-installtion: Partition disk | ${WARNINGCOLOR}User Input Required"
    notifyUser "Please specify the name of the disk you wish to partition. ${WARNINGCOLOR}If you are unsure about this consult the Arch Wiki${CLEAR_ALL_TEXT_STYLES}${NOTIFYCOLOR}:" 0 'dontClear'
    showDiskModificationWarning
    read -p "Disk name (e.g.${HIGHLIGHTCOLOR}sdb${NOTIFYCOLOR}):${CLEAR_ALL_TEXT_STYLES}" DISK_NAME
    cfdisk "/dev/${DISK_NAME}" || notifyUserAndExit "${WARNINGCOLOR}Warning: ${HIGHLIGHTCOLOR}cfdisk${WARNINGCOLOR} failed to start, please make sure it is installed then re-run ${SCRIPTNAME}" 0 'dontClear' 1
    clear && showBanner "Pre-installation: Partion disks | Complete | To make additional changes run ${HIGHLIGHTCOLOR}cfdisk${NOTIFYCOLOR} manually" && notifyUser "Please review the partions you just created, if everything looks good re-run ${SCRIPTNAME}${NOTIFYCOLOR} to continue the installtion." 0 'dontClear'
    showDiskInfo
    printf "disks_already_partitioned_to_partition_again_run_cfdisk_manually" >> "${CACHE_DIR}/.installer_cfdisk"
    exitOrContinue 0
}

makeExt4Filesystem()
{
    showBanner "Pre-installtion: Make EXT4 filesystem | User Input Required"
    [[ -f "${CACHE_DIR}/.installer_filesystemExt4" ]] && notifyUser "The filesystem was already created on $(cat ${CACHE_DIR}/.installer_filesystemExt4)" && return
    notifyUser "Please specify the name of the partition you created for ${HIGHLIGHTCOLOR}root${NOTIFYCOLOR}:" 0 'dontClear'
    showDiskModificationWarning
    read -p "${HIGHLIGHTCOLOR}Root${CLEAR_ALL_TEXT_STYLES} Partion Name (e.g.${HIGHLIGHTCOLOR}/dev/sdb2${NOTIFYCOLOR}):${CLEAR_ALL_TEXT_STYLES}" ROOT_PARTITION_NAME
    showLoadingBar "Createing EXT4 filesystem on ${ROOT_PARTITION_NAME}"
    showBanner "Pre-installtion: Make EXT4 filesystem"
    mkfs.ext4 "${ROOT_PARTITION_NAME}" || notifyUserAndExit "${WARNINGCOLOR}The filesystem could not be created on ${HIGHLIGHTCOLOR}${ROOT_PARTITION_NAME}" 0 'dontClear' 1
    notifyUser "The filesystem was created successfully" 0 'dontClear'
    showLoadingBar "Ext4 filesystem created, moving on"
    printf "${ROOT_PARTITION_NAME}" >> "${CACHE_DIR}/.installer_filesystemExt4"
}

enableSwap()
{
    showBanner "Pre-installtion: Enable SWAP | User Input Required"
    [[ -f "${CACHE_DIR}/.installer_swap_enabled" ]] && notifyUser "SWAP was already created and enabled on $(cat ${CACHE_DIR}/.installer_swap_enabled)" && return
    notifyUser "Please specify the name of the partition you created for ${HIGHLIGHTCOLOR}SWAP${NOTIFYCOLOR}:" 0 'dontClear'
    showDiskModificationWarning
    read -p "${HIGHLIGHTCOLOR}SWAP${CLEAR_ALL_TEXT_STYLES} Partion Name (e.g.${HIGHLIGHTCOLOR}/dev/sdb1${CLEAR_ALL_TEXT_STYLES}):" SWAP_PARTITION_NAME
    showLoadingBar "Enabling swap via ${HIGHLIGHTCOLOR}mkswap${CLEAR_ALL_TEXT_STYLES} and ${HIGHLIGHTCOLOR}swapon${CLEAR_ALL_TEXT_STYLES} on partition ${HIGHLIGHTCOLOR}${SWAP_PARTITION_NAME}"
    showBanner "Pre-installtion: Enable SWAP"
    mkswap "${SWAP_PARTITION_NAME}" || notifyUserAndExit "${WARNINGCOLOR}Failed to make SWAP on ${HIGHLIGHTCOLOR}${SWAP_PARTITION_NAME}" 0 'dontClear' 1
    swapon "${SWAP_PARTITION_NAME}" || notifyUserAndExit "${WARNINGCOLOR}Failed to turn on SWAP device ${HIGHLIGHTCOLOR}${SWAP_PARTITION_NAME}" 0 'dontClear' 1
    notifyUser "SWAP was created and enabled successfully"
    printf "${SWAP_PARTITION_NAME}" >> "${CACHE_DIR}/.installer_swap_enabled"
}

mountFilesystem()
{
    showBanner "Pre-installtion: Mount filesystem | User Input Required"
    [[ -f "${CACHE_DIR}/.installer_filesystem_mounted" ]] && notifyUser "Filesystem was already mounted from $(cat ${CACHE_DIR}/.installer_filesystem_mounted)" && return
    if [ -z "${ROOT_PARTITION_NAME}" ]
    then
        notifyUser "Please specify the name of the partition you created for ${HIGHLIGHTCOLOR}root${NOTIFYCOLOR}:" 0 'dontClear'
        showDiskModificationWarning
        read -p "${HIGHLIGHTCOLOR}Root${CLEAR_ALL_TEXT_STYLES} Partion Name (e.g.${HIGHLIGHTCOLOR}/dev/sdb2${CLEAR_ALL_TEXT_STYLES}):" ROOT_PARTITION_NAME
    fi
    showLoadingBar "Mounting root filesystem from ${ROOT_PARTITION_NAME} "
    showBanner "Pre-installtion: Mount filesystem"
    mount "${ROOT_PARTITION_NAME}" /mnt || notifyUserAndExit "${WARNINGCOLOR}Failed to mount ${HIGHLIGHTCOLOR}${ROOT_PARTITION_NAME}${WARNINGCOLOR}, please re-run ${SCRIPTNAME}${WARNINGCOLOR} and try again." 0 'dontClear' 1
    notifyUser "Filesystem was mounted successfully at /mnt" 0 'dontClear'
    showLoadingBar "Filesystem mounted, moving on"
    printf "${ROOT_PARTITION_NAME}" >> "${CACHE_DIR}/.installer_filesystem_mounted"
}

updateMirrors()
{
    showBanner "Pre-installtion: Configure mirrors used by ${HIGHLIGHTCOLOR}pacman${BANNER_MSG_COLOR} with ${HIGHLIGHTCOLOR}reflector"
    [[ -f "${CACHE_DIR}/.installer_mirrors_are_up_to_date" ]] && notifyUser "The mirrors used by ${HIGHLIGHTCOLOR}pacman${NOTIFYCOLOR} are already configured and up to date." && return
    notifyUser "${WARNINGCOLOR}--    This may take awhile, DO NOT QUIT TILL THIS STEP IS COMPLETE    --" 0 'dontClear'
    # NOTE: To get a list of countries run: reflector --list-countries
    reflector -c "United States" -a 5 --sort rate --save /etc/pacman.d/mirrorlist || notifyUserAndExit "${HIGHLIGHTCOLOR}reflector${WARNINGCOLOR} was not able to configure the mirrors for ${HIGHLIGHTCOLOR}pacman${WARNINGCOLOR}. Please re-run ${SCRIPTNAME}${WARNINGCOLOR}. If problem persists try re-installing ${HIGHLIGHTCOLOR}reflector${WARNINGCOLOR} with ${HIGHLIGHTCOLOR}pacman -Syy reflector" 0 'dontClear' 1
    pacman -Syy || notifyUserAndExit "${WARNINGCOLOR}mirrors could not be updated for ${HIGHLIGHTCOLOR}pacman${WARNINGCOLOR}. Either re-run ${SCRIPTNAME}${WARNINGCOLOR} or manually run ${HIGHLIGHTCOLOR}pacman -Syy" 1 'dontClear' 1
    notifyUser "Mirrors were configured and updated succesffully." 0 'dontClear'
    showLoadingBar "Mirrors are up to date, moving on"
    printf "mirrors_are_up_to_date" >> "${CACHE_DIR}/.installer_mirrors_are_up_to_date"
}

performPreInsallation() {
    showBanner "Pre-installation"
    showLoadingBar "${LB_PRE_INSTALL_MSG}"
    installPKGSRequiredByInstaller
    setRootPassword
    [[ -n "${SSH}" ]] && startSSH
    syncInstallationMediaTime
    partitionDisk
    makeExt4Filesystem
    enableSwap
    mountFilesystem
    updateMirrors
}

showPacstrapFailedMsg()
{
    notifyUser "${WARNINGCOLOR}Installation cannot be performed, package file ${HIGHLIGHTCOLOR}${WARNINGCOLOR} either does not exist, or is not properly implemented!" 0 'dontClear'
    notifyUser "Make sure that ${HIGHLIGHTCOLOR}${PACKAGE_FILE} exists, and is properly implemented." 0 'dontClear'
    notifyUser "The following is an example of a properly implemented packge file:" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}base${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}base-devel${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}linux${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}linux-headers${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}linux-firmware${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}linux-lts${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}linux-lts-headers${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}networkmanager${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}sudo${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}vim${WARNINGCOLOR}" 0 'dontClear'
    notifyUser "${HIGHLIGHTCOLOR}man${WARNINGCOLOR}" 0 'dontClear'
    notifyUserAndExit "Also, please make sure ${HIGHLIGHTCOLOR}each package${NOTIFYCOLOR} is specified ${HIGHLIGHTCOLOR}on it's own line${NOTIFYCOLOR} in ${HIGHLIGHTCOLOR}${PACKAGE_FILE}" 0 'dontClear' 1
}

validatePacstrapDapFile()
{
    grep -Fxq 'base' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'base-devel' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'linux' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'linux-headers' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'linux-firmware' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'linux-lts' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'linux-lts-headers' "${PACKAGE_FILE}" || showPacstrapFailedMsg
    grep -Fxq 'networkmanager' "${PACKAGE_FILE}" || showPacstrapFailedMsg
}

runPacstrap()
{
    showBanner "Installtion: Run ${HIGHLIGHTCOLOR}pacstrap"
    [[ -f "${CACHE_DIR}/.installer_pacstrap_already_run" ]] && notifyUser "${HIGHLIGHTCOLOR}pacstrap${NOTIFYCOLOR} already ran." && return
    notifyUser "${WARNINGCOLOR}--    This may take awhile, DO NOT QUIT TILL THIS STEP IS COMPLETE    --" 0 'dontClear'
    validatePacstrapDapFile
    pacstrap /mnt $(< "${PACKAGE_FILE}") || showPacstrapFailedMsg
    notifyUser "${HIGHLIGHTCOLOR}pacstrap${NOTIFYCOLOR} ran successfully, to install additional packages, use ${HIGHLIGHTCOLOR}pacman -S PACKAGE_NAME${NOTIFYCOLOR} once logged into the new Arch installation." 0 'dontClear'
    showLoadingBar "${HIGHLIGHTCOLOR}pacstrap${NOTIFYCOLOR} already ran, moving on"
    printf "pacstrap_already_ran_use_pacman_to_install_additional_packages_make_sure_your_logged_into_new_installation_via_arch_chroot" >> "${CACHE_DIR}/.installer_pacstrap_already_run"
}

performInstallation() {
    showBanner "-- Installation --"
    showLoadingBar "${LB_INSTALL_MSG}"
    runPacstrap
}

makeMNTETCDir()
{
    [[ -d /mnt/etc ]] && notifyUser "${HIGHLIGHTCOLOR}/mnt/etc${NOTIFYCOLOR} already exists." 0 'dontClear' && return
    mkdir /mnt/etc || notifyUserAndExit "${WARNINGCOLOR}Failed to create ${HIGHLIGHTCOLOR}/mnt/etc${WARNINGCOLOR}. Please re-run ${SCRIPTNAME}${WARNINGCOLOR}. If problem persists you may need to poweroff the computer and start over." 1 'dontClear' 1
    notifyUser "Created /mnt/etc successfully" 0 'dontClear'
}

configureFstab()
{
    showBanner "Post-installation: Generate fstab"
    [[ -f "${CACHE_DIR}/.installer_fstab_generated" ]] && notifyUser "fstab was already generated at ${HIGHLIGHTCOLOR}/mnt/etc/fstab" && return
    makeMNTETCDir
    genfstab -U -p /mnt >> /mnt/etc/fstab
    [[ -f /mnt/etc/fstab ]] || notifyUserAndExit "${WARNINGCOLOR}Failed to generate fstab. Please re-run ${SCRIPTNAME}${WARNINGCOLOR}. If problem persists you may need to poweroff and start over." 1 'dontClear' 1
    notifyUser "${HIGHLIGHTCOLOR}fstab${NOTIFYCOLOR} was generated successfully at ${HIGHLIGHTCOLOR}/mnt/etc/fstab" 0 'dontClear'
    showLoadingBar "${HIGHLIGHTCOLOR}fstab${NOTIFYCOLOR} was generated at ${HIGHLIGHTCOLOR}/mnt/etc/fstab${NOTIFYCOLOR}, moving on"
    printf "fstab_generated" >> "${CACHE_DIR}/.installer_fstab_generated"
}

showFlagInfo()
{
      showLoadingBar "Loading flag info"
      showBanner "Help: Flags"
      # -C
      notifyUser "The -C flag can be used to force ${SCRIPTNAME}${NOTIFYCOLOR} to perform installation without pausing for user review." 0 'dontClear'
      notifyUser "    For example: Typically ${SCRIPTNAME}${NOTIFYCOLOR} will exit after the partioning stage to give you an opprutunity" 0 'dontClear'
      notifyUser "                 to review the partions you created before continuing." 0 'dontClear'
      notifyUser "                 ${WARNINGCOLOR}If the -C flag is specified, ${SCRIPTNAME}${WARNINGCOLOR} will not exit unless an error occurs" 0 'dontClear'
      notifyUser "Basically, if you want to have an opputunity to review things at appropriate stage of the installation," 0 'dontClear'
      notifyUser "then ${WARNINGCOLOR} dont${NOTIFYCOLOR} use the -C flag." 0 'dontClear'
      notifyUser "If you want ${SCRIPTNAME}${NOTIFYCOLOR} to perform entire installation without stopping, use the -C flag." 0 'dontClear'
      # -p
      notifyUser "The -p flag can be used to specify a package file:" 0 'dontClear'
      notifyUser "${SCRIPTNAME}${HIGHLIGHTCOLOR} -p /path/to/file${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      notifyUser "Any packages named in the specified file will be included in the final insallation." 0 'dontClear'
      # -s
      notifyUser "The -s flag will cause ${SCRIPTNAME}${NOTIFYCOLOR} to attempt to start ssh via ${HIGHLIGHTCOLOR}systemctl start sshd${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      notifyUser "${SCRIPTNAME}${HIGHLIGHTCOLOR} -s${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      notifyUser "openssh MUST be installed for -s to work." 0 'dontClear'
      # -l
      notifyUser "The -l flag will cause ${SCRIPTNAME}${NOTIFYCOLOR} to print a log of all the messages shown while the script was running." 0 'dontClear'
      notifyUser "${SCRIPTNAME}${HIGHLIGHTCOLOR} -l${CLEAR_ALL_TEXT_STYLES}" 0 'dontClear'
      notifyUser "The -l flag is helpful if you need to review what ${SCRIPTNAME}${NOTIFYCOLOR} has done so far." 3 'dontClear'
}

showHelpMsg()
{
      notifyUser "${HELP_MSG_WELCOME1}" 0 'dontClear'
      notifyUser "${HELP_MSG_WELCOME2}" 0 'dontClear'
      notifyUser "${HELP_MSG_WELCOME3}" 0 'dontClear'
      notifyUser "${HELP_MSG_WELCOME4}" 0 'dontClear'
      showFlagInfo
}

mkCacheDir()
{
    mkdir -p "${CACHE_DIR}" || notifyUserAndExit "${CACHE_DIR} does not exist, and could not be created!" 0 'dontClear' 1
    showBanner "Setup cache directory used by ${SCRIPTNAME}"
    showLoadingBar "Attempting to setup cache directory at: ${HIGHLIGHTCOLOR}${CACHE_DIR}" 'dontClear'
}

#################### POST CHROOT #########################

configureTime()
{
    showBanner "${SCRIPTNAME}${BANNER_MSG_COLOR}: Configure Time"
    [[ -f ~/.cache/darlingarch/.config_time ]] && notifyUser "Time was aleady configured." && return
    notifyUser "Setting timezone" 0 'dontClear'
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime || notifyUserAndExit "${WARNINGCOLOR}Failed to set time, you may need to manually ${HIGHLIGHTCOLOR}arch-chroot${WARNINGCOLOR} into the new installation to complete post installation steps manually! Consult the Arch Wiki if you are unsure about this." 0 'dontClear' 1 'forceExit'
    notifyUser "Syncing hardware clock" 0 'dontClear'
    arch-chroot /mnt hwclock --systohc || notifyUserAndExit "${WARNINGCOLOR}Failed to sync hardware clock, you may need to manually ${HIGHLIGHTCOLOR}arch-chroot${WARNINGCOLOR} into the new installation to complete post installation steps manually! Consult the Arch Wiki if you are unsure about this." 0 'dontClear' 1 'forceExit'
    showLoadingBar "Time is configured, moving on."
    printf "time_already_configured" >> ~/.cache/darlingarch/.config_time
}

configureLocale()
{
    showBanner "Localization"
    [[ -f ~/.cache/darlingarch/.config_locale ]] && notifyUser "Localization was already configured." && return
    notifyUser "Setting up localization" 0 'dontClear'
    arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen || notifyUserAndExit "${WARNINGCOLOR}Failed to configure locale. You may need to arch-chroot into the installation manually to perform the remaining post-installation steps." 0 'dontClear' 1
    arch-chroot /mnt locale-gen || notifyUserAndExit "${WARNINGCOLOR}Failed to configure locale. You may need to arch-chroot into the installation manually to perform the remaining post-installation steps." 0 'dontClear' 1
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf || notifyUserAndExit "${WARNINGCOLOR}Failed to configure locale. You may need to arch-chroot into the installation manually to perform the remaining post-installation steps." 0 'dontClear' 1
    showLoadingBar "Localization was configured, moving on"
    printf "locale_is_configured_forInstallation" >> ~/.cache/darlingarch/.config_locale
}

configureNetwork()
{
    showBanner "Network Configuration | ${HIGHLIGHTCOLOR}User Input Required"
    [[ -f ~/.cache/darlingarch/.config_network_configured ]] && notifyUser "Network was already configured." && return
    notifyUser "Setting up network" 0 'dontClear'
    notifyUser "Plese enter the name you wish to assign to you computer, i.e. the hostname:" 0 'dontClear'
    notifyUser "${WARNINGCOLOR}The hostname MUST be alphanumeric, all lowercase, and contain no spaces, ${SCRIPTNAME}${WARNINGCOLOR} does not validate your input, get this right or your Network configuration will be invalid!" 0 'dontClear'
    read -p "Desired hostname (${WARNINGCOLOR}alphanumeric, all lowercase, no spaces${NOTIFYCOLOR}): " HOST_NAME
    [[ -f /mnt/etc/hostname ]] && notifyUser "Deleteing old /etc/hostname file" 0 'dontClear' && rm /mnt/etc/hostname
    [[ -f /mnt/etc/hosts ]] && notifyUser "Deleteing old /etc/hosts file" 0 'dontClear' && rm /mnt/etc/hosts
    echo "${HOST_NAME}" >> /mnt/etc/hostname
    echo "127.0.0.1        localhost" >> /mnt/etc/hosts
    echo "::1              localhost" >> /mnt/etc/hosts
    echo "127.0.1.1        ${HOST_NAME}.localdomain ${HOST_NAME}" >> /mnt/etc/hosts
    notifyUser "Current /etc/hostname file:" 0 'dontClear'
    arch-chroot /mnt cat /etc/hostname
    notifyUser "Current /etc/hosts file:" 0 'dontClear'
    arch-chroot /mnt cat /etc/hosts
    sleep 3
    notifyUser "Enabling NetworkManager" 0 'dontClear'
    arch-chroot /mnt systemctl enable NetworkManager
    showLoadingBar "Network is configured, and NetworkManager is enabled, moving on"
    printf "Network_is_configured_for_installation" >> ~/.cache/darlingarch/.config_network_configured
}

configureRootPassword()
{
    showBanner "Set ${HIGHLIGHTCOLOR}root${BANNER_MSG_COLOR} password"
    [[ -f ~/.cache/darlingarch/.config_root_pwd ]] && notifyUser "Root password was already set, to reset run: ${HIGHLIGHTCOLOR}passwd" && return
    notifyUser "Setting root password" 0 'dontClear'
    arch-chroot /mnt passwd
    showLoadingBar "Root password was set, moving on"
    printf "root_passwd_set_for_installation" >> ~/.cache/darlingarch/.config_root_pwd
}

configureGrub()
{
    showBanner "Install and configure ${HIGHLIGHTCOLOR}grub"
    [[ -f ~/.cache/darlingarch/.config_grub ]] && notifyUser "Grub was already installed and configured on: ${HIGHLIGHTCOLOR}$(cat ~/.cache/darlingarch/.config_grub)" && return
    notifyUser "Setting up ${HIGHLIGHTCOLOR}grub${NOTIFYCOLOR} bootloader" 0 'dontClear'
    arch-chroot /mnt pacman -S grub --noconfirm
    showBanner "Configure Grub | Enter Disk Name | ${HIGHLIGHTCOLOR}User input required"
    notifyUser "Please enter the name of the disk ${DISTRO}${NOTIFYCOLOR} is being installed on. (e.g., ${HIGHLIGHTCOLOR}sdb${NOTIFYCOLOR})" 0 'dontClear'
    showDiskInfo
    read -p "Disk name (e.g., ${HIGHLIGHTCOLOR}sdb${CLEAR_ALL_TEXT_STYLES}): " DISK_NAME
    arch-chroot /mnt grub-install -v --target=i386-pc "/dev/${DISK_NAME}"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    showLoadingBar "Grub was installed and configured on ${HIGHLIGHTCOLOR}${DISK_NAME}${NOTIFYCOLOR}, moving on"
    printf "${DISK_NAME}" >> ~/.cache/darlingarch/.config_grub
}

showUserAlreadyConfiguredMsg()
{
    showBanner "Configure User"
    notifyUser "Initial user account was already created and configured for user $(cat ~/.cache/darlingarch/.config_user)." 0 'dontClear'
    notifyUser "Additional changes to $(cat ~/.cache/darlingarch/.config_user)'s account will have to be made manually." 0 'dontClear'
    notifyUser "Also, any additional user accounts will need to be created and configured manually. Consult the Arch Wiki if you are unsure about how to do this." 0 'dontClear'
}
configureUser()
{
    [[ -f ~/.cache/darlingarch/.config_user ]] && showUserAlreadyConfiguredMsg && return
    notifyUser "" 0 'dontClear'
    showBanner "Configure User | ${HIGHLIGHTCOLOR}User input required"
    notifyUser "Please enter a username:" 0 'dontClear'
    read -p "Desired user name: " USER_NAME
    showLoadingBar "Creating new user"
    arch-chroot /mnt useradd -m -U -G wheel,audio,video,optical,storage -s /bin/bash "${USER_NAME}"
    showBanner "Configure User | Set new user's password | ${HIGHLIGHTCOLOR}User Input Required"
    notifyUser "Please set a password for the new user:" 0 'dontClear'
    arch-chroot /mnt passwd "${USER_NAME}"
    showLoadingBar "Password was set for new user, moving on"
    showBanner "Configure User | Install and configure sudo"
    arch-chroot /mnt pacman -S sudo --noconfirm
    showLoadingBar "${HIGHLIGHTCOLOR}sudo${CLEAR_ALL_TEXT_STYLES} is installed, moving on"
    showBanner "Configure User | Install and configure sudo"
    showLoadingBar "Enableing members of the wheel group to use sudo"
    arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
    showBanner "Configure User | Done"
    showLoadingBar "New user ${USER_NAME} was created, and given sudo privleges, additional changes will need to be made manually, moving on"
    printf "${USER_NAME}" >> ~/.cache/darlingarch/.config_user
}

performPostInstallation() {
    showBanner "-- Post-installation --"
    showLoadingBar "${LB_POST_INSTALL_MSG}"
    configureFstab
    configureTime
    configureLocale
    configureNetwork
    configureRootPassword
    configureGrub
    configureUser
}


########################## PROGRAM #######################

clear
initTextStyles
initMessages
initVars
[[ ! -d "${CACHE_DIR}" ]] && mkCacheDir
# For a great article on getopts, and other approaches to handling bash arguments:
# @see https://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":Cslp:h" OPTION; do
  case "${OPTION}" in
  C)
      CONTINUE="dontExit"
    ;;
  s)
      SSH="${OPENSSH}"
    ;;
  l)
      [[ -f "${CACHE_DIR}/.installer_msg_log" ]] || notifyUserAndExit "There are no logged messages" 0 'dontClear'
      cat "${CACHE_DIR}/.installer_msg_log" | more
      exitOrContinue 0 "forceExit"
    ;;
  p)
      showBanner "Confirm Package File | ${HIGHLIGHTCOLOR}User Input Required"
      notifyUser "You specified ${OPTARG} as the package file:" 0 'dontClear'
      notifyUser "${WARNINGCOLOR}Get this right, specifying the wrong file may cause installation to fail! If you are unsure about this, dont use the ${HIGHLIGHTCOLOR}-p${WARNINGCOLOR} flag!" 0 'dontClear'
      printf "\n"
      read -p "Is this correct? (Enter ${HIGHLIGHTCOLOR}Y${CLEAR_ALL_TEXT_STYLES} to continue, any other key to exit): " USER_VERIFIED_PACKAGE_FILE
      [[ "${USER_VERIFIED_PACKAGE_FILE}" == 'Y' ]] || notifyUserAndExit "Please re-run ${SCRIPTNAME}${NOTIFYCOLOR}, either with or without the ${HIGHLIGHTCOLOR}-p${NOTIFYCOLOR} flag. For help use ${SCRIPTNAME}${HIGHLIGHTCOLOR} -h${NOTIFYCOLOR}" 0 'dontClear' 1
      PACKAGE_FILE="${OPTARG}"
      validatePacstrapDapFile
    ;;
  h)
      showBanner "Help"
      showHelpMsg
      showBanner "Help"
      notifyUser "${SCRIPTNAME}${NOTIFYCOLOR} will now exit." 0 'dontClear'
      notifyUser "Tip: Run ${SCRIPTNAME}${HIGHLIGHTCOLOR} -l${NOTIFYCOLOR} to quickly view the preivous help messages, as well as any other messages output by ${SCRIPTNAME}" 0 'dontClear'
      showLoadingBar "Exiting installer"
      exitOrContinue 0 "forceExit"
    ;;
  \?)
     animatedPrint "Invalid argument: -${OPTARG}" && exitOrContinue 1 "forceExit"
    ;;
  :)
      showBanner "${WARNINGCOLOR}Error | Invalid flag use"
      notifyUser "${WARNINGCOLOR}The ${HIGHLIGHTCOLOR}-${OPTARG}${WARNINGCOLOR} expects an argument!" 2 'dontClear'
      showFlagInfo
      notifyUserAndExit "Please re-run ${SCRIPTNAME}${NOTIFYCOLOR} with correct syntax. Use ${SCRIPTNAME}${HIGHLIGHTCOLOR} -h${NOTIFYCOLOR} to view help info" 0 'dontClear' 1
    ;;
  esac
done
clear

performPreInsallation

performInstallation

performPostInstallation

showBanner "Finished"
notifyUserAndExit "Installation is complete, you should now be able to ${HIGHLIGHTCOLOR}poweroff${NOTIFYCOLOR} your computer, ${HIGHLIGHTCOLOR}remove the installation media${NOTIFYCOLOR}, ${HIGHLIGHTCOLOR}turn the computer back on${NOTIFYCOLOR}, and begin enjoying your new ${GREEN_FG_COLOR}Arch Linux${NOTIFYCOLOR} installation." 0  'dontClear' 0


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
}

notifyUserAndExit()
{
    notifyUser "${1}" "${2:-1}" "${3:-CLEAR}"
    exitOrContinue "${4:-0}" "${5:-default}"
}

initTextStyles
showLoadingBar "Setup will begin in a moment"
notifyUser "Installing vim, tmux, htop, and rsync" 0 'dontClear'
pacman -Syy tmux vim htop rsync --noconfirm
showLoadingBar "vim, tmux, tmux, htop are now installed, moving on"
showLoadingBar "Configuring git"
git config --global user.name "sevidmusic"
git config --global user.email "sdmwebsdm&gmail.com"
notifyUser "syncing user configuration files" 0 'dontClear'
[[ -d /root/.config/htop ]] || mkdir -p /root/.config/htop
rsync -cv ~/DarlingArch/.autorsync ~/.autorsync && chmod 755 ~/.autorsync
rsync -cv ~/DarlingArch/.bashrc ~/.bashrc && chmod 755 ~/.bashrc
rsync -cv ~/DarlingArch/.bash_aliases ~/.bash_aliases && chmod 755 ~/.bash_aliases
rsync -cv ~/DarlingArch/.bash_profile ~/.bash_profile && chmod 755 ~/.bash_profile
rsync -cv ~/DarlingArch/.tmux.conf ~/.tmux.conf && chmod 755 ~/.tmux.conf
rsync -cv ~/DarlingArch/.vimrc ~/.vimrc && chmod 755 ~/.vimrc
rsync -cv ~/DarlingArch/htoprc /root/.config/htop/htoprc && chmod 755 /root/.config/htop/htoprc
notifyUser "The following is a listing of the ~/ directory:" 0 'dontClear'
ls -a
showLoadingBar "Configuration files have been synced"
showLoadingBar "Making ~/Code direcotry"
[[ -d ~/Code ]] || mkdir ~/Code
showLoadingBar "Moving ~/DarlingArch to ~/Code/DarlingArch"
mv ~/DarlingArch ~/Code/DarlingArch
showLoadingBar "Setup complete"

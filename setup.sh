#!/bin/bash

set -o posix

error_dshells_repo_missing() {
    printf "\n\nPlease clone or mv DarlingArch repo to ~/DarlingArch to use this script"
    exit 1
}

[[ -f ~/DarlingArch/darlingarch.sh ]] || error_dshells_repo_missing

printf "\n\nInstalling vim, tmux, and htop\n\n" && sleep 2
pacman -Syy tmux vim htop rsync --noconfirm

sleep 2 && clear

printf "\n\nConfiguring git\n\n" && sleep 2
git config --global user.name "sevidmusic"
git config --global user.email "sdmwebsdm&gmail.com"

sleep 2 && clear

printf "\n\nsyncing user configuration files\n\n" && sleep 2
[[ -d /root/.config/htop ]] || mkdir -p /root/.config/htop
rsync -c ~/DarlingArch/.autorsync ~/.autorsync && chmod 755 ~/.autorsync
rsync -c ~/DarlingArch/.bashrc ~/.bashrc && chmod 755 ~/.bashrc
rsync -c ~/DarlingArch/.bash_aliases ~/.bash_aliases && chmod 755 ~/.bash_aliases
rsync -c ~/DarlingArch/.bash_profile ~/.bash_profile && chmod 755 ~/.bash_profile
rsync -c ~/DarlingArch/.tmux.conf ~/.tmux.conf && chmod 755 ~/.tmux.conf
rsync -c ~/DarlingArch/.vimrc ~/.vimrc && chmod 755 ~/.vimrc
rsync -c ~/DarlingArch/darlingarch.sh ~/darlingarch.sh && chmod 755 ~/darlingarch.sh
rsync -c ~/DarlingArch/darlingarch_post_chroot.sh ~/darlingarch_post_chroot.sh && chmod 755 ~/darlingarch_post_chroot.sh
rsync -c ~/DarlingArch/pacstrap.dap ~/pacstrap.dap && chmod 755 ~/pacstrap.dap
rsync -c ~/DarlingArch/htoprc /root/.config/htop/htoprc && chmod 755 /root/.config/htop/htoprc

sleep 2 && clear

printf "\n\nMaking ~/Code direcotry\n\n" && sleep 2
[[ -d ~/Code ]] || mkdir ~/Code

sleep 2 && clear

printf "\n\nMoving ~/DarlingArch to ~/Code/DarlingArch\n\n" && sleep 2
mv ~/DarlingArch ~/Code/DarlingArch

printf "\n\Moving back into home directory:\n\n"
cd ~/

sleep 2 && clear

printf "\n\nCurrent directory:\n\n"

pwd

printf "\n\n"

ls -a

sleep 4 && clear

printf "\n\n/root/.config/htop dirctory listing:\n\n"

ls -a /root/.config/htop

sleep 4 && clear

printf "\n\nLoading user configuration settings:\n\n"
[[ -f ~/.bash_profile ]] && source ~/.bash_profile
sleep 4 && clear

printf "\n\nDone\n\n"


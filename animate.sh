#!/bin/bash

set -o posix

FRAME_DIR="${1}";
clear && reset
while :; do for FRAME in `find $FRAME_DIR -type f`; do printf "$(cat "${FRAME}")"; printf "\e[0m"; sleep "${2:-0.05}"; clear; done; done

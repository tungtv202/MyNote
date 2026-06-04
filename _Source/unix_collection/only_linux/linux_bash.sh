#!/usr/bin/env zsh

LINUX_BASH_DIR="${${(%):-%x}:A:h}"

alias ms="bash $LINUX_BASH_DIR/mouse_wheel.sh"
alias sdn="sudo shutdown -h now"
alias rsn="sudo reboot -h now"
alias open="nautilus ."

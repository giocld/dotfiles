#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Nord dotfiles aliases
alias clock="tty-clock -c -C 6"
alias pipesh="pipes.sh -p 5 -c 4 -f 100"

. "$HOME/.local/bin/env"

# Source sevens-dots configuration
source ${HOME}/.config/zsh/config.zsh
export STEAM_FORCE_DESKTOPUI_SCALING=1
# Prevent zsh-newuser-install wizard
zstyle :compinstall filename '/home/gio/.zshrc'

. "$HOME/.local/bin/env"
alias fixown='sudo chown -R $USER:$USER'
# then: fixown /home/gio/Projects/metronomegr

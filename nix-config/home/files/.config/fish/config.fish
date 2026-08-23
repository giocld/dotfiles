# Disable greeting
set -U fish_greeting ""

# Fastfetch on startup
fastfetch

# Starship prompt
if status is-interactive
    set -gx STARSHIP_CONFIG $HOME/.config/starship/starship.toml
    starship init fish | source
end

# Format man pages
set -x MANROFFOPT -c
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Source fish_profile if exists
if test -f $HOME/.fish_profile
    source $HOME/.fish_profile
end

# PATH additions
for p in $HOME/.local/bin $HOME/.npm-global/bin $HOME/.local/share/nvim/mason/bin
    if test -d $p
        if not contains -- $p $PATH
            set -p PATH $p
        end
    end
end

#####################
### Key Bindings  ###
#####################
# Enable vim bindings
set -g fish_key_bindings fish_vi_key_bindings

# Always block cursor (disable cursor switching)
function fish_mode_prompt
    echo -n ''
end

# !! and !$ support
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

bind ! __history_previous_command
bind '$' __history_previous_command_arguments

# Ctrl+Backspace / Alt+Backspace — kill path component backward
bind -M insert \e\[127\;5u backward-kill-path-component
bind -M insert \e\x7f backward-kill-path-component
bind -M default \e\[127\;5u backward-kill-path-component
bind -M default \e\x7f backward-kill-path-component

##################
### Functions  ###
##################
# Better history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (string trim -r -c '/' $argv[1])
        set to $argv[2]
        command cp -r $from $to
    else
        command cp $argv
    end
end

# mkcd DIR
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

# Extract archives
function extract
    set file $argv[1]
    if test -f $file
        switch $file
            case '*.tar.bz2'
                tar xjf $file
            case '*.tar.gz'
                tar xzf $file
            case '*.bz2'
                bunzip2 $file
            case '*.rar'
                unrar x $file
            case '*.gz'
                gunzip $file
            case '*.tar'
                tar xvf $file
            case '*.tbz2'
                tar xjf $file
            case '*.tgz'
                tar xzf $file
            case '*.zip'
                unzip $file
            case '*.Z'
                uncompress $file
            case '*.7z'
                7z x $file
            case '*'
                echo "'$file' cannot be extracted via extract()"
        end
    else
        echo "'$file' is not a valid file"
    end
end

##################
### Aliases    ###
##################
# ls replacements
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.='eza -a | grep -e "^\."'

# Gruvbox colors for eza (ls) output
set -gx EZA_COLORS "di=38;2;102;92;84:ln=38;5;66:ex=38;5;102:pi=38;5;238:so=38;5;59:bd=38;5;59:cd=38;5;59:or=38;5;88:su=38;5;102:sg=38;5;88:ow=38;2;102;92;84:st=38;2;102;92;84:mh=38;5;66:da=38;5;240:sn=38;5;102:sb=38;5;245:in=38;5;240:bl=38;5;59:hd=38;5;101:lp=38;5;66:cc=38;5;240:lc=38;5;240:rc=38;5;240:xx=38;5;240:ur=38;5;102:uw=38;5;59:ux=38;5;102:ue=38;5;102:gr=38;5;102:gw=38;5;59:gx=38;5;102:tr=38;5;102:tw=38;5;59:tx=38;5;102:su=38;5;102:sf=38;5;102:uu=38;5;66:un=38;5;240:gu=38;5;95:gn=38;5;240:ga=38;5;95:gm=38;5;59:gd=38;5;88:gv=38;5;66:gt=38;5;66:gi=38;5;239:*.tar=38;5;66:*.tgz=38;5;66:*.gz=38;5;66:*.xz=38;5;66:*.bz2=38;5;66:*.zst=38;5;66:*.zip=38;5;66:*.7z=38;5;66:*.rar=38;5;66:*.deb=38;5;66:*.rpm=38;5;66:*.jar=38;5;66:*.war=38;5;66:*.ear=38;5;66:*.jpg=38;5;60:*.jpeg=38;5;60:*.png=38;5;60:*.gif=38;5;60:*.bmp=38;5;60:*.svg=38;5;60:*.webp=38;5;60:*.ico=38;5;60:*.avif=38;5;60:*.mkv=38;5;60:*.mp4=38;5;60:*.webm=38;5;60:*.avi=38;5;60:*.mov=38;5;60:*.mp3=38;5;60:*.flac=38;5;60:*.ogg=38;5;60:*.wav=38;5;60:*.opus=38;5;60:*.pdf=38;5;101:*.doc=38;5;101:*.docx=38;5;101:*.xls=38;5;101:*.xlsx=38;5;101:*.ppt=38;5;101:*.pptx=38;5;101:*.odt=38;5;101:*.ods=38;5;101:*.odp=38;5;101:*.epub=38;5;101:*.txt=38;5;102:*.md=38;5;102:*.rst=38;5;102:*.tex=38;5;102:*.log=38;5;102:*.csv=38;5;102:*.json=38;5;102:*.toml=38;5;102:*.yaml=38;5;102:*.yml=38;5;102:*.xml=38;5;102:*.html=38;5;102:*.css=38;5;102:*.js=38;5;102:*.ts=38;5;102:*.tsx=38;5;102:*.rs=38;5;102:*.go=38;5;102:*.py=38;5;102:*.sh=38;5;102:*.c=38;5;102:*.h=38;5;102:*.cpp=38;5;102:*.hpp=38;5;102:*.java=38;5;102:*.nix=38;5;102:*.lua=38;5;102:*.fish=38;5;102"

# System helpers
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Shortcuts
alias please='sudo'
alias jctl="journalctl -p 3 -xb"
alias ff='fastfetch'
alias q='exit'
alias h='history'
alias c='clear'

# Dotfiles bare repo
alias config='/usr/bin/git --git-dir=$HOME/.cfg --work-tree=$HOME'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcl='git clone'
alias gl='git log --oneline'
alias gd='git diff'
alias gpush='git push'
alias gpull='git pull'

# System control
alias wifi='nmtui'
alias shutdown='systemctl poweroff'

###################
### Environment ###
###################
set -gx SHELL_CONFIG_DIR $HOME/.config
set -gx GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH
set -gx CARGO_HOME $HOME/.cargo
set -gx PATH $CARGO_HOME/bin $PATH
# ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"

# ~/.bashrc — Russ's homelab shell config
# Managed via https://github.com/russshearer/dotfiles

# If not running interactively, bail
case $- in
    *i*) ;;
      *) return;;
esac

# ----------------------------------------------------------
# History
# ----------------------------------------------------------
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%F %T  "
shopt -s histappend

# ----------------------------------------------------------
# Shell options
# ----------------------------------------------------------
shopt -s checkwinsize   # Update LINES/COLUMNS after each command
shopt -s cdspell        # Auto-correct minor cd typos
shopt -s dirspell       # Auto-correct dir name typos in completion
shopt -s globstar       # ** matches recursively

# ----------------------------------------------------------
# PATH
# ----------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ----------------------------------------------------------
# Prompt — Oh My Posh (with fallback)
# ----------------------------------------------------------
__git_branch() {
    git branch 2>/dev/null | sed -n 's/* \(.*\)/ (\1)/p'
}

if command -v oh-my-posh &>/dev/null; then
    eval "$(oh-my-posh init bash --config https://github.com/russshearer/terminal/raw/main/oh-my-posh/themes/myterm.omp.json)"
else
    # Fallback: basic colored prompt if oh-my-posh isn't installed
    # Set terminal tab title
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}:${PWD}\007"'

    if [ "$(id -u)" -eq 0 ]; then
        PS1='\[\e[1;31m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    else
        PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[33m\]$(__git_branch)\[\e[0m\]\$ '
    fi
fi

# ----------------------------------------------------------
# Aliases (sourced from .bash_aliases if it exists)
# ----------------------------------------------------------
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# ----------------------------------------------------------
# Completions
# ----------------------------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# kubectl completion
command -v kubectl &>/dev/null && source <(kubectl completion bash)

# helm completion
command -v helm &>/dev/null && source <(helm completion bash)

# terraform completion
command -v terraform &>/dev/null && complete -C terraform terraform

# ----------------------------------------------------------
# Default editor
# ----------------------------------------------------------
export EDITOR=vim
export VISUAL=vim

# ----------------------------------------------------------
# Colors for ls and grep
# ----------------------------------------------------------
export CLICOLOR=1
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ----------------------------------------------------------
# Local overrides (not tracked in git)
# ----------------------------------------------------------
if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi


# ----------------------------------------------------------
# Profile reload
# ----------------------------------------------------------
rlp() {
    source ~/.bashrc
    eval "$(oh-my-posh init bash --config "https://raw.githubusercontent.com/russshearer/terminal/main/oh-my-posh/themes/myterm.omp.json"
    echo -e "\e[32mBash profile and Oh My Posh theme reloaded!\e[0m"
}

# Fark's zshrc 



export YDOTOOL_SOCKET=/tmp/.ydotool_socket

#doom emacs "doom" path
export PATH="$HOME/.emacs.d/bin:$PATH"


#rust shanenigasn

export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/fark/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lambda prompt
# Enable true color

setopt PROMPT_SUBST

# Lambda prompt with colors
PROMPT='%{$( [[ $EUID == 0 ]] && echo "%F{#c68aee}" || echo "%F{#79c3ee}" )%} λ %f %~ %# '
    
bindkey "^[[1;5C" forward-word   # Ctrl+Right
bindkey "^[[1;5D" backward-word  # Ctrl+Left
bindkey "^H" backward-kill-word  # Ctrl+Backspace

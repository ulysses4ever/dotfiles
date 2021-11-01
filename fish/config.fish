starship init fish | source
fish_vi_key_bindings

alias l="exa"
alias l1="exa -1"
alias ll="exa -l"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias p="ssh prl-julia"

set GPG_TTY (tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

function cd
    if count $argv > /dev/null
        builtin cd "$argv"; and ll
    else
        builtin cd ~
    end
end

function cdc
    cd "$argv"; and clear
end


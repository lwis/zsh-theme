function human_time_to_var() {
    local human
    local total_milliseconds=$1
    local var=$2
    local total_seconds=$(printf '%d' $total_milliseconds)

    if [[ $total_seconds -ge 1 ]]; then
        local days=$(( total_seconds / 60 / 60 / 24 ))
        local hours=$(( total_seconds / 60 / 60 % 24 ))
        local minutes=$(( total_seconds / 60 % 60 ))
        local seconds=$(( total_seconds % 60 ))
        (( days > 0 )) && human+="${days}d "
        (( hours > 0 )) && human+="${hours}h "
        (( minutes > 0 )) && human+="${minutes}m "
        human+="${seconds}s"
    else
        local milliseconds=$(printf '%d' $((total_milliseconds*1000)))
        human+="${milliseconds}ms"
    fi

    typeset -g "${var}"="${human}"
}

function prompt_preexec() {
    export timer=${timer:-$EPOCHREALTIME}
}

function prompt_precmd() {
    unset PROMPT_EXECUTION_TIME

    if [[ -n $timer ]]; then
        human_time_to_var $(($EPOCHREALTIME - $timer)) "timer_show"
        export PROMPT_EXECUTION_TIME="%F{cyan}‹${timer_show}›%f "
        unset timer
        unset timer_show
    fi
}

function parse_git_dirty() {
    local STATUS=$(command git status --porcelain 2> /dev/null | tail -n1)

    if [[ -n $STATUS ]]; then
        echo "*"
    fi
}

function check_git_arrows() {
    # check if there is an upstream configured for this branch
    command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

    local arrow_status
    # check git left and right arrow_status
    arrow_status="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
    # exit if the command failed
    (( !$? )) || return

    # left and right are tab-separated, split on tab and store as array
    arrow_status=(${(ps:\t:)arrow_status})
    local arrows left=${arrow_status[1]} right=${arrow_status[2]}

    (( ${right:-0} > 0 )) && arrows+="⇣"
    (( ${left:-0} > 0 )) && arrows+="⇡"

    echo "${arrows}"
}

function check_git_stash() {
    local stash_count=$(command git stash list 2> /dev/null | wc -l | tr -d ' ')

    if [[ $stash_count -gt 0 ]]; then
        echo "($stash_count)"
    fi
}

function git_prompt_info() {
    local ref
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    echo "%F{yellow}‹${ref#refs/heads/}%B$(check_git_stash)%F{red}$(parse_git_dirty)%b%F{yellow}$(check_git_arrows)›%f "
}

function virtualenv_prompt_info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        if [[ -f "$VIRTUAL_ENV/__name__" ]]; then
            local name=`cat $VIRTUAL_ENV/__name__`
        elif [ `basename $VIRTUAL_ENV` = "__" ]; then
            local name=$(basename $(dirname $VIRTUAL_ENV))
        else
            local name=$(basename $VIRTUAL_ENV)
        fi
        echo "%F{green}‹venv:$name›%f "
    fi
}

function jenv_prompt_info() {
    if $(jenv local &> /dev/null); then
        echo "%F{magenta}‹jenv:$(jenv local)›%f "
    fi
}

function user_display_prompt_info() {
    local display
    local user

    if [[ $UID -eq 0 ]]; then
        user="%B%F{white}%n%f%b"
    else
        user="%B%F{blue}%n%f%b"
    fi

    if [[ "$SSH_CONNECTION" != '' ]]; then
        display="%F{yellow}[SSH]$user %B%F{blue}on %m%f%b "
    else
        display="$user%B%F{blue} on %m%f%b "
    fi

    echo $display
}

local nl='
'

function theme_setup() {
    PROMPT_EOL_MARK=''

    zmodload zsh/datetime
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd prompt_precmd
    add-zsh-hook preexec prompt_preexec

    local user_host="$(user_display_prompt_info)"
    local exe_time='$PROMPT_EXECUTION_TIME'
    local current_dir='%~ '
    local git_branch='$(git_prompt_info)'
    local virtualenv='$(virtualenv_prompt_info)'
    local jenv='$(jenv_prompt_info)'

    local return_code="%(?..%F{red}%? ↵%f)"
    local prompt_color="%(?.%F{green}❯.%F{red}❯%f)"

    local prompt_top="╭─${user_host}${exe_time}${current_dir}${git_branch}${virtualenv}${jenv}"
    local prompt_btm="╰─${prompt_color} "

    PROMPT="${prompt_top}${nl}${prompt_btm}"

    RPS1="${return_code}"
}

theme_setup

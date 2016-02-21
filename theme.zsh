# black or 0	  red or 1
# green or 2	  yellow or 3
# blue or 4	    magenta or 5
# cyan or 6	    white or 7

local nl='
'

function prompt_pure_human_time_to_var() {
  local human
  local total_milliseconds=$1
  local var=$2
  local total_seconds=$(printf '%d' $total_milliseconds)

  if [ $total_seconds -ge 1 ]
  then
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
  timer=${timer:-$EPOCHREALTIME}
}

function prompt_precmd() {
  if [ $timer ]; then
    prompt_pure_human_time_to_var $(($EPOCHREALTIME - $timer)) "timer_show"
    export EXECUTION_TIME="%F{cyan}‹${timer_show}›%f"
    unset timer
  fi
}

function parse_git_dirty() {
  local STATUS=$(command git status --porcelain 2> /dev/null | tail -n1)

  if [[ -n $STATUS ]]; then
    echo "*"
  fi
}

function git_prompt_info() {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
  echo "%F{yellow}‹${ref#refs/heads/}%B%F{red}$(parse_git_dirty)%b%F{yellow}›%f"
}

function virtualenv_prompt_info() {
    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -f "$VIRTUAL_ENV/__name__" ]; then
            local name=`cat $VIRTUAL_ENV/__name__`
        elif [ `basename $VIRTUAL_ENV` = "__" ]; then
            local name=$(basename $(dirname $VIRTUAL_ENV))
        else
            local name=$(basename $VIRTUAL_ENV)
        fi
        echo "%F{green}‹venv:$name›%f"
    fi
}

function user_display() {
  local display

  if [[ "$SSH_CONNECTION" != '' ]]
  then
    display="%F{yellow}‹SSH› %n %B%F{blue}on %m%f%b"
  else
    display="%B%F{blue}%n on %m%f%b"
  fi

  echo $display
}

function theme_setup() {
  PROMPT_EOL_MARK=''

  zmodload zsh/datetime
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd prompt_precmd
  add-zsh-hook preexec prompt_preexec

  local user_host="$(user_display) "
  local exe_time='$EXECUTION_TIME '
  local current_dir='%~ '
  local git_branch='$(git_prompt_info) '
  local virtualenv='$(virtualenv_prompt_info) '

  local return_code="%(?..%F{red}%? ↵%f)"

  local prompt_top="╭─${user_host}${exe_time}${current_dir}${git_branch}${virtualenv}"
  local prompt_btm="╰─❯ "

  PROMPT="${prompt_top}${nl}${prompt_btm}"

  RPS1="${return_code}"
}

theme_setup

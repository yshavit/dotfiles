#!/usr/bin/env bash

without_color() {
  sed -E $'s/\x1b\\[[0-?]*[ -/]*[@-~]//g'
}

char_count() {
  PYTHONIOENCODING=utf-8 python3 -c "import sys; print(len(sys.stdin.read()))"
}

progress_bar() {
  local value="$(echo "$1" | grep -o '^[0-9]\+')"
  local width=${2:-8}
  local eighths=$(( value * width * 8 / 100 ))
  local filled=$(( eighths / 8 ))
  local partial=$(( eighths % 8 ))
  local empty=$(( width - filled - ( partial > 0 ? 1 : 0 ) ))
  local partial_chars=($'\x20' '▏' '▎' '▍' '▌' '▋' '▊' '▉')
  local color
  if (( value <= 80 )); then
    color=$'\e[2;32m'
  elif (( value <= 90 )); then
    color=$'\e[2;33m'
  else
    color=$'\e[2;31m'
  fi
  local reset=$'\e[0m'
  local bar="${color}"
  local i
  for (( i = 0; i < filled; i++ )); do bar+='█'; done
  (( partial > 0 )) && bar+="${partial_chars[$partial]}"
  bar+="${reset}"
  for (( i = 0; i < empty; i++ )); do bar+=' '; done
  printf '[%s] %d%%' "$bar" "$value"
}

input=$(cat)

session_name=$(echo "$input" | jq -r '.session_name // ""')

# Directory: just the last component of cwd
project_dir=$(echo "$input" | jq -r '.workspace.project_dir')
project_dir=${project_dir/#$HOME/\~}
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
if command -v cygpath &>/dev/null; then
  cwd="$(cygpath "$cwd")"
  project_dir="$(cygpath "$project_dir")"
fi
cwd="${cwd/#$HOME/\~}"
project_dir="${project_dir/#$HOME/\~}"

if [[ "$project_dir" != "$cwd" ]]; then
  project_dir="(from $project_dir)"
else
  project_dir=''
fi

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // "unknown model"')

# Git repo (owner/name) if available
branch="$(git branch --show-current 2>/dev/null || printf '')"

# Context remaining percentage
remaining_ctx=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [[ -n "$remaining_ctx" ]]; then
  taken_ctx="$(( 100 - "$remaining_ctx" ))"
else
  taken_ctx=0
fi

echo "$input" | jq '.' > ~/tmp-claude.json

remaining_rate=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage')
# And now get a nice string for how long until it resets
reset=$(jq -r '.rate_limits.five_hour.resets_at // ""' <<<"$input")
if [[ -n "$reset" ]]; then
  now=$(date +%s)
  diff=$(( reset - now ))
  (( diff < 0 )) && diff=0
  if (( diff >= 3600 )); then
    rate_reset_at=$(printf '%dh%dm' $(( diff / 3600 )) $(( diff % 3600 / 60 )))
  else
    rate_reset_at=$(printf '%dm' $(( diff / 60 )))
  fi
else
  rate_reset_at=''
fi

cwd_and_branch=''
[ -n "$cwd" ] && cwd_and_branch="${cwd_and_branch}${cwd}"
if [[ -n "$branch" ]]; then
  [ -n "$cwd_and_branch" ] && cwd_and_branch="$cwd_and_branch"$'\e[0;96m \e[0m'
  cwd_and_branch="$cwd_and_branch"$'\e[34m'""$'\e[0;36m'"<${branch}>"$'\e[0m'
fi

# Build the status line
first_parts=()
[ -n "$session_name" ] && first_parts+=($'\e[0;36m'"«${session_name}»"$'\e[0m')
[ -n "$cwd_and_branch" ] && first_parts+=("$cwd_and_branch")
[ -n "$project_dir" ] && first_parts+=("$project_dir")
first_part="${first_parts[*]}"

model_info="$(printf '%s%s%s' $'\e[0;35m' "${model:-No Model}" $'\e[0m')"
[ -n "$remaining_ctx" ] && model_info="$(printf '%s ctx:%s' "$model_info" "$(progress_bar "$taken_ctx")")"
[ -n "$rate_reset_at" ] && model_info="$(printf '%s · usage:%s (%s)' "$model_info" "$(progress_bar "$remaining_rate")" "$rate_reset_at")"

everything_with_colors="$(printf '%s · %s' "$first_part" "$model_info")"

prompt_len="$(<<<"$everything_with_colors" without_color | char_count)"
prompt_len=$(( prompt_len + 2 )) # claude code adds some padding
if [[ "$prompt_len" -le "$(tput cols)" ]]; then
  printf '%s' "$everything_with_colors"
else
  printf '%s\n%s' "$first_part" "$model_info"
fi


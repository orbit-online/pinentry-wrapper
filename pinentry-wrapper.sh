#!/usr/bin/env bash

pinentry_wrapper() {
  set -eo pipefail
  shopt -s inherit_errexit
  local pkgroot
  pkgroot=$(upkg root "${BASH_SOURCE[0]}")
  # shellcheck source=.upkg/orbit-online/records.sh/records.sh
  source "$pkgroot/.upkg/orbit-online/records.sh/records.sh"
  PATH="$pkgroot/.upkg/.bin:$PATH"

  DOC="Pinentry Wrapper - Cross-platform pinentry script with a CLI interface
Usage:
  pinentry-wrapper [options] PROMPT

Options:
  -d --desc TEXT    Text to appear below the prompt
  -o --ok TEXT      Text for the OK button [default: OK]
  -c --cancel TEXT  Text for the Cancel button [default: Cancel]
  -e --error TEXT   Set an error text
"
# docopt parser below, refresh this parser with `docopt.sh pinentry-wrapper.sh`
# shellcheck disable=2016,1090,1091,2034
docopt() { source "$pkgroot/.upkg/andsens/docopt.sh/docopt-lib.sh" '1.0.0' || {
ret=$?; printf -- "exit %d\n" "$ret"; exit "$ret"; }; set -e
trimmed_doc=${DOC:0:335}; usage=${DOC:71:42}; digest=64ce0; shorts=(-c -d -o -e)
longs=(--cancel --desc --ok --error); argcounts=(1 1 1 1); node_0(){
value __cancel 0; }; node_1(){ value __desc 1; }; node_2(){ value __ok 2; }
node_3(){ value __error 3; }; node_4(){ value PROMPT a; }; node_5(){
optional 0 1 2 3; }; node_6(){ optional 5; }; node_7(){ required 6 4; }
node_8(){ required 7; }; cat <<<' docopt_exit() {
[[ -n $1 ]] && printf "%s\n" "$1" >&2; printf "%s\n" "${DOC:71:42}" >&2; exit 1
}'; unset var___cancel var___desc var___ok var___error var_PROMPT; parse 8 "$@"
local prefix=${DOCOPT_PREFIX:-''}; unset "${prefix}__cancel" "${prefix}__desc" \
"${prefix}__ok" "${prefix}__error" "${prefix}PROMPT"
eval "${prefix}"'__cancel=${var___cancel:-Cancel}'
eval "${prefix}"'__desc=${var___desc:-}'; eval "${prefix}"'__ok=${var___ok:-OK}'
eval "${prefix}"'__error=${var___error:-}'
eval "${prefix}"'PROMPT=${var_PROMPT:-}'; local docopt_i=1
[[ $BASH_VERSION =~ ^4.3 ]] && docopt_i=2; for ((;docopt_i>0;docopt_i--)); do
declare -p "${prefix}__cancel" "${prefix}__desc" "${prefix}__ok" \
"${prefix}__error" "${prefix}PROMPT"; done; }
# docopt parser above, complete command for generating this parser is `docopt.sh --library='"$pkgroot/.upkg/andsens/docopt.sh/docopt-lib.sh"' pinentry-wrapper.sh`
  eval "$(docopt "$@")"

  local pinentry_cmd pinentry_mac="pinentry-mac" pinentry_win="/mnt/c/Program Files (x86)/Gpg4win/bin/pinentry.exe"
  if type pinentry >/dev/null 2>&1; then
    pinentry_cmd=pinentry
  elif type "$pinentry_win" >/dev/null 2>&1; then
    pinentry_cmd=$pinentry_win
  elif type "$pinentry_mac" >/dev/null 2>&1; then
    pinentry_cmd=$pinentry_mac
  else
    fatal "Missing dependency: Unable to find pinentry command"
  fi

  verbose "pinentry command found: '%s'" "$pinentry_cmd"

  local commands=() pinentry_script out
  commands+=("SETPROMPT $PROMPT")
  [[ -z $__desc ]] || commands+=("SETDESC $__desc")
  [[ -z $__ok ]] || commands+=("SETOK $__ok")
  [[ -z $__cancel ]] || commands+=("SETCANCEL $__cancel")
  [[ -z $__error ]] || commands+=("SETERROR $__error")
  commands+=("GETPIN")
  join_by() { local IFS="$1"; shift; echo "$*"; }
  pinentry_script=$(join_by $'\n' "${commands[@]}")
  debug "Final pinentry script:\n%s" "$pinentry_script"

  out=$("$pinentry_cmd" <<<"$pinentry_script" || true)
  debug "pinentry response:\n%s" "$out"
  if [[ $out = *$'\nOK' ]]; then
    out=${out#$'OK Pleased to meet you\n'}
    out=${out%%$'\nOK'}
    out=${out##*$'OK'}
    printf "%s" "${out##*$'\nD '}"
    return 0
  elif [[ $out = *'ERR 83886179'* ]]; then
    return 2
  else
    fatal "Unknown pinentry response: %s" "$out"
  fi
}

pinentry_wrapper "$@"

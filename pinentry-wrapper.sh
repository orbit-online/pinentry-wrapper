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
  pinentry-wrapper [options] [PROMPT]

Options:
  -d --desc TEXT    Text to appear below the prompt
                    [default: \${PINENTRY_DESC:-}]
  -o --ok TEXT      Text for the OK button
                    [default: \${PINENTRY_OK:-OK}]
  -c --cancel TEXT  Text for the Cancel button
                    [default: \${PINENTRY_CANCEL:-Cancel}]
  -e --error TEXT   Set an error text
                    [default: \${PINENTRY_ERROR:-}]

Note:
  PROMPT can be overriden with \$PINENTRY_PROMPT
  If PROMPT is not defined or overridden, the default is 'Enter your password'
"
# docopt parser below, refresh this parser with `docopt.sh pinentry-wrapper.sh`
# shellcheck disable=2016,1090,1091,2034
docopt() { source "$pkgroot/.upkg/andsens/docopt.sh/docopt-lib.sh" '1.0.0' || {
ret=$?; printf -- "exit %d\n" "$ret"; exit "$ret"; }; set -e
trimmed_doc=${DOC:0:648}; usage=${DOC:71:44}; digest=603ae; shorts=(-o -d -e -c)
longs=(--ok --desc --error --cancel); argcounts=(1 1 1 1); node_0(){
value __ok 0; }; node_1(){ value __desc 1; }; node_2(){ value __error 2; }
node_3(){ value __cancel 3; }; node_4(){ value PROMPT a; }; node_5(){
optional 0 1 2 3; }; node_6(){ optional 5; }; node_7(){ optional 4; }; node_8(){
required 6 7; }; node_9(){ required 8; }; cat <<<' docopt_exit() {
[[ -n $1 ]] && printf "%s\n" "$1" >&2; printf "%s\n" "${DOC:71:44}" >&2; exit 1
}'; unset var___ok var___desc var___error var___cancel var_PROMPT; parse 9 "$@"
local prefix=${DOCOPT_PREFIX:-''}; unset "${prefix}__ok" "${prefix}__desc" \
"${prefix}__error" "${prefix}__cancel" "${prefix}PROMPT"
eval "${prefix}"'__ok=${var___ok:-'"'"'${PINENTRY_OK:-OK}'"'"'}'
eval "${prefix}"'__desc=${var___desc:-'"'"'${PINENTRY_DESC:-}'"'"'}'
eval "${prefix}"'__error=${var___error:-'"'"'${PINENTRY_ERROR:-}'"'"'}'
eval "${prefix}"'__cancel=${var___cancel:-'"'"'${PINENTRY_CANCEL:-Cancel}'"'"'}'
eval "${prefix}"'PROMPT=${var_PROMPT:-}'; local docopt_i=1
[[ $BASH_VERSION =~ ^4.3 ]] && docopt_i=2; for ((;docopt_i>0;docopt_i--)); do
declare -p "${prefix}__ok" "${prefix}__desc" "${prefix}__error" \
"${prefix}__cancel" "${prefix}PROMPT"; done; }
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

  [[ -n $PROMPT ]] || PROMPT=${PINENTRY_PROMPT:-Enter your password}
  [[ $__desc != "\${PINENTRY_DESC:-}" ]] || __desc=${PINENTRY_DESC:-}
  [[ $__ok != "\${PINENTRY_OK:-OK}" ]] || __ok=${PINENTRY_OK:-OK}
  [[ $__cancel != "\${PINENTRY_CANCEL:-Cancel}" ]] || __cancel=${PINENTRY_CANCEL:-Cancel}
  [[ $__error != "\${PINENTRY_ERROR:-}" ]] || __error=${PINENTRY_ERROR:-}

  local pinentry_script out commands=()
  commands+=("SETPROMPT $(escape "$PROMPT")")
  [[ -z $__desc ]] || commands+=("SETDESC $(escape "$__desc")")
  commands+=("SETOK $__ok")
  commands+=("SETCANCEL $__cancel")
  [[ -z $__error ]] || commands+=("SETERROR $__error")
  commands+=("GETPIN")
  pinentry_script=$(printf "%s\n" "${commands[@]}")
  debug "Final pinentry script:\n%s" "$pinentry_script"

  out=$("$pinentry_cmd" --ttyname "$(tty)" <<<"$pinentry_script" || true)
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

escape() {
  local str=$1
  str=${str//%/%25}
  str=${str//$'\n'/%0A}
  printf "%s" "$str"
}

pinentry_wrapper "$@"

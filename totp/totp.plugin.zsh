# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154,SC2296
# totp: macOS Keychain 기반 TOTP 생성기
# zinit: zinit ice pick"totp/totp.plugin.zsh"; zinit light silee9019/zsh-plugins
#
# Usage:
#   totp                 fzf picker (totp 마커 항목만) → 코드 출력
#   totp <name>          6자리 코드를 stdout + 클립보드로 출력
#   totp add <name>      secret을 Keychain에 등록 + totp 마커
#   totp rm <name>       Keychain에서 제거
#   totp ls [pattern]    totp 마커 항목 나열
#   totp ls --all [pat]  마커 무시하고 모든 generic-password 나열
#   totp tag <name>      기존 keychain 항목에 totp 마커 부착 (마이그레이션)
#
# 저장: macOS Keychain, service="<name>", account="$USER"
# 마커: kind(-D 필드) = "TOTP (totp.plugin.zsh)"

typeset -g _TOTP_KIND='TOTP (totp.plugin.zsh)'
typeset -g _TOTP_VERSION='0.1.0'

_totp_calc() {
  /usr/bin/env python3 -c '
import sys, base64, hmac, hashlib, struct, time
secret = sys.stdin.read().strip().replace(" ", "").replace("-", "").upper()
if not secret:
    sys.exit("totp: empty secret")
key = base64.b32decode(secret + "=" * (-len(secret) % 8))
counter = struct.pack(">Q", int(time.time()) // 30)
digest = hmac.new(key, counter, hashlib.sha1).digest()
offset = digest[-1] & 0x0F
code = (struct.unpack(">I", digest[offset:offset+4])[0] & 0x7FFFFFFF) % 1000000
print(f"{code:06d}")
'
}

# stdout: 마커가 부착된 generic-password의 service 이름들 (sort -u)
_totp_list_marked() {
  security dump-keychain 2>/dev/null | /usr/bin/env python3 -c '
import sys, re
kind = sys.argv[1]
svce = desc = None
out = set()
for line in sys.stdin:
    if line.startswith("keychain:"):
        if svce and desc == kind:
            out.add(svce)
        svce = desc = None
        continue
    m = re.search(r"\"svce\"<blob>=(?:0x[0-9A-F]+\s*)?\"(.+)\"\s*$", line)
    if m: svce = m.group(1)
    m = re.search(r"\"desc\"<blob>=(?:0x[0-9A-F]+\s*)?\"(.+)\"\s*$", line)
    if m: desc = m.group(1)
if svce and desc == kind:
    out.add(svce)
for s in sorted(out):
    print(s)
' "$_TOTP_KIND"
}

# stdout: 모든 generic-password service 이름 (sort -u)
_totp_list_all() {
  security dump-keychain 2>/dev/null \
    | awk -F'"' '/"svce"<blob>=/ {print $4}' \
    | sort -u
}

_totp_help() {
  cat <<EOF
totp $_TOTP_VERSION — macOS Keychain 기반 TOTP 생성기

Usage:
  totp [FLAGS] [SUBCOMMAND] [ARGS...]

Flags:
  -h, --help            도움말 출력 후 종료
  -v, --version         버전 출력 후 종료

Subcommands:
  (none)                fzf picker (totp 마커 항목만) → 코드 출력
  <name>                6자리 코드 출력 + 클립보드 복사
  add <name>            secret 등록 + totp 마커 (입력 숨김)
  rm <name>             등록 제거 (alias: remove, delete)
  ls [--all] [pattern]  마커 항목 나열. --all은 마커 무시 (alias: list)
  tag <name>            기존 keychain 항목에 totp 마커 부착 (마이그레이션)
  help                  이 도움말 출력

저장 컨벤션:
  service="<name>"  account=\$USER  kind="$_TOTP_KIND"

예:
  totp add "MS: you@example.com"
  totp     "MS: you@example.com"
  totp ls
  totp ls --all "MS:"
  totp tag "MS: you@example.com"
EOF
}

totp() {
  emulate -L zsh
  local sub="${1:-}"

  case "$sub" in
    add)
      local name="${2:-}"
      [[ -z "$name" ]] && { print -u2 "usage: totp add <name>"; return 2 }
      local secret
      printf 'TOTP secret for %s (input hidden): ' "$name"
      IFS= read -rs secret
      printf '\n'
      [[ -z "$secret" ]] && { print -u2 "totp: empty secret, aborted"; return 1 }
      security add-generic-password -U \
        -s "$name" \
        -a "$USER" \
        -D "$_TOTP_KIND" \
        -w "$secret" \
        || { print -u2 "totp: keychain write failed"; return 1 }
      print -- "totp: stored '$name'"
      ;;

    rm|remove|delete)
      local name="${2:-}"
      [[ -z "$name" ]] && { print -u2 "usage: totp rm <name>"; return 2 }
      security delete-generic-password \
        -s "$name" \
        -a "$USER" >/dev/null 2>&1 \
        && print -- "totp: removed '$name'" \
        || { print -u2 "totp: '$name' not found"; return 1 }
      ;;

    tag)
      local name="${2:-}"
      [[ -z "$name" ]] && { print -u2 "usage: totp tag <name>  (기존 항목에 totp 마커 부착)"; return 2 }
      local secret
      secret=$(security find-generic-password -w \
        -s "$name" \
        -a "$USER" 2>/dev/null) \
        || { print -u2 "totp: '$name' not found in keychain"; return 1 }
      security add-generic-password -U \
        -s "$name" \
        -a "$USER" \
        -D "$_TOTP_KIND" \
        -w "$secret" \
        || { print -u2 "totp: keychain update failed"; return 1 }
      print -- "totp: tagged '$name'"
      ;;

    ls|list)
      local arg2="${2:-}"
      local arg3="${3:-}"
      local source pattern
      if [[ "$arg2" == "--all" ]]; then
        source=all; pattern="$arg3"
      else
        source=marked; pattern="$arg2"
      fi
      if [[ "$source" == all ]]; then
        if [[ -n "$pattern" ]]; then
          _totp_list_all | grep -- "$pattern"
        else
          _totp_list_all
        fi
      else
        if [[ -n "$pattern" ]]; then
          _totp_list_marked | grep -- "$pattern"
        else
          _totp_list_marked
        fi
      fi
      ;;

    -h|--help|help)
      _totp_help
      return 0
      ;;

    -v|--version)
      print -- "totp $_TOTP_VERSION"
      return 0
      ;;

    '')
      command -v fzf >/dev/null 2>&1 \
        || { print -u2 "totp: fzf not installed (인터랙티브 모드 필요)"; return 127 }
      local picked
      picked=$(_totp_list_marked \
        | fzf --prompt='totp> ' --height=40% --reverse --no-multi \
              --header='totp 마커 항목 (없으면: totp tag <name>)') \
        || return 130
      [[ -z "$picked" ]] && return 130
      totp "$picked"
      ;;

    *)
      local name="$sub"
      local secret
      secret=$(security find-generic-password -w \
        -s "$name" \
        -a "$USER" 2>/dev/null) \
        || { print -u2 "totp: '$name' not found in keychain (try: totp add \"$name\")"; return 1 }
      local code
      code=$(print -rn -- "$secret" | _totp_calc) || return 1
      print -- "$code"
      command -v pbcopy >/dev/null 2>&1 && print -rn -- "$code" | pbcopy
      ;;
  esac
}

# ─── zsh completion ──────────────────────────────────────────────

_totp_subcommands=(
  'add:Register a new TOTP secret (with marker)'
  'rm:Remove a TOTP entry'
  'remove:Alias for rm'
  'delete:Alias for rm'
  'ls:List entries (marker-only by default)'
  'list:Alias for ls'
  'tag:Add totp marker to existing keychain entry'
  'help:Show help'
)

_totp_marked_completion() {
  local -a entries
  entries=("${(@f)$(_totp_list_marked 2>/dev/null)}")
  if (( ${#entries} )); then
    # _describe는 'value:desc' 포맷으로 파싱하므로 항목 내 콜론을 escape
    entries=("${(@)entries//:/\\:}")
    _describe -t totp-entries 'totp entry' entries
  else
    _message 'no totp-marked entries (try: totp add ...)'
  fi
}

_totp_all_completion() {
  local -a entries
  entries=("${(@f)$(_totp_list_all 2>/dev/null)}")
  if (( ${#entries} )); then
    entries=("${(@)entries//:/\\:}")
    _describe -t keychain-entries 'keychain entry' entries
  else
    _message 'no keychain entries'
  fi
}

_totp_first_arg() {
  _describe -t commands 'totp subcommand' _totp_subcommands
  _totp_marked_completion
}

_totp() {
  local context state state_descr line ret=1
  typeset -A opt_args

  _arguments -C \
    '(- *)'{-h,--help}'[show help]' \
    '(- *)'{-v,--version}'[show version]' \
    '1:command:->command' \
    '*::arg:->args' && ret=0

  case "$state" in
    command)
      _totp_first_arg && ret=0
      ;;
    args)
      case "${words[2]}" in
        rm|remove|delete)
          _totp_marked_completion && ret=0
          ;;
        tag)
          _totp_all_completion && ret=0
          ;;
        ls|list)
          _arguments \
            '--all[ignore marker, list all generic-passwords]' \
            '*:pattern:' && ret=0
          ;;
        add)
          _message 'new entry name (e.g. "MS: you@example.com")' && ret=0
          ;;
      esac
      ;;
  esac

  return $ret
}

if (( $+functions[compdef] )); then
  compdef _totp totp
fi

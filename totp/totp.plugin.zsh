# shellcheck shell=bash
# totp: macOS Keychain 기반 TOTP 생성기
# zinit: zinit ice pick"totp/totp.plugin.zsh"; zinit light silee9019/zsh-plugins
#
# Usage:
#   totp                 # fzf 인터랙티브 picker → 선택 시 코드 출력
#   totp <name>          # 6자리 코드를 stdout + 클립보드로 출력
#   totp add <name>      # secret을 Keychain에 등록 (입력 시 echo 안 됨)
#   totp rm <name>       # Keychain에서 제거
#   totp ls [pattern]    # 등록된 service 나열 (pattern 있으면 grep 필터)
#
# 저장: macOS Keychain, service="<name>" (raw, prefix 없음), account="$USER"
# <name>은 사용자 기존 keychain 컨벤션 그대로 사용 가능 (예: "MS: silee@imagoworks.ai")

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

    ls|list)
      local pattern="${2:-}"
      if [[ -n "$pattern" ]]; then
        security dump-keychain 2>/dev/null \
          | awk -F'"' '/"svce"<blob>=/ {print $4}' \
          | grep -- "$pattern" \
          | sort -u
      else
        security dump-keychain 2>/dev/null \
          | awk -F'"' '/"svce"<blob>=/ {print $4}' \
          | sort -u
      fi
      ;;

    -h|--help|help)
      cat <<EOF
totp — macOS Keychain 기반 TOTP 생성기

  totp                 fzf picker → 선택 시 코드 출력
  totp <name>          6자리 코드 출력 + 클립보드 복사
  totp add <name>      secret 등록 (입력 시 echo 안 됨)
  totp rm <name>       등록 제거
  totp ls [pattern]    등록된 service 나열 (pattern 있으면 grep 필터)

저장 컨벤션:
  service = <name> (raw, prefix 없음)
  account = \$USER

예:
  totp add "MS: you@example.com"
  totp     "MS: you@example.com"
EOF
      return 0
      ;;

    '')
      command -v fzf >/dev/null 2>&1 \
        || { print -u2 "totp: fzf not installed (인터랙티브 모드 필요)"; return 127 }
      local picked
      picked=$(security dump-keychain 2>/dev/null \
        | awk -F'"' '/"svce"<blob>=/ {print $4}' \
        | sort -u \
        | fzf --prompt='totp> ' --height=40% --reverse --no-multi \
              --header='keychain generic-password service 선택') \
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

# shellcheck shell=bash
# totp: macOS Keychain 기반 TOTP 생성기
# zinit: zinit ice pick"totp/totp.plugin.zsh"; zinit light silee9019/zsh-plugins
#
# Usage:
#   totp <name>         # 6자리 코드를 stdout + 클립보드로 출력
#   totp add <name>     # secret을 Keychain에 등록 (입력 시 echo 안 됨)
#   totp rm <name>      # Keychain에서 제거
#   totp ls             # 등록된 totp:* 항목 나열
#
# 저장 위치: macOS Keychain, service="totp:<name>", account="$USER"

_totp_service() { print -- "totp:$1" }

_totp_calc() {
  # stdin: base32 secret (공백/하이픈 허용, 대소문자 무관)
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
        -s "$(_totp_service "$name")" \
        -a "$USER" \
        -w "$secret" \
        || { print -u2 "totp: keychain write failed"; return 1 }
      print -- "totp: stored '$name'"
      ;;

    rm|remove|delete)
      local name="${2:-}"
      [[ -z "$name" ]] && { print -u2 "usage: totp rm <name>"; return 2 }
      security delete-generic-password \
        -s "$(_totp_service "$name")" \
        -a "$USER" >/dev/null 2>&1 \
        && print -- "totp: removed '$name'" \
        || { print -u2 "totp: '$name' not found"; return 1 }
      ;;

    ls|list)
      security dump-keychain 2>/dev/null \
        | awk -F'"' '/"svce"<blob>="totp:/ {print $4}' \
        | sed 's/^totp://' \
        | sort -u
      ;;

    ''|-h|--help|help)
      cat <<EOF
totp — macOS Keychain 기반 TOTP 생성기

  totp <name>         6자리 코드 출력 + 클립보드 복사
  totp add <name>     secret 등록 (input hidden)
  totp rm <name>      등록 제거
  totp ls             등록 목록
EOF
      [[ "$sub" == "" ]] && return 2 || return 0
      ;;

    *)
      local name="$sub"
      local secret
      secret=$(security find-generic-password -w \
        -s "$(_totp_service "$name")" \
        -a "$USER" 2>/dev/null) \
        || { print -u2 "totp: '$name' not found in keychain (try: totp add $name)"; return 1 }
      local code
      code=$(print -rn -- "$secret" | _totp_calc) || return 1
      print -- "$code"
      command -v pbcopy >/dev/null 2>&1 && print -rn -- "$code" | pbcopy
      ;;
  esac
}

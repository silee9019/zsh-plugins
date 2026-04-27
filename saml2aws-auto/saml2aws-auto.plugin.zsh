# shellcheck shell=bash
# saml2aws-auto: saml2aws AzureAD 로그인 자동화 (expect + Keychain + TOTP)
# zinit: zinit ice pick"saml2aws-auto/saml2aws-auto.plugin.zsh"; zinit light silee9019/zsh-plugins
#
# 의존:
#   - /usr/bin/expect (macOS 기본)
#   - totp 플러그인 (totp/totp.plugin.zsh) — TOTP 코드 생성
#   - Keychain 항목:
#       service="saml2aws:password", account="$USER"  → AzureAD 비밀번호
#       service="totp:saml2aws",     account="$USER"  → TOTP base32 secret
#
# Usage:
#   saml2aws-auto-login                # 자동 로그인 1회 실행
#   SAML2AWS_AUTO_DEBUG=1 saml2aws-auto-login   # expect 트레이스 출력

typeset -g _SAML2AWS_AUTO_DIR="${0:A:h}"

_saml2aws_auto_get_password() {
  if [[ -n "$SAML2AWS_PASSWORD" ]]; then
    print -rn -- "$SAML2AWS_PASSWORD"
    return 0
  fi
  security find-generic-password -w \
    -s "saml2aws:password" \
    -a "$USER" 2>/dev/null
}

saml2aws-auto-login() {
  emulate -L zsh

  command -v saml2aws >/dev/null 2>&1 \
    || { print -u2 "saml2aws-auto: saml2aws not installed"; return 127 }
  command -v expect >/dev/null 2>&1 \
    || { print -u2 "saml2aws-auto: expect not installed"; return 127 }

  local password totp_code
  password=$(_saml2aws_auto_get_password) \
    || { print -u2 "saml2aws-auto: password not found in keychain (service=saml2aws:password)"; return 1 }
  [[ -z "$password" ]] && { print -u2 "saml2aws-auto: empty password"; return 1 }

  if command -v totp >/dev/null 2>&1; then
    totp_code=$(totp saml2aws 2>/dev/null)
  fi
  if [[ -z "$totp_code" ]]; then
    print -u2 "saml2aws-auto: TOTP unavailable (need: totp add saml2aws)"
    print -u2 "saml2aws-auto: falling back to interactive saml2aws login"
    SAML2AWS_PASSWORD="$password" saml2aws login --force
    return $?
  fi

  expect "$_SAML2AWS_AUTO_DIR/login.expect" "$password" "$totp_code"
}

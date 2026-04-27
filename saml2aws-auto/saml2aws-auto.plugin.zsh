# shellcheck shell=bash
# saml2aws-auto: saml2aws AzureAD 로그인 TOTP 자동 주입
# zinit: zinit ice pick"saml2aws-auto/saml2aws-auto.plugin.zsh"; zinit light silee9019/zsh-plugins
#
# 의존:
#   - totp 플러그인 (totp/totp.plugin.zsh) — TOTP 코드 생성
#   - Keychain 항목: service=$SAML2AWS_AUTO_TOTP_NAME, account=$USER
#       기본값: "MS: ${SAML2AWS_USERNAME}"
#
# 전제: AzureAD가 SSO/cached cookies로 비밀번호 단계를 건너뜀
#       (saml2aws --password="" --skip-prompt --mfa-token=... 으로 직접 호출)
#
# Usage:
#   saml2aws-auto-login

saml2aws-auto-login() {
  emulate -L zsh

  command -v saml2aws >/dev/null 2>&1 \
    || { print -u2 "saml2aws-auto: saml2aws not installed"; return 127 }
  command -v totp >/dev/null 2>&1 \
    || { print -u2 "saml2aws-auto: totp plugin not loaded"; return 127 }

  local totp_name="${SAML2AWS_AUTO_TOTP_NAME:-MS: ${SAML2AWS_USERNAME}}"
  if [[ "$totp_name" == "MS: " ]]; then
    print -u2 "saml2aws-auto: SAML2AWS_USERNAME unset and SAML2AWS_AUTO_TOTP_NAME not provided"
    return 1
  fi

  local totp_code
  totp_code=$(totp "$totp_name" 2>/dev/null) \
    || { print -u2 "saml2aws-auto: TOTP unavailable for '$totp_name' (try: totp add \"$totp_name\")"; return 1 }

  saml2aws login \
    --force \
    --skip-prompt \
    --password="" \
    --mfa-token="$totp_code"
}

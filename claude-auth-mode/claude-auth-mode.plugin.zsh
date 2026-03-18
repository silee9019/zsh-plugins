# shellcheck shell=bash
# claude-auth-mode: Claude Code 인증 모드 전환 (subscription ↔ Azure AI Foundry)
# zinit: zinit ice pick"claude-auth-mode/claude-auth-mode.plugin.zsh"; zinit light silee9019/zsh-plugins

CLAUDE_AUTH_MODE_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/claude-auth-mode"
CLAUDE_AUTH_MODE_PLUGIN_DIR="${0:A:h}"

# ── init: XDG 디렉토리 + sops 설정 자동 생성 ──
_claude_auth_mode_init() {
  mkdir -p "$CLAUDE_AUTH_MODE_DATA"

  # .sops.yaml 생성 (age 공개키 자동 감지)
  if [[ ! -f "$CLAUDE_AUTH_MODE_DATA/.sops.yaml" ]]; then
    local age_keys="$HOME/.config/sops/age/keys.txt"
    if [[ ! -f "$age_keys" ]]; then
      echo "warn: claude-auth-mode: age 키 파일이 없습니다 ($age_keys)" >&2
      echo "  foundry 모드 사용 시: age-keygen -o $age_keys" >&2
    else
      local age_pub
      age_pub=$(grep '^# public key:' "$age_keys" | head -1 | awk '{print $NF}')
      if [[ -n "$age_pub" ]]; then
        sed "s|__AGE_PUBLIC_KEY__|$age_pub|g" \
          "$CLAUDE_AUTH_MODE_PLUGIN_DIR/templates/.sops.yaml" \
          > "$CLAUDE_AUTH_MODE_DATA/.sops.yaml"
      else
        echo "warn: claude-auth-mode: age 공개키를 추출할 수 없습니다" >&2
      fi
    fi
  fi

  # 마이그레이션: foundry.sops.env → foundry.enc.env
  if [[ -f "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env" && ! -f "$CLAUDE_AUTH_MODE_DATA/foundry.enc.env" ]]; then
    mv "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env" "$CLAUDE_AUTH_MODE_DATA/foundry.enc.env"
  fi

  # 저장된 모드 자동 로드
  local active
  active=$(cat "$CLAUDE_AUTH_MODE_DATA/active" 2>/dev/null)
  [[ "$active" == "foundry" ]] && claude-auth-mode foundry >/dev/null 2>&1 || true
}

# ── interactive foundry env 설정 ──
# foundry.enc.env가 없을 때 호출됨
_claude_auth_mode_setup_foundry() {
  # 비대화형 셸이면 안내만 출력
  if [[ ! -t 0 ]]; then
    echo "직접 편집하세요: sops $CLAUDE_AUTH_MODE_DATA/foundry.enc.env" >&2
    return 1
  fi

  echo "=== Foundry 환경변수 설정 ==="
  echo ""

  local template="$CLAUDE_AUTH_MODE_PLUGIN_DIR/templates/foundry.env.template"
  local tmpfile="$CLAUDE_AUTH_MODE_DATA/foundry.env.tmp"
  local key value

  : > "$tmpfile"
  chmod 600 "$tmpfile"

  while IFS='=' read -r key _; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    value=""
    vared -p "${key}> " value
    printf '%s=%s\n' "$key" "$value" >> "$tmpfile"
  done < "$template"

  if ! sops --config "$CLAUDE_AUTH_MODE_DATA/.sops.yaml" \
    --encrypt --input-type dotenv --output-type dotenv \
    "$tmpfile" > "$CLAUDE_AUTH_MODE_DATA/foundry.enc.env"; then
    echo "error: sops 암호화 실패 — age 키와 .sops.yaml 설정을 확인하세요" >&2
    rm -f "$tmpfile"
    return 1
  fi

  rm -f "$tmpfile"
}

# ── 메인 함수 ──
claude-auth-mode() {
  local mode="${1:-status}"

  case "$mode" in
    foundry|f)
      # .sops.yaml 존재 확인
      if [[ ! -f "$CLAUDE_AUTH_MODE_DATA/.sops.yaml" ]]; then
        echo "error: .sops.yaml이 없습니다 — age 키를 먼저 설정하세요:" >&2
        echo "  age-keygen -o ~/.config/sops/age/keys.txt" >&2
        echo "  그 후 셸을 재시작하세요" >&2
        return 1
      fi

      # foundry.enc.env가 없으면 interactive setup
      if [[ ! -f "$CLAUDE_AUTH_MODE_DATA/foundry.enc.env" ]]; then
        _claude_auth_mode_setup_foundry || return 1
      fi

      local decrypted
      if ! decrypted="$(sops --config "$CLAUDE_AUTH_MODE_DATA/.sops.yaml" \
        --decrypt --output-type dotenv "$CLAUDE_AUTH_MODE_DATA/foundry.enc.env" 2>&1)"; then
        echo "error: sops 복호화 실패 — foundry.enc.env가 암호화되었는지 확인하세요" >&2
        echo "  $decrypted" >&2
        return 1
      fi
      eval "export ${decrypted//$'\n'/$'\nexport '}"
      export CLAUDE_CODE_USE_FOUNDRY=1
      echo "foundry" > "$CLAUDE_AUTH_MODE_DATA/active"
      echo "→ Foundry 모드 (claude 재시작 시 적용)"
      ;;
    sub|subscription|s)
      unset CLAUDE_CODE_USE_FOUNDRY ANTHROPIC_FOUNDRY_API_KEY \
            ANTHROPIC_FOUNDRY_RESOURCE ANTHROPIC_MODEL
      echo "subscription" > "$CLAUDE_AUTH_MODE_DATA/active"
      echo "→ Subscription 모드 (claude 재시작 시 적용)"
      ;;
    status|"")
      local active
      active=$(cat "$CLAUDE_AUTH_MODE_DATA/active" 2>/dev/null || echo "subscription")
      echo "모드: $active"
      if [[ -n "$CLAUDE_CODE_USE_FOUNDRY" ]]; then
        echo "  셸: foundry (ANTHROPIC_MODEL=${ANTHROPIC_MODEL:-unset})"
      else
        echo "  셸: subscription"
      fi
      ;;
    toggle|t)
      local active
      active=$(cat "$CLAUDE_AUTH_MODE_DATA/active" 2>/dev/null || echo "subscription")
      if [[ "$active" == "foundry" ]]; then
        claude-auth-mode sub
      else
        claude-auth-mode foundry
      fi
      ;;
    *)
      echo "Usage: claude-auth-mode [toggle|foundry|sub|status]" >&2
      return 1
      ;;
  esac
}

alias camt='claude-auth-mode toggle'
alias cams='claude-auth-mode status'

_claude_auth_mode_init

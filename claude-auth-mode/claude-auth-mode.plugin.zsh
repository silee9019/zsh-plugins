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
    if [[ -f "$age_keys" ]]; then
      local age_pub
      age_pub=$(grep '^# public key:' "$age_keys" | head -1 | awk '{print $NF}')
      if [[ -n "$age_pub" ]]; then
        sed "s|__AGE_PUBLIC_KEY__|$age_pub|g" \
          "$CLAUDE_AUTH_MODE_PLUGIN_DIR/templates/.sops.yaml" \
          > "$CLAUDE_AUTH_MODE_DATA/.sops.yaml"
      fi
    fi
  fi

  # foundry.sops.env 템플릿 복사
  if [[ ! -f "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env" ]]; then
    cp "$CLAUDE_AUTH_MODE_PLUGIN_DIR/templates/foundry.env.template" \
       "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env"
    chmod 600 "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env"
  fi

  # 저장된 모드 자동 로드
  local active
  active=$(cat "$CLAUDE_AUTH_MODE_DATA/active" 2>/dev/null)
  [[ "$active" == "foundry" ]] && claude-auth-mode foundry >/dev/null 2>&1 || true
}

# ── interactive foundry env 설정 ──
# foundry.sops.env에 CHANGE_ME가 남아있을 때 호출됨
# TODO: 사용자 구현 — vared/read로 API key 입력 → sops encrypt
_claude_auth_mode_setup_foundry() {
  # 비대화형 셸이면 안내만 출력
  if [[ ! -t 0 ]]; then
    echo "직접 편집하세요: sops $CLAUDE_AUTH_MODE_DATA/foundry.sops.env" >&2
    return 1
  fi

  echo "=== Foundry 환경변수 설정 ==="
  echo ""

  local api_key resource model
  vared -p 'ANTHROPIC_FOUNDRY_API_KEY> ' api_key
  vared -p 'ANTHROPIC_FOUNDRY_RESOURCE> ' resource
  vared -p 'ANTHROPIC_MODEL> ' model

  printf '%s\n' \
    "ANTHROPIC_FOUNDRY_API_KEY=$api_key" \
    "ANTHROPIC_FOUNDRY_RESOURCE=$resource" \
    "ANTHROPIC_MODEL=$model" \
    > "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env"

  sops --encrypt --in-place \
    --input-type dotenv --output-type dotenv \
    "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env"

  return 0
}

# ── 메인 함수 ──
claude-auth-mode() {
  local mode="${1:-status}"

  case "$mode" in
    foundry|f)
      # CHANGE_ME가 남아있으면 interactive setup
      if grep -q 'CHANGE_ME' "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env" 2>/dev/null; then
        _claude_auth_mode_setup_foundry || return 1
      fi

      local decrypted
      decrypted="$(sops --decrypt --output-type dotenv "$CLAUDE_AUTH_MODE_DATA/foundry.sops.env" 2>&1)"
      if [[ $? -ne 0 ]]; then
        echo "error: sops 복호화 실패 — foundry.sops.env가 암호화되었는지 확인하세요" >&2
        echo "  $decrypted" >&2
        return 1
      fi
      eval "$(echo "$decrypted" | sed 's/^/export /')"
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

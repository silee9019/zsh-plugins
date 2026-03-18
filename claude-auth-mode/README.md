# claude-auth-mode

Claude Code 인증 모드 전환 (subscription ↔ Azure AI Foundry). sops+age 기반 API key 관리.

## 의존성

- [sops](https://github.com/getsops/sops) — `brew install sops`
- [age](https://github.com/FiloSottile/age) — `brew install age`
- age 키: `age-keygen -o ~/.config/sops/age/keys.txt`

## 설치

### zinit

```zsh
zinit ice pick"claude-auth-mode/claude-auth-mode.plugin.zsh"
zinit light silee9019/zsh-plugins
```

### 수동

```zsh
source /path/to/zsh-plugins/claude-auth-mode/claude-auth-mode.plugin.zsh
```

## 사용법

```zsh
camt          # 모드 토글 (subscription ↔ foundry)
cams          # 현재 상태 확인

claude-auth-mode foundry       # Foundry 모드로 전환
claude-auth-mode sub           # Subscription 모드로 전환
claude-auth-mode status        # 상태 확인
claude-auth-mode toggle        # 토글
```

첫 `foundry` 전환 시 API key 등 환경변수를 interactive로 입력받고 sops로 암호화합니다.

## 데이터 경로

`${XDG_DATA_HOME:-$HOME/.local/share}/claude-auth-mode/`

| 파일 | 설명 |
|------|------|
| `.sops.yaml` | age 암호화 규칙 |
| `foundry.sops.env` | Foundry API key (sops 암호화) |
| `active` | 현재 활성 모드 (`foundry` 또는 `subscription`) |

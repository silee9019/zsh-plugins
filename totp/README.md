# totp

macOS Keychain 기반 TOTP(RFC 6238) 생성기. 외부 의존성 없음 (macOS 기본 `python3` + `security`).

## Install

```zsh
source /path/to/zsh-plugins/totp/totp.plugin.zsh
```

zinit:

```zsh
zinit ice pick"totp/totp.plugin.zsh"
zinit light silee9019/zsh-plugins
```

## Usage

```zsh
totp add "MS: you@example.com"     # secret 등록 (입력 숨김)
totp     "MS: you@example.com"     # 6자리 코드 → stdout + 클립보드
totp ls  "MS:"                     # service 이름이 pattern 포함하는 항목 나열
totp rm  "MS: you@example.com"     # 제거
```

저장 컨벤션:
- `service = <name>` (raw, prefix 없음 — 사용자 기존 keychain 컨벤션 그대로 사용)
- `account = $USER`
- 저장 위치: macOS Keychain (login)

첫 조회 시 Keychain 권한 다이얼로그가 한 번 뜬다 — "Always Allow" 누르면 이후 조용함.

## Notes

- 30초 윈도우 / 6자리 / SHA-1 (표준 TOTP). 다른 변종은 미지원.
- secret 입력은 base32 형식 (공백·하이픈은 제거 후 처리, 대소문자 무관).

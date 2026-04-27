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
totp                               # fzf picker (totp 마커 항목만) → 코드 출력
totp add "MS: you@example.com"     # secret 등록 + totp 마커
totp     "MS: you@example.com"     # 6자리 코드 → stdout + 클립보드
totp ls                            # totp 마커 항목 전체
totp ls "MS:"                      # pattern 필터
totp ls --all                      # 마커 무시, keychain의 모든 generic-password
totp tag "MS: you@example.com"     # 기존 keychain 항목에 마커 부착 (마이그레이션)
totp rm  "MS: you@example.com"     # 제거
```

`totp` 인자 없이 호출하면 [fzf](https://github.com/junegunn/fzf)로 picker가 뜬다 (oh-my-zsh `fzf` 플러그인 또는 `brew install fzf` 필요).

## 마커 기반 필터링

키체인에는 Wifi·브라우저·앱 등 수많은 generic-password가 섞여 있다. `totp add`는 항목을 등록할 때 keychain의 **kind 필드(`-D`)**를 `"TOTP (totp.plugin.zsh)"`로 마킹한다. `totp ls` / picker는 이 마커가 붙은 항목만 노출.

이미 keychain에 수동으로 등록한 secret이 있다면 `totp tag <name>`으로 마커만 부착할 수 있다 (secret 값은 보존, 재입력 불필요).

확인:

```zsh
security find-generic-password -s "MS: you@example.com" -g 2>&1 | grep -E '"desc"|"svce"'
```

## Completion

`compdef _totp totp`이 자동 등록되어 있어 별도 설정 없이 동작:

- `totp <TAB>` → 서브커맨드 + 마커 부착된 entry 후보
- `totp rm <TAB>` → 마커 부착된 entry만
- `totp tag <TAB>` → keychain의 모든 generic-password (마커 없는 기존 항목 마이그레이션용)
- `totp ls <TAB>` → `--all` 옵션
- `totp -h <TAB>` / `totp --help` 도 자동 완성

zinit이 자동으로 compdef replay를 처리한다 (별도 `compinit` 호출 불필요).

저장 컨벤션:
- `service = <name>` (raw, prefix 없음 — 사용자 기존 keychain 컨벤션 그대로 사용)
- `account = $USER`
- 저장 위치: macOS Keychain (login)

첫 조회 시 Keychain 권한 다이얼로그가 한 번 뜬다 — "Always Allow" 누르면 이후 조용함.

## Notes

- 30초 윈도우 / 6자리 / SHA-1 (표준 TOTP). 다른 변종은 미지원.
- secret 입력은 base32 형식 (공백·하이픈은 제거 후 처리, 대소문자 무관).

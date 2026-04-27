# saml2aws-auto

`saml2aws login`(AzureAD)을 expect로 감싸 **TOTP 코드를 자동 주입**한다.
SSO 환경 전제 — 비밀번호 단계는 IdP가 자동 패스, MFA(TOTP) prompt만 자동화.

## Install

```zsh
source /path/to/zsh-plugins/totp/totp.plugin.zsh         # 의존
source /path/to/zsh-plugins/saml2aws-auto/saml2aws-auto.plugin.zsh
```

zinit:

```zsh
zinit ice pick"totp/totp.plugin.zsh";                  zinit light silee9019/zsh-plugins
zinit ice pick"saml2aws-auto/saml2aws-auto.plugin.zsh"; zinit light silee9019/zsh-plugins
```

## Setup (1회)

```zsh
# AzureAD MFA Authenticator 등록 시 받은 base32 secret을 keychain에 저장
totp add "MS: ${SAML2AWS_USERNAME}"
# 예: SAML2AWS_USERNAME=silee@imagoworks.ai → service="MS: silee@imagoworks.ai"
```

처음 자동 로그인 시 Keychain 권한 다이얼로그가 한 번 뜬다 — "Always Allow" 권장.

## Usage

```zsh
saml2aws-auto-login                       # 자동 로그인
SAML2AWS_AUTO_DEBUG=1 saml2aws-auto-login # expect 트레이스 (prompt 문자열 디버깅용)
```

기존 `~/.config/zsh/saml2aws.zsh`(세션 만료 감지 + 버튼 UI)와 결합되어 있으면, "지금 로그인" 선택 시 자동으로 이 wrapper가 호출된다.

## 설정

| 환경변수 | 용도 | 기본값 |
|---------|------|--------|
| `SAML2AWS_AUTO_TOTP_NAME` | TOTP secret이 저장된 keychain service 이름 | `"MS: $SAML2AWS_USERNAME"` |
| `SAML2AWS_AUTO_DEBUG` | expect 내부 트레이스 출력 (=1) | unset |

## 가정 / 제약

- provider=AzureAD, mfa=Auto (TOTP). number-matching push 정책에서는 동작하지 않는다.
- AzureAD가 SSO 또는 cached cookie로 비밀번호 단계를 건너뛰고 바로 MFA로 진입하는 경우만 처리. password prompt가 뜨는 환경이면 expect가 그 단계를 못 지나간다 — 이 경우 wrapper 확장 필요.
- expect는 다음 prompt 패턴을 잡는다:
  - `verification code` / `enter code` / `mfa.*token` / `one-time` / `totp` / `otp token` → TOTP 송신
  - role 선택 prompt → Enter (default 선택)
- saml2aws 버전업으로 prompt 문자열이 바뀌면 `SAML2AWS_AUTO_DEBUG=1`로 캡처해 `login.expect` 정규식 보정. 검증 버전: saml2aws 2.36.19.

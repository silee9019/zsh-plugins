# saml2aws-auto

`saml2aws login`(AzureAD)에 TOTP 코드를 자동 주입하는 zsh 함수.
SSO 환경 전제 — `saml2aws login --skip-prompt --password="" --mfa-token=<code>`
한 줄 호출로 끝나며 expect/pty 같은 부가물 없음.

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
totp add "MS: ${SAML2AWS_USERNAME}"
```

처음 호출 시 Keychain 권한 다이얼로그가 한 번 뜬다 — "Always Allow" 권장.

## Usage

```zsh
saml2aws-auto-login
```

기존 `~/.config/zsh/saml2aws.zsh`(세션 만료 감지 + 버튼 UI)와 결합되어 있으면 "지금 로그인" 선택 시 자동으로 이 wrapper가 호출된다.

## 설정

| 환경변수 | 용도 | 기본값 |
|---------|------|--------|
| `SAML2AWS_AUTO_TOTP_NAME` | TOTP secret이 저장된 keychain service 이름 | `"MS: $SAML2AWS_USERNAME"` |

## 가정 / 제약

- provider=AzureAD, mfa=Auto (TOTP). number-matching push 정책에서는 동작하지 않는다.
- AzureAD가 SSO 또는 cached cookie로 비밀번호 단계를 건너뛰는 환경 가정. `--password=""`(명시적 빈 문자열)로 호출하면 saml2aws가 password 입력 단계를 우회하고 IdP의 SSO 흐름을 그대로 탄다.
- `--mfa-token` 플래그가 AzureAD provider에서도 동작함을 saml2aws 2.36.19에서 확인.

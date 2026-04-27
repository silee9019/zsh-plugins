# saml2aws-auto

`saml2aws login`(AzureAD)을 expect로 감싸 비밀번호와 TOTP를 자동 주입한다.

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
# AzureAD 비밀번호
security add-generic-password -U -s "saml2aws:password" -a "$USER" -w

# TOTP secret (Authenticator 등록 시 받은 base32)
totp add saml2aws
```

처음 자동 로그인 시 Keychain 권한 다이얼로그가 두 번 뜬다 ("Always Allow" 권장).

## Usage

```zsh
saml2aws-auto-login                       # 자동 로그인
SAML2AWS_AUTO_DEBUG=1 saml2aws-auto-login # expect 트레이스 출력 (prompt 문자열 디버깅용)
```

기존 `~/.config/zsh/saml2aws.zsh`(세션 만료 감지 + 버튼 UI)와 결합되어 있으면, "지금 로그인" 선택 시 자동으로 이 wrapper가 호출된다.

## 동작 / 가정

- provider=AzureAD, mfa=Auto (TOTP) 가정. number-matching push 정책에서는 동작하지 않는다.
- expect는 다음 prompt 패턴을 잡는다:
  - `password` → 비밀번호 송신
  - `verification code` / `mfa token` / `otp` / `totp` → TOTP 송신
  - role 선택 prompt → Enter (default)
- saml2aws 버전업으로 prompt 문자열이 바뀌면 `SAML2AWS_AUTO_DEBUG=1`로 캡처해 `login.expect` 정규식 보정 필요. 현재 검증 버전: saml2aws 2.36.19.

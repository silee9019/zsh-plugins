# zsh-plugins

[English (영어)](../README.md)

커스텀 Zsh 플러그인 모음.

## 기술 스택

- Zsh / Shell

## 시작하기

저장소를 클론하고 원하는 플러그인을 `.zshrc`에서 source합니다:

```zsh
source /path/to/zsh-plugins/<plugin-name>/<plugin-name>.plugin.zsh
```

## 플러그인

| 플러그인 | 설명 |
|----------|------|
| [claude-auth-mode](../claude-auth-mode/) | Claude Code 인증 모드 전환 (subscription ↔ Azure AI Foundry), sops+age 기반 |
| [overmind](../overmind/) | Overmind 명령, 옵션, alias, Procfile 프로세스명을 위한 Zsh 자동 완성 |

## Overmind 자동 완성

```zsh
source /path/to/zsh-plugins/overmind/overmind.plugin.zsh
```

Overmind v2.5.1 기준 명령과 alias, 명령별 플래그, socket/network 플래그, `restart`, `stop`, `connect` 등에서 Procfile 기반 프로세스명 완성을 지원합니다.

# zsh-plugins

커스텀 Zsh 플러그인 모음.

## 프로젝트 구조

```
zsh-plugins/
├── claude-auth-mode/
│   ├── claude-auth-mode.plugin.zsh   ← 인증 모드 전환 (sops+age)
│   ├── templates/                     ← .sops.yaml + foundry.env 템플릿
│   └── README.md
├── docs/
│   └── README_ko.md
└── .mise.toml
```

각 플러그인은 독립 디렉토리에 `<name>.plugin.zsh` 엔트리포인트로 구성.

## 개발

- Language: Zsh / Shell
- Task Runner: mise
- Lint: `mise run lint`
- Format: `mise run fmt`

## 플러그인 추가 규칙

1. 플러그인 디렉토리는 kebab-case
2. 엔트리포인트: `<plugin-name>.plugin.zsh`
3. 플러그인 매니저(zinit, antigen 등) 호환 구조 유지
4. README.md에 플러그인 테이블 업데이트

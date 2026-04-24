# zsh-plugins

[한국어 (Korean)](docs/README_ko.md)

A collection of custom Zsh plugins.

## Tech Stack

- Zsh / Shell

## Getting Started

Clone the repository and source the desired plugin in your `.zshrc`:

```zsh
source /path/to/zsh-plugins/<plugin-name>/<plugin-name>.plugin.zsh
```

## Plugins

| Plugin | Description |
|--------|-------------|
| [claude-auth-mode](claude-auth-mode/) | Claude Code auth mode switcher (subscription ↔ Azure AI Foundry) with sops+age |
| [overmind](overmind/) | Zsh completion for Overmind commands, options, aliases, and Procfile process names |

## Overmind Completion

```zsh
source /path/to/zsh-plugins/overmind/overmind.plugin.zsh
```

The completion supports Overmind v2.5.1 commands and aliases, command-specific flags, socket/network flags, and Procfile-based process name completion for commands such as `restart`, `stop`, and `connect`.

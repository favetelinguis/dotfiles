# Shared Agent Skills

Store machine-agnostic skills here.

Each skill should live in its own directory:

```text
~/.config/agents/skills/<skill-name>/SKILL.md
```

Use this directory as the canonical source. Agent-specific paths such as
`~/.claude/skills`, `~/.codex/skills`, and `~/.config/opencode/skills` are
managed as compatibility symlinks by chezmoi when enabled in the local
`chezmoi.toml` `data.ai` settings.

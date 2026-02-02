# AI Development Environment Bootstrap

A friendly script that helps beginners set up their Mac for AI-assisted coding.

## What It Installs

| Tool | Description |
|------|-------------|
| **Homebrew** | Package manager for macOS |
| **Git** | Version control |
| **NVM** | Node version manager |
| **Node.js LTS** | JavaScript runtime |
| **GitHub CLI** | GitHub from the command line |
| **AI Tools** | Codex, OpenCode, and/or Claude Code |

## Quick Start

**Visit [abregainc.github.io/ai-bootstrap](https://abregainc.github.io/ai-bootstrap)** for the landing page.

Or run directly:

```bash
curl -fsSL https://abregainc.github.io/ai-bootstrap/bootstrap.sh | bash
```

To clone and run locally:

```bash
git clone https://github.com/AbregaInc/ai-bootstrap.git
cd ai-bootstrap
chmod +x bootstrap.sh
./bootstrap.sh
```

## What to Expect

The script will:

1. ✅ Explain each step in plain English
2. ✅ Ask permission before installing anything
3. ✅ Skip tools that are already installed
4. ✅ Help you authenticate with GitHub
5. ✅ Let you choose which AI tools to install

## Requirements

- macOS (Apple Silicon or Intel)
- Admin password for your Mac
- Internet connection

## After Installation

You'll need API keys for the AI coding tools:

- **Codex CLI**: Get an OpenAI API key at https://platform.openai.com/api-keys
- **Claude Code**: Get an Anthropic API key at https://console.anthropic.com/

## Troubleshooting

### "command not found" after installation

Open a new terminal window. This loads the updated PATH.

### Homebrew installation fails

Make sure you have Xcode Command Line Tools:
```bash
xcode-select --install
```

### GitHub authentication issues

Run authentication manually:
```bash
gh auth login
```

## License

MIT

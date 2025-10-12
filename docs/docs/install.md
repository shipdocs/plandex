---
sidebar_position: 1
sidebar_label: Install
---

# Install Plandex

## Interactive Install (Recommended)

The interactive installer will guide you through setup, including:
- Choosing between cloud or local mode
- Automatically installing Docker for local mode (Linux only)
- Searching for existing API keys to auto-configure

```bash
curl -sL https://plandex.ai/install.sh | bash
```

When you run this command in an interactive terminal, you'll be prompted to select:
1. **Plandex Cloud** - Hosted service (being deprecated as of 10/3/2025)
2. **Local Mode** - Self-hosted on your machine (recommended)
3. **CLI only** - Just install the CLI, configure later

### Local Mode Features

If you select local mode, the installer will:
- Check if Docker is installed and offer to install it automatically (Linux)
- Guide you through Docker installation (macOS)
- Search your system for existing API keys with your permission
- Help you clone and start the Plandex server

### API Key Auto-Discovery

The installer can search common locations for API keys including:
- Environment variables (current session)
- Shell profile files (`.bashrc`, `.zshrc`, `.bash_profile`, etc.)
- Environment files (`.env`, `.envrc`)

Supported API keys:
- `OPENROUTER_API_KEY`
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `AZURE_OPENAI_API_KEY`
- `DEEPSEEK_API_KEY`
- `PERPLEXITY_API_KEY`

## Non-Interactive Install

If you pipe the installer (as shown above) or run it in a non-interactive environment, it will install the CLI only without prompting:

```bash
curl -sL https://plandex.ai/install.sh | bash
```

You can then manually configure your setup by running `plandex sign-in`.

## Manual install

Grab the appropriate binary for your platform from the latest [release](https://github.com/shipdocs/plandex/releases) and put it somewhere in your `PATH`.

## Build from source

```bash
git clone https://github.com/shipdocs/plandex.git
cd plandex/app/cli
go build -ldflags "-X plandex/version.Version=$(cat version.txt)"
mv plandex /usr/local/bin # adapt as needed for your system
```

## Windows

Windows is supported via [WSL](https://learn.microsoft.com/en-us/windows/wsl/about).

Plandex only works correctly in the WSL shell. It doesn't work in the Windows CMD prompt or PowerShell.
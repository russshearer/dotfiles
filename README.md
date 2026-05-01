# dotfiles

Personal dotfiles for homelab VMs — Proxmox, Kubernetes, Terraform, and general Ubuntu server work.

## What's included

| File | Purpose |
|------|---------|
| `.bashrc` | Shell config — Oh My Posh prompt, history, completions, PATH |
| `.bash_aliases` | Aliases for kubectl, terraform, git, system admin |
| `.vimrc` | Sensible Vim defaults (4-space indent, YAML override) |
| `.tmux.conf` | tmux config — Ctrl+a prefix, vim nav, mouse support |
| `.gitconfig` | Git aliases, rebase on pull, auto-prune |
| `install.sh` | Bootstrap script — installs Oh My Posh, symlinks everything |

## Prerequisites

- Git
- [Oh My Posh](https://ohmyposh.dev/) — auto-installed by `install.sh` if not present
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal for icons/glyphs

## Install

```bash
git clone https://github.com/russshearer/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

To overwrite existing files:

```bash
./install.sh --force
```

## Prompt theme

Oh My Posh is configured to pull the theme directly from:

```
https://github.com/russshearer/terminal/raw/main/oh-my-posh/themes/myterm.omp.json
```

Same theme is used across PowerShell, WSL, and homelab VMs. Edit it in the
[terminal](https://github.com/russshearer/terminal) repo.

If Oh My Posh is not installed, `.bashrc` falls back to a basic colored prompt with git branch.

## Local overrides

Add machine-specific config to `~/.bashrc.local` — it's sourced automatically and not tracked by git.

## Update

```bash
cd ~/.dotfiles
git pull
```

Symlinks mean changes take effect immediately (restart shell or `source ~/.bashrc`).

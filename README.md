# Workspace Pod Development Environment

## Overview

This repository provides a containerized development environment using VS Code Dev Containers. It offers a comprehensive, pre-configured workspace with modern development tools, programming languages, and IDE integrations for efficient software development.

## What's Included

### Base Environment
- **Container Image**: Microsoft Dev Containers Debian base image
- **Architecture**: Runs with privileged access for Docker operations
- **User Configuration**: Pre-configured `vscode` user with appropriate permissions
- **Persistence**: Container configured with `shutdownAction: none` for persistent sessions

### Programming Languages and Runtimes
- **Node.js**: Latest version with npm package manager
- **Python**: Python 3 with pip package manager
- **Docker-in-Docker**: Full Docker support within the container for containerized development

### Shell and Terminal
- **Zsh**: Advanced shell with Oh My Zsh framework
- **Powerlevel10k Theme**: Modern, customizable terminal theme with git integration
- **Tmux**: Terminal multiplexer for managing multiple sessions

### Development Tools
- **GitHub CLI (gh)**: Command-line interface for GitHub operations
- **Miniforge**: Conda package manager with conda-forge defaults
- **UV**: Fast Python package manager written in Rust
- **Claude Code CLI**: Anthropic's official CLI for AI-assisted development
- **Essential Build Tools**: curl, wget, git, build-essential, jq, and more

### VS Code Extensions
- **Roo Cline**: AI-powered coding assistant
- **GistFS**: Direct access to GitHub Gists in VS Code
- **GitHub Copilot**: AI pair programming assistant
- **GitHub Copilot Chat**: Interactive AI assistance
- **Claude Code**: Anthropic's official VS Code extension
- **Claude Code Extension**: Enhanced Claude features and cost tracking
- **CC Usage**: Claude Code usage monitoring

## Getting Started

### Prerequisites
1. **Docker**: Docker Desktop or Docker Engine must be installed and running
2. **VS Code**: Visual Studio Code with Dev Containers extension
3. **Git**: Git for cloning the repository

### Setup Instructions

#### Method 1: Using VS Code Dev Containers
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd workspace_pod
   ```

2. Open the folder in VS Code:
   ```bash
   code .
   ```

3. When prompted by VS Code, click "Reopen in Container" or use the command palette (F1) and select "Dev Containers: Reopen in Container"

4. Wait for the container to build and start. The post-create script will automatically install all development tools.

#### Method 2: Using DevPod CLI
1. Install DevPod CLI from https://devpod.sh/docs/getting-started/install

2. Create and start the development pod:
   ```bash
   devpod up <repository-url>
   ```

3. Connect to the pod:
   ```bash
   devpod ssh <pod-name>
   ```

### Post-Installation Setup

After the container starts, the following tools will be automatically installed via the `install-tools.sh` script:

1. **Verify Installation**: Check the installation report:
   ```bash
   cat ~/installation-report.md
   ```

2. **Apply Shell Configuration**: If using the terminal directly:
   ```bash
   source ~/.zshrc
   ```

3. **Configure GitHub CLI**: Authenticate with GitHub:
   ```bash
   gh auth login
   ```

4. **Customize Terminal Theme** (optional):
   ```bash
   p10k configure
   ```

5. **Test Python Environments**:
   - Conda/Mamba: `conda --version` or `mamba --version`
   - UV: `uv --version`

6. **Test Claude Code CLI**:
   ```bash
   claude --version
   ```

## Manual Tool Installation

If any tools fail to install automatically during container creation, you can run the installation script manually:

```bash
bash .devcontainer/install-tools.sh
```

This will attempt to install all missing tools and generate a detailed report.

## File Structure

```
workspace_pod/
├── .devcontainer/
│   ├── devcontainer.json    # Dev container configuration
│   └── install-tools.sh     # Automated tool installation script
├── .gitignore               # Git ignore rules
└── README.md               # This file
```

## System Requirements

- **RAM**: Minimum 4GB allocated to Docker
- **Storage**: 10GB available disk space
- **Network**: Internet connection for package downloads
- **OS**: Windows, macOS, or Linux with Docker support

## Troubleshooting

### Container Fails to Start
- Ensure Docker is running
- Check Docker has sufficient resources allocated
- Verify no port conflicts exist

### Tools Not Installed
- Run the installation script manually: `bash .devcontainer/install-tools.sh`
- Check the installation report: `cat ~/installation-report.md`
- Ensure internet connectivity for package downloads

### Permission Issues
- The container runs with privileged access
- User `vscode` has sudo privileges
- For Docker operations, ensure Docker socket is accessible

## Customization

You can customize the development environment by modifying:
- `.devcontainer/devcontainer.json`: Add more VS Code extensions or Dev Container features
- `.devcontainer/install-tools.sh`: Add additional tools or configurations
- Shell configurations: Modify `.zshrc` or `.p10k.zsh` after container creation

## Support

For issues or questions:
1. Check the installation report for any errors
2. Review the troubleshooting section
3. Consult VS Code Dev Containers documentation
4. Submit issues to the repository issue tracker
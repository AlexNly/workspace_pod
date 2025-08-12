#!/bin/bash

# Initialize report file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_FILE="$SCRIPT_DIR/installation-report.md"
echo "# DevContainer Installation Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Generated on:** $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## Installation Summary" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Track installation results
declare -A INSTALL_STATUS
declare -A INSTALL_NOTES

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to record installation status
record_status() {
    local tool="$1"
    local status="$2"
    local note="$3"
    
    INSTALL_STATUS["$tool"]="$status"
    INSTALL_NOTES["$tool"]="$note"
}

# Function to try installing a package
try_install() {
    local package="$1"
    local install_cmd="$2"
    
    echo "Attempting to install $package..."
    
    # Try without sudo first
    if $install_cmd 2>/dev/null; then
        echo "$package installed successfully without sudo"
        return 0
    fi
    
    # Try with sudo if available
    if command_exists sudo; then
        echo "Retrying with sudo..."
        if sudo $install_cmd 2>/dev/null; then
            echo "$package installed successfully with sudo"
            return 0
        fi
    fi
    
    echo "Failed to install $package - continuing without it"
    return 1
}

# Install tmux
echo "### Tmux Installation" >> "$REPORT_FILE"
if ! command_exists tmux; then
    if command_exists apt-get; then
        if try_install "tmux" "apt-get install -y tmux"; then
            record_status "tmux" "Success" "Installed via apt-get"
        else
            record_status "tmux" "Failed" "Installation failed - see manual instructions below"
        fi
    elif command_exists yum; then
        if try_install "tmux" "yum install -y tmux"; then
            record_status "tmux" "Success" "Installed via yum"
        else
            record_status "tmux" "Failed" "Installation failed - see manual instructions below"
        fi
    elif command_exists apk; then
        if try_install "tmux" "apk add tmux"; then
            record_status "tmux" "Success" "Installed via apk"
        else
            record_status "tmux" "Failed" "Installation failed - see manual instructions below"
        fi
    elif command_exists brew; then
        if try_install "tmux" "brew install tmux"; then
            record_status "tmux" "Success" "Installed via brew"
        else
            record_status "tmux" "Failed" "Installation failed - see manual instructions below"
        fi
    else
        record_status "tmux" "Failed" "No supported package manager found"
    fi
else
    record_status "tmux" "Already Installed" "Version: $(tmux -V 2>/dev/null || echo 'unknown')"
fi

# Install GitHub CLI
echo "### GitHub CLI Installation" >> "$REPORT_FILE"
if ! command_exists gh; then
    if command_exists apt-get; then
        # For Debian/Ubuntu systems
        echo "Installing GitHub CLI for Debian/Ubuntu..."
        INSTALL_GH_DEB="(type -p wget >/dev/null || apt-get install wget -y) && \
            wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
            chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
            echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
            apt-get update && \
            apt-get install gh -y"
        
        # Try without sudo first
        if bash -c "$INSTALL_GH_DEB" 2>/dev/null; then
            record_status "gh" "Success" "Installed via apt-get"
        elif command_exists sudo; then
            echo "Retrying GitHub CLI installation with sudo..."
            if sudo bash -c "$INSTALL_GH_DEB" 2>/dev/null; then
                record_status "gh" "Success" "Installed via apt-get with sudo"
            else
                record_status "gh" "Failed" "Installation failed - see manual instructions below"
            fi
        else
            record_status "gh" "Failed" "Installation failed - see manual instructions below"
        fi
    elif command_exists yum; then
        if try_install "gh" "yum install -y gh"; then
            record_status "gh" "Success" "Installed via yum"
        else
            record_status "gh" "Failed" "Installation failed - see manual instructions below"
        fi
    elif command_exists brew; then
        if try_install "gh" "brew install gh"; then
            record_status "gh" "Success" "Installed via brew"
        else
            record_status "gh" "Failed" "Installation failed - see manual instructions below"
        fi
    else
        record_status "gh" "Failed" "No supported package manager found"
    fi
else
    record_status "gh" "Already Installed" "Version: $(gh --version 2>/dev/null | head -n1 || echo 'unknown')"
fi

# Install Miniforge
echo "### Miniforge Installation" >> "$REPORT_FILE"
if ! command_exists conda && ! command_exists mamba; then
    echo "Installing Miniforge..."
    MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-$(uname -m).sh"
    
    # Download installer
    if command_exists wget; then
        wget -q "$MINIFORGE_URL" -O /tmp/miniforge.sh
    elif command_exists curl; then
        curl -sL "$MINIFORGE_URL" -o /tmp/miniforge.sh
    else
        record_status "miniforge" "Failed" "Neither wget nor curl available for download"
    fi
    
    if [ -f /tmp/miniforge.sh ]; then
        bash /tmp/miniforge.sh -b -p $HOME/miniforge3
        rm /tmp/miniforge.sh
        
        # Add to PATH
        echo 'export PATH="$HOME/miniforge3/bin:$PATH"' >> ~/.bashrc
        echo 'export PATH="$HOME/miniforge3/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
        
        # Initialize conda
        $HOME/miniforge3/bin/conda init bash
        $HOME/miniforge3/bin/conda init zsh 2>/dev/null || true
        
        record_status "miniforge" "Success" "Installed to $HOME/miniforge3"
    else
        record_status "miniforge" "Failed" "Download failed"
    fi
else
    if command_exists conda; then
        record_status "miniforge" "Already Installed" "Conda version: $(conda --version 2>/dev/null || echo 'unknown')"
    else
        record_status "miniforge" "Already Installed" "Mamba version: $(mamba --version 2>/dev/null || echo 'unknown')"
    fi
fi

# Install Oh My Zsh
echo "### Oh My Zsh Installation" >> "$REPORT_FILE"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    if command_exists curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        record_status "oh-my-zsh" "Success" "Installed to $HOME/.oh-my-zsh"
    elif command_exists wget; then
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        record_status "oh-my-zsh" "Success" "Installed to $HOME/.oh-my-zsh"
    else
        record_status "oh-my-zsh" "Failed" "Neither curl nor wget available"
    fi
else
    record_status "oh-my-zsh" "Already Installed" "Located at $HOME/.oh-my-zsh"
fi

# Install Powerlevel10k theme
echo "### Powerlevel10k Theme Installation" >> "$REPORT_FILE"
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    record_status "powerlevel10k" "Success" "Installed to Oh My Zsh custom themes"
else
    record_status "powerlevel10k" "Already Installed" "Located in Oh My Zsh custom themes"
fi

# Configure Zsh (basic configuration without the full P10k config for brevity)
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    cat > ~/.zshrc << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

# Miniforge/Conda initialization
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
fi

# Load P10k configuration if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add cargo/rust binaries to PATH (for UV)
export PATH="$HOME/.cargo/bin:$PATH"

# Add UV tools to PATH
export PATH="$HOME/.local/bin:$PATH"
EOF
    echo "Zsh configuration updated"
fi

# Install UV (Python package manager)
echo "### UV Installation" >> "$REPORT_FILE"
if ! command_exists uv; then
    echo "Installing UV Python package manager..."
    
    # First, ensure we have curl or wget for downloading
    if command_exists curl; then
        DOWNLOAD_CMD="curl -LsSf"
    elif command_exists wget; then
        DOWNLOAD_CMD="wget -qO-"
    else
        echo "Neither curl nor wget found. Attempting to install curl..."
        if command_exists apt-get; then
            try_install "curl" "apt-get install -y curl"
        elif command_exists yum; then
            try_install "curl" "yum install -y curl"
        elif command_exists apk; then
            try_install "curl" "apk add curl"
        fi
        
        if command_exists curl; then
            DOWNLOAD_CMD="curl -LsSf"
        else
            record_status "uv" "Failed" "Cannot install - neither curl nor wget available"
            echo "Failed to install UV - missing download tools"
        fi
    fi
    
    # If we have a download command, proceed with installation
    if [ -n "${DOWNLOAD_CMD:-}" ]; then
        # UV has a universal installer script
        INSTALL_UV="$DOWNLOAD_CMD https://astral.sh/uv/install.sh | sh"
        
        # Try to install UV using the official installer
        echo "Attempting UV installation via official installer..."
        if bash -c "$INSTALL_UV" 2>/dev/null; then
            # Source the env file to update PATH for current session
            if [ -f "$HOME/.cargo/env" ]; then
                source "$HOME/.cargo/env"
            fi
            # Verify installation
            if command_exists uv; then
                record_status "uv" "Success" "Installed via official installer"
            else
                # PATH might not be updated yet
                if [ -f "$HOME/.cargo/bin/uv" ]; then
                    export PATH="$HOME/.cargo/bin:$PATH"
                    record_status "uv" "Success" "Installed via official installer (PATH updated)"
                else
                    record_status "uv" "Partial" "Installed but not in PATH - restart shell"
                fi
            fi
        else
            # Try alternative installation method via pip
            echo "Official installer failed, trying pip installation..."
            if command_exists python3 || command_exists python; then
                PYTHON_CMD=$(command -v python3 || command -v python)
                
                # Check if pip is available
                if $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
                    echo "Installing UV via pip..."
                    
                    if $PYTHON_CMD -m pip install --user uv 2>/dev/null; then
                        record_status "uv" "Success" "Installed via pip (user)"
                    elif command_exists sudo; then
                        echo "Retrying UV installation with sudo..."
                        if sudo $PYTHON_CMD -m pip install uv 2>/dev/null; then
                            record_status "uv" "Success" "Installed via pip (system)"
                        else
                            record_status "uv" "Failed" "All installation methods failed"
                        fi
                    else
                        record_status "uv" "Failed" "pip installation failed without sudo"
                    fi
                else
                    record_status "uv" "Failed" "Python found but pip not available"
                fi
            else
                record_status "uv" "Failed" "Python not found - required for fallback installation"
            fi
        fi
    fi
else
    # UV is already installed
    UV_VERSION=$(uv --version 2>/dev/null | head -n1 || echo 'unknown')
    record_status "uv" "Already Installed" "Version: $UV_VERSION"
    
    # Check if UV is properly configured
    if uv --version >/dev/null 2>&1; then
        echo "UV is properly installed and accessible"
    else
        echo "UV is installed but may have PATH issues"
    fi
fi

# Install Claude Code CLI
echo "### Claude Code CLI Installation" >> "$REPORT_FILE"
if ! command_exists claude; then
    echo "Installing Claude Code CLI..."
    
    if command_exists curl; then
        curl -fsSL https://install.claude.ai/claude-code | sh
        if [ $? -eq 0 ]; then
            record_status "claude-code" "Success" "Installed via official installer"
        else
            record_status "claude-code" "Failed" "Installation script failed"
        fi
    elif command_exists wget; then
        wget -qO- https://install.claude.ai/claude-code | sh
        if [ $? -eq 0 ]; then
            record_status "claude-code" "Success" "Installed via official installer"
        else
            record_status "claude-code" "Failed" "Installation script failed"
        fi
    else
        record_status "claude-code" "Failed" "Neither curl nor wget available"
    fi
else
    record_status "claude-code" "Already Installed" "Version: $(claude --version 2>/dev/null || echo 'unknown')"
fi

# Write the status table to the report
echo "| Tool | Status | Notes |" >> "$REPORT_FILE"
echo "|------|--------|-------|" >> "$REPORT_FILE"
echo "| tmux | ${INSTALL_STATUS[tmux]} | ${INSTALL_NOTES[tmux]} |" >> "$REPORT_FILE"
echo "| GitHub CLI | ${INSTALL_STATUS[gh]} | ${INSTALL_NOTES[gh]} |" >> "$REPORT_FILE"
echo "| Miniforge | ${INSTALL_STATUS[miniforge]} | ${INSTALL_NOTES[miniforge]} |" >> "$REPORT_FILE"
echo "| Oh My Zsh | ${INSTALL_STATUS[oh-my-zsh]} | ${INSTALL_NOTES[oh-my-zsh]} |" >> "$REPORT_FILE"
echo "| Powerlevel10k | ${INSTALL_STATUS[powerlevel10k]} | ${INSTALL_NOTES[powerlevel10k]} |" >> "$REPORT_FILE"
echo "| UV | ${INSTALL_STATUS[uv]} | ${INSTALL_NOTES[uv]} |" >> "$REPORT_FILE"
echo "| Claude Code | ${INSTALL_STATUS[claude-code]} | ${INSTALL_NOTES[claude-code]} |" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Add manual installation instructions for failed items
FAILED_ITEMS=0
for tool in tmux gh miniforge oh-my-zsh powerlevel10k uv claude-code; do
    if [[ "${INSTALL_STATUS[$tool]}" == *"Failed"* ]]; then
        ((FAILED_ITEMS++))
    fi
done

if [ $FAILED_ITEMS -gt 0 ]; then
    echo "## Manual Installation Instructions" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Some tools failed to install automatically. Please follow these instructions to install them manually:" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [[ "${INSTALL_STATUS[tmux]}" == *"Failed"* ]]; then
        echo "### Installing tmux manually" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "**For Debian/Ubuntu:**" >> "$REPORT_FILE"
        echo '```bash' >> "$REPORT_FILE"
        echo "sudo apt update" >> "$REPORT_FILE"
        echo "sudo apt install -y tmux" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    if [[ "${INSTALL_STATUS[gh]}" == *"Failed"* ]]; then
        echo "### Installing GitHub CLI manually" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "**For Debian/Ubuntu:**" >> "$REPORT_FILE"
        echo '```bash' >> "$REPORT_FILE"
        echo "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg" >> "$REPORT_FILE"
        echo "sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg" >> "$REPORT_FILE"
        echo 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null' >> "$REPORT_FILE"
        echo "sudo apt update" >> "$REPORT_FILE"
        echo "sudo apt install gh -y" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
else
    echo "## All Tools Successfully Installed!" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Your development environment is ready to use. Enjoy coding!" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "*Report generated at: $(date)*" >> "$REPORT_FILE"

echo "Tool installation script completed"
echo "Installation report saved to: $REPORT_FILE"
echo ""
echo "To view the installation report, run:"
echo "    cat .devcontainer/installation-report.md"
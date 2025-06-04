#!/bin/bash

# init-wsl.sh - Complete WSL Development Environment Setup
# Run with: curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/init-wsl.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/yourusername/dotfiles/main/init-wsl.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_info "Detected OS: $OS $VER"

# Check if running in WSL
if ! grep -q Microsoft /proc/version && ! grep -q WSL /proc/version; then
    print_error "This script is designed for WSL only"
    exit 1
fi

# Update system
print_step "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential packages
print_step "Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    zip \
    unzip \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    tree \
    htop \
    vim \
    nano \
    jq \
    ripgrep \
    fd-find \
    bat \
    tmux \
    netcat-openbsd \
    dnsutils \
    iputils-ping \
    openssh-client \
    postgresql-client \
    mysql-client \
    redis-tools \
    python3-pip \
    python3-venv \
    python3-dev \
    rsyslog \
    zsh \
    fonts-powerline \
    fzf \
    neofetch \
    ncdu \
    duf \
    exa \
    httpie

print_success "Essential packages installed"

# Install GitHub CLI
print_step "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
fi
print_success "GitHub CLI installed"

# Install Docker
print_step "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker $USER
    print_info "You'll need to log out and back in for docker group to take effect"
fi
print_success "Docker installed"

# Install SDKMAN (for Java ecosystem)
print_step "Installing SDKMAN..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    # Install Java versions
    sdk install java 21-tem  # Temurin JDK 21 (LTS)
    sdk install java 17-tem  # Temurin JDK 17 (LTS)
    sdk install maven
    sdk install gradle
    sdk install kotlin
    sdk install groovy
fi
print_success "SDKMAN installed"

# Install NVM and Node.js
print_step "Installing NVM and Node.js..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node versions
    nvm install --lts
    nvm install 20
    nvm alias default node
    
    # Install global npm packages
    npm install -g \
        pnpm@latest \
        yarn@latest \
        typescript \
        tsx \
        nodemon \
        pm2 \
        serve \
        vercel \
        netlify-cli \
        @angular/cli \
        @vue/cli \
        create-react-app \
        create-next-app \
        vite \
        eslint \
        prettier
fi
print_success "NVM and Node.js installed"

# Install Rust
print_step "Installing Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # Install useful Rust tools
    cargo install \
        ripgrep \
        fd-find \
        bat \
        exa \
        tokei \
        procs \
        bottom \
        zoxide \
        starship
fi
print_success "Rust installed"

# Install Go
print_step "Installing Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.23.3"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz
    
    # Install Go tools
    export PATH="/usr/local/go/bin:$PATH"
    go install github.com/jesseduffield/lazygit@latest
    go install github.com/jesseduffield/lazydocker@latest
fi
print_success "Go installed"

# Setup Python environment
print_step "Setting up Python environment..."
# Install pyenv for Python version management
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    # Install Python versions
    pyenv install 3.12.0
    pyenv install 3.11.6
    pyenv global 3.12.0
fi

# Create a global virtual environment
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install \
    pipenv \
    poetry \
    black \
    flake8 \
    mypy \
    pytest \
    httpie \
    requests \
    pandas \
    numpy \
    jupyterlab \
    ipython \
    django \
    flask \
    fastapi \
    uvicorn
print_success "Python environment set up"

# Install Terraform
print_step "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
fi
print_success "Terraform installed"

# Install kubectl
print_step "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi
print_success "kubectl installed"

# Install AWS CLI v2
print_step "Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
fi
print_success "AWS CLI installed"

# Install Azure CLI
print_step "Installing Azure CLI..."
if ! command -v az &> /dev/null; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
print_success "Azure CLI installed"

# Create directory structure
print_step "Creating directory structure..."
mkdir -p ~/projects/{personal,work,learning,sandbox}
mkdir -p ~/scripts
mkdir -p ~/tools
mkdir -p ~/.config
mkdir -p ~/backups
print_success "Directory structure created"

# Setup Git configuration
print_step "Configuring Git..."
read -p "Enter your Git email: " git_email
read -p "Enter your Git name: " git_name

git config --global user.email "$git_email"
git config --global user.name "$git_name"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "vim"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg 'log --oneline --graph --decorate'
print_success "Git configured"

# Install Oh My Zsh
print_step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install Powerlevel10k theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
fi
print_success "Oh My Zsh installed"

# Create enhanced shell configuration
print_step "Setting up shell configuration..."

# Create common shell aliases and functions
cat > ~/.shell_common << 'EOL'
# Navigation aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# List aliases
alias ls="exa --icons"
alias ll="exa -alh --icons"
alias la="exa -a --icons"
alias l="exa -F --icons"
alias lt="exa --tree --icons"

# Git aliases
alias g="git"
alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"
alias gco="git checkout"
alias gbr="git branch"

# Docker aliases
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias dimg="docker images"
alias dexec="docker exec -it"
alias dlog="docker logs -f"
alias dprune="docker system prune -af"

# Kubectl aliases
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kdp="kubectl describe pod"
alias klog="kubectl logs -f"

# Python aliases
alias py="python3"
alias pip="pip3"
alias venv="python3 -m venv"
alias activate="source .venv/bin/activate"

# System aliases
alias h="history"
alias c="clear"
alias q="exit"
alias reload="source ~/.zshrc"
alias myip="curl -s https://ipinfo.io/ip"
alias ports="netstat -tulanp"
alias usage="du -h --max-depth=1 | sort -hr"

# Safety aliases
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup function
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Create and enter directory
take() {
    mkdir -p $@ && cd ${@:$#}
}

# Docker cleanup
docker-cleanup() {
    docker rm $(docker ps -a -q) 2>/dev/null
    docker rmi $(docker images -q -f dangling=true) 2>/dev/null
    docker volume rm $(docker volume ls -q -f dangling=true) 2>/dev/null
}

# Quick server
serve() {
    local port="${1:-8000}"
    python3 -m http.server $port
}

# Weather
weather() {
    curl "wttr.in/${1:-}"
}
EOL

# Update .bashrc
cat >> ~/.bashrc << 'EOL'

# Source common shell configuration
[ -f ~/.shell_common ] && source ~/.shell_common

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
source "$HOME/.cargo/env"

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Activate Python virtual environment
[ -d "$HOME/.venv" ] && source "$HOME/.venv/bin/activate"

# Path additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Starship prompt (if using bash)
eval "$(starship init bash)"
EOL

# Create .zshrc
cat > ~/.zshrc << 'EOL'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    docker
    docker-compose
    kubectl
    terraform
    aws
    npm
    node
    python
    pip
    golang
    rust
    sudo
    command-not-found
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf
    z
)

source $ZSH/oh-my-zsh.sh

# Source common shell configuration
[ -f ~/.shell_common ] && source ~/.shell_common

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Go
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
source "$HOME/.cargo/env"

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Activate Python virtual environment
[ -d "$HOME/.venv" ] && source "$HOME/.venv/bin/activate"

# Path additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOL

print_success "Shell configuration complete"

# Create Windows symlinks
print_step "Creating Windows symlinks..."
ln -sf /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r') ~/host
ln -sf ~/host/Desktop ~/desktop
ln -sf ~/host/Documents ~/docs
ln -sf ~/host/Downloads ~/downloads
print_success "Windows symlinks created"

# Create useful scripts
print_step "Creating utility scripts..."

# Create docker-compose wrapper for common tasks
cat > ~/scripts/dc-helper << 'EOL'
#!/bin/bash
# Docker Compose Helper Script

case "$1" in
    start)
        docker compose up -d
        ;;
    stop)
        docker compose down
        ;;
    restart)
        docker compose restart
        ;;
    logs)
        shift
        docker compose logs -f "$@"
        ;;
    clean)
        docker compose down -v
        ;;
    rebuild)
        docker compose down
        docker compose build --no-cache
        docker compose up -d
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|clean|rebuild}"
        exit 1
        ;;
esac
EOL
chmod +x ~/scripts/dc-helper

# Final setup
print_step "Final setup..."

# Set zsh as default shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s $(which zsh)
    print_info "Default shell changed to zsh. Please restart your terminal."
fi

# Create a summary file
cat > ~/wsl-setup-summary.txt << EOF
WSL Development Environment Setup Complete!
==========================================

Installed Tools:
- Languages: Java (via SDKMAN), Node.js (via NVM), Python (via pyenv), Go, Rust
- Package Managers: apt, snap, pip, npm, cargo, go
- Version Managers: SDKMAN, NVM, pyenv
- Containers: Docker, docker-compose, kubectl
- Cloud CLIs: AWS CLI, Azure CLI, GitHub CLI
- Databases: PostgreSQL client, MySQL client, Redis tools
- Utilities: git, vim, tmux, htop, tree, jq, fzf, ripgrep, bat, exa
- Shell: zsh with Oh My Zsh and Powerlevel10k theme

Directory Structure:
- ~/projects/     - Your coding projects
- ~/scripts/      - Utility scripts
- ~/tools/        - Additional tools
- ~/backups/      - Backup files

Symlinks to Windows:
- ~/host          - Your Windows user directory
- ~/desktop       - Windows Desktop
- ~/docs          - Windows Documents  
- ~/downloads     - Windows Downloads

Configuration Files:
- ~/.zshrc        - Zsh configuration
- ~/.bashrc       - Bash configuration (fallback)
- ~/.gitconfig    - Git configuration
- ~/.shell_common - Common aliases and functions

Next Steps:
1. Restart your terminal or run: source ~/.zshrc
2. Configure Powerlevel10k by running: p10k configure
3. Set up your SSH keys: ssh-keygen -t ed25519
4. Configure cloud CLIs if needed (aws configure, az login, etc.)
5. Clone your projects to ~/projects/

Docker is installed but you need to log out and back in for group permissions.

Enjoy your development environment!
EOF

# Display summary
echo
cat ~/wsl-setup-summary.txt

print_success "Setup complete! 🎉"
print_info "Please restart your terminal or run: source ~/.zshrc"

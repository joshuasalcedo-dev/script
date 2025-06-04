#!/bin/bash

# init-wsl.sh - Complete WSL Development Environment Setup for Ubuntu 24.04
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
BOLD='\033[1m'
UNDERLINE='\033[4m'

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

# Install essential packages (Ubuntu 24.04 compatible)
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
    eza \
    httpie

print_success "Essential packages installed"

# Install MongoDB Shell (mongosh) separately
print_step "Installing MongoDB Shell..."
if ! command -v mongosh &> /dev/null; then
    wget -qO- https://www.mongodb.org/static/pgp/server-7.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-7.0.asc
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-mongosh
fi
print_success "MongoDB Shell installed"

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
mkdir -p ~/docker-data/{postgres,mongodb,redis,elasticsearch,nexus,logs,init,config}
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

# Create the show-banner.sh script
print_step "Creating banner script..."
cat > ~/scripts/show-banner.sh << 'BANNER_SCRIPT'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Get service statuses
get_service_status() {
    local container=$1
    if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "^${container}$"; then
        echo -e "${GREEN}● Running${NC}"
    else
        echo -e "${RED}● Stopped${NC}"
    fi
}

# Get Nexus admin password
get_nexus_password() {
    if [ -f ~/docker-data/nexus/admin.password ]; then
        cat ~/docker-data/nexus/admin.password
    else
        echo "Check container logs after first start"
    fi
}

# Clear screen for better presentation
clear

echo -e "${CYAN}"
cat << 'BANNER'
╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                          ║
║     ███████╗██╗    ██╗ █████╗ ███████╗██╗    ██╗ █████╗                                               ║
║     ██╔════╝██║    ██║██╔══██╗██╔════╝██║    ██║██╔══██╗                                              ║
║     ███████╗██║ █╗ ██║███████║███████╗██║ █╗ ██║███████║                                              ║
║     ╚════██║██║███╗██║██╔══██║╚════██║██║███╗██║██╔══██║                                              ║
║     ███████║╚███╔███╔╝██║  ██║███████║╚███╔███╔╝██║  ██║                                              ║
║     ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝                                              ║
║                                                                                                          ║
║     Development Environment                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Display services information
echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${WHITE}SERVICES STATUS & INFORMATION${NC}"
echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════════════════════════════${NC}"
echo

# Databases
echo -e "${BOLD}${BLUE}📊 DATABASES${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ %-20s %-15s %-50s │\n" "SERVICE" "STATUS" "CONNECTION"
echo -e "├─────────────────────────────────────────────────────────────────────────────────────┤"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "PostgreSQL" "$(get_service_status postgres-dev)" "psql -h localhost -p 5432 -U postgres"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "MongoDB" "$(get_service_status mongodb-dev)" "mongodb://admin:admin@localhost:27017"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "Redis" "$(get_service_status redis-dev)" "redis-cli -h localhost -p 6379"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# Web Services
echo -e "${BOLD}${BLUE}🌐 WEB SERVICES${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ %-20s %-15s %-50s │\n" "SERVICE" "STATUS" "URL"
echo -e "├─────────────────────────────────────────────────────────────────────────────────────┤"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "Kibana" "$(get_service_status kibana-dev)" "http://localhost:5601"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "Elasticsearch" "$(get_service_status elasticsearch-dev)" "http://localhost:9200"
printf "│ ${CYAN}%-20s${NC} %-15s ${UNDERLINE}${BLUE}%-50s${NC} │\n" "Nexus Repository" "$(get_service_status nexus-dev)" "http://localhost:8091"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# Development Ports
echo -e "${BOLD}${BLUE}🚀 DEVELOPMENT PORTS${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ %-20s %-64s │\n" "PURPOSE" "PORT"
echo -e "├─────────────────────────────────────────────────────────────────────────────────────┤"
printf "│ ${CYAN}%-20s${NC} ${YELLOW}%-64s${NC} │\n" "Node.js Apps" "localhost:3000"
printf "│ ${CYAN}%-20s${NC} ${YELLOW}%-64s${NC} │\n" "Java/Spring Apps" "localhost:8080"
printf "│ ${CYAN}%-20s${NC} ${YELLOW}%-64s${NC} │\n" "Python/Flask Apps" "localhost:5000"
printf "│ ${CYAN}%-20s${NC} ${YELLOW}%-64s${NC} │\n" "Angular Apps" "localhost:4200"
printf "│ ${CYAN}%-20s${NC} ${YELLOW}%-64s${NC} │\n" "Vite Apps" "localhost:5173"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# Credentials
echo -e "${BOLD}${BLUE}🔐 CREDENTIALS${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ %-20s %-30s %-34s │\n" "SERVICE" "USERNAME" "PASSWORD"
echo -e "├─────────────────────────────────────────────────────────────────────────────────────┤"
printf "│ ${CYAN}%-20s${NC} %-30s %-34s │\n" "PostgreSQL" "postgres" "postgres"
printf "│ ${CYAN}%-20s${NC} %-30s %-34s │\n" "MongoDB (root)" "admin" "admin"
printf "│ ${CYAN}%-20s${NC} %-30s %-34s │\n" "MongoDB (app)" "appuser" "apppassword"
printf "│ ${CYAN}%-20s${NC} %-30s %-34s │\n" "Nexus" "admin" "$(get_nexus_password)"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# Quick Commands
echo -e "${BOLD}${BLUE}⚡ QUICK COMMANDS${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ ${GREEN}%-83s${NC} │\n" "dbstart        - Start all services"
printf "│ ${GREEN}%-83s${NC} │\n" "dbstop         - Stop all services"
printf "│ ${GREEN}%-83s${NC} │\n" "dbstatus       - Check service status"
printf "│ ${GREEN}%-83s${NC} │\n" "psql           - Connect to PostgreSQL"
printf "│ ${GREEN}%-83s${NC} │\n" "mongo          - Connect to MongoDB"
printf "│ ${GREEN}%-83s${NC} │\n" "redis-cli      - Connect to Redis"
printf "│ ${GREEN}%-83s${NC} │\n" "dblogs [name]  - View service logs"
printf "│ ${GREEN}%-83s${NC} │\n" "banner         - Show this banner again"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# System Info
echo -e "${BOLD}${BLUE}💻 SYSTEM INFORMATION${NC}"
echo -e "┌─────────────────────────────────────────────────────────────────────────────────────┐"
printf "│ ${CYAN}%-20s${NC} %-62s │\n" "Hostname:" "$(hostname)"
printf "│ ${CYAN}%-20s${NC} %-62s │\n" "IP Address:" "$(hostname -I | awk '{print $1}')"
printf "│ ${CYAN}%-20s${NC} %-62s │\n" "Memory Usage:" "$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
printf "│ ${CYAN}%-20s${NC} %-62s │\n" "Disk Usage:" "$(df -h ~ | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')"
printf "│ ${CYAN}%-20s${NC} %-62s │\n" "Docker Containers:" "$(docker ps -q 2>/dev/null | wc -l) running, $(docker ps -aq 2>/dev/null | wc -l) total"
echo -e "└─────────────────────────────────────────────────────────────────────────────────────┘"
echo

# Footer
echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${WHITE}Docker data stored at: ${CYAN}~/docker-data${NC}"
echo -e "${BOLD}${WHITE}Windows home at: ${CYAN}~/host${NC} ${WHITE}→ ${CYAN}C:\\Users\\<username>${NC}"
echo -e "${BOLD}${YELLOW}═══════════════════════════════════════════════════════════════════════════════════════${NC}"
BANNER_SCRIPT

chmod +x ~/scripts/show-banner.sh

# Create symlink for easy access
ln -sf ~/scripts/show-banner.sh ~/scripts/banner.sh
print_success "Banner script created"

# Create database management scripts
print_step "Creating database management scripts..."

cat > ~/scripts/manage-databases.sh << 'DB_SCRIPT'
#!/bin/bash

COMPOSE_FILE="$HOME/docker-compose.yml"

case "$1" in
  start)
    echo "Starting all database services..."
    docker compose -f "$COMPOSE_FILE" up -d
    echo "Waiting for services to be healthy..."
    sleep 10
    docker compose -f "$COMPOSE_FILE" ps
    ;;
  stop)
    echo "Stopping all database services..."
    docker compose -f "$COMPOSE_FILE" down
    ;;
  restart)
    echo "Restarting all database services..."
    docker compose -f "$COMPOSE_FILE" restart
    ;;
  status)
    docker compose -f "$COMPOSE_FILE" ps
    ;;
  logs)
    service=${2:-}
    if [ -z "$service" ]; then
      docker compose -f "$COMPOSE_FILE" logs -f
    else
      docker compose -f "$COMPOSE_FILE" logs -f "$service"
    fi
    ;;
  psql)
    docker exec -it postgres-dev psql -U postgres
    ;;
  mongo)
    docker exec -it mongodb-dev mongosh -u admin -p admin --authenticationDatabase admin
    ;;
  redis-cli)
    docker exec -it redis-dev redis-cli
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs [service]|psql|mongo|redis-cli}"
    exit 1
    ;;
esac
DB_SCRIPT

chmod +x ~/scripts/manage-databases.sh
print_success "Database management scripts created"

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

# List aliases (using eza instead of exa for Ubuntu 24.04)
alias ls="eza --icons"
alias ll="eza -alh --icons"
alias la="eza -a --icons"
alias l="eza -F --icons"
alias lt="eza --tree --icons"

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

# Database management aliases
alias dbstart="~/scripts/manage-databases.sh start"
alias dbstop="~/scripts/manage-databases.sh stop"
alias dbstatus="~/scripts/manage-databases.sh status"
alias dblogs="~/scripts/manage-databases.sh logs"
alias psql="~/scripts/manage-databases.sh psql"
alias mongo="~/scripts/manage-databases.sh mongo"
alias redis-cli="~/scripts/manage-databases.sh redis-cli"

# Banner alias
alias banner="~/scripts/banner.sh"

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

# Show banner on new terminal
~/scripts/banner.sh
EOL

print_success "Shell configuration complete"

# Create Windows symlinks
print_step "Creating Windows symlinks..."
WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
ln -sf /mnt/c/Users/$WINDOWS_USER ~/host
ln -sf ~/host/Desktop ~/desktop
ln -sf ~/host/Documents ~/docs
ln -sf ~/host/Downloads ~/downloads
print_success "Windows symlinks created"

# Create sample docker-compose.yml
print_step "Creating sample docker-compose.yml..."
cat > ~/docker-compose.yml << 'DOCKER_COMPOSE'
services:
  # PostgreSQL Database
  postgres:
    image: postgres:alpine
    container_name: postgres-dev
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
      PGDATA: /var/lib/postgresql/data/pgdata
    ports:
      - "5432:5432"
    volumes:
      - ~/docker-data/postgres:/var/lib/postgresql/data
      - ~/docker-data/init/postgres:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MongoDB Database
  mongodb:
    image: mongo
    container_name: mongodb-dev
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin
    ports:
      - "27017:27017"
    volumes:
      - ~/docker-data/mongodb:/data/db
      - ~/docker-data/init/mongodb:/docker-entrypoint-initdb.d
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s

  # Redis Cache
  redis:
    image: redis:alpine
    container_name: redis-dev
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - ~/docker-data/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.15.0
    container_name: elasticsearch-dev
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
      - cluster.name=docker-cluster
      - bootstrap.memory_lock=false
    ports:
      - "9200:9200"
    volumes:
      - ~/docker-data/elasticsearch:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 90s

  # Logstash
  logstash:
    image: docker.elastic.co/logstash/logstash:8.15.0
    container_name: logstash-dev
    restart: unless-stopped
    ports:
      - "5044:5044"
      - "5514:5514/udp"
      - "5514:5514/tcp"
    volumes:
      - ~/docker-data/config/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - ~/docker-data/logs:/var/log
    environment:
      - "LS_JAVA_OPTS=-Xms256m -Xmx256m"
    depends_on:
      elasticsearch:
        condition: service_healthy

  # Kibana
  kibana:
    image: docker.elastic.co/kibana/kibana:8.15.0
    container_name: kibana-dev
    restart: unless-stopped
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  # Nexus Repository Manager
  nexus:
    image: sonatype/nexus3
    container_name: nexus-dev
    restart: unless-stopped
    ports:
      - "8091:8081"
    volumes:
      - ~/docker-data/nexus:/nexus-data
    environment:
      - NEXUS_CONTEXT=/
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8081/service/rest/v1/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 10
      start_period: 120s

networks:
  default:
    driver: bridge
DOCKER_COMPOSE

print_success "Sample docker-compose.yml created"

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
- Databases: PostgreSQL client, MySQL client, Redis tools, MongoDB client
- Utilities: git, vim, tmux, htop, tree, jq, fzf, ripgrep, bat, eza
- Shell: zsh with Oh My Zsh and Powerlevel10k theme

Directory Structure:
- ~/projects/     - Your coding projects
- ~/scripts/      - Utility scripts
- ~/tools/        - Additional tools
- ~/backups/      - Backup files
- ~/docker-data/  - Docker persistent data

Symlinks to Windows:
- ~/host          - Your Windows user directory
- ~/desktop       - Windows Desktop
- ~/docs          - Windows Documents  
- ~/downloads     - Windows Downloads

Key Commands:
- banner          - Show the service status banner
- dbstart         - Start all Docker services
- dbstop          - Stop all Docker services
- dbstatus        - Check service status
- psql            - Connect to PostgreSQL
- mongo           - Connect to MongoDB
- redis-cli       - Connect to Redis
- dblogs [name]   - View service logs

Configuration Files:
- ~/.zshrc        - Zsh configuration
- ~/.bashrc       - Bash configuration (fallback)
- ~/.gitconfig    - Git configuration
- ~/.shell_common - Common aliases and functions

Docker Compose:
- ~/docker-compose.yml - Your services configuration
- ~/docker-data/       - Persistent data directory

Next Steps:
1. Log out and back in for Docker group permissions
2. Restart your terminal or run: source ~/.zshrc
3. Configure Powerlevel10k by running: p10k configure
4. Start your services: dbstart
5. View service status: banner

Enjoy your development environment!
EOF

# Display summary
echo
cat ~/wsl-setup-summary.txt

print_success "Setup complete! 🎉"
print_info "Please log out and back in for Docker permissions, then restart your terminal"
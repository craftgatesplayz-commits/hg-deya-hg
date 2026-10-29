#!/bin/bash

# ============================================================
#                    Xeriox Installer
#          Multi-Panel Installer with Own Branding
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Branding
BRAND="Xeriox"
VERSION="1.2.0"

# Script directory (where admin-panel folder lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clear screen and show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "============================================================"
    echo "                                                            "
    echo "     ██╗  ██╗███████╗██████╗ ██╗ ██████╗ ██╗  ██╗          "
    echo "     ╚██╗██╔╝██╔════╝██╔══██╗██║██╔═══██╗╚██╗██╔╝          "
    echo "      ╚███╔╝ █████╗  ██████╔╝██║██║   ██║ ╚███╔╝           "
    echo "      ██╔██╗ ██╔══╝  ██╔══██╗██║██║   ██║ ██╔██╗           "
    echo "     ██╔╝ ██╗███████╗██║  ██║██║╚██████╔╝██╔╝ ██╗          "
    echo "     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝          "
    echo "                                                            "
    echo "              Multi-Panel Installer v${VERSION}             "
    echo "============================================================"
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}[ERROR] This script must be run as root${NC}"
       echo -e "Please run: ${YELLOW}sudo bash install.sh${NC}"
       exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        echo -e "${RED}[ERROR] Cannot detect operating system${NC}"
        exit 1
    fi
    echo -e "${GREEN}[INFO]${NC} Detected OS: ${BOLD}$OS $OS_VERSION${NC}"
    echo ""
}

ask_domain() {
    local panel_name=$1
    local default_domain=$2
    echo ""
    echo -e "${YELLOW}Domain Configuration for ${panel_name}${NC}"
    echo -e "Example: ${default_domain}"
    read -p "Enter domain (or press Enter for ${default_domain}): " domain
    if [[ -z "$domain" ]]; then
        domain=$default_domain
    fi
    echo -e "${GREEN}Using domain: ${BOLD}$domain${NC}"
    echo "$domain"
}

ask_email() {
    echo ""
    read -p "Enter email for SSL certificate (Let's Encrypt): " email
    if [[ -z "$email" ]]; then
        email="admin@localhost"
    fi
    echo -e "${GREEN}Using email: ${BOLD}$email${NC}"
    echo "$email"
}

# ==================== GAME PANEL ====================
install_game_panel() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}Installing Game Panel (Pterodactyl)${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    GAME_DOMAIN=$(ask_domain "Game Panel" "game.example.com")
    EMAIL=$(ask_email)

    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "  Panel   : Pterodactyl"
    echo -e "  Domain  : $GAME_DOMAIN"
    echo -e "  Email   : $EMAIL"
    echo ""
    read -p "Continue with installation? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    echo ""
    echo -e "${GREEN}[INFO]${NC} Starting Pterodactyl installation..."
    echo -e "${YELLOW}When asked for FQDN use: $GAME_DOMAIN${NC}"
    echo -e "${YELLOW}When asked for email use: $EMAIL${NC}"
    echo ""
    sleep 2
    bash <(curl -s https://pterodactyl-installer.se)
}

# ==================== WEB PANEL ====================
install_web_panel() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}Installing Web Panel (HestiaCP)${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    WEB_DOMAIN=$(ask_domain "Web Panel" "web.example.com")
    EMAIL=$(ask_email)

    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "  Panel   : HestiaCP"
    echo -e "  Domain  : $WEB_DOMAIN"
    echo -e "  Email   : $EMAIL"
    echo ""
    read -p "Continue with installation? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    echo ""
    echo -e "${GREEN}[INFO]${NC} Starting HestiaCP installation..."
    echo -e "${YELLOW}When asked for hostname use: $WEB_DOMAIN${NC}"
    sleep 2

    apt update
    apt install -y curl
    curl -s https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh | bash
}

# ==================== BOT PANEL ====================
install_bot_panel() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}Installing Bot Panel (Mechon)${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Mechon is a self-hosted panel for Discord bots.${NC}"
    echo ""

    BOT_DOMAIN=$(ask_domain "Bot Panel" "bot.example.com")
    EMAIL=$(ask_email)

    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "  Panel   : Mechon"
    echo -e "  Domain  : $BOT_DOMAIN"
    echo -e "  Email   : $EMAIL"
    echo ""
    read -p "Continue with installation? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    echo ""
    echo -e "${GREEN}[INFO]${NC} Installing Docker if needed..."

    if ! command -v docker &> /dev/null; then
        curl -sSL https://get.docker.com/ | CHANNEL=stable bash
        systemctl enable --now docker
    fi

    if ! docker compose version &> /dev/null; then
        apt install -y docker-compose-plugin 2>/dev/null || true
    fi

    mkdir -p /opt/mechon
    cd /opt/mechon

    if [ -d "/opt/mechon/.git" ]; then
        git pull
    else
        git clone https://github.com/jub0t/Mechon.git .
    fi

    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Mechon downloaded to /opt/mechon"
    echo -e "Configure domain ${BOLD}$BOT_DOMAIN${NC} and follow Mechon docs."
    echo -e "Repo: ${CYAN}https://github.com/jub0t/Mechon${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# ==================== XERIOX ADMIN PANEL ====================
install_admin_panel() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}Installing Xeriox Admin Panel${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "This is the central control panel."
    echo -e "You can start/stop services and customize theme from here."
    echo ""

    ADMIN_DOMAIN=$(ask_domain "Xeriox Admin Panel" "admin.example.com")
    EMAIL=$(ask_email)

    echo ""
    read -p "Set Admin Username [admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    read -p "Set Admin Password [xeriox123]: " ADMIN_PASS
    ADMIN_PASS=${ADMIN_PASS:-xeriox123}

    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "  Panel    : Xeriox Admin"
    echo -e "  Domain   : $ADMIN_DOMAIN"
    echo -e "  Username : $ADMIN_USER"
    echo -e "  Password : $ADMIN_PASS"
    echo ""
    read -p "Continue with installation? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    echo ""
    echo -e "${GREEN}[INFO]${NC} Installing Node.js if needed..."

    # Install Node.js 20 if not present
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    fi

    # Create install directory
    mkdir -p /opt/xeriox-admin
    cp -r "$SCRIPT_DIR/admin-panel/"* /opt/xeriox-admin/
    cd /opt/xeriox-admin

    # Create config with user credentials
    cat > /opt/xeriox-admin/config.json <<EOF
{
  "brandName": "Xeriox",
  "primaryColor": "#0ea5e9",
  "secondaryColor": "#1e293b",
  "accentColor": "#22c55e",
  "theme": "dark",
  "panels": {
    "game": { "name": "Game Panel", "service": "nginx", "enabled": true, "domain": "game.example.com" },
    "web": { "name": "Web Panel", "service": "hestia", "enabled": true, "domain": "web.example.com" },
    "bot": { "name": "Bot Panel", "service": "docker", "enabled": true, "domain": "bot.example.com" }
  },
  "adminUser": "$ADMIN_USER",
  "adminPass": "$ADMIN_PASS"
}
EOF

    echo -e "${GREEN}[INFO]${NC} Installing dependencies..."
    npm install --production

    # Create systemd service
    cat > /etc/systemd/system/xeriox-admin.service <<EOF
[Unit]
Description=Xeriox Admin Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/xeriox-admin
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=PORT=3080

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xeriox-admin
    systemctl restart xeriox-admin

    # Simple Nginx reverse proxy if nginx is installed
    if command -v nginx &> /dev/null; then
        cat > /etc/nginx/sites-available/xeriox-admin <<EOF
server {
    listen 80;
    server_name $ADMIN_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
        ln -sf /etc/nginx/sites-available/xeriox-admin /etc/nginx/sites-enabled/ 2>/dev/null || true
        nginx -t && systemctl reload nginx || true
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${BOLD}Xeriox Admin Panel Installed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "  URL      : ${CYAN}http://$ADMIN_DOMAIN${NC}"
    echo -e "  (or)     : ${CYAN}http://YOUR_SERVER_IP:3080${NC}"
    echo -e "  Username : ${BOLD}$ADMIN_USER${NC}"
    echo -e "  Password : ${BOLD}$ADMIN_PASS${NC}"
    echo ""
    echo -e "  Service  : systemctl status xeriox-admin"
    echo ""
    read -p "Press Enter to continue..."
}

# ==================== VPS PANEL (placeholder) ====================
install_vps_panel() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}VPS Panel${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}VPS Panel support is coming soon.${NC}"
    echo ""
    read -p "Press Enter to go back..."
}

# ==================== MULTIPLE ====================
install_multiple() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}Install Multiple Panels${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    read -p "Install Game Panel (Pterodactyl)? (y/n): " install_game
    read -p "Install Web Panel (HestiaCP)? (y/n): " install_web
    read -p "Install Bot Panel (Mechon)? (y/n): " install_bot
    read -p "Install Xeriox Admin Panel? (y/n): " install_admin

    echo ""
    if [[ $install_game == "y" || $install_game == "Y" ]]; then
        GAME_DOMAIN=$(ask_domain "Game Panel" "game.example.com")
    fi
    if [[ $install_web == "y" || $install_web == "Y" ]]; then
        WEB_DOMAIN=$(ask_domain "Web Panel" "web.example.com")
    fi
    if [[ $install_bot == "y" || $install_bot == "Y" ]]; then
        BOT_DOMAIN=$(ask_domain "Bot Panel" "bot.example.com")
    fi
    if [[ $install_admin == "y" || $install_admin == "Y" ]]; then
        ADMIN_DOMAIN=$(ask_domain "Xeriox Admin" "admin.example.com")
    fi

    EMAIL=$(ask_email)

    echo ""
    echo -e "${YELLOW}========== Installation Summary ==========${NC}"
    [[ $install_game == "y" || $install_game == "Y" ]] && echo -e "  Game Panel  : $GAME_DOMAIN"
    [[ $install_web == "y" || $install_web == "Y" ]] && echo -e "  Web Panel   : $WEB_DOMAIN"
    [[ $install_bot == "y" || $install_bot == "Y" ]] && echo -e "  Bot Panel   : $BOT_DOMAIN"
    [[ $install_admin == "y" || $install_admin == "Y" ]] && echo -e "  Admin Panel : $ADMIN_DOMAIN"
    echo -e "  Email       : $EMAIL"
    echo -e "${YELLOW}==========================================${NC}"
    echo ""

    read -p "Start installation? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    if [[ $install_game == "y" || $install_game == "Y" ]]; then
        echo -e "${GREEN}>>> Installing Game Panel...${NC}"
        bash <(curl -s https://pterodactyl-installer.se)
    fi

    if [[ $install_web == "y" || $install_web == "Y" ]]; then
        echo -e "${GREEN}>>> Installing Web Panel...${NC}"
        apt update && apt install -y curl
        curl -s https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh | bash
    fi

    if [[ $install_bot == "y" || $install_bot == "Y" ]]; then
        echo -e "${GREEN}>>> Installing Bot Panel...${NC}"
        install_bot_panel
    fi

    if [[ $install_admin == "y" || $install_admin == "Y" ]]; then
        echo -e "${GREEN}>>> Installing Xeriox Admin Panel...${NC}"
        install_admin_panel
    fi

    echo ""
    echo -e "${GREEN}All selected panels finished!${NC}"
    read -p "Press Enter to return to menu..."
}

# ==================== MAIN MENU ====================
main_menu() {
    while true; do
        show_banner
        detect_os

        echo -e "${BOLD}What would you like to install?${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} Game Panel          (Pterodactyl)"
        echo -e "  ${GREEN}[2]${NC} Web Panel           (HestiaCP)"
        echo -e "  ${GREEN}[3]${NC} Bot Panel           (Mechon)"
        echo -e "  ${GREEN}[4]${NC} VPS Panel           (Coming Soon)"
        echo -e "  ${GREEN}[5]${NC} ${BOLD}Xeriox Admin Panel${NC}  (Control Center)"
        echo -e "  ${GREEN}[6]${NC} Install Multiple Panels"
        echo -e "  ${RED}[0]${NC} Exit"
        echo ""
        read -p "Enter your choice [0-6]: " choice

        case $choice in
            1) install_game_panel ;;
            2) install_web_panel ;;
            3) install_bot_panel ;;
            4) install_vps_panel ;;
            5) install_admin_panel ;;
            6) install_multiple ;;
            0)
                echo ""
                echo -e "${GREEN}Thank you for using ${BRAND} Installer!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start
check_root
main_menu

#!/data/data/com.termux/files/usr/bin/bash
#########################################################
# LINUX ON TERMUX — Uninstaller v3.0
# Removes all components installed by the installer
#########################################################

set -euo pipefail

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${RED}"
    cat << 'BANNER'
  ┌──────────────────────────────────────────────────┐
  │                                                  │
  │    LINUX ON TERMUX — UNINSTALLER                 │
  │                                                  │
  │    Remove all installed components               │
  │                                                  │
  └──────────────────────────────────────────────────┘
BANNER
    echo -e "${NC}"
    echo -e "${WHITE}  This will remove all installed components.${NC}"
    echo ""
}

# ============== CONFIRMATION ==============
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will remove:${NC}"
    echo -e "  - Linux distribution and desktop environment"
    echo -e "  - Custom scripts and configurations"
    echo -e "  - GPU acceleration configs"
    echo -e "  - Audio configuration"
    echo ""
    echo -e "${RED}This action cannot be undone.${NC}"
    echo ""
    read -p "$(echo -e "${WHITE}Type 'UNINSTALL' to confirm: ${NC}")" confirm

    if [ "$confirm" != "UNINSTALL" ]; then
        echo -e "${YELLOW}Uninstall cancelled.${NC}"
        exit 0
    fi
}

# ============== LOAD INSTALL INFO ==============
load_install_info() {
    if [ -f ~/.termux-linuxlab/install-info.conf ]; then
        source ~/.termux-linuxlab/install-info.conf
        echo -e "${GREEN}✓${NC} Found installation: ${WHITE}${DISTRO_NAME} + ${DE_NAME}${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠${NC} No installation info found. Will attempt generic removal."
        echo ""
        PROOT_DISTRO=""
    fi
}

# ============== STOP RUNNING PROCESSES ==============
stop_processes() {
    echo ""
    echo -e "${PURPLE}[*] Stopping running processes...${NC}"

    pkill -9 -f "termux.x11" 2>/dev/null
    pkill -9 -f "pulseaudio" 2>/dev/null
    pkill -9 -f "proot"       2>/dev/null
    pkill -9 -f "gnome"       2>/dev/null
    pkill -9 -f "plasma"      2>/dev/null
    pkill -9 -f "Hyprland"    2>/dev/null
    pkill -9 -f "xfce"        2>/dev/null
    pkill -9 -f "openbox"     2>/dev/null
    pkill -9 -f "wine"        2>/dev/null
    pkill -9 -f "dbus"        2>/dev/null

    echo -e " ${GREEN}✓${NC} Processes stopped"
}

# ============== REMOVE PROOT DISTRO ==============
remove_distro() {
    echo ""
    echo -e "${PURPLE}[*] Removing Linux distribution...${NC}"

    if [ -n "${PROOT_DISTRO:-}" ]; then
        proot-distro remove "$PROOT_DISTRO" 2>/dev/null && \
            echo -e " ${GREEN}✓${NC} ${PROOT_DISTRO} removed" || \
            echo -e " ${YELLOW}⚠${NC} Could not remove ${PROOT_DISTRO} (may not exist)"
    else
        echo -e " ${YELLOW}⚠${NC} No distro info available. Manual removal:"
        echo -e "   proot-distro list"
        echo -e "   proot-distro remove <id>"
    fi
}

# ============== REMOVE SCRIPTS ==============
remove_scripts() {
    echo ""
    echo -e "${PURPLE}[*] Removing custom scripts...${NC}"

    rm -f ~/start-linux.sh
    rm -f ~/stop-linux.sh
    rm -f ~/shell-linux.sh
    rm -f ~/README-linuxlab.md

    echo -e " ${GREEN}✓${NC} Scripts removed"
}

# ============== REMOVE CONFIG ==============
remove_config() {
    echo ""
    echo -e "${PURPLE}[*] Removing configuration files...${NC}"

    rm -rf ~/.termux-linuxlab 2>/dev/null

    # Remove bashrc entries
    if [ -f ~/.bashrc ]; then
        sed -i '/termux-linuxlab/d' ~/.bashrc
        sed -i '/Linux on Termux/d' ~/.bashrc
    fi

    echo -e " ${GREEN}✓${NC} Configuration removed"
}

# ============== REMOVE TERMUX PACKAGES ==============
remove_termux_packages() {
    echo ""
    echo -e "${PURPLE}[*] Removing Termux packages (GPU/X11/Audio)...${NC}"

    pkg uninstall mesa-zink -y 2>/dev/null
    pkg uninstall mesa-vulkan-icd-freedreno -y 2>/dev/null
    pkg uninstall mesa-vulkan-icd-swrast -y 2>/dev/null
    pkg uninstall vulkan-loader-android -y 2>/dev/null
    pkg uninstall pulseaudio -y 2>/dev/null
    pkg uninstall termux-x11-nightly -y 2>/dev/null
    pkg uninstall xorg-xrandr -y 2>/dev/null
    pkg uninstall proot-distro -y 2>/dev/null
    pkg uninstall proot -y 2>/dev/null
    pkg uninstall tur-repo -y 2>/dev/null
    pkg uninstall x11-repo -y 2>/dev/null

    echo -e " ${GREEN}✓${NC} Termux packages removed"
}

# ============== CLEANUP ==============
cleanup() {
    echo ""
    echo -e "${PURPLE}[*] Cleaning up...${NC}"

    # Remove config directories
    rm -rf ~/.config/hacklab* 2>/dev/null

    # Clean package cache
    pkg clean 2>/dev/null

    echo -e " ${GREEN}✓${NC} Cleanup complete"
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
  ┌──────────────────────────────────────────────────┐
  │                                                  │
  │        UNINSTALLATION COMPLETE                   │
  │                                                  │
  └──────────────────────────────────────────────────┘
COMPLETE
    echo -e "${NC}"
    echo -e "${WHITE}  Linux on Termux has been completely removed.${NC}"
    echo ""
    echo -e "${YELLOW}  Note: Termux itself is still installed.${NC}"
    echo -e "${YELLOW}  To reset Termux completely:${NC}"
    echo -e "    ${GREEN}pkg install termux-tools && termux-reset${NC}"
    echo ""
}

# ============== MAIN ==============
main() {
    show_banner
    confirm_uninstall
    load_install_info

    stop_processes
    remove_distro
    remove_scripts
    remove_config
    remove_termux_packages
    cleanup

    show_completion
}

# ============== RUN ==============
main

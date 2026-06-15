#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  LINUX ON TERMUX - Multi-Distro Installer v3.1
#
#  Distributions:
#    1) Ubuntu 24.04 LTS  + GNOME 46
#    2) Arch Linux        + Hyprland
#    3) Debian 12         + KDE Plasma 6
#    4) Fedora 40         + GNOME 46
#    5) Kali Linux        + XFCE4
#    6) Alpine Linux      + Openbox
#
#  Features:
#    - GPU acceleration (Turnip/Zink/Freedreno)
#    - Termux-X11 display server
#    - PulseAudio / PipeWire sound
#    - One-click launcher scripts
#    - No root required
#
#  Based on: termux-hacklab by Tech Jarves
#  Repository: https://github.com/cameleonnbss/linux-on-termux
#######################################################

# NO set -e — an installer must survive individual package failures

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# ============== GLOBALS ==============
TOTAL_STEPS=0
CURRENT_STEP=0
DISTRO_NAME=""
DISTRO_ID=""
DE_NAME=""
PROOT_DISTRO=""
GPU_DRIVER="swrast"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED_PKGS=""

# ============== LOGGING ==============
LOG_FILE="$HOME/linux-on-termux-install.log"

log()  { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "[WARN] $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; log "[ERROR] $*"; }

# ============== PROGRESS ==============
update_progress() {
    local label="$1"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((pct / 5))
    local empty=$((20 - filled))
    local bar="${GREEN}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${GRAY}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${NC}"
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${bar} ${WHITE}${pct}%${NC}"
    echo -e "${CYAN}  ▶ ${label}${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log "STEP ${CURRENT_STEP}/${TOTAL_STEPS}: ${label}"
}

spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${YELLOW}⏳${NC} ${msg} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    wait "$pid" 2>/dev/null
    local code=$?
    if [ $code -eq 0 ]; then
        printf "\r  ${GREEN}✓${NC} %-55s\n" "${msg}"
    else
        printf "\r  ${RED}✗${NC} %-55s ${RED}(failed — continuing)${NC}\n" "${msg}"
        log "FAILED: ${msg} (exit code ${code})"
    fi
    # IMPORTANT: do NOT return non-zero — that would kill the script
    return 0
}

pkg_install() {
    local pkg_name="$1"
    local label="${2:-$pkg_name}"
    (yes | pkg install "$pkg_name" -y > /dev/null 2>&1) &
    spinner $! "Installing ${label}..."
}

proot_run() {
    proot-distro login "$PROOT_DISTRO" -- bash -c "$1" > /dev/null 2>&1 || true
}

proot_run_verbose() {
    proot-distro login "$PROOT_DISTRO" -- bash -c "$1" 2>&1 | tail -5 || true
}

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
  ┌──────────────────────────────────────────────────┐
  │                                                  │
  │    LINUX ON TERMUX  v3.1                         │
  │                                                  │
  │    Run a real Linux desktop on Android           │
  │    No root  |  GPU accelerated  |  Your choice   │
  │                                                  │
  └──────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

# ============== DISTRO SELECTION ==============
select_distro() {
    echo -e "${WHITE}  Choose your Linux distribution:${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Ubuntu 24.04 LTS  + ${PURPLE}GNOME 46${NC}       (beginner friendly)"
    echo -e "  ${CYAN}[2]${NC} Arch Linux        + ${PURPLE}Hyprland${NC}        (tiling WM, rice ready)"
    echo -e "  ${CYAN}[3]${NC} Debian 12          + ${PURPLE}KDE Plasma 6${NC}    (stable & polished)"
    echo -e "  ${CYAN}[4]${NC} Fedora 40          + ${PURPLE}GNOME 46${NC}        (bleeding edge)"
    echo -e "  ${CYAN}[5]${NC} Kali Linux         + ${PURPLE}XFCE4${NC}           (pentesting tools)"
    echo -e "  ${CYAN}[6]${NC} Alpine Linux       + ${PURPLE}Openbox${NC}         (ultra lightweight)"
    echo ""
    echo -ne "  ${YELLOW}Select [1-6]:${NC} "
    read -r choice

    case "$choice" in
        1)
            DISTRO_NAME="Ubuntu 24.04 LTS"
            DISTRO_ID="ubuntu"
            DE_NAME="GNOME"
            PROOT_DISTRO="ubuntu"
            TOTAL_STEPS=12
            ;;
        2)
            DISTRO_NAME="Arch Linux"
            DISTRO_ID="arch"
            DE_NAME="Hyprland"
            PROOT_DISTRO="archlinux"
            TOTAL_STEPS=14
            ;;
        3)
            DISTRO_NAME="Debian 12 (Bookworm)"
            DISTRO_ID="debian"
            DE_NAME="KDE Plasma 6"
            PROOT_DISTRO="debian"
            TOTAL_STEPS=12
            ;;
        4)
            DISTRO_NAME="Fedora 40"
            DISTRO_ID="fedora"
            DE_NAME="GNOME 46"
            PROOT_DISTRO="fedora"
            TOTAL_STEPS=12
            ;;
        5)
            DISTRO_NAME="Kali Linux"
            DISTRO_ID="kali"
            DE_NAME="XFCE4"
            PROOT_DISTRO="kali"
            TOTAL_STEPS=13
            ;;
        6)
            DISTRO_NAME="Alpine Linux"
            DISTRO_ID="alpine"
            DE_NAME="Openbox"
            PROOT_DISTRO="alpine"
            TOTAL_STEPS=11
            ;;
        *)
            echo -e "${RED}  Invalid choice. Defaulting to Ubuntu + GNOME.${NC}"
            DISTRO_NAME="Ubuntu 24.04 LTS"
            DISTRO_ID="ubuntu"
            DE_NAME="GNOME"
            PROOT_DISTRO="ubuntu"
            TOTAL_STEPS=12
            ;;
    esac

    echo ""
    echo -e "  ${GREEN}✓${NC} Selected: ${WHITE}${DISTRO_NAME}${NC} with ${PURPLE}${DE_NAME}${NC}"
    echo ""
    echo -e "  ${YELLOW}Estimated time: 20-40 min (depends on connection)${NC}"
    echo -e "  ${YELLOW}Storage needed: ~3-6 GB${NC}"
    echo -e "  ${GRAY}Log file: ${LOG_FILE}${NC}"
    echo ""
    echo -ne "  ${WHITE}Press Enter to start, Ctrl+C to cancel...${NC} "
    read -r
}

# ============== DEVICE DETECTION ==============
detect_device() {
    echo -e "${PURPLE}[*] Detecting device & GPU...${NC}"
    echo ""

    local model brand android abi gpu_vendor
    model=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    brand=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    android=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    abi=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    gpu_vendor=$(getprop ro.hardware.egl 2>/dev/null || echo "")

    echo -e "  ${GREEN}▸${NC} Device  : ${WHITE}${brand} ${model}${NC}"
    echo -e "  ${GREEN}▸${NC} Android : ${WHITE}${android}${NC}"
    echo -e "  ${GREEN}▸${NC} CPU     : ${WHITE}${abi}${NC}"

    if echo "$gpu_vendor" | grep -qi "adreno"; then
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}▸${NC} GPU     : ${WHITE}Adreno (Qualcomm) → Turnip driver${NC}"
    elif echo "$gpu_vendor" | grep -qi "mali"; then
        GPU_DRIVER="swrast"
        echo -e "  ${GREEN}▸${NC} GPU     : ${WHITE}Mali → Software fallback${NC}"
    else
        GPU_DRIVER="swrast"
        echo -e "  ${GREEN}▸${NC} GPU     : ${WHITE}Unknown → Software rendering${NC}"
    fi

    echo ""
    sleep 1
}

# ============== STEP: TERMUX BASE SETUP ==============
step_termux_base() {
    update_progress "Updating Termux packages"

    (yes | pkg update -y 2>&1 | tail -3) &
    spinner $! "Updating package lists..."

    (yes | pkg upgrade -y 2>&1 | tail -3) &
    spinner $! "Upgrading installed packages..."

    pkg_install "x11-repo" "X11 Repository"
    pkg_install "tur-repo" "TUR Repository"
}

# ============== STEP: TERMUX-X11 ==============
step_x11() {
    update_progress "Installing Termux-X11 display server"

    pkg_install "termux-x11-nightly" "Termux-X11"
    pkg_install "xorg-xrandr" "XRandR"
}

# ============== STEP: GPU DRIVERS ==============
step_gpu() {
    update_progress "Installing GPU drivers (Turnip/Zink)"

    pkg_install "mesa-zink" "Mesa Zink (OpenGL over Vulkan)"

    if [ "$GPU_DRIVER" == "freedreno" ]; then
        pkg_install "mesa-vulkan-icd-freedreno" "Turnip Adreno GPU driver"
    else
        pkg_install "mesa-vulkan-icd-swrast" "Software Vulkan renderer"
    fi

    pkg_install "vulkan-loader-android" "Vulkan Loader"
}

# ============== STEP: PROOT-DISTRO ==============
step_proot() {
    update_progress "Installing proot-distro engine"

    pkg_install "proot-distro" "proot-distro"
    pkg_install "proot" "proot"
    pkg_install "tar" "tar"
}

# ============== STEP: INSTALL DISTRO ==============
step_install_distro() {
    update_progress "Downloading & installing ${DISTRO_NAME}"

    echo -e "  ${YELLOW}⏳${NC} Downloading ${DISTRO_NAME} rootfs — this may take a while..."
    echo -e "  ${GRAY}(This is the longest step — don't close Termux)${NC}"
    proot-distro install "$PROOT_DISTRO" 2>&1 | tail -5
    echo -e "  ${GREEN}✓${NC} ${DISTRO_NAME} rootfs installed"
}

# ============== STEP: INSTALL DESKTOP ENVIRONMENT ==============
step_install_de() {
    update_progress "Installing ${DE_NAME} desktop environment"

    case "$DISTRO_ID" in
        ubuntu)   _install_de_ubuntu  ;;
        arch)     _install_de_arch    ;;
        debian)   _install_de_debian  ;;
        fedora)   _install_de_fedora  ;;
        kali)     _install_de_kali    ;;
        alpine)   _install_de_alpine  ;;
    esac
}

_install_de_ubuntu() {
    echo -e "  ${YELLOW}⏳${NC} Installing GNOME on Ubuntu (long step — 5-15 min)..."
    echo -e "  ${GRAY}(Don't close Termux — the desktop is being installed)${NC}"
    proot_run_verbose "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y --no-install-recommends \
            ubuntu-desktop-minimal \
            gnome-terminal \
            nautilus \
            gedit \
            eog \
            evince \
            gnome-tweaks \
            gnome-shell-extensions \
            dbus-x11 \
            at-spi2-core \
            xdg-utils \
            fonts-noto
    "
    echo -e "  ${GREEN}✓${NC} GNOME installed on Ubuntu"
}

_install_de_arch() {
    echo -e "  ${YELLOW}⏳${NC} Installing Hyprland on Arch (long step — 5-15 min)..."
    echo -e "  ${GRAY}(Don't close Termux — the desktop is being installed)${NC}"
    proot_run_verbose "
        pacman -Syu --noconfirm 2>/dev/null
        pacman -S --noconfirm \
            hyprland \
            waybar \
            wofi \
            alacritty \
            thunar \
            grim slurp \
            swww \
            dunst \
            pipewire pipewire-pulse wireplumber \
            noto-fonts \
            ttf-jetbrains-mono-nerd \
            xdg-utils xdg-desktop-portal-hyprland \
            polkit-gnome \
            qt5-wayland qt6-wayland
    "
    echo -e "  ${GREEN}✓${NC} Hyprland installed on Arch"
}

_install_de_debian() {
    echo -e "  ${YELLOW}⏳${NC} Installing KDE Plasma on Debian (long step — 5-15 min)..."
    echo -e "  ${GRAY}(Don't close Termux — the desktop is being installed)${NC}"
    proot_run_verbose "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y --no-install-recommends \
            kde-plasma-desktop \
            plasma-nm \
            plasma-pa \
            dolphin \
            konsole \
            kate \
            ark \
            spectacle \
            okular \
            dbus-x11 \
            fonts-noto
    "
    echo -e "  ${GREEN}✓${NC} KDE Plasma installed on Debian"
}

_install_de_fedora() {
    echo -e "  ${YELLOW}⏳${NC} Installing GNOME on Fedora (long step — 5-15 min)..."
    echo -e "  ${GRAY}(Don't close Termux — the desktop is being installed)${NC}"
    proot_run_verbose "
        dnf install -y @gnome-desktop \
            gnome-terminal \
            nautilus \
            gedit \
            dbus-x11 \
            xdg-utils \
            google-noto-fonts-common
    "
    echo -e "  ${GREEN}✓${NC} GNOME installed on Fedora"
}

_install_de_kali() {
    echo -e "  ${YELLOW}⏳${NC} Installing XFCE4 + Kali tools (long step — 5-20 min)..."
    echo -e "  ${GRAY}(Don't close Termux — the desktop + tools are being installed)${NC}"
    proot_run_verbose "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y --no-install-recommends \
            kali-desktop-xfce \
            kali-tools-top10 \
            dbus-x11 \
            fonts-noto
    "
    echo -e "  ${GREEN}✓${NC} Kali XFCE4 + tools installed"
}

_install_de_alpine() {
    echo -e "  ${YELLOW}⏳${NC} Installing Openbox on Alpine..."
    proot_run_verbose "
        apk update
        apk add \
            openbox \
            xterm \
            tint2 \
            pcmanfm \
            mousepad \
            dbus \
            dbus-x11 \
            font-noto
    "
    echo -e "  ${GREEN}✓${NC} Openbox installed on Alpine"
}

# ============== STEP: COMMON APPS ==============
step_common_apps() {
    update_progress "Installing common applications"

    case "$DISTRO_ID" in
        ubuntu|debian|kali)
            proot_run "
                export DEBIAN_FRONTEND=noninteractive
                apt-get install -y --no-install-recommends \
                    firefox-esr \
                    git curl wget \
                    neofetch htop
            "
            # Try code, don't fail if unavailable
            proot_run "
                export DEBIAN_FRONTEND=noninteractive
                apt-get install -y --no-install-recommends code 2>/dev/null || true
            "
            ;;
        arch)
            proot_run "
                pacman -S --noconfirm \
                    firefox git curl wget neofetch htop
            "
            ;;
        fedora)
            proot_run "
                dnf install -y \
                    firefox git curl wget neofetch htop
            "
            ;;
        alpine)
            proot_run "
                apk add firefox git curl wget neofetch htop
            "
            ;;
    esac

    echo -e "  ${GREEN}✓${NC} Common apps installed"
}

# ============== STEP: AUDIO ==============
step_audio() {
    update_progress "Configuring audio (PulseAudio)"

    pkg_install "pulseaudio" "PulseAudio"

    case "$DISTRO_ID" in
        ubuntu|debian|kali)
            proot_run "apt-get install -y --no-install-recommends pulseaudio pulseaudio-utils"
            ;;
        arch)
            proot_run "pacman -S --noconfirm pulseaudio pulseaudio-alsa"
            ;;
        fedora)
            proot_run "dnf install -y pulseaudio pulseaudio-utils"
            ;;
        alpine)
            proot_run "apk add pulseaudio"
            ;;
    esac

    echo -e "  ${GREEN}✓${NC} Audio configured"
}

# ============== STEP: EXTRA TOOLS ==============
step_extra_tools() {
    case "$DISTRO_ID" in
        kali)
            update_progress "Installing additional pentesting tools"
            proot_run_verbose "
                export DEBIAN_FRONTEND=noninteractive
                apt-get install -y --no-install-recommends \
                    nmap hydra sqlmap nikto \
                    john hashcat \
                    aircrack-ng
            "
            # Metasploit separately — it's huge and sometimes fails
            echo -e "  ${YELLOW}⏳${NC} Installing Metasploit (this is a large package)..."
            proot_run "
                export DEBIAN_FRONTEND=noninteractive
                apt-get install -y --no-install-recommends metasploit-framework 2>/dev/null || \
                echo 'Metasploit install skipped — install manually with: apt install metasploit-framework'
            "
            echo -e "  ${GREEN}✓${NC} Pentesting tools installed"
            ;;
        arch)
            update_progress "Installing AUR helper (yay)"
            proot_run_verbose "
                pacman -S --noconfirm base-devel git 2>/dev/null
                useradd -m builder 2>/dev/null || true
                echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
                su - builder -c '
                    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
                    cd /tmp/yay && makepkg -si --noconfirm
                ' 2>/dev/null || echo 'yay install skipped'
            "
            echo -e "  ${GREEN}✓${NC} AUR helper step done"
            ;;
    esac
}

# ============== STEP: GPU CONFIG ==============
step_gpu_config() {
    update_progress "Configuring GPU acceleration inside ${DISTRO_NAME}"

    mkdir -p ~/.termux-linuxlab

    cat > ~/.termux-linuxlab/gpu.env << 'GPUEOF'
# Linux on Termux — GPU Acceleration
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
export LIBGL_ALWAYS_SOFTWARE=0
GPUEOF

    # Source GPU env from bashrc
    if ! grep -q "termux-linuxlab/gpu.env" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# Linux on Termux - GPU acceleration' >> ~/.bashrc
        echo 'source ~/.termux-linuxlab/gpu.env 2>/dev/null' >> ~/.bashrc
    fi

    echo -e "  ${GREEN}✓${NC} GPU environment configured"
}

# ============== STEP: HYPRLAND CONFIG ==============
step_hyprland_config() {
    if [ "$DISTRO_ID" != "arch" ]; then return; fi
    update_progress "Setting up Hyprland configuration files"

    proot_run "mkdir -p /root/.config/hypr /root/.config/waybar /root/.config/wofi /root/.config/alacritty"

    # Deploy hyprland.conf from bundled config
    if [ -f "${SCRIPT_DIR}/configs/hyprland/hyprland.conf" ]; then
        cat "${SCRIPT_DIR}/configs/hyprland/hyprland.conf" | proot-distro login "$PROOT_DISTRO" -- bash -c "cat > /root/.config/hypr/hyprland.conf" 2>/dev/null
    else
        # Inline fallback
        proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/.config/hypr/hyprland.conf << '\''HYPREOF'\''
monitor=,preferred,auto,1

exec-once = waybar
exec-once = swww init
exec-once = dunst

$terminal   = alacritty
$fileManager = thunar
$menu       = wofi --show drun

env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct

input {
    kb_layout = us
    follow_mouse = 1
    touchpad { natural_scroll = yes }
    sensitivity = 0
}

general {
    gaps_in  = 5
    gaps_out = 10
    border_size = 2
    col.active_border   = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur { enabled = true; size = 8; passes = 1 }
    drop_shadow = yes
    shadow_range        = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows,    1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border,     1, 10, default
    animation = fade,       1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile     = yes
    preserve_split = yes
}

gestures { workspace_swipe = on }

$mainMod = SUPER

bind = $mainMod,       Return, exec,          $terminal
bind = $mainMod,       Q,      killactive
bind = $mainMod,       M,      exit
bind = $mainMod,       E,      exec,          $fileManager
bind = $mainMod,       V,      togglefloating
bind = $mainMod,       R,      exec,          $menu
bind = $mainMod,       P,      pseudo
bind = $mainMod,       J,      togglesplit
bind = $mainMod,       F,      fullscreen

bind = $mainMod,       left,   movefocus,     l
bind = $mainMod,       right,  movefocus,     r
bind = $mainMod,       up,     movefocus,     u
bind = $mainMod,       down,   movefocus,     d

bind = $mainMod SHIFT, left,   movewindow,    l
bind = $mainMod SHIFT, right,  movewindow,    r
bind = $mainMod SHIFT, up,     movewindow,    u
bind = $mainMod SHIFT, down,   movewindow,    d

bind = $mainMod,       1,      workspace,     1
bind = $mainMod,       2,      workspace,     2
bind = $mainMod,       3,      workspace,     3
bind = $mainMod,       4,      workspace,     4
bind = $mainMod,       5,      workspace,     5

bind = $mainMod SHIFT, 1,      movetoworkspace, 1
bind = $mainMod SHIFT, 2,      movetoworkspace, 2
bind = $mainMod SHIFT, 3,      movetoworkspace, 3
bind = $mainMod SHIFT, 4,      movetoworkspace, 4
bind = $mainMod SHIFT, 5,      movetoworkspace, 5

bind = ,       Print,  exec, grim ~/screenshot-$(date +%F_%T).png
bind = $mainMod, Print, exec, grim -g "$(slurp)" ~/screenshot-$(date +%F_%T).png

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
HYPREOF' 2>/dev/null
    fi

    # Deploy waybar config
    if [ -f "${SCRIPT_DIR}/configs/waybar/config" ]; then
        cat "${SCRIPT_DIR}/configs/waybar/config" | proot-distro login "$PROOT_DISTRO" -- bash -c "cat > /root/.config/waybar/config" 2>/dev/null
    fi
    if [ -f "${SCRIPT_DIR}/configs/waybar/style.css" ]; then
        cat "${SCRIPT_DIR}/configs/waybar/style.css" | proot-distro login "$PROOT_DISTRO" -- bash -c "cat > /root/.config/waybar/style.css" 2>/dev/null
    fi

    # Deploy alacritty config
    if [ -f "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" ]; then
        cat "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" | proot-distro login "$PROOT_DISTRO" -- bash -c "cat > /root/.config/alacritty/alacritty.toml" 2>/dev/null
    fi

    echo -e "  ${GREEN}✓${NC} Hyprland, Waybar, Alacritty configured"
}

# ============== STEP: CREATE LAUNCHERS ==============
step_launchers() {
    update_progress "Creating launcher scripts"

    local start_cmd
    case "$DISTRO_ID" in
        ubuntu|fedora)   start_cmd="gnome-session" ;;
        arch)            start_cmd="Hyprland" ;;
        debian)          start_cmd="startplasma-x11" ;;
        kali)            start_cmd="startxfce4" ;;
        alpine)          start_cmd="openbox-session" ;;
    esac

    # -- start script --
    cat > ~/start-linux.sh << STARTEOF
#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# Linux on Termux — Start ${DISTRO_NAME} / ${DE_NAME}
# ============================================
echo ""
echo "  Starting ${DISTRO_NAME} / ${DE_NAME}..."
echo ""

# Load GPU config
source ~/.termux-linuxlab/gpu.env 2>/dev/null

# Kill old sessions
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio"  2>/dev/null
sleep 1

# Audio
unset PULSE_SERVER
pulseaudio --start --exit-idle-time=-1
sleep 1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# X11 server
echo "  Starting X11 display server..."
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Open the Termux-X11 app on your phone"
echo "  ${DISTRO_NAME} — ${DE_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start desktop via proot
proot-distro login ${PROOT_DISTRO} --shared-tmp -- bash -c "
  export DISPLAY=:0
  export PULSE_SERVER=127.0.0.1
  source /etc/profile 2>/dev/null
  dbus-launch --exit-with-session ${start_cmd}
"
STARTEOF
    chmod +x ~/start-linux.sh

    # -- stop script --
    cat > ~/stop-linux.sh << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Linux on Termux — Stop desktop
echo "  Stopping Linux desktop..."
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio"  2>/dev/null
pkill -9 -f "proot"       2>/dev/null
pkill -9 -f "gnome"       2>/dev/null
pkill -9 -f "plasma"      2>/dev/null
pkill -9 -f "Hyprland"    2>/dev/null
pkill -9 -f "xfce"        2>/dev/null
pkill -9 -f "openbox"     2>/dev/null
echo "  Done."
STOPEOF
    chmod +x ~/stop-linux.sh

    # -- shell shortcut --
    cat > ~/shell-linux.sh << SHELLEOF
#!/data/data/com.termux/files/usr/bin/bash
# Linux on Termux — Drop into ${DISTRO_NAME} shell
proot-distro login ${PROOT_DISTRO} -- bash
SHELLEOF
    chmod +x ~/shell-linux.sh

    echo -e "  ${GREEN}✓${NC} Created ~/start-linux.sh"
    echo -e "  ${GREEN}✓${NC} Created ~/stop-linux.sh"
    echo -e "  ${GREEN}✓${NC} Created ~/shell-linux.sh"
}

# ============== STEP: DESKTOP SHORTCUTS ==============
step_shortcuts() {
    update_progress "Creating desktop shortcuts"

    proot_run "mkdir -p /root/Desktop"

    case "$DISTRO_ID" in
        ubuntu|fedora)
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Firefox.desktop << '\''EOF'\''
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Terminal.desktop << '\''EOF'\''
[Desktop Entry]
Name=Terminal
Comment=GNOME Terminal
Exec=gnome-terminal
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Files.desktop << '\''EOF'\''
[Desktop Entry]
Name=Files
Comment=File Manager
Exec=nautilus
Icon=folder
Type=Application
Categories=System;FileManager;
EOF' 2>/dev/null
            ;;
        arch)
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Firefox.desktop << '\''EOF'\''
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Alacritty.desktop << '\''EOF'\''
[Desktop Entry]
Name=Alacritty
Comment=Terminal
Exec=alacritty
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF' 2>/dev/null
            ;;
        debian)
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Firefox.desktop << '\''EOF'\''
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox-esr
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Konsole.desktop << '\''EOF'\''
[Desktop Entry]
Name=Konsole
Comment=Terminal
Exec=konsole
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Dolphin.desktop << '\''EOF'\''
[Desktop Entry]
Name=Dolphin
Comment=File Manager
Exec=dolphin
Icon=folder
Type=Application
Categories=System;FileManager;
EOF' 2>/dev/null
            ;;
        kali)
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Firefox.desktop << '\''EOF'\''
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox-esr
Icon=firefox
Type=Application
Categories=Network;WebBrowser;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Terminal.desktop << '\''EOF'\''
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Nmap.desktop << '\''EOF'\''
[Desktop Entry]
Name=Nmap
Comment=Network Scanner
Exec=xfce4-terminal -e "nmap"
Icon=network-wireless
Type=Application
Categories=Security;
EOF' 2>/dev/null
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Metasploit.desktop << '\''EOF'\''
[Desktop Entry]
Name=Metasploit
Comment=Exploitation Framework
Exec=xfce4-terminal -e "msfconsole"
Icon=utilities-terminal
Type=Application
Categories=Security;
EOF' 2>/dev/null
            ;;
        alpine)
            proot-distro login "$PROOT_DISTRO" -- bash -c 'cat > /root/Desktop/Terminal.desktop << '\''EOF'\''
[Desktop Entry]
Name=xterm
Comment=Terminal
Exec=xterm
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
EOF' 2>/dev/null
            ;;
    esac

    echo -e "  ${GREEN}✓${NC} Desktop shortcuts created"
}

# ============== STEP: SAVE INSTALL INFO ==============
step_save_info() {
    update_progress "Saving installation metadata"

    cat > ~/.termux-linuxlab/install-info.conf << INFOEOF
# Linux on Termux — Installation Info
# Generated: $(date)
DISTRO_NAME="${DISTRO_NAME}"
DISTRO_ID="${DISTRO_ID}"
DE_NAME="${DE_NAME}"
PROOT_DISTRO="${PROOT_DISTRO}"
GPU_DRIVER="${GPU_DRIVER}"
INFOEOF

    echo -e "  ${GREEN}✓${NC} Installation info saved"
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'EOF'
  ┌──────────────────────────────────────────────────┐
  │                                                  │
  │        INSTALLATION COMPLETE                     │
  │                                                  │
  └──────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"

    echo -e "  ${WHITE}${DISTRO_NAME} + ${DE_NAME} is ready${NC}"
    echo ""
    echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${WHITE}Start desktop :${NC}  ${GREEN}bash ~/start-linux.sh${NC}"
    echo -e "  ${WHITE}Stop desktop  :${NC}  ${GREEN}bash ~/stop-linux.sh${NC}"
    echo -e "  ${WHITE}Open a shell  :${NC}  ${GREEN}bash ~/shell-linux.sh${NC}"
    echo ""
    echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}TIP: Open Termux-X11 BEFORE running start-linux.sh${NC}"
    echo ""

    if [ "$DISTRO_ID" == "arch" ]; then
        echo -e "  ${CYAN}Hyprland keybinds:${NC}"
        echo -e "    Super+Enter = Terminal  |  Super+R = App Launcher"
        echo -e "    Super+Q = Close window  |  Super+1-5 = Workspaces"
        echo ""
    fi

    echo -e "  ${GRAY}Install log saved to: ${LOG_FILE}${NC}"
    echo ""
}

# ============== MAIN ==============
main() {
    show_banner
    select_distro
    detect_device

    step_termux_base
    step_x11
    step_gpu
    step_proot
    step_install_distro
    step_install_de
    step_common_apps
    step_audio
    step_gpu_config

    # Distro-specific extras
    case "$DISTRO_ID" in
        kali|arch) step_extra_tools ;;
    esac

    step_hyprland_config   # no-op unless arch
    step_launchers
    step_shortcuts
    step_save_info

    show_completion
}

# ============== RUN ==============
main

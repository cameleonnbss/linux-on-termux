# Linux on Termux

Run a **real Linux desktop** on Android — no root required, GPU accelerated, with your choice of distribution.

![No Root](https://img.shields.io/badge/Root-Not_Required-brightgreen?style=for-the-badge)
![GPU](https://img.shields.io/badge/GPU-Accelerated-orange?style=for-the-badge)
![Distros](https://img.shields.io/badge/Distros-6_choices-blue?style=for-the-badge)

Based on [termux-hacklab](https://github.com/jarvesusaram99/termux-hacklab) by Tech Jarves — extended with multi-distro support, Hyprland, GNOME, KDE Plasma, and more.

---

## One-Command Install

Open **Termux** and paste:

```bash
curl -sL https://raw.githubusercontent.com/cameleonnbss/linux-on-termux/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/cameleonnbss/linux-on-termux
cd linux-on-termux
bash install.sh
```

---

## Available Distributions

| # | Distribution | Desktop | Style |
|---|-------------|---------|-------|
| 1 | **Ubuntu 24.04 LTS** | GNOME 46 | Beginner friendly |
| 2 | **Arch Linux** | Hyprland | Tiling WM, rice ready |
| 3 | **Debian 12** | KDE Plasma 6 | Stable and polished |
| 4 | **Fedora 40** | GNOME 46 | Bleeding edge |
| 5 | **Kali Linux** | XFCE4 | Pentesting tools included |
| 6 | **Alpine Linux** | Openbox | Ultra lightweight |

---

## Features

| Feature | Details |
|---------|---------|
| **GPU Acceleration** | Turnip/Zink drivers (Qualcomm Adreno up to 60 FPS) |
| **Real Desktop** | Full DE via proot-distro + Termux-X11 |
| **Audio** | PulseAudio with TCP loopback |
| **No Root** | Uses proot — works on any Android 7+ |
| **Wayland/X11** | Hyprland (Wayland) or X11 depending on DE |
| **Apps included** | Firefox, Git, neofetch, htop, and more |
| **One installer** | Interactive menu, single script does everything |

---

## GPU Acceleration

Unlike solutions that rely on slow software rendering, this installer sets up real GPU acceleration using Mesa Turnip/Zink drivers:

| Without GPU Accel | With GPU Accel (this installer) |
|-------------------|--------------------------------|
| llvmpipe (CPU) | Turnip Adreno (GPU) |
| 15-20 FPS | ~60 FPS |
| Laggy desktop | Smooth |
| High battery drain | Efficient |

**Supported GPUs:**
- Qualcomm Adreno (Snapdragon) — full Turnip driver
- ARM Mali — software fallback (still functional)
- MediaTek — software fallback

---

## Arch + Hyprland

The Arch Linux option comes with a pre-configured Hyprland setup including:

- **Waybar** — status bar with workspaces, clock, CPU, memory, audio
- **Wofi** — application launcher
- **Alacritty** — GPU-accelerated terminal with Catppuccin Mocha theme
- **Thunar** — file manager
- **PipeWire** — audio server
- **Dunst** — notification daemon
- **grim/slurp** — screenshot tools

**Hyprland keybinds (pre-configured):**

| Keys | Action |
|------|--------|
| `Super + Enter` | Open terminal (alacritty) |
| `Super + R` | App launcher (wofi) |
| `Super + Q` | Close window |
| `Super + E` | File manager (thunar) |
| `Super + F` | Fullscreen toggle |
| `Super + 1-5` | Switch workspace |
| `Super + Shift + 1-5` | Move window to workspace |
| `Super + arrows` | Move focus |
| `Super + Shift + arrows` | Move window |
| `Print` | Screenshot (full screen) |
| `Super + Print` | Screenshot (selection) |

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **Android** | 7.0 or higher |
| **Termux** | [Download from GitHub](https://github.com/termux/termux-app/releases) (**NOT Play Store**) |
| **Termux-X11** | [Download from GitHub](https://github.com/termux-x11/releases) |
| **Storage** | ~3-6 GB free |
| **RAM** | 3 GB+ recommended |
| **Internet** | Required during install |

> **Important:** Download Termux from GitHub, not the Play Store. The Play Store version is outdated and will not work.

---

## Usage After Install

```bash
bash ~/start-linux.sh   # Start the desktop
bash ~/stop-linux.sh    # Stop everything
bash ~/shell-linux.sh   # Open a shell inside the distro
```

1. Open the **Termux-X11** app first (leave it running)
2. Run `bash ~/start-linux.sh` in Termux
3. The desktop appears in Termux-X11

---

## Uninstall

```bash
bash uninstall.sh
```

This will remove the proot-distro, all scripts, configs, and Termux packages installed by the installer.

---

## Project Structure

```
linux-on-termux/
├── install.sh                     # Main installer (interactive menu)
├── uninstall.sh                   # Clean uninstaller
├── README.md                      # This file
├── .gitignore
├── LICENSE
└── configs/
    ├── hyprland/
    │   └── hyprland.conf          # Hyprland window manager config
    ├── waybar/
    │   ├── config                 # Waybar module config
    │   └── style.css              # Waybar Catppuccin Mocha theme
    ├── alacritty/
    │   └── alacritty.toml         # Alacritty terminal config
    └── gpu/
        └── gpu.env                # GPU acceleration environment vars
```

---

## proot-distro IDs Reference

| Distribution | proot-distro ID |
|---|---|
| Ubuntu 24.04 | `ubuntu` |
| Arch Linux | `archlinux` |
| Debian 12 | `debian` |
| Fedora 40 | `fedora` |
| Kali Linux | `kali` |
| Alpine Linux | `alpine` |

List available with: `proot-distro list`
Install one with: `proot-distro install <id>`
Login with: `proot-distro login <id>`
Remove with: `proot-distro remove <id>`

---

## Pro Tips

1. **Disable Phantom Process Killer** in Developer Options for stability
2. **Use Bluetooth keyboard + mouse** for near-PC experience
3. **Samsung DeX** works great with this setup
4. For Hyprland: start with workspace 1, open wofi with `Super+R`
5. Run `neofetch` inside the distro to verify GPU driver loaded

---

## Contributing

PRs welcome:
- Bug reports
- New distro support (openSUSE, Void, NixOS)
- Better Hyprland/GNOME/KDE configs
- Documentation improvements

---

## Disclaimer

This tool is for personal and educational use. Only use pentesting tools on systems you own or have explicit permission to test. The author is not responsible for any misuse.

---

Real Linux on Android — your distro, your DE, your choice.

Based on [termux-hacklab](https://github.com/jarvesusaram99/termux-hacklab) by Tech Jarves.

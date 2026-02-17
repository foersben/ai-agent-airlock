# **🛡️ AI Agent Airlock**

**Zero-Trust Development Environment for AI Agents**

Run powerful AI coding assistants like Google Antigravity, Cursor, or VS Code inside a secured, rootless Podman sandbox on Arch Linux.

## **📖 Overview**

AI Agent Airlock provides an "air-gapped" development environment where AI agents have full autonomy to write code, run terminal commands, and manage projects, but are physically isolated from your host system's sensitive data (SSH keys, Documents, Photos, System Configs).

The setup uses Podman to create a seamless bridge between your desktop environment (i3wm, Wayland, GNOME) and the container, forwarding only what is strictly necessary: X11/Wayland sockets, specific project folders, and SSH authentication.

### **✨ Features**

* **🛡️ Zero-Trust Sandbox:** The AI sees only `~/Documents/ai_sandbox`. It cannot read your `$HOME`.
* **🔑 Secure Identity:** Uses SSH Agent forwarding via unix sockets. Your private keys never leave the host RAM.
* **🚀 Native Performance:** Uses crun for low-overhead containerization. Supports GPU-accelerated UI or stable SwiftShader fallbacks.
* **💾 Persistence:** "Pet Container" logic ensures installed packages, VS Code extensions, and settings survive reboots.
* **🎨 Dotfiles Integration:** Automatically mounts your local `zsh`, `tmux`, and `fish` configurations so the terminal feels like home.
* **🔋 Batteries Included:** The image comes pre-loaded with git, python (pip/poetry/pipx), node, go, jdk, chromium, and act (for local GitHub Actions).
* **🔌 Integration:** Bridges for Gurobi licenses, System Fonts, and GTK Themes so the app looks native.

---

## **🧐 Why Podman?**

The "best" way to sandbox an AI agent depends on how you balance Security (isolation) vs. Efficiency (performance/convenience).

While Docker is common and effective, it typically runs a root daemon. That means: if an AI manages to escape the container, it could theoretically gain root access to your host.

I selected Podman as the *Gold Standard* for this repository because it provides the best balance:

* **Rootless & daemonless** → No privileged background service.
* **High isolation** → Escapes drop the AI into an *unprivileged* user.
* **High efficiency** → Same performance as Docker.

### **🏛️ The Hierarchy of Isolation**

1.  **The "Better" Standard: Podman (Recommended) ✅**
    * **Verdict:** More secure than Docker, equally efficient.
    * **Why:** Podman is *rootless by design*. If the AI manages to break out, it becomes a regular user mapped to your host user. It cannot modify system files.

2.  **The "Efficiency" Trap: Distrobox ⚠️**
    * **Verdict:** ❌ DO NOT USE for untrusted AI agents.
    * **Risk:** Distrobox bind-mounts your entire Home directory (`~/.ssh`, `~/.mozilla`, `~/Photos`) by default. An untrusted AI has instant access to everything.

3.  **The "Paranoid" Standard: MicroVMs (Firecracker / Qubes) 🛡️**
    * **Verdict:** 🛡️ Maximum security, lower efficiency.
    * **Trade-off:** Running GUI apps is slow, and GPU acceleration is often unavailable.

---

## **⚙️ Prerequisites**

### **1. System Packages**

You need a standard Arch Linux install with the following tools:

```sh
sudo pacman -S --noconfirm podman podman-docker fuse-overlayfs slirp4netns crun git wget xorg-xhost wmctrl ttf-jetbrains-mono-nerd

```

*(Note: `ttf-jetbrains-mono-nerd` is required for icons to render correctly).*

### **2. Rootless Configuration (Critical)**

Podman needs a range of "Sub-UIDs" to map users securely. Check if they exist:

```sh
grep $(whoami) /etc/subuid

```

**If output is empty**, generate them:

```sh
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $(whoami)

```

### **3. Performance Tuning (containers.conf)**

Switch to the C-based runtime `crun` for better speed:

```sh
mkdir -p ~/.config/containers
cp /usr/share/containers/containers.conf ~/.config/containers/
sed -i 's/^# runtime = "crun"/runtime = "crun"/' ~/.config/containers/containers.conf

```

---

## **🚀 Installation**

### **Step 1: Configuration (The Architect)**

Run the installer to set up the directory structure and copy configuration files to `~/.config/containers/antigravity_build`.

```sh
chmod +x install.sh
./install.sh

```

> **⚠️ IGNORE THE BUILD ERROR:**
> During this step, you will see an error at **Step 6/8** saying `COPY ... no such file or directory`.
> **This is intentional.** The installer sets up the blueprints but does not download the heavy source code. That happens in the next step.

### **Step 2: Build & Launch (The Builder)**

Now, run the update script. This will download the Antigravity source code from the AUR and build the final container image.

```sh
./bin/update-antigravity

```

Once you see `✅ Update Complete!`, you can launch the tool:

```sh
antigravity

```

---

## **🎨 Customization & Dotfiles**

This sandbox is designed to feel like your native terminal. It automatically detects and mounts dotfiles from `~/.config/containers/antigravity_dotfiles`.

### **Supported Configs**

Place your config files in the following structure on your host:

* `.../antigravity_dotfiles/zsh/.zshrc`
* `.../antigravity_dotfiles/tmux/.tmux.conf`
* `.../antigravity_dotfiles/fish/config.fish`

### **Flexible Package Installation (`boot.sh`)**

Need extra tools (like `htop`, `neofetch`, or specific python libs) inside the container? You don't need to rebuild the image.

1. Create a script at `~/.config/containers/antigravity_dotfiles/boot.sh`.
2. Add your installation commands:
```bash
#!/bin/bash

# Define a function to install only if missing
install_if_missing() {
    PACKAGE=$1
    # Check if the package is already installed (returns 0 if found)
    if ! pacman -Qi "$PACKAGE" &> /dev/null; then
        echo "🔧 boot.sh: Installing $PACKAGE..."
        sudo pacman -S --noconfirm "$PACKAGE"
    fi
}

# --- List your tools here ---
install_if_missing htop
install_if_missing neofetch
install_if_missing ripgre

```


3. Add `source ~/.boot.sh` to your `.zshrc` or `config.fish`.
*The container will now auto-install these tools every time you enter the shell.*

---

## **🔄 Updates & Maintenance**

There are two ways to update the system.

### **1. Routine Software Update**

To update the Antigravity tool and system packages (e.g., Python, Node, system libs):

```sh
./bin/update-antigravity

```

* **What it does:** Pulls latest AUR changes, rebuilds the image, and **replaces** the container.
* **Data Safety:** Project files (`~/Documents/ai_sandbox`) are SAFE. System packages installed manually inside the container are LOST (unless you use `boot.sh`).

### **2. Configuration Update**

If you edited the `Containerfile` or `install.sh` (e.g., to fix a build bug):

```sh
./install.sh
./bin/update-antigravity

```

* **Why:** You must run `install.sh` first to copy your new config files to the build directory.

---

## **🔧 Troubleshooting**

### **The "Rectangular Boxes" Issue (Missing Fonts)**

If your prompt looks like ` `, your host terminal is missing a Nerd Font.
**Fix:** Install `ttf-jetbrains-mono-nerd` on your host and configure your terminal (Ghostty/Alacritty) to use it.

### **"Update Available" Notification**

When you launch Antigravity, it may say "Update Available."
**Cause:** The AUR package (community maintained) is slightly behind the official release.
**Action:** Ignore it. The container is immutable, so the in-app updater cannot modify system files. Wait for the `update-antigravity` script to pick up the new version in a few days.

### **Graphics / Black Screen**

If the window crashes or is black:

1. The script defaults to **Software Rendering** (`--use-gl=swiftshader`) for stability.
2. To try GPU acceleration, edit `~/.local/bin/antigravity`:
* Remove `--disable-gpu` and `--use-gl=swiftshader`.
* Add `--device /dev/dri`.



## **License**

MIT

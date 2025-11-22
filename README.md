# **🛡️ AI Airlock**

**Zero-Trust Development Environment for AI Agents**

Run powerful AI coding assistants like Google Antigravity, Cursor, or VS Code inside a secured, rootless Podman sandbox on Arch Linux.

## **📖 Overview**

AI Agent Airlock provides an "air-gapped" development environment where AI agents have full autonomy to write code, run terminal commands, and manage projects, but are physically isolated from your host system's sensitive data (SSH keys, Documents, Photos, System Configs).

The setup uses Podman to create a seamless bridge between your desktop environment (i3wm, Wayland, GNOME) and the container, forwarding only what is strictly necessary: X11/Wayland sockets, specific project folders, and SSH authentication.

### **✨ Features**

* **🛡️ Zero-Trust Sandbox:** The AI sees only \~/Documents/ai\_sandbox. It cannot read your $HOME.  
* **🔑 Secure Identity:** Uses SSH Agent forwarding via unix sockets. Your private keys (id\_rsa) never leave the host RAM.  
* **🚀 Native Performance:** Uses crun for low-overhead containerization. Supports GPU-accelerated UI or stable SwiftShader fallbacks.  
* **💾 Persistence:** "Pet Container" logic ensures installed packages, VS Code extensions, and settings survive reboots.  
* **🔋 Batteries Included:** The image comes pre-loaded with git, python (pip/poetry/pipx), node, go, jdk, chromium, and act (for local GitHub Actions).  
* **🔌 Integration:** Bridges for Gurobi licenses, System Fonts, and GTK Themes so the app looks native.

## **🧐 Why Podman?**

The "best" way to sandbox an AI agent depends on how you balance Security (isolation) vs. Efficiency (performance/convenience).

While Docker is common and effective, it typically runs a root daemon.
That means: if an AI manages to escape the container, it could theoretically gain root access to your host.

I selected Podman as the *Gold Standard* for this repository because it provides the best balance:

* **Rootless & daemonless** → no privileged background service
* **High isolation** → escapes drop the AI into an *unprivileged* user
* **High efficiency** → same performance as Docker
* **Low system overhead** → no root daemon draining battery

### **🏛️ The Hierarchy of Isolation**

1. The "Better" Standard: Podman (Recommended)
    * Verdict: ✅ More secure than Docker, equally efficient
    * Why: Podman is *rootless by design*.
      If the AI manages to break out of the container, it becomes a regular user mapped to your host user.
      It cannot modify system files, and there's **no daemon** running with elevated privileges.
2. The "Efficiency" Trap: Distrobox ⚠️
    * Verdict: ❌ DO NOT USE for untrusted AI agents
    * Risk: Distrobox prioritizes convenience, not isolation.
      It bind-mounts your entire Home directory by default:
      ```sh
      ~/.ssh
      ~/.mozilla
      ~/Photos
      ```
      An untrusted AI has instant access to SSH keys, browser history, and personal files.
3. The "Paranoid" Standard: MicroVMs (Firecracker / Qubes) 🛡️
    * Verdict: 🛡️ Maximum security, lower efficiency
    * Trade-off:
      This is what AWS/OpenAI use to run your code.
      A MicroVM provides hardware-enforced boundaries, but:

    * running GUI apps is slow
    * GPU acceleration is usually unavailable
    * IDEs feel laggy
    * resource usage is higher

### **📊 Summary Comparison**

| Method                | Security  | Efficiency | AI Risk Level                                                |
| :-------------------- | :-------- | :--------- | :----------------------------------------------------------- |
| **Distrobox**         | 🔴 Low    | 🟢 High    | **Critical:** Can read your `~/.ssh` and all personal files. |
| **Docker (Root)**     | 🟡 Medium | 🟡 Medium  | **Moderate:** Root daemon escape → host compromise.          |
| **Podman (Rootless)** | 🟢 High   | 🟢 High    | **Low:** Escapes drop into an unprivileged user.             |
| **Qubes OS / VM**     | 🛡️ Max   | 🔴 Low     | **Zero:** Full hardware isolation.                           |


### **Choice: Podman + Wayland/X11**

I use Podman to achieve strong filesystem isolation while still providing near-native GUI performance through X11/Wayland socket forwarding.

This avoids the historic screen-logging risks of X11 forwarding, works flawlessly with modern AI tooling, and keeps the environment lightweight and secure.

## **⚙️ Prerequisites**

### **1\. System Packages**

You need a standard Arch Linux install with the following tools:

```sh
sudo pacman -S --noconfirm podman podman-docker fuse-overlayfs slirp4netns crun git wget xorg-xhost wmctrl
```

### **2\. Rootless Configuration (Critical)**

Podman needs a range of "Sub-UIDs" to map users securely. Check if they exist:

```sh
grep $(whoami) /etc/subuid
```

**If output is empty**, generate them:

```sh
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $(whoami)
```

### **3\. Performance Tuning (containers.conf)**

I recommend switching the runtime to crun (C-based) instead of runc (Go-based) for better memory usage and speed.

```sh
mkdir -p ~/.config/containers  
cp /usr/share/containers/containers.conf ~/.config/containers/

# Enable crun  
sed -i 's/^# runtime = "crun"/runtime = "crun"/' ~/.config/containers/containers.conf
```

## **🚀 Installation**

### **1\. Clone the Repository**

```sh
git clone https://github.com/yourusername/ai-airlock.git  
cd ai-airlock
```

### **2\. Run the Installer**

This script sets up the directory structure in \~/.config/containers and builds the base image.

```sh
chmod +x install.sh  
./install.sh
```

*Note: This will take a few minutes as it compiles the Antigravity binary from the AUR inside a temporary builder container.*

## **🖥️ Usage**

### **Launching the IDE**

You can launch the environment in three ways:

1. **Terminal:** Run antigravity in your shell.  
2. **Launcher:** Search for "Antigravity" in dmenu, rofi, or your desktop app grid.  
3. **Shortcut:** Bind exec antigravity to a key in your i3 config.

### **The "Magic Portal" (File Sharing)**

The container is isolated, but I created one specific shared folder:

| Host Location | Container Location | Purpose |
| :---- | :---- | :---- |
| \~/Documents/ai\_sandbox | /home/pilot/projects | **Put your code here.** The AI can read/write these files. |

### **Installing Packages (Persistence)**

The wrapper script uses "Pet Container" logic.

* If you run sudo pacman \-S htop inside the terminal, it **will persist** after you close the window.  
* To reset the system to a clean state (wiping system packages but keeping your project code), run:

  ```sh
  podman rm -f antigravity_box
  ```

## **🔧 Advanced Configuration**

### **The Wrapper Script (\~/.local/bin/antigravity)**

This script is the brain of the operation. It handles:

1. **X11 Permissions:** Automatically runs xhost to allow GUI rendering.  
2. **SSH Agent:** Mounts $SSH\_AUTH\_SOCK so git push works without copying keys.  
3. **Gurobi:** Detects \~/gurobi.lic and mounts it if present.  
4. **DBus:** Spoofs the DBus socket for theme integration.

### **Gurobi Optimization**

If you use Gurobi for optimization, place your license file at \~/gurobi.lic. The container will auto-detect it.

* *Note:* If you have a node-locked license that fails inside the container, edit \~/.local/bin/antigravity and change `--net=slirp4netns` to `--net=host` (Warning: Reduces network isolation).

### **Troubleshooting Graphics**

If the window is black or crashes:

1. The script defaults to **Software Rendering** (`--use-gl=swiftshader`) which is 100% stable but CPU-intensive.  
2. If you want to try GPU acceleration (e.g., for NVIDIA), edit \~/.local/bin/antigravity:  
   * Remove `--disable-gpu` and `--use-gl=swiftshader`.  
   * Add `--device /dev/dri`.  
   * *Warning:* This often causes crashes on rolling release distros due to driver version mismatches between Host and Container.

## **🧹 Maintenance**

Container builds can use up disk space. Use these commands to clean up:

```sh
# Clean up "dangling" build layers (Safe)  
podman image prune -f

# Clean up build cache (Safe)  
podman builder prune -f
```

⚠️ NUCLEAR OPTION (Deletes everything except active containers)

```sh
podman system prune -a
```

## License

MIT

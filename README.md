# AI Agent Airlock: Sandboxed Agentic IDEs

**Run AI coding agents (Google Antigravity, VS Code) in a secure, rootless Podman container on Arch Linux.**

This setup creates an "air-gapped" development environment where AI agents have full autonomy to write code, run terminals, and manage projects, but are physically isolated from your host system's sensitive files (~/.ssh, ~/Documents).

Features:

🛡️ Zero-Trust Sandbox: The AI sees only the project folder you explicitly mount.

🔑 Secure Identity: Uses SSH Agent forwarding—your private keys never leave the host.

🚀 Native Performance: GPU-accelerated (or SwiftShader fallback) GUI via Wayland/X11.

💾 Persistence: Installed extensions, settings, and package caches survive container resets.

🔌 Host Integration: Includes bridges for act (GitHub Actions), Gurobi licenses, and DBus themes.

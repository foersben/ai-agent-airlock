#!/bin/bash
set -e

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Antigravity Setup...${NC}"

# 1. Dependency Check
echo -e "${BLUE}📦 Checking dependencies...${NC}" DEPS="podman podman-docker fuse-overlayfs slirp4netns crun git wget xorg-xhost"
MISSING=""

for dep in $DEPS; do
    if ! pacman -Qi $dep &> /dev/null; then
        MISSING="$MISSING $dep"
    fi
done

if [ -n "$MISSING" ]; then
    echo -e "${RED}❌ Missing dependencies: $MISSING${NC}"
    echo "Please run: sudo pacman -S $MISSING"
    exit 1
fi

# 2. Rootless Configuration (SubUID/SubGID)
echo -e "${BLUE}🔒 Checking rootless permissions...${NC}"
USER_SUBID=$(grep "$(whoami)" /etc/subuid || true)
if [ -z "$USER_SUBID" ]; then
    echo -e "${RED}⚠️  Rootless subuid range missing.${NC}"
    echo "Running fix (requires sudo)..."
    sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
    echo -e "${GREEN}✅ Permissions added.${NC}"
else
    echo -e "${GREEN}✅ Rootless config looks good.${NC}"
fi

# 3. Directory Setup
echo -e "${BLUE}📂 Creating directory structure...${NC}"
INSTALL_DIR="$HOME/.config/containers/antigravity_build"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
PROJECTS_DIR="$HOME/Documents/ai_sandbox"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$PROJECTS_DIR"
mkdir -p "$HOME/.local/share/applications"

# 4. Copy Files
echo -e "${BLUE}📝 Installing configuration files...${NC}"
cp build/Containerfile "$INSTALL_DIR/"
cp config/starship.toml "$CONFIG_DIR/starship_container.toml"
cp bin/antigravity "$BIN_DIR/antigravity"
cp assets/antigravity.desktop "$HOME/.local/share/applications/"

# Make executable
chmod +x "$BIN_DIR/antigravity"

# 4.5. Optional Dotfiles Setup
echo -e "${BLUE}🎨 Dotfiles Configuration${NC}"
DOTFILES_DEST="$HOME/.config/containers/antigravity_dotfiles"

if [ -d "$DOTFILES_DEST" ]; then
    echo -e "${GREEN}✅ Dotfiles already detected at $DOTFILES_DEST${NC}"
else
    read -p "Do you want to use your private dotfiles? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your Dotfiles Git URL: " DOTFILES_REPO
        echo "Cloning $DOTFILES_REPO..."
        # Uses host SSH keys, so private repos work fine
        git clone "$DOTFILES_REPO" "$DOTFILES_DEST"
    fi
fi

# 5. Build Image
echo -e "${BLUE}🏗️  Building Antigravity Image (This will take a while)...${NC}"
cd "$INSTALL_DIR"
podman build -t antigravity_image .

echo -e "${GREEN}✨ Setup Complete!${NC}"
echo "You can now launch 'Antigravity' from your dmenu/launcher."

#!/usr/bin/env bash
# Quick setup script for building WebOS in a Docker container
# Run this on CachyOS (or any non-Gentoo system)

set -e

echo "════════════════════════════════════════════════════════════════"
echo "  WebOS Container Build Setup"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Don't run this as root. Run as your normal user."
   exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "📦 Docker not found. Installing..."
    echo "    You may be prompted for your sudo password."
    sudo pacman -S --needed docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo ""
    echo "👤 Adding you to the docker group..."
    sudo usermod -aG docker "$USER"
    
    echo ""
    echo "⚠️  You need to log out and back in for group changes to take effect."
    echo "    OR run: newgrp docker"
    echo ""
    read -p "Press Enter to continue (make sure you've run 'newgrp docker')..."
fi

# Test Docker
if ! docker ps &> /dev/null; then
    echo "❌ Docker is not running or you don't have permission."
    echo "   Try: sudo systemctl start docker"
    echo "   And: newgrp docker"
    exit 1
fi

echo "✅ Docker is ready"
echo ""

# Check disk space
available=$(df --output=avail -B 1G . | tail -1 | xargs)
if [[ $available -lt 50 ]]; then
    echo "⚠️  Warning: Only ${available}GB available. Build needs ~40GB."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Disk space: ${available}GB available"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Ready to build!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Choose an option:"
echo ""
echo "  1) Interactive build (recommended first time)"
echo "     - You'll get a shell inside a Gentoo container"
echo "     - Run commands manually to see what happens"
echo ""
echo "  2) Automated build (3-6 hours, unattended)"
echo "     - Runs the entire build automatically"
echo "     - Check back later for the ISO"
echo ""
echo "  3) Just start a Gentoo shell (for testing)"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting interactive build..."
        echo ""
        echo "You'll be in a Gentoo container. Run these commands:"
        echo ""
        echo "  emerge-webrsync"
        echo "  emerge sys-fs/squashfs-tools app-cdr/xorriso"
        echo "  ./build.sh all"
        echo ""
        echo "When done, type 'exit' to leave the container."
        echo "The ISO will be in build/sanus-*.iso"
        echo ""
        read -p "Press Enter to start..."
        
        docker run -it --rm \
            --privileged \
            -v "$(pwd):/sanusos" \
            -w /sanusos \
            -e PS1='(gentoo-build) \u@\h:\w\$ ' \
            gentoo/stage3:latest \
            /bin/bash
        ;;
        
    2)
        echo ""
        echo "🚀 Starting automated build..."
        echo "⏰ This will take 3-6 hours depending on your CPU."
        echo "   You can close this terminal - the build will continue."
        echo ""
        read -p "Press Enter to start..."
        
        # Create the build script if it doesn't exist
        if [[ ! -f build-in-container.sh ]]; then
            cat > build-in-container.sh << 'BUILDEOF'
#!/bin/bash
set -e
echo "==> Syncing Portage tree..."
emerge-webrsync
echo "==> Installing build tools..."
emerge --quiet sys-fs/squashfs-tools app-cdr/xorriso
echo "==> Starting WebOS build (this takes 3-6 hours)..."
cd /sanusos
./build.sh all
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ✅ BUILD COMPLETE!"
echo "════════════════════════════════════════════════════════════════"
ls -lh build/*.iso
BUILDEOF
            chmod +x build-in-container.sh
        fi
        
        docker run -it --rm \
            --privileged \
            -v "$(pwd):/sanusos" \
            -w /sanusos \
            gentoo/stage3:latest \
            /sanusos/build-in-container.sh
        ;;
        
    3)
        echo ""
        echo "🐚 Starting Gentoo shell..."
        echo "   Type 'exit' when done."
        echo ""
        
        docker run -it --rm \
            --privileged \
            -v "$(pwd):/sanusos" \
            -w /sanusos \
            -e PS1='(gentoo) \u@\h:\w\$ ' \
            gentoo/stage3:latest \
            /bin/bash
        ;;
        
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

echo ""
if [[ -f build/sanus-*.iso ]]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  ✅ SUCCESS! ISO created:"
    echo "════════════════════════════════════════════════════════════════"
    ls -lh build/sanus-*.iso
    echo ""
    echo "Next steps:"
    echo "  - Test it: qemu-system-x86_64 -m 4096 -enable-kvm -cdrom build/sanus-*.iso -boot d"
    echo "  - Flash to USB: sudo dd if=build/sanus-*.iso of=/dev/sdX bs=4M status=progress"
else
    echo "No ISO found. Check the output above for errors."
fi

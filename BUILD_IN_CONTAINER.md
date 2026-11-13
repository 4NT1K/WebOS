# Building WebOS in a Gentoo Container

Since you're running CachyOS (not Gentoo), we'll use a Gentoo Docker container to build the ISO.

## Prerequisites

You need Docker installed and running. This guide will install it.

---

## Step 1: Install Docker

```bash
# Install Docker
sudo pacman -S docker

# Start the Docker service
sudo systemctl start docker

# Enable it to start on boot (optional)
sudo systemctl enable docker

# Add yourself to the docker group (so you don't need sudo for docker commands)
sudo usermod -aG docker $USER

# Log out and back in, OR run this in current shell:
newgrp docker

# Test it works:
docker run hello-world
```

---

## Step 2: Prepare the Build Environment

```bash
cd /home/brah/sanusos

# Create a build script that will run inside the container
cat > build-in-container.sh << 'EOF'
#!/bin/bash
set -e

echo "==> Setting up Gentoo environment..."
emerge-webrsync || echo "Portage sync may have failed, continuing..."

echo "==> Installing build dependencies..."
emerge --quiet sys-fs/squashfs-tools app-cdr/xorriso

echo "==> Starting WebOS build..."
cd /sanusos
./build.sh all

echo "==> Build complete!"
ls -lh build/*.iso
EOF

chmod +x build-in-container.sh
```

---

## Step 3: Run the Build in Container

**Option A: Interactive (Recommended for first time)**

This lets you see what's happening and troubleshoot:

```bash
# Start a Gentoo container with your source code mounted
docker run -it --rm \
  --privileged \
  -v /home/brah/sanusos:/sanusos \
  -w /sanusos \
  gentoo/stage3:latest \
  /bin/bash

# Inside the container, run:
emerge-webrsync
emerge sys-fs/squashfs-tools app-cdr/xorriso
./build.sh all

# When done, exit the container
# The ISO will be in /home/brah/sanusos/build/ on your host
```

**Option B: Automated**

Run everything automatically (takes 3-6 hours):

```bash
docker run -it --rm \
  --privileged \
  -v /home/brah/sanusos:/sanusos \
  -w /sanusos \
  gentoo/stage3:latest \
  /sanusos/build-in-container.sh
```

---

## What This Does

1. **Pulls the Gentoo container** (~200 MB download)
2. **Mounts your WebOS source** at `/sanusos` inside the container
3. **Syncs Portage** (Gentoo's package tree)
4. **Installs build tools** (squashfs-tools, xorriso)
5. **Runs `./build.sh all`** which:
   - Downloads Gentoo stage3 (~400 MB)
   - Unpacks and configures the build chroot
   - Compiles the kernel with gaming patches (30-60 min)
   - Emerges all packages (@base, @desktop, @gaming) (2-4 hours)
   - Builds the installer
   - Creates the ISO (~1.6 GB)

---

## Expected Timeline

| Stage | Time | What It Does |
|-------|------|--------------|
| Docker pull | 2-5 min | Download Gentoo image |
| emerge-webrsync | 1-2 min | Sync Portage tree |
| Install tools | 5-10 min | Build squashfs-tools, xorriso |
| fetch | 5-10 min | Download stage3, portage snapshot |
| bootstrap | 45-90 min | Emerge base system |
| kernel | 30-60 min | Compile kernel with patches |
| rootfs | 90-180 min | Emerge desktop + gaming packages |
| iso | 10-20 min | Create bootable ISO |
| **TOTAL** | **3-6 hours** | Mostly CPU-bound |

**The build is CPU-intensive.** Your system will be busy but usable.

---

## Troubleshooting

### "Permission denied" errors
Make sure you're in the docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### "Not enough disk space"
The build needs ~40 GB. Check:
```bash
df -h /home/brah
```

### Build fails at bootstrap/kernel/rootfs
This is usually due to:
- Network issues (can't download packages)
- Disk space
- Missing tools in the container

Run interactively (Option A) to see the exact error.

### "Cannot connect to Docker daemon"
Start the service:
```bash
sudo systemctl start docker
```

---

## After the Build

The ISO will be at:
```
/home/brah/sanusos/build/webos-1.0-Ashen-amd64.iso
```

You can then:

```bash
# Check it was created
ls -lh /home/brah/sanusos/build/*.iso

# Flash to USB (replace /dev/sdX with your USB device!)
sudo dd if=/home/brah/sanusos/build/webos-1.0-Ashen-amd64.iso \
        of=/dev/sdX \
        bs=4M \
        status=progress \
        oflag=sync

# Or test in QEMU first
qemu-system-x86_64 -m 4096 -enable-kvm \
  -cdrom /home/brah/sanusos/build/webos-1.0-Ashen-amd64.iso \
  -boot d
```

---

## Notes

- The container runs as root (needed for chroot operations)
- Your source directory is bind-mounted (changes persist)
- The container is ephemeral (`--rm` deletes it after exit)
- All build artifacts stay on your host in `build/`
- You can stop/resume by just re-running the container

---

## Alternative: Full Gentoo VM

If Docker doesn't work, you can use a full VM instead:

1. Install QEMU: `sudo pacman -S qemu-full virt-manager`
2. Download Gentoo minimal ISO
3. Create 60 GB VM
4. Install Gentoo
5. Copy sources and build

But Docker is much faster and easier for this use case.

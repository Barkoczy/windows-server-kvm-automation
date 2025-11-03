# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a fully automated Windows Server VM deployment system for Ubuntu 24.04 using KVM/libvirt. The key innovation is zero-touch installation using `Autounattend.xml` - no manual interaction required during Windows Server installation.

**Primary automation tool**: Makefile with 20+ targets for complete VM lifecycle management.

## Complete Make Targets Reference

### Preparation and Setup

**`make help`**
- Displays comprehensive help with Czech translations
- Shows current configuration (vCPU, RAM, DISK)
- Provides quick start guide
- Color-coded sections for better readability

**`make deps`**
- Installs all required packages: qemu-kvm, libvirt-daemon-system, libvirt-clients, virt-manager, virt-viewer, ovmf, bridge-utils, cpu-checker, yq
- Enables and starts libvirtd service
- Adds current user to libvirt and kvm groups
- Creates ISO and disk directories
- Note: Requires logout/login for group changes to take effect

**`make check`**
- Displays host system information (OS, kernel, CPU, virtualization, vCPUs, RAM, disk)
- Shows configuration source (config.yml with yq, config.yml without yq, or built-in defaults)
- Displays current VM configuration (name, version, vCPU, RAM, disk, paths)
- Shows network interfaces (using nmcli or ip)
- Lists libvirt networks
- Warns about Wi-Fi detected and NAT requirement

**`make net-default`**
- Defines libvirt default NAT network from /usr/share/libvirt/networks/default.xml
- Sets network to autostart
- Starts the network
- Displays all libvirt networks
- Configures 192.168.122.0/24 subnet

### ISO Management

**`make download-virtio`**
- Downloads VirtIO drivers ISO v0.1.285-1 from Fedora Project
- Target location: $(ISO_DIR)/virtio-win.iso
- Fails if ISO already exists (must remove manually first)
- Sets file permissions to 644
- File size: ~500MB

**`make download-ws-iso`**
- Executes scripts/download-windows-iso.sh with version from config.yml or command line
- Downloads official Windows Server evaluation ISO from Microsoft
- Supports versions: 2019, 2022, 2025
- Interactive prompts for confirmation
- Optional progress bar with pv
- Target location: $(ISO_DIR)/WinServer$(WS_VERSION).iso

**`make download-ws-iso-manual`**
- Opens Microsoft Evaluation Center in browser
- Displays manual download instructions
- Shows expected file path

### Disk Management

**`make disk`**
- Creates qcow2 disk at $(DISK_PATH) with size $(DISK_GB)GB
- Fails if disk already exists
- Sets group to libvirt and permissions to 660
- Uses sudo for disk creation

### VM Installation and Management

**`make install`**
- Complete automated installation (see "VM Installation Details" section for full details)
- Dependencies: deps, net-default
- Checks: VM existence, ISO files, disk
- Creates unattended ISO if missing
- Launches virt-install with full configuration
- Installation time: ~15-20 minutes

**`make start`**
- Starts VM using `virsh start`
- Fails if VM is already running

**`make stop`**
- Graceful shutdown using `virsh shutdown`
- Ignores errors (continues if already stopped)

**`make reboot`**
- Restarts VM using `virsh reboot`

**`make destroy`**
- Force stops VM using `virsh destroy`
- Ignores errors (continues if already stopped)

**`make console`**
- Opens graphical console using virt-viewer
- Connects to qemu:///system
- Runs in background
- Also displays command for text console (virsh console)

**`make status`**
- Displays VM information using `virsh dominfo`
- Shows network addresses using `virsh domifaddr`
- Provides tip about console access

### RDP Access

**`make rdp`**
- Extracts VM IP address from virsh domifaddr
- Displays RDP connection instructions
- Shows credentials (Administrator / Admin123!Password)
- Provides multiple connection methods (make rdp-connect, rdesktop, xfreerdp)
- Fails with helpful message if no IP assigned yet

**`make rdp-connect`**
- Automatically connects to VM via RDP using xfreerdp
- Features: dynamic resolution, clipboard sharing, audio mode 1
- Falls back to rdesktop suggestion if xfreerdp fails
- Requires VM to have IP assigned

### Cleanup and Maintenance

**`make vm-undefine`**
- Depends on: destroy
- Removes VM definition using `virsh undefine`
- Attempts to remove NVRAM (for UEFI VMs)
- Falls back to undefine without --nvram if needed
- Preserves disk at $(DISK_PATH)
- Ignores errors

**`make remove`**
- Alias for vm-undefine
- Depends on: vm-undefine
- Preserves disk

**`make clean`**
- Removes disk file $(DISK_PATH) if exists
- Removes unattended ISO $(ISO_DIR)/WinServer2019_Unattended.iso
- Uses sudo for disk removal

**`make reinstall`**
- Depends on: destroy, vm-undefine, clean
- Performs complete cleanup and reinstallation
- Calls `make install` after cleanup

**`make purge`**
- Depends on: destroy, undefine (NOTE: should be vm-undefine)
- Complete cleanup including disk and unattended ISO
- Equivalent to destroy + vm-undefine + clean

## Essential Commands

### Initial Setup (3-step installation)
```bash
make download-virtio     # Download VirtIO drivers ISO
make download-ws-iso     # Auto-download Windows Server ISO from Microsoft
make install            # Fully automated VM installation (~15-20 min)
```

### VM Management
```bash
make start              # Start VM
make stop               # Graceful shutdown
make reboot             # Restart VM
make console            # Open graphical console (virt-viewer)
make status             # Show VM state and IP address
make rdp                # Show RDP connection instructions
make rdp-connect        # Direct RDP connection (xfreerdp)
```

### Maintenance
```bash
make destroy            # Force stop VM
make vm-undefine        # Remove VM definition (preserves disk)
make remove             # Alias for vm-undefine
make clean              # Delete VM disk + unattended ISO
make reinstall          # Full reinstall (destroy + vm-undefine + clean + install)
make purge              # Complete cleanup (destroy + vm-undefine + clean)
```

### System Checks
```bash
make check              # Verify host system, config source, and network
make net-default        # Configure libvirt NAT network
make deps               # Install all dependencies (including yq for config.yml)
```

## Architecture

### Configuration System

The project uses a **dual-source configuration** with intelligent fallback:

1. **config.yml** (preferred): YAML-based central configuration
   - Located at repository root
   - Parsed using `yq` tool
   - Fallback to defaults if missing or yq not installed

2. **Makefile variables**: Can override config.yml values via command line
   ```bash
   make install VM_NAME=winserver-prod VCPU=8 RAM_MB=16384
   ```

Configuration hierarchy (highest priority first):
- Command-line variables → config.yml → Built-in defaults

**IMPORTANT**: Machine type defaults differ:
- With config.yml: defaults to `q35` (modern PCIe)
- Without config.yml: defaults to `pc` (i440fx legacy)
- Command-line override: `make install MACHINE_TYPE=q35`

### Key Configuration Files

- **config.yml**: VM hardware specs, paths, advanced settings
- **Autounattend.xml**: Windows unattended installation configuration
  - Automated disk partitioning (EFI 100MB + MSR 128MB + Windows NTFS)
  - Windows Server installation: Image index 2 (Datacenter edition)
  - Administrator credentials: `Admin123!Password` (plain text in XML)
  - Computer name: `WINLAB`
  - Pre-configured RDP access (fDenyTSConnections=false)
  - Firewall: Remote Desktop group enabled for all profiles
  - Locale: en-US (all settings: UI, input, system, user)
  - OOBE: EULA hidden, ProtectYourPC=3 (disabled)

### Automation Scripts

**scripts/repack-unattended-iso.sh**
- Repacks Windows Server ISO with embedded `Autounattend.xml`
- Critical requirement: `Autounattend.xml` must be in both ISO root AND `sources/` directory for UEFI boot
- Uses `xorriso` for ISO manipulation with specific parameters:
  - `-iso-level 4` for long filename support
  - `-rock` for POSIX metadata
  - Dual boot configuration: BIOS (etfsboot.com) + UEFI (efisys_noprompt.bin)
- Creates `.tmp/` directory for mounting and building
- Properly handles case-sensitive filename (exactly "Autounattend.xml" with capital A)
- Auto-invoked by `make install` if unattended ISO doesn't exist
- Cleanup: removes temporary directories after completion

**scripts/download-windows-iso.sh**
- Downloads official Windows Server evaluation ISOs directly from Microsoft
- Supports versions: 2019, 2022, 2025
- No registration required
- Includes progress bar (requires `pv`) and size verification
- Direct URLs from Microsoft Evaluation Center (verified October 2025)
- Features: colored output, size validation, optional SHA256 checksum verification
- Auto-reads version from config.yml if available
- Interactive prompts for overwrite confirmation

### VM Architecture

**Hardware Configuration**:
- CPU: host-passthrough (full CPU feature exposure, maximum performance)
- Chipset: PC-i440fx (default) or Q35 (if specified in config.yml)
- Firmware: UEFI (OVMF) - required for modern Windows Server
- Disk: IDE bus (not VirtIO SCSI), qcow2 format, writeback cache
- Network: e1000 adapter (not VirtIO-Net) on NAT (192.168.122.x) - Wi-Fi compatible
- Graphics: QXL + Spice (localhost only)

**Why NAT networking?**
- Wi-Fi interfaces don't support macvtap/bridge mode (verified limitation)
- NAT provides full internet connectivity
- RDP access requires port forwarding from host to guest

**Default Credentials** (set by Autounattend.xml):
- Username: `Administrator`
- Password: `Admin123!Password`

### Critical Implementation Details

**ISO Handling**:
- All ISOs stored in `iso/` directory (gitignored except `.gitkeep`)
- Original ISO filename pattern: `WinServer{VERSION}.iso` (e.g., `WinServer2019.iso`)
- Unattended ISO: `WinServer2019_Unattended.iso` (auto-generated)
- VirtIO ISO: `virtio-win.iso` (downloaded from Fedora project)

**Disk Management**:
- Default location: `/var/lib/libvirt/images/{VM_NAME}.qcow2`
- Permissions: Group `libvirt`, mode `660`
- qcow2 format for thin provisioning and snapshots
- Bus type: IDE (not VirtIO SCSI)

**Permissions Setup** (automatic in `make install`):
- Sets ACLs for `libvirt-qemu` user to access ISO directory
- Applies recursive ACL to parent directories up to root
- Required for virt-install to read ISO files from user's home directory

## VM Installation Details

The `make install` target performs the following operations:

1. **Dependency check**: Runs `make deps` to ensure all required packages are installed
2. **Network setup**: Runs `make net-default` to ensure NAT network is active
3. **Existence check**: Verifies VM doesn't already exist (fails with helpful message if it does)
4. **ISO validation**: Checks for both Windows Server and VirtIO ISOs
5. **Disk creation**: Creates qcow2 disk if it doesn't exist (via `make disk`)
6. **Permissions setup**: Sets ACLs for libvirt-qemu user on ISO directory and parent directories
7. **Unattended ISO creation**: Creates `WinServer2019_Unattended.iso` if it doesn't exist
8. **virt-install execution**: Launches VM with specific parameters:
   - `--name $(VM_NAME)` - VM name (default: winlab)
   - `--virt-type kvm` - Use KVM hypervisor
   - `--machine $(MACHINE_TYPE)` - pc or q35
   - `--cpu $(CPU_MODE)` - host-passthrough
   - `--vcpus $(VCPU)` - Number of vCPUs (default: 12)
   - `--memory $(RAM_MB)` - RAM in MB (default: 12288)
   - `--boot uefi` - UEFI firmware
   - `--os-variant $(OS_VARIANT)` - win2k19 or win2k22
   - `--graphics spice,listen=127.0.0.1` - Spice graphics on localhost
   - `--video qxl` - QXL video driver
   - `--disk path=...,format=qcow2,bus=ide` - IDE disk (not VirtIO)
   - `--cdrom` - Windows Server unattended ISO
   - `--disk path=...,device=cdrom` - VirtIO drivers ISO (second CDROM)
   - `--network network=default,model=e1000` - e1000 adapter on NAT
   - `--features smm=on` - UEFI Secure Boot support
   - `--check all=off` - Skip validation checks
   - `--noautoconsole` - Don't auto-open console

## Development Workflow

### Making Configuration Changes

1. Edit `config.yml` for persistent changes
2. Use command-line overrides for temporary changes
3. Run `make check` to verify configuration source and values
4. Note: config.yml changes don't affect existing VMs (requires reinstall)

### Modifying Autounattend.xml

After editing `Autounattend.xml`:
```bash
rm iso/WinServer2019_Unattended.iso  # Force regeneration
make install  # Will recreate unattended ISO
```

### Testing Different Windows Versions

Edit `config.yml`:
```yaml
vm:
  version: 2022  # Change from 2019 to 2022
```

Or command-line override:
```bash
make download-ws-iso WS_VERSION=2022
make install WS_VERSION=2022
```

### Troubleshooting

**Installation hanging >30 minutes**:
- Use `make console` to check installation progress visually
- Check `make status` for IP assignment (indicates installation complete)

**VM has no internet**:
- Verify NAT network: `sudo virsh net-list --all` (should show "default" as "active")
- Fix: `make net-default`

**Permission errors during install**:
- The Makefile automatically sets ACLs for libvirt-qemu
- If issues persist, verify: `getfacl iso/` should show libvirt-qemu with r-x

**Cannot connect via RDP**:
- Wait for IP assignment: `make status` (may take 15-20 min during first install)
- Check RDP details: `make rdp`
- Direct connection: `make rdp-connect`

## Project Structure

```
windows-server/
├── config.yml                       # Central VM configuration
├── Makefile                         # Main automation (20+ targets)
├── Autounattend.xml                 # Windows unattended install config
├── iso/                             # ISOs (gitignored, local only)
│   ├── WinServer{VERSION}.iso       # Original Microsoft ISO
│   ├── WinServer{VERSION}_Unattended.iso  # Auto-generated with Autounattend.xml
│   └── virtio-win.iso               # VirtIO drivers
├── scripts/
│   ├── download-windows-iso.sh      # Auto-download Windows Server ISO
│   └── repack-unattended-iso.sh     # ISO repackaging with Autounattend.xml
└── docs/                            # Additional documentation
    ├── postinstall-guide.md         # Post-installation steps
    ├── configuration.md             # config.yml reference
    └── download-iso.md              # ISO download guide
```

## Platform Requirements

**Verified Environment**:
- Ubuntu 24.04.3 LTS (kernel 6.14.x)
- Intel i9-13980HX with VT-x (or AMD with AMD-V)
- Minimum 4GB free RAM (12GB recommended)
- Minimum 40GB free disk (60GB recommended)
- Any network interface (Wi-Fi or Ethernet)

**Dependencies** (auto-installed by `make deps`):
- qemu-kvm, libvirt-daemon-system, libvirt-clients
- virt-manager, virt-viewer (GUI tools)
- ovmf (UEFI firmware)
- bridge-utils, cpu-checker
- yq (YAML parser for config.yml) - CRITICAL for config.yml parsing
- xorriso (ISO manipulation) - CRITICAL for unattended ISO creation
- curl (for ISO downloads)
- pv (optional, for download progress bars)

## Important Notes

- **Always use `make` commands** instead of direct `virsh`/`virt-install` commands - the Makefile handles permissions, paths, and configuration parsing
- **config.yml requires yq** - install via `sudo apt install yq` or configuration will fall back to defaults
- **xorriso is REQUIRED** - the unattended ISO creation will fail without it; install via `make deps`
- **Unattended ISO is auto-generated** - don't manually create or edit it; modify `Autounattend.xml` and delete the unattended ISO to force regeneration
- **IP address assignment happens after installation completes** - don't expect immediate IP from `make status` during initial 15-20 minute installation
- **Wi-Fi networking limitation** - macvtap mode doesn't work on Wi-Fi interfaces; NAT mode is the correct choice for Wi-Fi hosts
- **Network adapter**: Uses e1000 (not VirtIO) for maximum compatibility during Windows installation
- **Disk bus**: Uses IDE (not VirtIO SCSI) for maximum compatibility during Windows installation

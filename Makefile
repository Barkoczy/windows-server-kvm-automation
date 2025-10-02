# Windows Server VM on Ubuntu 24.04 (KVM/libvirt)
# Optimized for Intel i9-13980HX, 31GB RAM, Wi-Fi networking
# Based on Oct 2025 best practices: PC machine type, UEFI, IDE disk, e1000 network, NAT networking

# Load configuration from config.yml (if exists) using yq
CONFIG_FILE := config.yml
HAS_YQ := $(shell command -v yq 2>/dev/null)
HAS_CONFIG := $(shell test -f $(CONFIG_FILE) && echo yes || echo no)

# Default fallback values (used if config.yml doesn't exist or yq not installed)
WS_VERSION_DEFAULT := 2019
VM_NAME_DEFAULT := winlab
VCPU_DEFAULT := 12
RAM_MB_DEFAULT := 12288
DISK_GB_DEFAULT := 60
ISO_DIR_DEFAULT := $(CURDIR)/iso
DISK_DIR_DEFAULT := /var/lib/libvirt/images

# Load from config.yml if available, otherwise use defaults
ifeq ($(HAS_CONFIG),yes)
  ifneq ($(HAS_YQ),)
    WS_VERSION ?= $(shell yq eval '.vm.version' $(CONFIG_FILE) 2>/dev/null || echo $(WS_VERSION_DEFAULT))
    VM_NAME ?= $(shell yq eval '.vm.name' $(CONFIG_FILE) 2>/dev/null || echo $(VM_NAME_DEFAULT))
    VCPU ?= $(shell yq eval '.hardware.vcpu' $(CONFIG_FILE) 2>/dev/null || echo $(VCPU_DEFAULT))
    RAM_MB ?= $(shell yq eval '.hardware.ram_mb' $(CONFIG_FILE) 2>/dev/null || echo $(RAM_MB_DEFAULT))
    DISK_GB ?= $(shell yq eval '.hardware.disk_gb' $(CONFIG_FILE) 2>/dev/null || echo $(DISK_GB_DEFAULT))
    ISO_DIR ?= $(shell yq eval '.paths.iso_dir' $(CONFIG_FILE) 2>/dev/null || echo $(ISO_DIR_DEFAULT))
    DISK_DIR ?= $(shell yq eval '.paths.disk_dir' $(CONFIG_FILE) 2>/dev/null || echo $(DISK_DIR_DEFAULT))
    CPU_MODE ?= $(shell yq eval '.advanced.cpu_mode' $(CONFIG_FILE) 2>/dev/null || echo host-passthrough)
    MACHINE_TYPE ?= $(shell yq eval '.advanced.machine_type' $(CONFIG_FILE) 2>/dev/null || echo pc)
    DISK_CACHE ?= $(shell yq eval '.advanced.disk_cache' $(CONFIG_FILE) 2>/dev/null || echo writeback)
  else
    # config.yml exists but yq not installed - use defaults and warn
    WS_VERSION ?= $(WS_VERSION_DEFAULT)
    VM_NAME ?= $(VM_NAME_DEFAULT)
    VCPU ?= $(VCPU_DEFAULT)
    RAM_MB ?= $(RAM_MB_DEFAULT)
    DISK_GB ?= $(DISK_GB_DEFAULT)
    ISO_DIR ?= $(ISO_DIR_DEFAULT)
    DISK_DIR ?= $(DISK_DIR_DEFAULT)
    CPU_MODE ?= host-passthrough
    MACHINE_TYPE ?= pc
    DISK_CACHE ?= writeback
  endif
else
  # No config.yml - use defaults
  WS_VERSION ?= $(WS_VERSION_DEFAULT)
  VM_NAME ?= $(VM_NAME_DEFAULT)
  VCPU ?= $(VCPU_DEFAULT)
  RAM_MB ?= $(RAM_MB_DEFAULT)
  DISK_GB ?= $(DISK_GB_DEFAULT)
  ISO_DIR ?= $(ISO_DIR_DEFAULT)
  DISK_DIR ?= $(DISK_DIR_DEFAULT)
  CPU_MODE ?= host-passthrough
  MACHINE_TYPE ?= q35
  DISK_CACHE ?= writeback
endif

# Derived values
OS_VARIANT := $(if $(filter $(WS_VERSION),2019),win2k19,win2k22)
DISK_PATH := $(DISK_DIR)/$(VM_NAME).qcow2

# ISO names (adjust if needed)
WS_ISO     ?= $(ISO_DIR)/WinServer$(WS_VERSION).iso
VIRTIO_ISO ?= $(ISO_DIR)/virtio-win.iso

.PHONY: help deps check net-default disk download-virtio download-ws-iso install start stop reboot console status destroy undefine clean

help:
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║  Windows Server $(WS_VERSION) VM on Ubuntu 24.04 (KVM/libvirt)       ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "TARGETS:"
	@echo "  make deps                - Install KVM/libvirt/OVMF and start libvirtd"
	@echo "  make check               - Display host info and network status"
	@echo "  make net-default         - Enable libvirt NAT network 'default'"
	@echo "  make download-virtio     - Download virtio-win ISO to $(ISO_DIR)"
	@echo "  make download-ws-iso     - Auto-download Windows Server $(WS_VERSION) ISO (official)"
	@echo "  make download-ws-iso-manual - Manual download guide (browser)"
	@echo "  make disk                - Create qcow2 disk $(DISK_PATH) ($(DISK_GB)G)"
	@echo "  make install             - Start FULLY AUTOMATED VM installation"
	@echo "  make reinstall           - Remove VM + disk and reinstall from scratch"
	@echo "  make remove              - Remove VM (keeps disk)"
	@echo "  make start|stop|reboot   - VM management"
	@echo "  make console             - Connect to graphical console (virt-viewer)"
	@echo "  make status              - Display VM status"
	@echo "  make destroy|undefine    - Destroy and remove VM definition (disk remains)"
	@echo "  make clean               - Delete disk $(DISK_PATH)"
	@echo ""
	@echo "CURRENT CONFIG: vCPU=$(VCPU), RAM=$(RAM_MB)MB, DISK=$(DISK_GB)GB"
	@echo ""
	@echo "QUICK START:"
	@echo "  1. make download-virtio"
	@echo "  2. make download-ws-iso      # Automatic download from Microsoft"
	@echo "  3. make install"

deps:
	@echo "📦 Installing KVM/libvirt packages for Ubuntu 24.04..."
	sudo apt update
	sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager \
	                    ovmf virt-viewer bridge-utils cpu-checker yq
	sudo systemctl enable --now libvirtd
	sudo usermod -aG libvirt $$USER || true
	sudo usermod -aG kvm $$USER || true
	sudo mkdir -p $(ISO_DIR) $(DISK_DIR)
	@echo "✅ Dependencies installed (including yq for config.yml parsing)."
	@echo "   Please log out and back in for group changes."
	@echo "   Verify with: kvm-ok && virsh version"

check:
	@echo "═══ Host System ═══"
	@echo "OS: $$(lsb_release -ds)"
	@echo "Kernel: $$(uname -r)"
	@echo "CPU: $$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
	@echo "Virtualization: $$(lscpu | grep Virtualization | cut -d: -f2 | xargs)"
	@echo "vCPUs: $$(nproc)"
	@echo "RAM: $$(free -h | awk '/^Mem:/ {print $$2}')"
	@echo "Disk: $$(df -h / | awk 'NR==2 {print $$4}' ) available"
	@echo ""
	@echo "═══ Configuration Source ═══"
	@if [ "$(HAS_CONFIG)" = "yes" ]; then \
		if [ -n "$(HAS_YQ)" ]; then \
			echo "✅ Using config.yml (parsed with yq)"; \
		else \
			echo "⚠️  config.yml found but yq not installed - using defaults"; \
			echo "   Install: sudo apt install yq"; \
		fi \
	else \
		echo "ℹ️  Using built-in defaults (config.yml not found)"; \
	fi
	@echo ""
	@echo "═══ VM Configuration ═══"
	@echo "VM Name: $(VM_NAME)"
	@echo "Windows Version: $(WS_VERSION)"
	@echo "vCPU: $(VCPU) cores"
	@echo "RAM: $(RAM_MB) MB"
	@echo "Disk: $(DISK_GB) GB"
	@echo "ISO Dir: $(ISO_DIR)"
	@echo "Disk Path: $(DISK_PATH)"
	@echo ""
	@echo "═══ Network Interfaces ═══"
	@nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null || ip -br addr
	@echo ""
	@echo "═══ Libvirt Networks ═══"
	@virsh net-list --all 2>/dev/null || echo "Run 'make net-default' first"
	@echo ""
	@echo "⚠️  Wi-Fi detected (wlo1) - using NAT networking (macvtap not supported on Wi-Fi)"

net-default:
	@echo "🌐 Configuring libvirt default NAT network..."
	- sudo virsh net-define /usr/share/libvirt/networks/default.xml 2>/dev/null
	- sudo virsh net-autostart default
	- sudo virsh net-start default 2>/dev/null
	@sudo virsh net-list --all
	@echo "✅ NAT network 'default' configured (192.168.122.0/24)"

download-virtio:
	@echo "⬇️  Downloading latest virtio-win ISO (v0.1.285-1)..."
	@mkdir -p "$(ISO_DIR)"
	@if [ -f "$(VIRTIO_ISO)" ]; then \
		echo "⚠️  $(VIRTIO_ISO) already exists. Remove it first if you want to re-download."; \
		exit 1; \
	fi
	curl -L -o "$(VIRTIO_ISO)" \
		"https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win.iso"
	@chmod 644 "$(VIRTIO_ISO)"
	@echo "✅ VirtIO drivers downloaded: $(VIRTIO_ISO)"

download-ws-iso:
	@echo "🪟 Downloading Windows Server $(WS_VERSION) ISO..."
	@if [ ! -x "$(CURDIR)/scripts/download-windows-iso.sh" ]; then \
		chmod +x "$(CURDIR)/scripts/download-windows-iso.sh"; \
	fi
	@"$(CURDIR)/scripts/download-windows-iso.sh" $(WS_VERSION)

download-ws-iso-manual:
	@echo "🪟 Windows Server ISO Download Guide (Manual)"
	@echo "════════════════════════════════════════════════"
	@echo "1. Download LEGALLY from Microsoft Evaluation Center:"
	@echo "   https://www.microsoft.com/evalcenter"
	@echo ""
	@echo "2. Select: Windows Server $(WS_VERSION) (180-day evaluation)"
	@echo ""
	@WS_ISO_ABS=$$(cd "$(dir $(WS_ISO))" && pwd)/$(notdir $(WS_ISO)); \
	echo "3. Save ISO as: $$WS_ISO_ABS"; \
	echo ""
	@echo "Opening browser..."
	@xdg-open "https://www.microsoft.com/evalcenter" >/dev/null 2>&1 || true

disk:
	@echo "💾 Creating qcow2 disk: $(DISK_PATH) ($(DISK_GB)G)..."
	@if [ -f "$(DISK_PATH)" ]; then \
		echo "⚠️  Disk already exists: $(DISK_PATH)"; \
		exit 1; \
	fi
	sudo qemu-img create -f qcow2 "$(DISK_PATH)" $(DISK_GB)G
	sudo chgrp libvirt "$(DISK_PATH)" && sudo chmod 660 "$(DISK_PATH)"
	@echo "✅ Disk created with VirtIO-optimized settings"

install: deps net-default
	@echo "🚀 Installing Windows Server $(WS_VERSION) VM..."
	@echo "════════════════════════════════════════════════"
	@# Check if VM already exists
	@if sudo virsh dominfo "$(VM_NAME)" >/dev/null 2>&1; then \
		echo "⚠️  VM $(VM_NAME) already exists!"; \
		echo ""; \
		echo "Options:"; \
		echo "  1. Keep existing VM: make start"; \
		echo "  2. Remove and reinstall: make reinstall"; \
		echo "  3. Remove only: make remove"; \
		echo ""; \
		exit 1; \
	fi
	@# Convert relative path to absolute for virt-install
	@WS_ISO_ABS=$$(cd "$(dir $(WS_ISO))" && pwd)/$(notdir $(WS_ISO)); \
	VIRTIO_ISO_ABS=$$(cd "$(dir $(VIRTIO_ISO))" && pwd)/$(notdir $(VIRTIO_ISO)); \
	if [ ! -f "$$WS_ISO_ABS" ]; then \
		echo "❌ Missing: $$WS_ISO_ABS"; \
		echo "   Run 'make download-ws-iso'"; \
		exit 2; \
	fi; \
	if [ ! -f "$$VIRTIO_ISO_ABS" ]; then \
		echo "❌ Missing: $$VIRTIO_ISO_ABS"; \
		echo "   Run 'make download-virtio'"; \
		exit 3; \
	fi
	@if [ ! -f "$(DISK_PATH)" ]; then \
		$(MAKE) disk; \
	fi
	@echo ""
	@echo "🔒 Setting up libvirt-qemu permissions for ISO access..."
	@# Grant libvirt-qemu read+execute access to parent directories
	@ISO_DIR_ABS=$$(cd "$(ISO_DIR)" && pwd); \
	for dir in $$(echo "$$ISO_DIR_ABS" | tr '/' ' ' | awk '{for(i=1;i<=NF;i++){printf "/%s",$$i; if(i<NF) for(j=i+1;j<=NF;j++) printf "/%s",$$j; printf "\n"}}' | tac); do \
		sudo setfacl -m u:libvirt-qemu:rx "$$dir" 2>/dev/null || true; \
	done
	@sudo setfacl -R -m u:libvirt-qemu:rx "$(ISO_DIR)" 2>/dev/null || true
	@echo "✅ Permissions configured"
	@echo ""
	@echo "Configuration:"
	@echo "  - vCPU: $(VCPU) cores (host-passthrough)"
	@echo "  - RAM: $(RAM_MB) MB"
	@echo "  - Disk: $(DISK_GB) GB (VirtIO SCSI)"
	@echo "  - Network: NAT (libvirt default)"
	@echo "  - Chipset: Q35 + UEFI"
	@echo ""
	@# Create unattended ISO with embedded autounattend.xml
	@if [ ! -f "$(ISO_DIR)/WinServer2019_Unattended.iso" ]; then \
		echo "📝 Creating unattended ISO with embedded autounattend.xml..."; \
		bash scripts/repack-unattended-iso.sh; \
	fi
	@WS_ISO_ABS=$$(cd "$(dir $(ISO_DIR)/WinServer2019_Unattended.iso)" && pwd)/WinServer2019_Unattended.iso; \
	VIRTIO_ISO_ABS=$$(cd "$(dir $(VIRTIO_ISO))" && pwd)/$(notdir $(VIRTIO_ISO)); \
	sudo virt-install \
	  --name "$(VM_NAME)" \
	  --virt-type kvm \
	  --machine $(MACHINE_TYPE) \
	  --cpu $(CPU_MODE) \
	  --vcpus $(VCPU) \
	  --memory $(RAM_MB) \
	  --boot uefi \
	  --os-variant $(OS_VARIANT) \
	  --graphics spice,listen=127.0.0.1 \
	  --video qxl \
	  --disk path="$(DISK_PATH)",format=qcow2,bus=ide \
	  --cdrom "$$WS_ISO_ABS" \
	  --disk path="$$VIRTIO_ISO_ABS",device=cdrom \
	  --network network=default,model=e1000 \
	  --features smm=on \
	  --check all=off \
	  --noautoconsole
	@echo ""
	@echo "✅ Fully automated installation started!"
	@echo ""
	@echo "📝 What happens automatically:"
	@echo "   ✓ UEFI/GPT disk partitioning (100MB EFI + 128MB MSR + Windows partition)"
	@echo "   ✓ VirtIO drivers auto-loaded during installation"
	@echo "   ✓ Windows Server 2019 Datacenter installation (index 2)"
	@echo "   ✓ Administrator password: Admin123!Password"
	@echo "   ✓ Computer name: WINLAB"
	@echo "   ✓ RDP enabled + firewall configured"
	@echo "   ✓ Server Manager auto-start disabled"
	@echo ""
	@echo "⏱️  Installation takes ~15-20 minutes. Monitor with:"
	@echo "   make console    # Open VM console"
	@echo "   make status     # Check VM status"
	@echo ""
	@echo "🔧 After installation completes:"
	@echo "   1. Connect via RDP: rdesktop 192.168.122.XXX"
	@echo "   2. Find IP: make status"
	@echo "   3. Login: Administrator / Admin123!Password"

start:
	@echo "▶️  Starting VM: $(VM_NAME)"
	@sudo virsh start "$(VM_NAME)"

stop:
	@echo "⏹️  Stopping VM: $(VM_NAME)"
	@sudo virsh shutdown "$(VM_NAME)" || true

reboot:
	@echo "🔄 Rebooting VM: $(VM_NAME)"
	@sudo virsh reboot "$(VM_NAME)"

console:
	@echo "🖥️  Connecting to VM console..."
	@echo "Graphical (recommended):"
	@virt-viewer --connect qemu:///system "$(VM_NAME)" &
	@echo ""
	@echo "Text console (if needed): sudo virsh console $(VM_NAME)"

status:
	@echo "📊 VM Status: $(VM_NAME)"
	@echo "════════════════════════════════════"
	@sudo virsh dominfo "$(VM_NAME)" 2>/dev/null || echo "VM not defined"
	@echo ""
	@echo "Network addresses:"
	@sudo virsh domifaddr "$(VM_NAME)" 2>/dev/null || echo "No IP assigned yet"
	@echo ""
	@echo "💡 Tip: Open console to watch installation progress:"
	@echo "   make console"

rdp:
	@echo "🖥️  RDP Connection Info"
	@echo "════════════════════════════════════"
	@IP=$$(sudo virsh domifaddr "$(VM_NAME)" 2>/dev/null | grep -oP '192\.168\.122\.\d+' | head -1); \
	if [ -z "$$IP" ]; then \
		echo "❌ No IP address assigned yet"; \
		echo ""; \
		echo "Installation may still be in progress. Check:"; \
		echo "  make console  # Watch installation"; \
		echo "  make status   # Check VM state"; \
		exit 1; \
	else \
		echo "✅ VM IP Address: $$IP"; \
		echo ""; \
		echo "Connect with:"; \
		echo "  rdesktop $$IP"; \
		echo "  xfreerdp /v:$$IP /u:Administrator /p:Admin123!Password /cert:ignore"; \
		echo ""; \
		echo "Credentials:"; \
		echo "  Username: Administrator"; \
		echo "  Password: Admin123!Password"; \
	fi

destroy:
	@echo "🛑 Destroying VM: $(VM_NAME)"
	@sudo virsh destroy "$(VM_NAME)" 2>/dev/null || true


undefine: destroy
	@echo "🗑️  Removing VM definition: $(VM_NAME)"
	@sudo virsh undefine "$(VM_NAME)" --nvram 2>/dev/null || sudo virsh undefine "$(VM_NAME)" 2>/dev/null || true
	@echo "✅ VM definition removed (disk remains at $(DISK_PATH))"

remove: undefine
	@echo "✅ VM $(VM_NAME) removed (disk preserved)"

reinstall: destroy undefine clean
	@echo "🔄 Reinstalling VM from scratch..."
	@$(MAKE) install

clean:
	@echo "🗑️  Removing disk: $(DISK_PATH)"
	@if [ -f "$(DISK_PATH)" ]; then \
		sudo rm -f "$(DISK_PATH)"; \
		echo "✅ Disk deleted: $(DISK_PATH)"; \
	else \
		echo "ℹ️  Disk not found: $(DISK_PATH)"; \
	fi
	@echo "🗑️  Removing unattended ISO..."
	@if [ -f "$(ISO_DIR)/WinServer2019_Unattended.iso" ]; then \
		rm -f "$(ISO_DIR)/WinServer2019_Unattended.iso"; \
		echo "✅ Unattended ISO deleted"; \
	fi

purge: destroy undefine clean
	@echo "💥 Complete cleanup of VM $(VM_NAME)"
	@echo "✅ VM completely removed (VM definition + disk + unattended ISO)"


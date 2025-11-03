# Configuration Guide

## Config.yml Reference

### Complete Example
```yaml
# Windows Server VM Configuration
vm:
  name: winlab              # VM name (used in virsh commands)
  version: 2019             # Windows Server version: 2016, 2019, 2022, 2025

hardware:
  vcpu: 12                  # Number of virtual CPU cores
  ram_mb: 12288             # RAM in MB (12288 = 12 GB)
  disk_gb: 60               # Disk size in GB

paths:
  iso_dir: /var/lib/libvirt/boot        # ISO storage directory
  disk_dir: /var/lib/libvirt/images     # VM disk storage directory

# Advanced settings (optional)
advanced:
  cpu_mode: host-passthrough   # CPU mode: host-passthrough, host-model, or custom
  machine_type: q35            # Machine type: q35 (modern PCIe) or pc-i440fx (legacy)
  firmware: uefi               # Firmware: uefi (required for Windows Server) or bios
  disk_cache: writeback        # Disk cache: writeback, writethrough, none
  disk_io: threads             # Disk I/O: threads or native
```

## Configuration Options

### VM Settings

#### `vm.name`
- **Type**: String
- **Default**: `winlab`
- **Description**: Virtual machine name used in virsh commands
- **Examples**:
  ```yaml
  vm:
    name: winserver-dev      # Development server
    name: winserver-prod     # Production server
    name: dc01               # Domain controller
  ```

#### `vm.version`
- **Type**: String (2016, 2019, 2022, 2025)
- **Default**: `2019`
- **Description**: Windows Server version to install
- **Notes**:
  - Affects ISO filename and OS variant detection
  - ⚠️ Windows Server 2016: Extended support ends 12.1.2027

### Hardware Settings

#### `hardware.vcpu`
- **Type**: Integer
- **Default**: `12`
- **Min**: 1 (not recommended for Windows Server)
- **Recommended**:
  - Minimum: 2 for Server Core
  - Recommended: 4+ for Desktop Experience
  - Optimal: 25-50% of host cores
- **Examples**:
  ```yaml
  hardware:
    vcpu: 4    # Minimal (2 cores)
    vcpu: 8    # Standard (4 cores)
    vcpu: 16   # High performance (8 cores)
  ```

#### `hardware.ram_mb`
- **Type**: Integer (in MB)
- **Default**: `12288` (12 GB)
- **Min**:
  - 512 MB (absolute minimum, not practical)
  - 2048 MB (2 GB) for Server Core
  - 4096 MB (4 GB) for Desktop Experience
- **Recommended**:
  - 4-8 GB: Light workloads
  - 12-16 GB: Standard workloads
  - 24+ GB: Heavy workloads (SQL, Exchange)
- **Examples**:
  ```yaml
  hardware:
    ram_mb: 4096   # 4 GB
    ram_mb: 8192   # 8 GB
    ram_mb: 16384  # 16 GB
  ```

#### `hardware.disk_gb`
- **Type**: Integer (in GB)
- **Default**: `60`
- **Min**:
  - 32 GB (absolute minimum)
  - 40 GB (Server Core with roles)
  - 60 GB (Desktop Experience)
- **Recommended**:
  - 60-80 GB: Standard installation
  - 120+ GB: With applications
  - 500+ GB: Database/file server
- **Examples**:
  ```yaml
  hardware:
    disk_gb: 60    # Standard
    disk_gb: 120   # With apps
    disk_gb: 500   # Database server
  ```

### Path Settings

#### `paths.iso_dir`
- **Type**: String (absolute path)
- **Default**: `/var/lib/libvirt/boot`
- **Description**: Directory for ISO files
- **Requirements**: Must have sudo write access
- **Examples**:
  ```yaml
  paths:
    iso_dir: /home/user/isos          # User home directory
    iso_dir: /mnt/storage/isos        # External storage
  ```

#### `paths.disk_dir`
- **Type**: String (absolute path)
- **Default**: `/var/lib/libvirt/images`
- **Description**: Directory for VM disk images
- **Requirements**:
  - Fast storage (SSD recommended)
  - Enough space for disk_gb + growth
  - libvirt group access
- **Examples**:
  ```yaml
  paths:
    disk_dir: /var/lib/libvirt/images     # Default (system SSD)
    disk_dir: /mnt/nvme/vms               # Dedicated NVMe
    disk_dir: /home/user/vms              # User directory
  ```

### Advanced Settings

#### `advanced.cpu_mode`
- **Type**: String
- **Default**: `host-passthrough`
- **Options**:
  - `host-passthrough`: Full CPU features (best performance, no migration)
  - `host-model`: Similar to host CPU (good performance, migration possible)
  - `custom`: Custom CPU model (maximum compatibility)
- **Recommendation**: Use `host-passthrough` for single-host VMs
- **Examples**:
  ```yaml
  advanced:
    cpu_mode: host-passthrough   # Best performance (default)
    cpu_mode: host-model         # For VM migration
  ```

#### `advanced.machine_type`
- **Type**: String
- **Default**: `q35`
- **Options**:
  - `q35`: Modern PCIe chipset (required for Windows Server 2019+)
  - `pc-i440fx`: Legacy PCI chipset (older OS)
- **Recommendation**: Always use `q35` for Windows Server
- **Notes**: Cannot be changed after VM creation

#### `advanced.firmware`
- **Type**: String
- **Default**: `uefi`
- **Options**:
  - `uefi`: UEFI firmware (required for Windows Server)
  - `bios`: Legacy BIOS (not supported for modern Windows)
- **Recommendation**: Always use `uefi`
- **Requirements**: OVMF package installed

#### `advanced.disk_cache`
- **Type**: String
- **Default**: `writeback`
- **Options**:
  - `writeback`: Best performance, cache writes (risk on host crash)
  - `writethrough`: Safe, cache reads only
  - `none`: No cache (slowest, safest)
- **Recommendation**:
  - Development: `writeback`
  - Production: `writethrough`
- **Examples**:
  ```yaml
  advanced:
    disk_cache: writeback      # Performance (default)
    disk_cache: writethrough   # Safety
    disk_cache: none          # Maximum safety (slow)
  ```

#### `advanced.disk_io`
- **Type**: String
- **Default**: `threads`
- **Options**:
  - `threads`: User-space I/O (works everywhere)
  - `native`: Kernel-space I/O (requires direct disk access)
- **Recommendation**: Use `threads` (default)

## Configuration Priority

The configuration is loaded in this order (later overrides earlier):

1. **Built-in defaults** (Makefile fallback values)
2. **config.yml** (if exists and yq installed)
3. **Environment variables** (if set)
4. **Command-line parameters** (highest priority)

### Example Priority Chain
```bash
# 1. Default in Makefile: VCPU=12
# 2. Override in config.yml: vcpu: 8
# 3. Override on command line (highest priority):
make install VCPU=16  # Uses 16 CPUs
```

## Configuration Scenarios

### Minimal Development VM
```yaml
vm:
  name: windev
  version: 2019

hardware:
  vcpu: 4
  ram_mb: 4096
  disk_gb: 40
```

### Standard Production VM
```yaml
vm:
  name: winprod
  version: 2022

hardware:
  vcpu: 8
  ram_mb: 16384
  disk_gb: 120

advanced:
  disk_cache: writethrough  # Safety over performance
```

### High-Performance Database VM
```yaml
vm:
  name: sqlserver
  version: 2022

hardware:
  vcpu: 16
  ram_mb: 32768
  disk_gb: 500

paths:
  disk_dir: /mnt/nvme/vms  # Fast NVMe storage

advanced:
  cpu_mode: host-passthrough
  disk_cache: writeback
  disk_io: threads
```

### Testing Multiple Versions
```yaml
# config-2019.yml
vm:
  name: test2019
  version: 2019

# config-2022.yml
vm:
  name: test2022
  version: 2022

# Use different configs:
# cp config-2019.yml config.yml && make install
# cp config-2022.yml config.yml && make install
```

## Validation

### Check Current Configuration
```bash
make check
```
Shows:
- Configuration source (config.yml or defaults)
- All effective values
- Host resources available

### Test Configuration Without Installing
```bash
# Dry run (check values only)
make check

# View what virt-install command will be run
make -n install | grep virt-install
```

## Troubleshooting

### config.yml Ignored
**Problem**: Values from config.yml not applied

**Solutions**:
```bash
# 1. Check yq installed
which yq || sudo apt install yq

# 2. Verify config.yml syntax
yq eval . config.yml

# 3. Check file location
ls -la config.yml  # Must be in project root

# 4. Test manual load
yq eval '.hardware.vcpu' config.yml
```

### Invalid Values
**Problem**: VM fails to start with config errors

**Solutions**:
```bash
# Check minimum values
hardware:
  vcpu: 2        # Min 1, recommend 2+
  ram_mb: 2048   # Min 512, recommend 2048+
  disk_gb: 40    # Min 32, recommend 40+

# Verify paths exist
sudo mkdir -p /var/lib/libvirt/boot
sudo mkdir -p /var/lib/libvirt/images
```

### Permission Errors
**Problem**: Cannot write to ISO/disk directories

**Solutions**:
```bash
# Fix permissions
sudo chown -R libvirt:libvirt /var/lib/libvirt/images
sudo chmod -R 775 /var/lib/libvirt/images

# Add user to libvirt group
sudo usermod -aG libvirt $USER
# Log out and back in

# Or use user-owned directory
paths:
  iso_dir: $HOME/vms/isos
  disk_dir: $HOME/vms/disks
```

## Best Practices

1. **Always use config.yml** for persistent configuration
2. **Comment your changes** in config.yml
3. **Test with `make check`** before installing
4. **Backup config.yml** before major changes
5. **Use version control** for config.yml (git)
6. **Document custom values** with comments
7. **Start conservative** (can increase later)
8. **Monitor host resources** (don't over-allocate)

## Reference

### Host Resource Guidelines
Based on your system (i9-13980HX, 32 threads, 31GB RAM):

- **Safe allocation**:
  - vCPU: 12 (37% of 32 threads)
  - RAM: 12 GB (38% of 31 GB)

- **Maximum allocation**:
  - vCPU: 24 (75% of 32 threads)
  - RAM: 24 GB (77% of 31 GB)

- **Leave for host**:
  - Min 4 CPU threads
  - Min 4 GB RAM

### Official Documentation
- libvirt domain XML: https://libvirt.org/formatdomain.html
- QEMU machine types: https://wiki.qemu.org/Features/Q35
- Windows Server requirements: https://learn.microsoft.com/windows-server/get-started/hardware-requirements

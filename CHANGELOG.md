# Changelog

## [1.0.0] - 2025-10-02

### Added
- ✅ Initial project structure
- ✅ Automated Windows Server VM installation for Ubuntu 24.04
- ✅ Support for Windows Server 2019, 2022, 2025
- ✅ YAML configuration file (config.yml)
- ✅ Automated ISO download script
- ✅ Local `iso/` directory for ISO files
- ✅ Comprehensive documentation in `docs/`
- ✅ Git-friendly structure (.gitignore, .gitkeep)

### Features
- **Hardware**: Optimized for Intel i9-13980HX (12 vCPU, 12GB RAM, 60GB disk)
- **Virtualization**: KVM/libvirt with Q35 chipset and UEFI firmware
- **Drivers**: VirtIO 0.1.285-1 (latest as of Oct 2025)
- **Network**: NAT networking (Wi-Fi compatible)
- **Storage**: VirtIO SCSI with writeback cache and IO threads
- **Automation**: Full Makefile-based workflow

### Configuration
- Flexible config.yml with fallback to defaults
- Command-line parameter override support
- Automatic path resolution (relative/absolute)

### Documentation
- Main README.md with quick start guide
- docs/README.md - Documentation index
- docs/configuration.md - Complete config reference
- docs/download-iso.md - ISO download guide
- docs/postinstall-guide.md - Post-installation steps

### Scripts
- scripts/download-windows-iso.sh - Automated ISO downloader
  - Direct downloads from Microsoft Evaluation Center
  - Progress bar support (with pv)
  - Checksum verification (optional)

### ISO Management
- Local `iso/` directory for all ISO files
- Git-tracked structure with .gitkeep
- ISOs excluded from git (*.iso in .gitignore)
- Automatic directory creation

### Technical Details
- Based on October 2025 best practices
- Verified on Ubuntu 24.04.3 LTS (kernel 6.14.0-32)
- Supports Windows Server 2019/2022/2025 Evaluation (180 days)
- Wi-Fi compatible (NAT instead of macvtap bridge)

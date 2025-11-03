# Changelog

## [1.1.0] - 2025-11-03

### Added
- ✅ **Windows Server 2016 support** with full automation
- ✅ Dynamic OS variant mapping with osinfo-db fallback (win2k16 → win2k12r2)
- ✅ Automatic image index adjustment for WS 2016 (Datacenter = index 4 vs. index 2 for newer versions)
- ✅ EOL lifecycle warnings for Windows Server 2016 (Extended Support ends 12.1.2027)
- ✅ Project instructions document (CLAUDE.md) for AI-assisted development
- ✅ Comprehensive implementation plan (WS2016-IMPLEMENTATION-PLAN.md)

### Fixed
- 🐛 **Critical**: Removed hardcoded "2019" references in Makefile (3 locations)
- 🐛 **Critical**: Fixed incomplete OS variant mapping (only 2019 was mapped explicitly)
- 🐛 Fixed non-parametrized repack-unattended-iso.sh (now accepts WS_VERSION parameter)
- 🐛 Fixed static ISO paths preventing multi-version support

### Changed
- 📝 Updated configuration documentation with WS 2016 support and EOL warnings
- 📝 Updated ISO download guide with WS 2016 section and lifecycle information
- 📝 Enhanced download script with 2016 URL, size (~6.5 GB), and warnings
- 🔧 Improved version detection in repack script (parameter → config.yml → default)

### Technical Details
- **Image Index Logic**: WS 2016 uses index 4 for Datacenter Desktop Experience (vs. index 2 for 2019+)
- **OS Variant Fallback**: Automatic detection with graceful fallback for older osinfo-db
- **Version Range**: Now supports 2016, 2019, 2022, 2025
- **Lifecycle Warning**: WS 2016 mainstream support ended 11.1.2022, extended ends 12.1.2027

### Files Modified
- `Makefile` - OS variant mapping, dynamic ISO paths
- `config.yml` - Updated version comment
- `docs/configuration.md` - Added 2016 documentation with EOL warning
- `docs/download-iso.md` - Added complete 2016 download section
- `scripts/download-windows-iso.sh` - Added 2016 URL and size
- `scripts/repack-unattended-iso.sh` - Parametrized version, image index logic

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

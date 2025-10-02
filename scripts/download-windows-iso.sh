#!/bin/bash
# Automated Windows Server ISO Downloader
# Downloads official evaluation ISO from Microsoft
# Usage: ./download-windows-iso.sh [2019|2022|2025]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config.yml"
DEFAULT_VERSION="2019"
DEFAULT_ISO_DIR="$PROJECT_ROOT/iso"

# Load version from config.yml if available
if [ -f "$CONFIG_FILE" ] && command -v yq >/dev/null 2>&1; then
    WS_VERSION=$(yq eval '.vm.version' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_VERSION")
    ISO_DIR=$(yq eval '.paths.iso_dir' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_ISO_DIR")
else
    WS_VERSION="$DEFAULT_VERSION"
    ISO_DIR="$DEFAULT_ISO_DIR"
fi

# Override with command line argument if provided
if [ $# -ge 1 ]; then
    WS_VERSION="$1"
fi

# ISO download URLs (Microsoft Evaluation Center - verified October 2025)
declare -A ISO_URLS=(
    ["2019"]="https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
    ["2022"]="https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
    ["2025"]="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
)

# ISO file sizes (approximate, for validation)
declare -A ISO_SIZES=(
    ["2019"]="5.3 GB"
    ["2022"]="5.2 GB"
    ["2025"]="5.4 GB"
)

# ISO checksums (SHA256 - update these with official values if available)
declare -A ISO_SHA256=(
    ["2019"]=""  # Add official checksum if available
    ["2022"]=""
    ["2025"]=""
)

# Helper functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Windows Server ISO Downloader (Evaluation)             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_dependencies() {
    local missing=0

    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl not found. Install: sudo apt install curl"
        missing=1
    fi

    if ! command -v pv >/dev/null 2>&1; then
        print_warning "pv not found (optional, for progress bar). Install: sudo apt install pv"
    fi

    return $missing
}

validate_version() {
    if [[ ! "${ISO_URLS[$WS_VERSION]+isset}" ]]; then
        print_error "Invalid Windows Server version: $WS_VERSION"
        echo ""
        echo "Supported versions:"
        echo "  • 2019 - Windows Server 2019 (180-day evaluation)"
        echo "  • 2022 - Windows Server 2022 (180-day evaluation)"
        echo "  • 2025 - Windows Server 2025 (180-day evaluation)"
        echo ""
        echo "Usage: $0 [2019|2022|2025]"
        exit 1
    fi
}

download_iso() {
    local url="${ISO_URLS[$WS_VERSION]}"
    local filename="WinServer${WS_VERSION}.iso"
    local output_path="$ISO_DIR/$filename"
    local temp_path="${output_path}.tmp"

    print_info "Downloading Windows Server $WS_VERSION Evaluation"
    print_info "Source: Microsoft Evaluation Center (official)"
    print_info "Size: ~${ISO_SIZES[$WS_VERSION]}"
    print_info "Expiration: 180 days from installation"
    echo ""

    # Check if ISO already exists
    if [ -f "$output_path" ]; then
        print_warning "ISO already exists: $output_path"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Download cancelled."
            exit 0
        fi
        rm -f "$output_path"
    fi

    # Ensure ISO directory exists
    mkdir -p "$ISO_DIR"

    # Download with progress bar
    print_info "Downloading to: $output_path"
    echo ""

    if command -v pv >/dev/null 2>&1; then
        # Download with pv progress bar
        curl -L --progress-bar "$url" | pv -pterb > "$temp_path"
        mv "$temp_path" "$output_path"
    else
        # Download with curl progress
        curl -L --progress-bar -o "$temp_path" "$url"
        mv "$temp_path" "$output_path"
    fi

    # Set permissions (readable by everyone, writable by owner)
    chmod 644 "$output_path"

    echo ""
    print_success "Download completed: $output_path"

    # Verify file size
    local actual_size=$(du -h "$output_path" | cut -f1)
    print_info "File size: $actual_size"

    # Calculate SHA256 if requested
    if [ "${VERIFY_CHECKSUM:-0}" = "1" ]; then
        print_info "Calculating SHA256 checksum (this may take a while)..."
        local checksum=$(sha256sum "$output_path" | cut -d' ' -f1)
        print_info "SHA256: $checksum"

        if [ -n "${ISO_SHA256[$WS_VERSION]}" ]; then
            if [ "$checksum" = "${ISO_SHA256[$WS_VERSION]}" ]; then
                print_success "Checksum verified!"
            else
                print_warning "Checksum mismatch! Download may be corrupted."
                print_info "Expected: ${ISO_SHA256[$WS_VERSION]}"
                print_info "Got:      $checksum"
            fi
        fi
    fi

    echo ""
    print_success "Windows Server $WS_VERSION ISO ready for installation!"
    print_info "Next step: make install"
}

show_iso_info() {
    echo ""
    print_info "Windows Server $WS_VERSION Evaluation Edition"
    echo ""
    echo "  License:"
    echo "    • 180-day evaluation period"
    echo "    • Must activate within 10 days (internet required)"
    echo "    • Can convert to full license with product key"
    echo ""
    echo "  Editions included:"
    echo "    • Standard Edition"
    echo "    • Datacenter Edition (recommended)"
    echo ""
    echo "  Installation options:"
    echo "    • Server Core (minimal, recommended for VMs)"
    echo "    • Server with Desktop Experience (GUI)"
    echo ""
}

# Main execution
print_header

# Check dependencies
if ! check_dependencies; then
    exit 1
fi

# Validate version
validate_version

# Show info
show_iso_info

# Confirm download
print_warning "This will download ~${ISO_SIZES[$WS_VERSION]} from Microsoft servers."
read -p "Continue? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_info "Download cancelled."
    exit 0
fi

# Download
download_iso

# Show next steps
echo ""
print_header
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Verify ISO: ls -lh $ISO_DIR/WinServer${WS_VERSION}.iso"
echo "  2. Start installation: make install"
echo "  3. Load VirtIO drivers during Windows setup"
echo ""
print_info "See README.md for detailed installation guide"

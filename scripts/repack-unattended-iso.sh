#!/bin/bash
# Repack Windows Server ISO with autounattend.xml for fully automated installation
# Usage: ./scripts/repack-unattended-iso.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO_DIR="$PROJECT_ROOT/iso"
ORIGINAL_ISO="$ISO_DIR/WinServer2019.iso"
OUTPUT_ISO="$ISO_DIR/WinServer2019_Unattended.iso"
AUTOUNATTEND_XML="$PROJECT_ROOT/Autounattend.xml"

# Temporary directories for mounting and building
MOUNT_DIR="$PROJECT_ROOT/.tmp/winiso_mount"
ADDONS_DIR="$PROJECT_ROOT/.tmp/winiso_addons"

echo "🔧 Repackaging Windows Server ISO with autounattend.xml..."
echo "=================================================="

# Check prerequisites
if [ ! -f "$ORIGINAL_ISO" ]; then
    echo "❌ Original ISO not found: $ORIGINAL_ISO"
    echo "   Run: make download-ws-iso"
    exit 1
fi

if [ ! -f "$AUTOUNATTEND_XML" ]; then
    echo "❌ autounattend.xml not found: $AUTOUNATTEND_XML"
    exit 1
fi

if ! command -v xorriso &> /dev/null; then
    echo "❌ xorriso not installed"
    echo "   Run: sudo apt install -y xorriso"
    exit 1
fi

# Cleanup old temporary directories
sudo umount "$MOUNT_DIR" 2>/dev/null || true
sudo rm -rf "$PROJECT_ROOT/.tmp"
mkdir -p "$MOUNT_DIR" "$ADDONS_DIR"

# Mount original ISO
echo "📀 Mounting original ISO..."
sudo mount -o loop "$ORIGINAL_ISO" "$MOUNT_DIR"

# Copy autounattend.xml to addons directory
echo "📝 Copying autounattend.xml..."
cp "$AUTOUNATTEND_XML" "$ADDONS_DIR/"

# Copy ISO contents to build directory for modification
BUILD_DIR="$PROJECT_ROOT/.tmp/winiso_build"
mkdir -p "$BUILD_DIR"
echo "📦 Copying ISO contents..."
cp -r "$MOUNT_DIR"/* "$BUILD_DIR/"

# Make all files writable
chmod -R u+w "$BUILD_DIR"

# Remove any existing autounattend.xml files (case-insensitive) and add new ones
echo "🗑️  Removing existing autounattend files..."
rm -f "$BUILD_DIR"/[Aa]utounattend.xml "$BUILD_DIR"/sources/[Aa]utounattend.xml 2>/dev/null || true

# Copy Autounattend.xml to ISO root AND sources/ directory (UEFI boot requirement)
# CRITICAL: Filename MUST be exactly "Autounattend.xml" (capital A) for Windows Setup to detect it
echo "📝 Adding Autounattend.xml to ISO root and sources/ directory..."
install -m 644 "$AUTOUNATTEND_XML" "$BUILD_DIR/Autounattend.xml"
install -m 644 "$AUTOUNATTEND_XML" "$BUILD_DIR/sources/Autounattend.xml"

# Verify files were created correctly
echo "🔍 Verifying Autounattend.xml placement..."
if [ ! -f "$BUILD_DIR/Autounattend.xml" ]; then
    echo "❌ ERROR: Autounattend.xml missing in ISO root"
    exit 1
fi
if [ ! -f "$BUILD_DIR/sources/Autounattend.xml" ]; then
    echo "❌ ERROR: Autounattend.xml missing in sources/"
    exit 1
fi
echo "✅ Autounattend.xml correctly placed in both locations"

# Create new bootable ISO with xorriso
# Use graft-points to explicitly control filenames (especially case-sensitivity)
echo "🔨 Creating unattended ISO with xorriso..."
cd "$BUILD_DIR"
xorriso -as mkisofs \
    -iso-level 4 \
    -rock \
    -disable-deep-relocation \
    -untranslated-filenames \
    -graft-points \
    -b boot/etfsboot.com \
    -no-emul-boot \
    -boot-load-size 8 \
    -eltorito-alt-boot \
    -eltorito-platform efi \
    -b efi/microsoft/boot/efisys_noprompt.bin \
    -no-emul-boot \
    -V "CCCOMA_X64FRE_EN-US_DV9" \
    -o "$OUTPUT_ISO" \
    -path-list <(find . -type f -o -type d | sed 's|^\./||' | grep -v "^autounattend.xml$" | awk '{print $0"="$0}') \
    Autounattend.xml=Autounattend.xml \
    sources/Autounattend.xml=sources/Autounattend.xml \
    2>&1 | grep -E "(UPDATE|WARNING|ERROR)" || true

cd "$PROJECT_ROOT"

# Cleanup
echo "🧹 Cleaning up..."
sudo umount "$MOUNT_DIR"
rm -rf "$PROJECT_ROOT/.tmp"

# Verify output
if [ -f "$OUTPUT_ISO" ]; then
    SIZE=$(du -h "$OUTPUT_ISO" | cut -f1)
    echo ""
    echo "✅ Unattended ISO created successfully!"
    echo "   Location: $OUTPUT_ISO"
    echo "   Size: $SIZE"
    echo ""
    echo "📝 Features:"
    echo "   • Fully automated installation (no user interaction)"
    echo "   • VirtIO drivers pre-configured"
    echo "   • Administrator password: Admin123!Password"
    echo "   • Computer name: WINLAB"
    echo "   • RDP enabled"
    echo ""
    echo "Next: Run 'make install' to start VM installation"
else
    echo "❌ Failed to create unattended ISO"
    exit 1
fi

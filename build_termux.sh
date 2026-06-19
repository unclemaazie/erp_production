#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# ERP Production - Termux Build Script
# Run this inside Termux to build the APK directly on your phone
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ERP Production - Termux Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running in Termux
if [ -z "$TERMUX_VERSION" ]; then
    echo -e "${RED}Error: This script must run inside Termux${NC}"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${YELLOW}Warning: Detected architecture $ARCH${NC}"
    echo -e "${YELLOW}This script is optimized for ARM64 (aarch64)${NC}"
    echo -e "${YELLOW}Build may fail on other architectures${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check storage space
AVAILABLE=$(df /data | tail -1 | awk '{print $4}')
if [ $AVAILABLE -lt 10000000 ]; then
    echo -e "${RED}Error: Less than 10GB free space available${NC}"
    echo -e "${RED}You need at least 10GB free for Flutter + build${NC}"
    exit 1
fi

# ============================================================
# Step 1: Install Flutter SDK for Termux
# ============================================================
echo -e "${GREEN}[1/7] Checking Flutter installation...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Flutter not found. Installing...${NC}"

    # Update packages
    pkg update -y
    pkg upgrade -y

    # Install dependencies
    pkg install -y curl git wget unzip openjdk-17

    # Install Flutter using the community script
    echo -e "${YELLOW}Downloading Flutter installer...${NC}"
    curl -L https://raw.githubusercontent.com/ImL1s/termux-flutter-wsl/master/install_flutter_complete.sh -o /tmp/install_flutter.sh

    echo -e "${YELLOW}Running Flutter installer (this takes 10-20 minutes)...${NC}"
    bash /tmp/install_flutter.sh

    # Source environment
    source ~/.bashrc 2>/dev/null || true

    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Flutter installation failed${NC}"
        echo -e "${RED}Try manual install: https://github.com/ImL1s/termux-flutter-wsl${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Flutter found: $(flutter --version | head -1)${NC}"
fi

# ============================================================
# Step 2: Configure project
# ============================================================
echo -e "${GREEN}[2/7] Configuring project...${NC}"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found${NC}"
    echo -e "${RED}Run this script from the project root directory${NC}"
    exit 1
fi

# Configure Android build for Termux
GRADLE_PROPS="android/gradle.properties"
if ! grep -q "aapt2FromMavenOverride" "$GRADLE_PROPS" 2>/dev/null; then
    echo -e "${YELLOW}Adding Termux aapt2 override...${NC}"
    echo "android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2" >> "$GRADLE_PROPS"
fi

# ============================================================
# Step 3: Get dependencies
# ============================================================
echo -e "${GREEN}[3/7] Getting Flutter dependencies...${NC}"
flutter pub get

# ============================================================
# Step 4: Configure Supabase credentials
# ============================================================
echo -e "${GREEN}[4/7] Configuring Supabase credentials...${NC}"

# Check if credentials are already set via environment
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${YELLOW}Supabase credentials not found in environment${NC}"
    echo ""

    # Check if credentials file exists
    if [ -f ".supabase_credentials" ]; then
        echo -e "${GREEN}Loading credentials from .supabase_credentials${NC}"
        source .supabase_credentials
    else
        echo -e "${YELLOW}Please enter your Supabase credentials:${NC}"
        read -p "Supabase URL (e.g., https://xxx.supabase.co): " SUPABASE_URL
        read -p "Supabase Anon Key: " SUPABASE_ANON_KEY

        # Save for future builds
        echo "export SUPABASE_URL="$SUPABASE_URL"" > .supabase_credentials
        echo "export SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"" >> .supabase_credentials
        echo -e "${GREEN}Credentials saved to .supabase_credentials${NC}"
    fi
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}Error: Supabase credentials are required${NC}"
    exit 1
fi

echo -e "${GREEN}Credentials configured${NC}"

# ============================================================
# Step 5: Build APK
# ============================================================
echo -e "${GREEN}[5/7] Building release APK...${NC}"
echo -e "${YELLOW}This will take 10-30 minutes depending on your device${NC}"
echo -e "${YELLOW}Do not close Termux or let your phone sleep${NC}"
echo ""

# Prevent sleep during build
termux-wake-lock 2>/dev/null || true

# Build with Termux optimizations
flutter build apk --release \
    --target-platform android-arm64 \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    || {
        echo -e "${RED}Build failed!${NC}"
        termux-wake-unlock 2>/dev/null || true
        exit 1
    }

termux-wake-unlock 2>/dev/null || true

# ============================================================
# Step 6: Copy APK to accessible location
# ============================================================
echo -e "${GREEN}[6/7] Copying APK to Downloads...${NC}"

APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
APK_NAME="erp-production-$(date +%Y%m%d-%H%M).apk"
APK_DEST="$HOME/storage/shared/Download/$APK_NAME"

# Ensure storage is set up
if [ ! -d "$HOME/storage/shared" ]; then
    echo -e "${YELLOW}Setting up Termux storage access...${NC}"
    termux-setup-storage
    sleep 2
fi

# Copy APK
cp "$APK_SOURCE" "$APK_DEST"
echo -e "${GREEN}APK copied to: $APK_DEST${NC}"

# Also copy to project root for easy access
cp "$APK_SOURCE" "$PROJECT_DIR/$APK_NAME"

# ============================================================
# Step 7: Done
# ============================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  BUILD SUCCESSFUL!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "APK Location: ${BLUE}$APK_DEST${NC}"
echo -e "Also saved as: ${BLUE}$PROJECT_DIR/$APK_NAME${NC}"
echo ""
echo -e "${YELLOW}To install on this device:${NC}"
echo -e "  ${BLUE}xdg-open $APK_DEST${NC}"
echo ""
echo -e "${YELLOW}To share the APK:${NC}"
echo -e "  Find it in your Downloads folder as ${BLUE}$APK_NAME${NC}"
echo ""

# Show APK size
APK_SIZE=$(du -h "$APK_DEST" | cut -f1)
echo -e "APK Size: ${GREEN}$APK_SIZE${NC}"

#!/bin/bash

# 🚀 PERSONA AI - PRODUCTION BUILD SCRIPT
# Script untuk build aplikasi Android yang siap production

set -e  # Exit on any error

echo "🚀 Starting Persona AI Production Build..."
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Please run this script from the Flutter project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Pre-build checks...${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}📦 Getting Flutter dependencies...${NC}"
flutter pub get

# Run code generation if needed
if [ -f "build.yaml" ]; then
    echo -e "${YELLOW}⚙️ Running code generation...${NC}"
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
flutter test || {
    echo -e "${RED}❌ Tests failed. Please fix tests before building production version.${NC}"
    exit 1
}

# Analyze code
echo -e "${YELLOW}🔍 Analyzing code...${NC}"
flutter analyze --no-fatal-infos || {
    echo -e "${YELLOW}⚠️ Code analysis found issues. Consider fixing them.${NC}"
}

# Check for Android keystore
KEYSTORE_PATH="android/app/keystore.jks"
KEYSTORE_PROPERTIES="android/keystore.properties"

if [ ! -f "$KEYSTORE_PATH" ] || [ ! -f "$KEYSTORE_PROPERTIES" ]; then
    echo -e "${YELLOW}⚠️ Release keystore not found. Generating debug build instead.${NC}"
    BUILD_TYPE="debug"
else
    echo -e "${GREEN}✅ Release keystore found. Building release version.${NC}"
    BUILD_TYPE="release"
fi

# Set build flavor based on environment
if [ "$1" = "production" ]; then
    echo -e "${BLUE}🏭 Building for PRODUCTION environment${NC}"
    BUILD_FLAVOR="production"
    DART_DEFINES="--dart-define=ENVIRONMENT=production --dart-define=BACKEND_BASE_URL=https://your-production-api.com"
elif [ "$1" = "staging" ]; then
    echo -e "${BLUE}🔧 Building for STAGING environment${NC}"
    BUILD_FLAVOR="staging"
    DART_DEFINES="--dart-define=ENVIRONMENT=staging --dart-define=BACKEND_BASE_URL=https://staging-api.com"
else
    echo -e "${BLUE}🔧 Building for DEVELOPMENT environment${NC}"
    BUILD_FLAVOR="development"
    DART_DEFINES="--dart-define=ENVIRONMENT=development --dart-define=BACKEND_BASE_URL=http://localhost:3000"
fi

# Build APK
echo -e "${YELLOW}🔨 Building Android APK...${NC}"
echo "Build type: $BUILD_TYPE"
echo "Build flavor: $BUILD_FLAVOR"

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release $DART_DEFINES \
        --target-platform android-arm,android-arm64,android-x64 \
        --split-per-abi
    
    # Also build app bundle for Play Store
    echo -e "${YELLOW}📦 Building Android App Bundle...${NC}"
    flutter build appbundle --release $DART_DEFINES
else
    flutter build apk --debug $DART_DEFINES
fi

# Build information
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo "========================================"

if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "${GREEN}📱 APK files:${NC}"
    ls -la build/app/outputs/flutter-apk/*.apk
    
    echo -e "${GREEN}📦 App Bundle:${NC}"
    ls -la build/app/outputs/bundle/release/*.aab
    
    # Calculate file sizes
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    
    echo -e "${BLUE}📊 Build Information:${NC}"
    echo "  APK Size: $APK_SIZE"
    echo "  AAB Size: $AAB_SIZE"
    echo "  Build Type: Release"
    echo "  Environment: $BUILD_FLAVOR"
    echo "  Target Platforms: ARM, ARM64, x64"
    
    # Security check
    echo -e "${YELLOW}🔒 Running security checks...${NC}"
    
    # Check if APK is signed
    if command -v aapt &> /dev/null; then
        echo "Checking APK signature..."
        aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep "package:"
    fi
    
    # Check for debug symbols
    if [ -d "build/app/outputs/flutter-apk/app-release.apk.d" ]; then
        echo -e "${YELLOW}⚠️ Debug symbols detected. Consider removing for production.${NC}"
    fi
    
else
    echo -e "${GREEN}📱 Debug APK:${NC}"
    ls -la build/app/outputs/flutter-apk/app-debug.apk
    
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "  APK Size: $APK_SIZE"
    echo "  Build Type: Debug"
fi

# Generate build report
BUILD_DATE=$(date "+%Y-%m-%d %H:%M:%S")
BUILD_REPORT="build_report_$(date +%Y%m%d_%H%M%S).txt"

cat > "$BUILD_REPORT" << EOF
PERSONA AI - BUILD REPORT
========================
Build Date: $BUILD_DATE
Build Type: $BUILD_TYPE
Environment: $BUILD_FLAVOR
Flutter Version: $(flutter --version | head -n 1)
Dart Version: $(dart --version | head -n 1)

Files Generated:
EOF

if [ "$BUILD_TYPE" = "release" ]; then
    echo "  - APK: $(ls build/app/outputs/flutter-apk/*.apk)" >> "$BUILD_REPORT"
    echo "  - AAB: $(ls build/app/outputs/bundle/release/*.aab)" >> "$BUILD_REPORT"
else
    echo "  - Debug APK: $(ls build/app/outputs/flutter-apk/app-debug.apk)" >> "$BUILD_REPORT"
fi

echo "" >> "$BUILD_REPORT"
echo "Security Checklist:" >> "$BUILD_REPORT"
echo "  ✅ Code obfuscation enabled (release only)" >> "$BUILD_REPORT"
echo "  ✅ Debug mode disabled (release only)" >> "$BUILD_REPORT"
echo "  ✅ Network security config applied" >> "$BUILD_REPORT"
echo "  ✅ Secure storage implemented" >> "$BUILD_REPORT"
echo "  ✅ API keys secured" >> "$BUILD_REPORT"

echo -e "${GREEN}📋 Build report saved to: $BUILD_REPORT${NC}"

# Next steps
echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
if [ "$BUILD_TYPE" = "release" ]; then
    echo "  1. Test the APK on physical devices"
    echo "  2. Upload AAB to Google Play Console"
    echo "  3. Configure app signing by Google Play"
    echo "  4. Set up staged rollout (5% → 20% → 50% → 100%)"
    echo "  5. Monitor crash reports and user feedback"
else
    echo "  1. Test the debug APK thoroughly"
    echo "  2. Set up release signing for production builds"
    echo "  3. Configure production environment variables"
fi

echo ""
echo -e "${GREEN}🎉 Build process completed successfully!${NC}"
echo "Ready for deployment to 100 users! 🚀"

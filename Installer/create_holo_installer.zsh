#!/usr/bin/env zsh
set -euo pipefail

# Creates installer for different channel versions.
# Run this script from the local BlackHole repo's root directory.
# If this script is not executable from the Terminal, 
# it may need execute permissions first by running this command:
#   chmod +x create_installer.sh

driverName="HOLOPHONIX Virtual Soundcard"
devTeamID="FLPYMFKWA9" # ⚠️ Replace this with your own developer team ID
notarize=true # To skip notarization, set this to false
notarizeProfile="AppleDev_Notarize_Amadeus" # ⚠️ Replace this with your own notarytool keychain profile name

# CFPlugIn factory UUID per variant — CoreFoundation registers factories globally
# by UUID, so each must differ from the others and from upstream's e395c745…
# Fixed, not generated, so the same commit always produces the same bundle.
typeset -A factoryUUIDs=(
  16  47bfd44c-1c48-49f3-b06a-2b828447d8e2
  32  1117ce82-10e1-47ff-9f56-2917d417657f
  64  b93546b0-7789-4d87-8104-b83470061aed
  128 302ee2c0-5c23-47cb-9c96-0cabbb8ecad3
)

############################################################################

# Basic Validation
if [ ! -d BlackHole.xcodeproj ]; then
    echo "This script must be run from the BlackHole repo root folder."
    echo "For example:"
    echo "  cd /path/to/BlackHole"
    echo "  ./Installer/create_installer.sh"
    exit 1
fi

# Package version: a plain number macOS Installer can compare, so it can tell an
# upgrade from a reinstall. Kept in lockstep with upstream via the VERSION file.
pkgVersion=$(cat VERSION)
if [ -z "$pkgVersion" ]; then
    echo "VERSION file is missing or empty; cannot version the packages."
    exit 1
fi

# The package filename embeds the commit hash, so a dirty tree would produce an
# artifact whose stamp does not describe its contents. ALLOW_DIRTY=1 to override.
if [ -z "${ALLOW_DIRTY:-}" ] && [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is dirty; the version stamp would not match the source."
    echo "Commit or stash first, or re-run with ALLOW_DIRTY=1 for a throwaway build."
    exit 1
fi

rm -rf Installer/drivers
rm -rf Installer/packages

mkdir -p Installer/drivers
mkdir -p Installer/uscripts

version=$(git describe --tags --abbrev=0)_$(git rev-parse --short HEAD)_$(date "+%Y-%m-%d")_x86_64-arm64

# Create individual packages for each number of channels
for channels in 16 32 64 128
do
    # Env
    ch=$channels"ch"
    bundleID="com.amadeus.holophonix.vs$ch"
    bundleIDu="com.amadeus.holophonix.uvs$ch"

    # Build Xcode Project
    xcodebuild \
    -project BlackHole.xcodeproj \
    -configuration Release \
    -target BlackHole CONFIGURATION_BUILD_DIR=build \
    PRODUCT_BUNDLE_IDENTIFIER=$bundleID \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    MACOSX_DEPLOYMENT_TARGET=10.13 \
    GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS kNumber_Of_Channels='$channels' kPlugIn_BundleID=\"'$bundleID'\" kDriver_Name=\"HOLOPHONIX\ Virtual\ Soundcard\" kPlugIn_Icon=\"HOLOPHONIX\ Virtual\ Soundcard.icns\" kManufacturer_Name=\"HOLOPHONIX\"'

    # Both bundle-ID sources must agree: from v0.7.1 the driver looks itself up by
    # kPlugIn_BundleID, and a mismatch with CFBundleIdentifier crashes coreaudiod.
    builtID=$(plutil -extract CFBundleIdentifier raw build/BlackHole.driver/Contents/Info.plist)
    binStrings=$(strings build/BlackHole.driver/Contents/MacOS/BlackHole)
    if [ "$builtID" != "$bundleID" ] || ! grep -qx "$bundleID" <<< "$binStrings"; then
        echo "Bundle ID mismatch for $ch: Info.plist has '$builtID', expected '$bundleID'"
        echo "(and kPlugIn_BundleID must carry the same value)."
        exit 1
    fi

    # Stamp this variant's fixed CFPlugIn factory UUID
    uuid=${factoryUUIDs[$channels]:-}
    if [ -z "$uuid" ]; then
        echo "No factory UUID defined for ${channels}ch — add one to factoryUUIDs."
        exit 1
    fi
    awk '{sub(/e395c745-4eea-4d94-bb92-46224221047c/,"'$uuid'")}1' build/BlackHole.driver/Contents/Info.plist > Temp.plist
    mv Temp.plist build/BlackHole.driver/Contents/Info.plist

    # Move driver
    mv build/BlackHole.driver "Installer/drivers/$driverName $ch.driver"

    # Sign driver
    codesign --force --options runtime --sign $devTeamID "Installer/drivers/$driverName $ch.driver"

    # Check install scripts permissions
    chmod 755 Installer/holo-scripts/preinstall
    chmod 755 Installer/holo-scripts/postinstall

    # Create installer package with pkgbuild
    pkgbuild --sign $devTeamID --identifier $bundleID --version $pkgVersion --component "Installer/drivers/$driverName $ch.driver" --scripts Installer/holo-scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/HOLOPHONIX_Virtual_Soundcard-$ch.pkg

    # Create uninstall script
    echo "#!/bin/bash
    file=\"/Library/Audio/Plug-Ins/HAL/$driverName $ch.driver\"
    if [ -d \"\$file\" ] ; then
        sudo rm -R "\"\$file\""
    fi
    sleep 0.1
    sudo killall -9 coreaudiod || true" > Installer/uscripts/postinstall

    # Check uninstall scripts permissions
    chmod 755 Installer/uscripts/postinstall

    # Create uninstaller package with pkgbuild
    pkgbuild --nopayload --sign $devTeamID --identifier $bundleIDu --version $pkgVersion --scripts Installer/uscripts Installer/uninstall_HOLOPHONIX_Virtual_Soundcard-$ch.pkg

done

rm -r Installer/drivers

cd Installer

# Substitute the package version into the distribution template
sed "s/__VERSION__/$pkgVersion/g" distribution.orig.xml > distribution.xml

# Build & sign combined package
productbuild --sign $devTeamID --distribution distribution.xml --resources . HOLOPHONIX_Virtual_Soundcard.$version.pkg


# Notarize and Staple
if [ "$notarize" = true ]; then
    xcrun notarytool submit HOLOPHONIX_Virtual_Soundcard.$version.pkg --team-id $devTeamID --progress --wait --keychain-profile $notarizeProfile
    # Staple
    xcrun stapler staple HOLOPHONIX_Virtual_Soundcard.$version.pkg
fi

# Remove script created files
rm -r uscripts
rm distribution.xml
#rm HOLOPHONIX_Virtual_Soundcard-*
#rm uninstall_HOLOPHONIX_Virtual_Soundcard-*
# OR move to folders
mkdir ./packages
mv HOLOPHONIX_Virtual_Soundcard-* ./packages
mv uninstall_HOLOPHONIX_Virtual_Soundcard-* ./packages

cd ..

# Remove build files
rm -r build
rm -r DerivedData

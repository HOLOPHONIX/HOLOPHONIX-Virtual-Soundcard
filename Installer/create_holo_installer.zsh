#!/usr/bin/env zsh

# Creates installer for different channel versions.
# Run this script from the local BlackHole repo's root directory.
# If this script is not executable from the Terminal, 
# it may need execute permissions first by running this command:
#   chmod +x create_installer.sh

devTeamID="FLPYMFKWA9" # ⚠️ Replace this with your own developer team ID
notarize=false # To skip notarization, set this to false
notarizeProfile="AppleDev_Notarize_Amadeus" # ⚠️ Replace this with your own notarytool keychain profile name

############################################################################

# Basic Validation
if [ ! -d BlackHole.xcodeproj ]; then
    echo "This script must be run from the BlackHole repo root folder."
    echo "For example:"
    echo "  cd /path/to/BlackHole"
    echo "  ./Installer/create_installer.sh"
    exit 1
fi

rm -r Installer/drivers
rm -r Installer/packages

mkdir Installer/drivers
mkdir Installer/uscripts

version=$(git describe --tags --abbrev=0)_$(git rev-parse --short HEAD)_$(date "+%Y-%m-%d")_x86_64-arm64

# Create individual packages for each number of channels
for channels in 16 64 128
do
    # Env
    ch=$channels"ch"
    bundleID="com.amadeus.holophonix.vs$ch"
    bundleIDu="com.amadeus.holophonix.uvs$ch"
    driverName="HOLOPHONIX\ Virtual\ Soundcard"
    iconFile="HOLOPHONIX\ Virtual\ Soundcard.icns"

    # Build Xcode Project
    xcodebuild \
    -project BlackHole.xcodeproj \
    -configuration Release \
    -target BlackHole CONFIGURATION_BUILD_DIR=build \
    PRODUCT_BUNDLE_IDENTIFIER=$bundleID \
    GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS kNumber_Of_Channels='$channels' kPlugIn_BundleID=\"'$bundleID'\" kDriver_Name=\"'$driverName'\" kPlugIn_Icon=\"'$iconFile'\"'

    # Generate a new UUID
    uuid=$(uuidgen)
    awk '{sub(/e395c745-4eea-4d94-bb92-46224221047c/,"'$uuid'")}1' build/BlackHole.driver/Contents/Info.plist > Temp.plist
    mv Temp.plist build/BlackHole.driver/Contents/Info.plist

    # Move driver
    mv build/BlackHole.driver "Installer/drivers/$driverName $ch.driver"

    # Sign driver
    codesign --force --deep --options runtime --sign $devTeamID "Installer/drivers/$driverName $ch.driver"

    # Check install scripts permissions
    chmod 755 Installer/Scripts/preinstall
    chmod 755 Installer/Scripts/postinstall

    # Create installer package with pkgbuild
    pkgbuild --sign $devTeamID --identifier $bundleID --component "Installer/drivers/$driverName $ch.driver" --scripts Installer/scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/HOLOPHONIX_Virtual_Soundcard-$ch.pkg

    # Create uninstall script
    echo "#!/bin/bash
    file=\"/Library/Audio/Plug-Ins/HAL/$driverName $ch.driver\"
    if [ -d \"\$file\" ]
        then
        sudo rm -R "\"\$file\""
    fi
    if [[ \$(sw_vers -productVersion) == \"10.9\" ]] 
        then
            sudo killall coreaudiod
        else 
            sudo launchctl kickstart -k system/com.apple.audio.coreaudiod
    fi
    exit 0" > Installer/uscripts/postinstall

    # Check uninstall scripts permissions
    chmod 755 Installer/uscripts/postinstall

    # Create uninstaller package with pkgbuild
    pkgbuild --nopayload --sign $devTeamID --identifier $bundleIDu --scripts Installer/uscripts Installer/uninstall_HOLOPHONIX_Virtual_Soundcard-$ch.pkg

done

rm -r Installer/drivers

cp LICENSE ./Installer/
cd Installer

# Build & sign combined package
productbuild --sign $devTeamID --distribution distribution.orig.xml --resources . HOLOPHONIX_Virtual_Soundcard.$version.pkg


# Notarize and Staple
if [ "$notarize" = true ]; then
    xcrun notarytool submit HOLOPHONIX_Virtual_Soundcard.$version.pkg --team-id $devTeamID --progress --wait --keychain-profile $notarizeProfile
    # Staple
    xcrun stapler staple HOLOPHONIX_Virtual_Soundcard.$version.pkg
fi

# Remove script created files
rm -r uscripts
rm LICENSE
rm HOLOPHONIX_Virtual_Soundcard-*
rm uninstall_HOLOPHONIX_Virtual_Soundcard-*
# OR move to folders
#mkdir ./packages
#mv HOLOPHONIX_Virtual_Soundcard-* ./packages
#v uninstall_HOLOPHONIX_Virtual_Soundcard-* ./packages

cd ..

# Remove build files
rm -r build
rm -r DerivedData

#!/usr/bin/env zsh

# create installer & uninstaller for different channel versions

rm -r Installer/drivers
rm -r Installer/packages

mkdir Installer/drivers
mkdir Installer/uscripts

version=$(head -n 1 VERSION)_$(git rev-parse --short HEAD)_$(date "+%Y-%m-%d")_x86_64-arm64

# Create individual packages for each number of channels
for channels in 16 64 128
do

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

    # Move driver
    mv build/BlackHole.driver "Installer/drivers/HOLOPHONIX Virtual Soundcard $ch.driver"

    # Sign driver
    codesign --force --deep --options runtime --sign FLPYMFKWA9 "Installer/drivers/HOLOPHONIX Virtual Soundcard $ch.driver"

    # Check install scripts permissions
    chmod 755 Installer/Scripts/preinstall
    chmod 755 Installer/Scripts/postinstall

    # Create installer package with pkgbuild
    pkgbuild --sign "FLPYMFKWA9" --identifier $bundleID --component "Installer/drivers/HOLOPHONIX Virtual Soundcard $ch.driver" --scripts Installer/scripts --install-location /Library/Audio/Plug-Ins/HAL Installer/HOLOPHONIX_Virtual_Soundcard-$ch.pkg

    # Create uninstall script
    echo "#!/bin/bash
    file=\"/Library/Audio/Plug-Ins/HAL/HOLOPHONIX Virtual Soundcard $ch.driver\"
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
    pkgbuild --nopayload --sign "FLPYMFKWA9" --identifier $bundleIDu --scripts Installer/uscripts Installer/uninstall_HOLOPHONIX_Virtual_Soundcard-$ch.pkg

done

rm -r Installer/drivers

cp LICENSE ./Installer/
cd Installer

# Build & sign combined package
productbuild --sign "FLPYMFKWA9" --distribution distribution.orig.xml --resources . HOLOPHONIX_Virtual_Soundcard.$version.pkg


# Notarize
#xcrun notarytool submit HOLOPHONIX_Virtual_Soundcard_$ch.$version.pkg --team-id Q5C99V536K --progress --wait --keychain-profile "Notarize"
#xcrun notarytool submit HOLOPHONIX_Virtual_Soundcard.$version.pkg --team-id FLPYMFKWA9 --progress --wait --keychain-profile "AppleDev_Notarize_Amadeus"
# Staple
#xcrun stapler staple HOLOPHONIX_Virtual_Soundcard.$version.pkg

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

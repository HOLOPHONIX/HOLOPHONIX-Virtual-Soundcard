<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/HOLOPHONIX%20Virtual%20Soundcard%20v2_White.png">
  <img src="Images/HOLOPHONIX%20Virtual%20Soundcard%20v2_Black.png" alt="HOLOPHONIX Virtual Soundcard" width="620">
</picture>

# HOLOPHONIX Virtual Soundcard

![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Architecture: Intel + Apple Silicon](https://img.shields.io/badge/arch-x86__64%20%7C%20arm64-blue)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)

**HOLOPHONIX Virtual Soundcard** is a free macOS virtual audio driver that routes audio
between applications on the same Mac with zero additional latency. Audio sent to its
output channels is immediately available on its input channels, so any application can
feed any other — a DAW into HOLOPHONIX Native, a media player into a recorder, a game
engine into a spatialisation engine.

It is distributed free of charge as part of the [HOLOPHONIX](https://holophonix.xyz)
ecosystem.

### [⬇ Download the installer](https://holophonix.xyz/en/support/downloads)

> **This project is a modified version of [BlackHole](https://github.com/ExistentialAudio/BlackHole),
> © 2019–2026 Existential Audio Inc., used under the GNU General Public License v3.0.**
> The driver core is Existential Audio's work; HOLOPHONIX Virtual Soundcard changes only
> the branding, the channel-count variants and the installer. See
> [Relationship to BlackHole](#relationship-to-blackhole) for the exact list of changes.
> "BlackHole" and the BlackHole logo are trademarks of Existential Audio Inc. and are used
> here only to identify the upstream project. This is not an official BlackHole build and
> is not supported by Existential Audio.

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Uninstallation](#uninstallation)
- [Usage](#usage)
- [Relationship to BlackHole](#relationship-to-blackhole)
- [Building from Source](#building-from-source)
- [FAQ](#faq)
- [Support](#support)
- [Licence and Source Availability](#licence-and-source-availability)
- [The HOLOPHONIX Ecosystem](#the-holophonix-ecosystem)

---

## Features

- **Four channel-count variants**: 16, 32, 64 and 128 channels — install any combination
- **Zero additional driver latency** — audio is passed through a shared ring buffer
- **32-bit float**, matching what macOS Core Audio uses natively at the system level
- **Sample rates**: 8, 16, 24, 44.1, 48, 88.2, 96, 176.4, 192, 352.8, 384, 705.6 and 768 kHz
- **No kernel extension** — it is a userspace Core Audio `AudioServerPlugIn` (HAL plugin),
  so no changes to system security settings are needed
- **Signed and notarised** for Gatekeeper
- **Single installer** that both installs and uninstalls any variant
- Native on Intel and Apple Silicon: macOS 10.13 High Sierra or newer on Intel,
  macOS 11 Big Sur or newer on Apple Silicon

<!-- TODO: replace with a HOLOPHONIX Virtual Soundcard screenshot of Audio MIDI Setup.
     Images/audio-midi-setup.png is upstream's BlackHole screenshot and must not be reused. -->

## Installation

1. [Download the latest installer](https://holophonix.xyz/en/support/downloads)
2. Quit all running audio applications
3. Open the `.pkg` and select the channel-count variants you want to install
4. Restart your Mac

Each variant appears in `Audio MIDI Setup` as a separate device, for example
**HOLOPHONIX Virtual Soundcard 64ch**. The driver bundles are installed to
`/Library/Audio/Plug-Ins/HAL/`.

> Installing several variants side by side is supported and is often useful — a 16ch device
> for general routing and a 128ch device for a full spatialisation session, for instance.

## Uninstallation

### Option 1 — use the installer

The installer package also contains uninstall options. Open the same `.pkg`, click
**Customise**, and select the variants you want to remove under *Uninstall HOLOPHONIX
Virtual Soundcard*. Install and uninstall choices for the same variant are mutually
exclusive.

### Option 2 — manually

1. Delete the driver bundle — mind the quotes, the name contains spaces:

   ```bash
   sudo rm -R "/Library/Audio/Plug-Ins/HAL/HOLOPHONIX Virtual Soundcard 64ch.driver"
   ```

   Replace `64` with `16`, `32` or `128` as appropriate. Note this is the root `/Library`,
   not `~/Library`.

2. Restart Core Audio:

   ```bash
   sudo killall -9 coreaudiod
   ```

## Usage

### Route audio between two applications

1. In the sending application, set the output device to **HOLOPHONIX Virtual Soundcard**
2. Output to any channel
3. In the receiving application, set the input device to **HOLOPHONIX Virtual Soundcard**
4. Take input from the matching channels

### Record or capture system audio

1. Create a Multi-Output Device in `Audio MIDI Setup` containing both your real output and
   HOLOPHONIX Virtual Soundcard
2. Right-click the new Multi-Output Device and choose *Use This Device For Sound Output*
3. In your DAW or recorder, set the input device to HOLOPHONIX Virtual Soundcard

Enable drift correction on every device in a Multi-Output or Aggregate **except** the clock
source, otherwise audio will glitch after a few minutes.

### Hear the audio while routing it

Use a Multi-Output Device, as above. A virtual driver alone has no physical output.

## Relationship to BlackHole

HOLOPHONIX Virtual Soundcard is a **fork of [BlackHole](https://github.com/ExistentialAudio/BlackHole)**
by Existential Audio Inc., licensed under GPL-3.0.

The audio driver itself — `BlackHole/BlackHole.c`, the ring buffer, the Core Audio plugin
implementation, all of the DSP and device logic — is **Existential Audio's work, unmodified**.
Credit for how well this driver performs belongs to them.

What this fork changes:

| Area | Change |
|---|---|
| Product name | Devices are named `HOLOPHONIX Virtual Soundcard <N>ch` (via the `kDriver_Name` build constant) |
| Manufacturer | Reported as `HOLOPHONIX` (via `kManufacturer_Name`) |
| Icon | HOLOPHONIX device icon in place of the BlackHole icon |
| Bundle identifiers | `com.amadeus.holophonix.vs<N>ch` |
| Channel variants | 16, 32, 64, 128 — upstream ships 2, 16, 64, 128, 256 |
| Plugin factory UUID | Regenerated per build, so this driver can coexist with an existing BlackHole installation |
| Installer | New build script (`Installer/create_holo_installer.zsh`) producing a single package that installs *or* uninstalls any combination of variants |

No change is made to the audio path. Consequently:

- **Bugs in audio behaviour are almost certainly upstream bugs.** Please check the
  [BlackHole issue tracker](https://github.com/ExistentialAudio/BlackHole/issues) before
  reporting, and report driver-core issues there so all users benefit.
- **Report packaging, naming, signing and installer problems to
  [HOLOPHONIX support](#support)** — those are ours, not upstream's.
- Upstream's [wiki](https://github.com/ExistentialAudio/BlackHole/wiki) applies to this
  driver too, substituting the device name.

### If you are not a HOLOPHONIX user

You almost certainly want [BlackHole](https://github.com/ExistentialAudio/BlackHole)
itself — it is the original, it is actively maintained, and it offers 2ch and 256ch builds
that this fork does not. Consider
[sponsoring Existential Audio](https://github.com/sponsors/ExistentialAudio); this fork
exists only because their work is good.

### Commercial licensing of the driver core

BlackHole is GPL-3.0. To use the driver core in a project that is *not* GPL-3.0, a licence
must be obtained from Existential Audio — contact them at
<devinroth@existential.audio>. That arrangement is between you and Existential Audio;
Amadeus cannot grant it, and nothing in this repository does.

## Building from Source

Requires Xcode and a macOS host. Building the driver alone:

```bash
xcodebuild -project BlackHole.xcodeproj -configuration Release -target BlackHole
```

To install a driver you built yourself:

1. Copy the built `.driver` bundle to `/Library/Audio/Plug-Ins/HAL`
2. `sudo chown -R root:wheel "/Library/Audio/Plug-Ins/HAL/<your driver>.driver"`
3. `sudo killall -9 coreaudiod`

### Building the release installer

`Installer/create_holo_installer.zsh` builds all four channel variants, signs them, and
produces the combined install/uninstall package. Run it from the repository root:

```bash
./Installer/create_holo_installer.zsh
```

Before running it, set `devTeamID` and `notarizeProfile` at the top of the script to your
own Apple Developer team ID and `notarytool` keychain profile, or set `notarize=false` to
skip notarisation. Signing and notarisation credentials are not included in this
repository.

Upstream's own `Installer/create_installer.sh` is retained for reference and is not used
for HOLOPHONIX builds.

## FAQ

**Why doesn't it appear in the Applications folder?**
It is an audio driver, not an application. It appears in `Audio MIDI Setup`, in Sound
settings, and in the device lists of audio applications.

**Which variant should I install?**
The smallest that covers your channel count. Installing several is fine.

**Nothing is playing through it.**
- Check `System Settings` → `Privacy & Security` → `Microphone` and confirm your
  application has microphone access.
- Check that input and output volume are up in `Audio MIDI Setup`.
- In a Multi-Output Device, macOS requires the Built-in Output to be enabled and listed
  first.

**Audio glitches after a few minutes in a Multi-Output or Aggregate device.**
Enable drift correction on every device except the clock source.

**What bit depth is used, and can I change it?**
32-bit float, because that is what Core Audio uses natively system-wide. It is lossless for
up to 24-bit integer material, and there is nothing to configure at the driver level.

**Can I change the volume of a Multi-Output Device?**
macOS does not support this. Set the volume of the individual devices in
`Audio MIDI Setup` instead.

**The installer fails.**
Some macOS versions fail to run installer packages from certain folders. Move the `.pkg`
to the Desktop (or to Downloads if it is already on the Desktop) and try again.

**Can I use it alongside BlackHole?**
Yes. The bundle identifiers, device names, device UIDs and plugin factory UUIDs are all
distinct.

**Which applications is it known to work with?**
Any Core Audio application. Reported working with Ableton Live, Cubase, Digital Performer,
IanniX, Logic Pro, Max, Nuendo, Pro Tools, Pure Data, Pyramix, QLab, Reaktor, REAPER,
Reason and Traktor, among others.

## Support

Issue tracking is not enabled on this repository. Please use these channels instead:

- **Packaging, installation, naming or signing problems** —
  [HOLOPHONIX Help Center](https://holophonix.atlassian.net/servicedesk/customer/portals)
- **General help and setup** — [HOLOPHONIX documentation](https://docs.holophonix.xyz)
- **Audio behaviour** (dropouts, sample rates, Multi-Output devices) — these belong
  upstream, see [Relationship to BlackHole](#relationship-to-blackhole)

Please do not contact Existential Audio for support on this build.

## Licence and Source Availability

HOLOPHONIX Virtual Soundcard is a modified version of BlackHole and is distributed under
the **GNU General Public License, version 3** — see [LICENSE](LICENSE). The complete
corresponding source for every released binary is in this repository:

**<https://github.com/HOLOPHONIX/HOLOPHONIX-Virtual-Soundcard>**

You are free to use, study, modify and redistribute it under the terms of the GPL.

- BlackHole is © 2019–2026 Existential Audio Inc. — <https://github.com/ExistentialAudio/BlackHole>
- Modifications for HOLOPHONIX Virtual Soundcard are © Amadeus. <!-- CONFIRM: Amadeus or the HOLOPHONIX spin-off entity? The signing certificate and bundle identifiers (com.amadeus.holophonix.*) are Amadeus's. -->
- Signed and notarised under Amadeus's Apple Developer identity.
- "BlackHole" and the BlackHole logo are trademarks of Existential Audio Inc. and are not
  licensed by the GPL. They appear in this repository, and in the upstream file and target
  names it retains, solely to identify the project this work derives from.
- "HOLOPHONIX" and "Amadeus" are trademarks of Amadeus.

## The HOLOPHONIX Ecosystem

HOLOPHONIX is a spatial audio platform developed in coordination with
[IRCAM](https://www.ircam.fr), combining several spatialisation techniques — Wave Field
Synthesis, High-Order Ambisonics, Distance-Based Amplitude Panning and others — for
theatre, concert, museum and immersive installation work.

| | |
|---|---|
| [**HOLOPHONIX Native**](https://holophonix.xyz/en/software/holophonix-native) | macOS spatialisation application, up to 128 inputs. The most common companion to this driver — route a DAW into Native on the same Mac |
| [**HOLOPHONIX Ultra**](https://holophonix.xyz/en/hardware/holophonix-ultra) | Flagship hardware spatialisation processor |
| [**HOLOSCORE**](https://holophonix.xyz/en/software/holoscore) | Free plugin for automating spatialisation from a DAW timeline |
| [**HOLOPHONIX Designer**](https://holophonix.xyz/en/software/holophonix-designer) | Free offline editor with binaural preview, for macOS and Windows |
| [**All software**](https://holophonix.xyz/en/software) · [**All hardware**](https://holophonix.xyz/en/hardware) | |

Company and contact: <https://holophonix.xyz/en/contact>

Upstream project this driver derives from:
[BlackHole](https://github.com/ExistentialAudio/BlackHole) by Existential Audio Inc.

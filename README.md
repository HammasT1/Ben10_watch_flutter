<div align="center">

# ⌚ Omnitrix — Ben 10 Watch

**An interactive, fan-made alien-transformation watch built with Flutter.**

Spin the dial, pick an alien, slam the core and go hero, until the watch times out.

[![Build APK](https://github.com/HammasT1/Ben10_watch_flutter/actions/workflows/build-apk.yml/badge.svg)](https://github.com/HammasT1/Ben10_watch_flutter/actions/workflows/build-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/HammasT1/Ben10_watch_flutter?color=39FF14&label=release&logo=android&logoColor=white)](https://github.com/HammasT1/Ben10_watch_flutter/releases/latest)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-1a1a1a)

[**📥 Download APK**](https://github.com/HammasT1/Ben10_watch_flutter/releases/latest) ·
[Features](#-features) ·
[Getting Started](#-getting-started) ·
[Releases](#-building--releasing)

</div>

---

## ✨ Features

| | |
|---|---|
| 🧊 **3D intro** | A rotatable 3D watch model greets you. Hit **ACTIVATE** to power it up. |
| 🎛️ **Physics dial** | Drag or flick the dial. It carries momentum and snaps cleanly onto each alien slot. |
| 👽 **11 aliens** | XLR8, Wildvine, Stinkfly, Heatblast, Benwolf, Benmummy, Upchuck, Upgrade, Eye Guy, Frankenstrike and Four Arms. |
| 🎨 **Per-alien theming** | Each alien has its own glow color, used across the whole UI while it's active. |
| 📇 **Info cards** | Swipeable cards with species, homeworld, powers and a stat breakdown (strength, speed, intelligence, durability). |
| ⚡ **Transform sequence** | Charge-up, flash and shockwave effects drawn with custom painters (sparks, bubbles, ring pulses). |
| ⏳ **Timeout & recharge** | You get 15 seconds as an alien, with warning beeps near the end. Then the watch turns red and needs 8 seconds to recharge. |
| 🔊 **Sound & haptics** | A click for each dial step, transform and revert sounds, a buzz when the watch refuses, and a one-tap mute toggle. |

### How the watch works

```text
  ┌──────┐  tap core  ┌──────────────┐        ┌─────────────┐  15s   ┌────────────┐
  │ IDLE │ ─────────▶ │ TRANSFORMING │ ─────▶ │ TRANSFORMED │ ─────▶ │ RECHARGING │
  └──────┘            └──────────────┘        └─────────────┘        └────────────┘
     ▲                                               │ revert               │ 8s
     └───────────────────────────────────────────────┴──────────────────────┘
```

---

## 📥 Install on Android

1. Open the [**latest release**](https://github.com/HammasT1/Ben10_watch_flutter/releases/latest).
2. Download an APK:

   | File | Use it for |
   |---|---|
   | `ben10-watch-<ver>-universal.apk` | **Any phone.** Pick this one if you're not sure. |
   | `ben10-watch-<ver>-arm64-v8a.apk` | Most phones from the last few years (smaller download) |
   | `ben10-watch-<ver>-armeabi-v7a.apk` | Older 32-bit phones |
   | `ben10-watch-<ver>-x86_64.apk` | Emulators and Chromebooks |

3. Open the file and allow **Install unknown apps** if Android asks.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.47+** (Dart 3.9+)
- Android Studio or the Android SDK, plus JDK 17, for Android builds

### Run locally

```bash
git clone https://github.com/HammasT1/Ben10_watch_flutter.git
cd Ben10_watch_flutter
flutter pub get
flutter run
```

> **Note:** The 3D intro needs a WebView-capable platform (Android, iOS or Web). On Linux and Windows desktop the app skips straight to the watch.

### Run tests

```bash
flutter test
```

---

## 📦 Building & Releasing

### Local build

```bash
flutter build apk --release                  # universal APK
flutter build apk --release --split-per-abi  # one APK per CPU type
```

Output: `build/app/outputs/flutter-apk/`

### Automated releases (GitHub Actions)

Pushing a version tag starts [`build-apk.yml`](.github/workflows/build-apk.yml). It builds every APK and attaches them to a GitHub Release.

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The tag sets the version (`v1.0.0` becomes `1.0.0`). You can also run the workflow by hand from the **Actions** tab.

---

## 🗂️ Project Structure

```text
lib/
├── main.dart                 # App entry, theme, intro → watch routing
├── data/
│   └── aliens.dart           # Alien roster: names, colors, powers, stats
├── models/
│   ├── alien.dart            # Alien & AlienStats models
│   ├── watch_phase.dart      # idle → transforming → transformed → recharging
│   └── effect_seeds.dart     # Randomized seeds for particle effects
├── screens/
│   ├── intro_screen.dart     # 3D model intro with ACTIVATE button
│   └── omnitrix_screen.dart  # Dial, core, timers and transform logic
├── widgets/
│   ├── alien_image.dart      # Silhouette / lit alien rendering
│   ├── alien_info_sheet.dart # Swipeable alien info cards
│   └── transformed_view.dart # Active-alien view with countdown
├── painters/                 # CustomPainter effects
│   ├── bubble_painter.dart
│   ├── ring_pulse_painter.dart
│   ├── shockwave_painter.dart
│   └── spark_painter.dart
└── services/
    └── watch_feedback.dart   # Sound effects, haptics and mute
assets/
├── images/                   # Alien artwork (slot N → N.png)
├── models/                   # .glb 3D watch model
└── sounds/                   # .wav sound effects
```

### Customizing aliens

Everything about an alien lives in [`lib/data/aliens.dart`](lib/data/aliens.dart). To add or change one:

1. Put the artwork in `assets/images/` as `<slot>.png`.
2. Add an `Alien(...)` entry with its name, species, homeworld, description, powers, color and stats.

The dial updates itself from the list. You don't need to change any other code.

---

## 🛠️ Tech Stack

| Package | Purpose |
|---|---|
| [`model_viewer_plus`](https://pub.dev/packages/model_viewer_plus) | Interactive 3D `.glb` watch on the intro screen |
| [`audioplayers`](https://pub.dev/packages/audioplayers) | Low-latency sound effects |
| `CustomPainter` | Hand-drawn sparks, shockwaves, bubbles and ring pulses |
| `AnimationController` | Transform, timeout and recharge timing |

---

## ⚠️ Disclaimer

This is an unofficial, non-commercial **fan project**, made for learning and fun. *Ben 10*, the Omnitrix and all related characters are trademarks of Cartoon Network / Warner Bros. Discovery. This project is not affiliated with or endorsed by them.

---

<div align="center">

Made with 💚 and Flutter by **[Muhammad Hammas Rasheed](https://github.com/HammasT1)**

⭐ Star the repo if you liked it! It's going hero time.

</div>

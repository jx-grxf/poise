<div align="center">

# 🧍 Poise

**Turn your AirPods into a posture coach.**

*A native macOS menu bar app that reads the motion sensors in your AirPods to track your head posture in real time — no camera, no cloud, everything runs locally.*

[![CI](https://github.com/jx-grxf/poise/actions/workflows/ci.yml/badge.svg)](https://github.com/jx-grxf/poise/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/jx-grxf/poise?color=informational)](https://github.com/jx-grxf/poise/releases/latest)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
[![Built with Tuist](https://img.shields.io/badge/built%20with-Tuist-9B51E0)](https://tuist.dev)
[![Updates: Sparkle](https://img.shields.io/badge/updates-Sparkle-5E5CE6)](https://sparkle-project.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

</div>

---

## Features

- 🎯 **Live posture tracking** via `CMHeadphoneMotionManager` — forward slouch and side tilt, smoothed and calibrated against your personal baseline
- 🟢 **Colored menu bar status** — green when you sit upright, orange when you drift, red when you slouch, with an optional live posture score
- 🧭 **Guided onboarding and calibration** — a three-second averaged baseline capture instead of a blind snapshot
- 🔔 **Smart alerts** — notifications only after bad posture persists, with grace period, cooldown, and automatic suppression while you're walking or moving
- 📊 **Statistics** — per-minute history, daily posture score, 14-day trend, and a live view of all AirPods sensor data (attitude, rotation rate, acceleration)
- ⚙️ **Native settings** — liquid-glass settings window, launch at login, Sparkle auto-updates

## Requirements

- macOS 14.0 or later
- AirPods Pro (any generation), AirPods Max, AirPods 3rd gen or later, or Beats with spatial audio support

## Building

The project uses [Tuist](https://tuist.dev):

```bash
tuist install
tuist generate --no-open
./run-menubar.sh
```

## Architecture

| File | Responsibility |
|---|---|
| `Sources/HeadphoneMotionClient.swift` | CoreMotion transport, fused sensor samples |
| `Sources/PostureStore.swift` | Observable state: calibration, slouch state machine, movement detection, alerting, minute bucketing |
| `Sources/HistoryStore.swift` | Per-day JSON persistence and day summaries |
| `Sources/MenuBarView.swift` | Menu bar panel UI |
| `Sources/StatsView.swift` | Charts and live sensor readout |
| `Sources/OnboardingView.swift` | Guided first-run flow |

## License

MIT — see [LICENSE](LICENSE). © 2026 Johannes Grof.

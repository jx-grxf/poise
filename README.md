# Poise

Turn your AirPods into a posture coach. Poise is a native macOS menu bar app that uses the motion sensors in AirPods (Pro, Max, 3rd gen and later) to track your head posture in real time — no camera, no cloud, everything runs locally.

## Features

- **Live posture tracking** via `CMHeadphoneMotionManager` — forward slouch and side tilt, smoothed and calibrated against your personal baseline
- **Colored menu bar status** — green when you sit upright, orange when you drift, red when you slouch, with an optional live posture score
- **Guided onboarding and calibration** — a three-second averaged baseline capture instead of a blind snapshot
- **Smart alerts** — notifications only after bad posture persists, with grace period, cooldown, and automatic suppression while you're walking or moving
- **Statistics** — per-minute history, daily posture score, 14-day trend, and a live view of all AirPods sensor data (attitude, rotation rate, acceleration)
- **Native settings** — liquid-glass settings window, launch at login, Sparkle auto-updates

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

- `Sources/HeadphoneMotionClient.swift` — CoreMotion transport, fused sensor samples
- `Sources/PostureStore.swift` — observable state: calibration, slouch state machine, movement detection, alerting, minute bucketing
- `Sources/HistoryStore.swift` — per-day JSON persistence and day summaries
- `Sources/MenuBarView.swift` — menu bar panel UI
- `Sources/StatsView.swift` — charts and live sensor readout
- `Sources/OnboardingView.swift` — guided first-run flow

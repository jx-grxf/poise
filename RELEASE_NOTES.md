# Release Notes

Newest version on top. Each release must have a `## <version>` section that
exactly matches the tag (without the leading `v`) — the release workflow
extracts it for the GitHub release and the Sparkle update dialog, and fails
if the section is missing.

## 0.1.0

Initial release.

### Highlights

- **Live posture tracking with your AirPods** — forward slouch and side tilt
  detected via the built-in motion sensors, no camera, everything on-device
- **Colored menu bar status** — green when you sit upright, orange when you
  drift, red when you slouch, with an optional live posture score
- **Guided onboarding and calibration** — a three-second averaged baseline
  capture instead of a blind snapshot
- **Smart alerts** — notifications only after bad posture persists, with grace
  period, cooldown, and automatic suppression while you're moving
- **Statistics** — daily posture score, per-minute timeline, 14-day trend and
  a live sensor readout
- **Native experience** — liquid-glass settings, launch at login, Sparkle
  auto-updates with stable and beta channels

### Compatibility

- macOS 14.0 or later
- AirPods Pro, AirPods Max, AirPods 3rd gen or later, or Beats with spatial
  audio support

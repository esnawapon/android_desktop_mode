## 0.1.0

Initial release.

- `AndroidDesktopMode.getState()`, `isDesktopMode()` and `stateChanges` for detecting
  desktop sessions on Android.
- Samsung DeX detection through `SemDesktopModeManager` and
  `Configuration.semDesktopModeEnabled`, including the DeX display type
  (standalone/dual).
- ChromeOS detection through the `org.chromium.arc` system features.
- Android desktop windowing detection through freeform windowing mode and the system
  caption bar.
- Best-effort probes for Huawei/Honor PC mode plus a scan of vendor desktop system
  features.
- Heuristic fallback for external display, hardware keyboard and pointer devices, with a
  four-level confidence scale.
- `DesktopModeBuilder` widget, and a full `DesktopModeSignals` dump for debugging and
  device reports.

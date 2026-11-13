## 0.1.1

- Support Flutter 3.50: raise the Android Gradle Plugin to 9.3.1 (Flutter now requires
  at least 9.1.1) and Kotlin to 2.4.20.
- Example app: Gradle 9.5.0, and Material imported from `package:material_ui`.
- Shorten the package description to fit pub.dev's 60–180 character limit.

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

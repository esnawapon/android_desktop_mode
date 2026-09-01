/// Detects whether an Android device is running in a desktop mode such as Samsung DeX,
/// ChromeOS or Android's own desktop windowing.
library;

import 'package:flutter/foundation.dart';

import 'src/android_desktop_mode_platform_interface.dart';
import 'src/models.dart';

export 'src/desktop_mode_builder.dart';
export 'src/models.dart';

/// Entry point of the plugin.
///
/// ```dart
/// final state = await AndroidDesktopMode.getState();
/// if (state.isDesktopMode) {
///   // Lay out for a mouse, a keyboard and a big window.
/// }
/// ```
///
/// On platforms other than Android every call resolves to
/// [DesktopModeState.notDesktop], so calls do not need to be guarded.
abstract final class AndroidDesktopMode {
  /// Whether the running platform can report desktop mode at all.
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Reads the current state, including the raw signals behind it.
  static Future<DesktopModeState> getState() async {
    if (!isSupportedPlatform) return const DesktopModeState.notDesktop();
    return AndroidDesktopModePlatform.instance.getState();
  }

  /// Whether the device is in desktop mode right now.
  ///
  /// [minimumConfidence] sets how much evidence is enough. The default,
  /// [DesktopModeConfidence.likely], accepts strong platform signals as well as vendor
  /// APIs; pass [DesktopModeConfidence.confirmed] to only trust an explicit vendor or
  /// platform answer, or [DesktopModeConfidence.heuristic] to also accept "an external
  /// screen and a mouse are attached".
  static Future<bool> isDesktopMode({
    DesktopModeConfidence minimumConfidence = DesktopModeConfidence.likely,
  }) async => (await getState()).isDesktopModeAtLeast(minimumConfidence);

  /// Emits the state whenever it changes, starting with the current one.
  ///
  /// The Android side watches configuration changes, Samsung DeX broadcasts, display
  /// hotplugs and input-device changes, and only emits when the state actually differs.
  static Stream<DesktopModeState> get stateChanges {
    if (!isSupportedPlatform) {
      return Stream<DesktopModeState>.value(
        const DesktopModeState.notDesktop(),
      );
    }
    return AndroidDesktopModePlatform.instance.stateChanges;
  }
}

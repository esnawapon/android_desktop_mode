import 'package:flutter/services.dart';

import 'android_desktop_mode_platform_interface.dart';
import 'models.dart';

/// The default [AndroidDesktopModePlatform], talking to the Android plugin over channels.
class MethodChannelAndroidDesktopMode extends AndroidDesktopModePlatform {
  /// The channel used for one-shot queries.
  static const MethodChannel methodChannel = MethodChannel(
    'dev.esnawapon.android_desktop_mode/methods',
  );

  /// The channel that streams state changes.
  static const EventChannel eventChannel = EventChannel(
    'dev.esnawapon.android_desktop_mode/events',
  );

  Stream<DesktopModeState>? _stateChanges;

  @override
  Future<DesktopModeState> getState() async {
    final Map<Object?, Object?>? result = await methodChannel
        .invokeMapMethod<Object?, Object?>('getState');
    if (result == null) return const DesktopModeState.notDesktop();
    return DesktopModeState.fromMap(result);
  }

  @override
  Stream<DesktopModeState> get stateChanges => _stateChanges ??= eventChannel
      .receiveBroadcastStream()
      .map(
        (Object? event) => event is Map<Object?, Object?>
            ? DesktopModeState.fromMap(event)
            : const DesktopModeState.notDesktop(),
      )
      .asBroadcastStream();
}

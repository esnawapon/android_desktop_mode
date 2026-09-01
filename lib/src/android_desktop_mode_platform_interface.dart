import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_desktop_mode_method_channel.dart';
import 'models.dart';

/// The interface every platform implementation of `android_desktop_mode` implements.
///
/// Swap [instance] in tests to fake desktop mode without an emulator.
abstract class AndroidDesktopModePlatform extends PlatformInterface {
  /// Creates a platform implementation.
  AndroidDesktopModePlatform() : super(token: _token);

  static final Object _token = Object();

  static AndroidDesktopModePlatform _instance =
      MethodChannelAndroidDesktopMode();

  /// The implementation currently in use.
  static AndroidDesktopModePlatform get instance => _instance;

  /// Replaces the implementation in use.
  static set instance(AndroidDesktopModePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Reads the current desktop-mode state.
  Future<DesktopModeState> getState() {
    throw UnimplementedError('getState() has not been implemented.');
  }

  /// Emits a new state whenever the device enters or leaves a desktop session.
  Stream<DesktopModeState> get stateChanges {
    throw UnimplementedError('stateChanges has not been implemented.');
  }
}

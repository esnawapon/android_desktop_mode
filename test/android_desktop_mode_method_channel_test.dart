import 'package:android_desktop_mode/android_desktop_mode.dart';
import 'package:android_desktop_mode/src/android_desktop_mode_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelAndroidDesktopMode();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(
      MethodChannelAndroidDesktopMode.methodChannel,
      null,
    );
  });

  test('getState decodes what the Android side sends', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(
      MethodChannelAndroidDesktopMode.methodChannel,
      (MethodCall call) async {
        calls.add(call.method);
        return <String, Object?>{
          'confidence': 'confirmed',
          'implementation': 'chromeOs',
          'reasons': <String>['chrome_os'],
          'signals': <String, Object?>{'isChromeOs': true, 'sdkInt': 33},
        };
      },
    );

    final state = await platform.getState();

    expect(calls, <String>['getState']);
    expect(state.implementation, DesktopModeImplementation.chromeOs);
    expect(state.isDesktopMode, isTrue);
    expect(state.signals.isChromeOs, isTrue);
  });

  test(
    'getState falls back to "not desktop" when the platform returns nothing',
    () async {
      messenger.setMockMethodCallHandler(
        MethodChannelAndroidDesktopMode.methodChannel,
        (MethodCall call) async => null,
      );

      expect(await platform.getState(), const DesktopModeState.notDesktop());
    },
  );
}

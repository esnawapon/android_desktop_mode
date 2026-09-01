import 'package:android_desktop_mode/android_desktop_mode.dart';
import 'package:android_desktop_mode/src/android_desktop_mode_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePlatform extends AndroidDesktopModePlatform
    with MockPlatformInterfaceMixin {
  _FakePlatform(this.state);

  DesktopModeState state;
  int getStateCalls = 0;

  @override
  Future<DesktopModeState> getState() async {
    getStateCalls++;
    return state;
  }

  @override
  Stream<DesktopModeState> get stateChanges =>
      Stream<DesktopModeState>.value(state);
}

void main() {
  const confirmedDex = DesktopModeState(
    confidence: DesktopModeConfidence.confirmed,
    implementation: DesktopModeImplementation.samsungDex,
    reasons: <String>['samsung_dex_enabled'],
    signals: DesktopModeSignals(
      samsungDexAvailable: true,
      samsungDexEnabled: true,
    ),
  );

  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform(confirmedDex);
    AndroidDesktopModePlatform.instance = platform;
  });

  test('getState forwards the platform state', () async {
    expect(await AndroidDesktopMode.getState(), confirmedDex);
    expect(platform.getStateCalls, 1);
  });

  test('isDesktopMode honours the confidence threshold', () async {
    platform.state = const DesktopModeState(
      confidence: DesktopModeConfidence.heuristic,
      implementation: DesktopModeImplementation.unknown,
      reasons: <String>['external_display_connected'],
    );

    expect(await AndroidDesktopMode.isDesktopMode(), isFalse);
    expect(
      await AndroidDesktopMode.isDesktopMode(
        minimumConfidence: DesktopModeConfidence.heuristic,
      ),
      isTrue,
    );
    expect(
      await AndroidDesktopMode.isDesktopMode(
        minimumConfidence: DesktopModeConfidence.confirmed,
      ),
      isFalse,
    );
  });

  test('stateChanges forwards the platform stream', () async {
    expect(await AndroidDesktopMode.stateChanges.first, confirmedDex);
  });

  test('is only supported on Android', () {
    expect(AndroidDesktopMode.isSupportedPlatform, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(AndroidDesktopMode.isSupportedPlatform, isFalse);
  });

  test(
    'resolves to "not desktop" without touching the platform elsewhere',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(
        await AndroidDesktopMode.getState(),
        const DesktopModeState.notDesktop(),
      );
      expect(await AndroidDesktopMode.isDesktopMode(), isFalse);
      expect(
        await AndroidDesktopMode.stateChanges.first,
        const DesktopModeState.notDesktop(),
      );
      expect(platform.getStateCalls, 0);
    },
  );
}

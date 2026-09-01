import 'package:android_desktop_mode/android_desktop_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopModeConfidence', () {
    test('is ordered from none to confirmed', () {
      expect(
        DesktopModeConfidence.confirmed.isAtLeast(DesktopModeConfidence.likely),
        isTrue,
      );
      expect(
        DesktopModeConfidence.likely.isAtLeast(DesktopModeConfidence.likely),
        isTrue,
      );
      expect(
        DesktopModeConfidence.heuristic.isAtLeast(DesktopModeConfidence.likely),
        isFalse,
      );
      expect(
        DesktopModeConfidence.none.isAtLeast(DesktopModeConfidence.heuristic),
        isFalse,
      );
    });
  });

  group('DesktopModeState', () {
    test('isDesktopMode uses "likely" as the default threshold', () {
      DesktopModeState stateWith(DesktopModeConfidence confidence) =>
          DesktopModeState(
            confidence: confidence,
            implementation: DesktopModeImplementation.unknown,
          );

      expect(stateWith(DesktopModeConfidence.confirmed).isDesktopMode, isTrue);
      expect(stateWith(DesktopModeConfidence.likely).isDesktopMode, isTrue);
      expect(stateWith(DesktopModeConfidence.heuristic).isDesktopMode, isFalse);
      expect(stateWith(DesktopModeConfidence.none).isDesktopMode, isFalse);
    });

    test('a heuristic state counts when the caller lowers the threshold', () {
      const state = DesktopModeState(
        confidence: DesktopModeConfidence.heuristic,
        implementation: DesktopModeImplementation.unknown,
      );

      expect(
        state.isDesktopModeAtLeast(DesktopModeConfidence.heuristic),
        isTrue,
      );
      expect(
        state.isDesktopModeAtLeast(DesktopModeConfidence.confirmed),
        isFalse,
      );
    });

    test('"none" is never desktop mode, whatever the threshold', () {
      const state = DesktopModeState.notDesktop();

      expect(state.isDesktopModeAtLeast(DesktopModeConfidence.none), isFalse);
      expect(state.isDesktopMode, isFalse);
    });

    test('decodes a platform payload', () {
      final state = DesktopModeState.fromMap(const <Object?, Object?>{
        'confidence': 'confirmed',
        'implementation': 'samsungDex',
        'reasons': <Object?>['samsung_dex_enabled'],
        'signals': <Object?, Object?>{
          'samsungDexAvailable': true,
          'samsungDexEnabled': true,
          'samsungDexDisplayType': 'dual',
          'externalDisplayCount': 1,
          'hasPointerDevice': true,
          'vendorDesktopFeatures': <Object?>[
            'com.samsung.feature.samsung_experience_mobile',
          ],
          'manufacturer': 'samsung',
          'model': 'SM-S928B',
          'sdkInt': 34,
        },
      });

      expect(state.isDesktopMode, isTrue);
      expect(state.confidence, DesktopModeConfidence.confirmed);
      expect(state.implementation, DesktopModeImplementation.samsungDex);
      expect(state.reasons, <String>['samsung_dex_enabled']);
      expect(state.signals.samsungDexDisplayType, DexDisplayType.dual);
      expect(state.signals.externalDisplayCount, 1);
      expect(state.signals.model, 'SM-S928B');
      expect(state.signals.sdkInt, 34);
    });

    test('falls back to safe values on an unknown or partial payload', () {
      final state = DesktopModeState.fromMap(const <Object?, Object?>{
        'confidence': 'something-new',
        'implementation': 'something-new',
      });

      expect(state.confidence, DesktopModeConfidence.none);
      expect(state.implementation, DesktopModeImplementation.unknown);
      expect(state.reasons, isEmpty);
      expect(state.signals, const DesktopModeSignals());
      expect(state.isDesktopMode, isFalse);
    });

    test('survives a map round trip', () {
      const state = DesktopModeState(
        confidence: DesktopModeConfidence.likely,
        implementation: DesktopModeImplementation.androidDesktopWindowing,
        reasons: <String>['feature_pc'],
        signals: DesktopModeSignals(
          isPcDeviceType: true,
          supportsFreeformWindows: true,
          brand: 'google',
          sdkInt: 36,
        ),
      );

      expect(DesktopModeState.fromMap(state.toMap()), state);
    });
  });
}

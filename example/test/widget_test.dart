import 'package:android_desktop_mode_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Same channel the Android plugin uses; under `flutter test` there is no Android side,
  // so the example is driven with canned platform answers.
  const MethodChannel channel = MethodChannel(
    'dev.esnawapon.android_desktop_mode/methods',
  );
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockState(Map<String, Object?> state) {
    messenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async => state,
    );
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('reports a DeX session', (WidgetTester tester) async {
    mockState(<String, Object?>{
      'confidence': 'confirmed',
      'implementation': 'samsungDex',
      'reasons': <String>['samsung_dex_enabled'],
      'signals': <String, Object?>{
        'samsungDexAvailable': true,
        'samsungDexEnabled': true,
        'samsungDexDisplayType': 'dual',
        'manufacturer': 'samsung',
        'sdkInt': 34,
      },
    });

    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('Desktop mode'), findsWidgets);
    expect(find.text('samsungDex · confirmed confidence'), findsOneWidget);
    expect(find.text('samsung_dex_enabled'), findsOneWidget);
  });

  testWidgets('reports a plain phone', (WidgetTester tester) async {
    mockState(<String, Object?>{
      'confidence': 'none',
      'implementation': 'none',
      'reasons': <String>[],
      'signals': <String, Object?>{'manufacturer': 'Google', 'sdkInt': 36},
    });

    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('Not desktop mode'), findsOneWidget);
    expect(find.text('No desktop-mode signal fired.'), findsOneWidget);
  });
}

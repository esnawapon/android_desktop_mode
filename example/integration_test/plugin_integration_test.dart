// Runs on a real device or emulator, against the real Android implementation.
//
//   flutter test integration_test
import 'package:android_desktop_mode/android_desktop_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads a state from the device', (WidgetTester tester) async {
    final DesktopModeState state = await AndroidDesktopMode.getState();

    expect(state.signals.sdkInt, greaterThan(0));
    expect(state.signals.manufacturer, isNotEmpty);
    // A verdict is always produced, whatever the device answers.
    expect(DesktopModeConfidence.values, contains(state.confidence));
  });

  testWidgets('the change stream emits the current state first', (
    WidgetTester tester,
  ) async {
    final DesktopModeState first = await AndroidDesktopMode.stateChanges.first;

    expect(first.signals.sdkInt, greaterThan(0));
  });
}

# Contributing

## Device reports

The most useful contribution is a device report. Vendors ship desktop modes without public
APIs, so the only way to support them properly is to see what a real device answers.

1. Run the example app (`cd example && flutter run`).
2. Put the device into its desktop mode.
3. Tap the copy button and open a [device report issue](https://github.com/esnawapon/android_desktop_mode/issues/new?template=device-report.yml).

## Development

```bash
flutter pub get
flutter analyze
flutter test                                   # Dart
cd example/android && ./gradlew :android_desktop_mode:testDebugUnitTest   # Kotlin
cd example && flutter test integration_test    # on a device
```

The decision table lives in `android/src/main/kotlin/.../DesktopModeSignals.kt`
(`DesktopModeResolver`) and is pure Kotlin, so new rules should come with a unit test in
`DesktopModeResolverTest`. Signal *collection* lives in `DesktopModeDetector`, and vendor
specific reflection in `SamsungDexProbe` / `VendorProbe`.

Adding a vendor probe: add the class and no-argument boolean methods to
`VendorProbe.REFLECTIVE_PROBES`. Probes are fully guarded, so a wrong guess is harmless —
but please back it up with a device report.

## Style

`dart format .` and `flutter analyze` must be clean; the Kotlin follows the ktlint-ish
formatting the Flutter plugin template ships with.

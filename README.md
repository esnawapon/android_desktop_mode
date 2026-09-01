# android_desktop_mode

[![pub package](https://img.shields.io/pub/v/android_desktop_mode.svg)](https://pub.dev/packages/android_desktop_mode)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Detect whether an Android device is running your app in a **desktop mode** — Samsung DeX,
ChromeOS, Android's own desktop windowing, or a vendor PC mode — and react when that
changes.

The plugin does not just answer yes/no: it tells you **which** desktop stack it found, **how
sure** it is, and **every raw signal** it read to get there.

```dart
final state = await AndroidDesktopMode.getState();

if (state.isDesktopMode) {
  print(state.implementation); // DesktopModeImplementation.samsungDex
  print(state.confidence);     // DesktopModeConfidence.confirmed
  print(state.reasons);        // [samsung_dex_enabled]
}
```

## Install

```bash
flutter pub add android_desktop_mode
```

Android only. On every other platform the API resolves to
`DesktopModeState.notDesktop()`, so calls need no `Platform.isAndroid` guard.

Minimum Android SDK: 24.

## Usage

### One-shot check

```dart
if (await AndroidDesktopMode.isDesktopMode()) {
  // Lay out for a mouse, a keyboard and a large resizable window.
}
```

### React to changes

A device can enter or leave desktop mode while your app is running (dock the phone, plug in
HDMI, toggle DeX). `stateChanges` emits the current state immediately and then on every
change:

```dart
StreamSubscription<DesktopModeState>? sub;

@override
void initState() {
  super.initState();
  sub = AndroidDesktopMode.stateChanges.listen((state) {
    setState(() => _desktop = state.isDesktopMode);
  });
}

@override
void dispose() {
  sub?.cancel();
  super.dispose();
}
```

Or use the widget:

```dart
DesktopModeBuilder(
  builder: (context, state) =>
      state.isDesktopMode ? const DesktopLayout() : const PhoneLayout(),
)
```

### Choose how much evidence you need

`isDesktopMode` uses `DesktopModeConfidence.likely` as its threshold. Pick your own:

```dart
// Only trust an explicit vendor/platform answer.
await AndroidDesktopMode.isDesktopMode(
  minimumConfidence: DesktopModeConfidence.confirmed,
);

// Also accept "there is an external screen and a mouse".
await AndroidDesktopMode.isDesktopMode(
  minimumConfidence: DesktopModeConfidence.heuristic,
);
```

| Confidence  | Meaning                                                                |
| ----------- | ---------------------------------------------------------------------- |
| `confirmed` | A vendor or platform API reported a desktop session.                    |
| `likely`    | Strong platform evidence (desk UI mode, PC device type, app on an external screen with input devices). |
| `heuristic` | Circumstantial only (an external screen, or a mouse and keyboard on a freeform-capable device). |
| `none`      | Nothing suggests a desktop session.                                     |

### Inspect the raw signals

Every signal the plugin read is on `state.signals` — useful for debugging, and for filing
device reports for a vendor the plugin does not know yet:

```dart
final signals = (await AndroidDesktopMode.getState()).signals;
signals.samsungDexEnabled;        // Samsung says DeX is on
signals.samsungDexDisplayType;    // standalone (device screen) or dual (external screen)
signals.inFreeformWindow;         // this task is in a freeform window
signals.captionBarVisible;        // the system draws a desktop caption bar
signals.onExternalDisplay;        // the activity is on a non-default display
signals.hasPointerDevice;         // a mouse or trackpad is attached
signals.vendorDesktopFeatures;    // vendor desktop-related system features
```

The example app renders all of them and can copy the whole set to the clipboard.

## Which Android systems have a desktop mode?

| System | Desktop mode | How this plugin detects it | Best confidence |
| --- | --- | --- | --- |
| **Samsung** One UI | **Samsung DeX** — wired to a monitor, wireless, DeX on Tab (on the device's own screen) and DeX for PC | `SemDesktopModeManager.getDesktopModeState()`, `Configuration.semDesktopModeEnabled`, and the DeX enter/exit broadcasts. Also reports whether DeX is `standalone` or `dual`. | `confirmed` |
| **ChromeOS** (ARC / ARCVM) | Android apps always run in resizable desktop windows | `org.chromium.arc` and `org.chromium.arc.device_management` system features | `confirmed` |
| **Android / AOSP** 15 QPR+ and 16+ (Pixel, tablets, connected displays) | **Desktop windowing**: freeform windows with a system caption bar, on-device or on a connected display | Freeform windowing mode, plus the caption-bar window inset (`WindowInsets.Type.captionBar()`) | `confirmed` |
| **Huawei / Honor** (EMUI, MagicOS) | **Desktop Mode / PC Mode** (Easy Projection) | Best-effort reflection on the vendor framework (`HwPCUtils`), then the platform signals below | `confirmed` when the probe answers, otherwise `likely` |
| **Motorola / Lenovo** | **Ready For** / Smart Connect desktop | No vendor API is published — platform signals only (desk UI mode, external display + keyboard/mouse) | `likely` |
| **Xiaomi** (HyperOS PC mode, MIUI+) | PC mode on phones and tablets | Platform signals only | `likely` |
| **OPPO / OnePlus** (O+ Connect / PC Connect), **vivo**, **ASUS**, **Nothing**, others | Varies by model and region | Platform signals only | `likely` |
| Android-x86, Bliss OS and similar desktop ports | Desktop by nature | `android.hardware.type.pc` / freeform windowing | `likely` |

Only the Samsung, ChromeOS and AOSP paths are based on documented behaviour. Everything
else is best-effort: vendors ship desktop modes without a public API, so the plugin falls
back to platform signals, and reports how sure it is instead of guessing. If your device
reports the wrong thing, [open an issue][issues] with the copied signals from the example
app.

## Making your app behave in desktop mode

Detection is only half the job. In your app's `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:resizeableActivity="true"
    android:configChanges="orientation|keyboardHidden|keyboard|navigation|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    ... >
```

Without those `configChanges` your activity is destroyed and recreated every time the
device enters or leaves DeX. Samsung additionally recommends keeping the process alive
across the transition:

```xml
<meta-data
    android:name="com.samsung.android.multidisplay.keep_process_alive"
    android:value="true" />
```

A note on philosophy: Google's guidance is to adapt to the *window* (size, pointer,
keyboard) rather than to the *device*. Use this plugin for the decisions that genuinely
depend on the desktop session — desktop chrome, window management, "you are on a big
screen" onboarding, analytics — and keep using `MediaQuery` for layout.

## API

| Member | Description |
| --- | --- |
| `AndroidDesktopMode.getState()` | The current `DesktopModeState`, with signals and reasons. |
| `AndroidDesktopMode.isDesktopMode({minimumConfidence})` | Just the boolean. |
| `AndroidDesktopMode.stateChanges` | Broadcast stream, emits the current state then every change. |
| `AndroidDesktopMode.isSupportedPlatform` | `true` on Android only. |
| `DesktopModeBuilder` | Widget that rebuilds on desktop-mode changes. |

The Android side watches configuration changes, DeX broadcasts, display hotplugs and input
device changes, and only emits when the resolved state actually differs.

### Testing

Swap the platform implementation to fake a desktop session:

```dart
class FakeDesktop extends AndroidDesktopModePlatform with MockPlatformInterfaceMixin {
  @override
  Future<DesktopModeState> getState() async => const DesktopModeState(
        confidence: DesktopModeConfidence.confirmed,
        implementation: DesktopModeImplementation.samsungDex,
      );

  @override
  Stream<DesktopModeState> get stateChanges => Stream.value(...);
}

AndroidDesktopModePlatform.instance = FakeDesktop();
```

## Limitations

- Window-scoped signals (caption bar, "am I on an external display", multi-window) need an
  attached activity; from a background isolate they read as `false`.
- The caption-bar signal needs Android 11 (API 30).
- Vendor probes rely on reflection into vendor frameworks. They are fully guarded — a miss
  costs nothing but a lower confidence — but they can go stale when a vendor renames things.
- The plugin never asks for a permission and never touches the network.

## Contributing

Device reports are the most valuable contribution: run the example app on a device in
desktop mode, tap the copy button, and paste the signals into an [issue][issues]. That is
how support for vendors beyond Samsung/ChromeOS/AOSP gets confirmed.

## Sources

- [Samsung — Optimizing your app for DeX](https://developer.samsung.com/samsung-dex/modify-optimizing.html)
- [Samsung — How to detect the Samsung DeX mode](https://developer.samsung.com/sdp/blog/en/2017/07/27/samsung-dex-how-to-detect-the-samsung-dex-mode)
- [Android — Support desktop windowing](https://developer.android.com/develop/adaptive-apps/guides/support-desktop-windowing)
- [Android — Support multi-window](https://developer.android.com/guide/topics/large-screens/multi-window-support)
- [AOSP — Desktop windowing](https://source.android.com/docs/core/display/desktop-windowing)
- [Android Developers Blog — Enhanced Android desktop experiences with connected displays](https://android-developers.googleblog.com/2025/06/developer-preview-enhanced-android-desktop-experiences-connected-displays.html)
- [Android — Test your game on ChromeOS devices](https://developer.android.com/games/playgames/pg-chromeos)

## License

MIT — see [LICENSE](LICENSE).

[issues]: https://github.com/esnawapon/android_desktop_mode/issues

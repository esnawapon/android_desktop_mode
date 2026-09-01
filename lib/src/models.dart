import 'package:flutter/foundation.dart';

/// How sure the plugin is that the app is currently running in a desktop session.
///
/// Ordered from weakest to strongest, so [DesktopModeConfidence.isAtLeast] can be used
/// to pick your own threshold.
enum DesktopModeConfidence {
  /// Nothing suggests a desktop session.
  none,

  /// Circumstantial evidence only, such as an external screen being plugged in.
  heuristic,

  /// Strong platform evidence, but no vendor API confirmed it.
  likely,

  /// A vendor or platform API explicitly reported a desktop session.
  confirmed;

  /// Whether this confidence is at least as strong as [other].
  bool isAtLeast(DesktopModeConfidence other) => index >= other.index;

  static DesktopModeConfidence _fromWire(Object? value) =>
      DesktopModeConfidence.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => DesktopModeConfidence.none,
      );
}

/// Which desktop stack the device is running.
enum DesktopModeImplementation {
  /// No desktop session detected.
  none,

  /// Samsung DeX (One UI), wired, wireless or on the device's own screen.
  samsungDex,

  /// Android apps running on ChromeOS, which is always a windowed desktop.
  chromeOs,

  /// AOSP/Google desktop windowing: freeform windows with a system caption bar,
  /// as shipped on Android 15 QPR/16+ and on OEM builds that enable it.
  androidDesktopWindowing,

  /// Huawei/Honor "PC mode" (EMUI, MagicOS).
  huaweiPcMode,

  /// Another vendor desktop mode identified through a vendor probe.
  vendorDesktopMode,

  /// A desktop session was detected but the stack behind it could not be named.
  unknown;

  static DesktopModeImplementation _fromWire(Object? value) =>
      DesktopModeImplementation.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => DesktopModeImplementation.unknown,
      );
}

/// Where a Samsung DeX session is being rendered.
enum DexDisplayType {
  /// Not a DeX session, or Samsung did not report a display type.
  unknown,

  /// DeX runs on the device's own screen (DeX on Tab, DeX on the phone screen).
  standalone,

  /// DeX runs on an external screen while the device screen stays usable.
  dual;

  static DexDisplayType _fromWire(Object? value) =>
      DexDisplayType.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => DexDisplayType.unknown,
      );
}

/// The raw signals the platform answered with.
///
/// Handy for debugging and for filing device reports: nothing is hidden, and a signal the
/// plugin could not read is reported as `false`/empty rather than as an error.
@immutable
class DesktopModeSignals {
  /// Creates a set of raw signals. Every field defaults to "not detected".
  const DesktopModeSignals({
    this.samsungDexAvailable = false,
    this.samsungDexEnabled = false,
    this.samsungDexDisplayType = DexDisplayType.unknown,
    this.isChromeOs = false,
    this.supportsFreeformWindows = false,
    this.isPcDeviceType = false,
    this.inFreeformWindow = false,
    this.captionBarVisible = false,
    this.isDeskUiMode = false,
    this.inMultiWindow = false,
    this.onExternalDisplay = false,
    this.externalDisplayCount = 0,
    this.hasHardwareKeyboard = false,
    this.hasPointerDevice = false,
    this.vendorDesktopActive = false,
    this.vendorProbe,
    this.vendorDesktopFeatures = const <String>[],
    this.manufacturer = '',
    this.brand = '',
    this.model = '',
    this.sdkInt = 0,
  });

  /// Whether the device exposes Samsung's DeX APIs at all.
  final bool samsungDexAvailable;

  /// Whether Samsung reported an active DeX session.
  final bool samsungDexEnabled;

  /// Where DeX is rendering, when DeX reported it.
  final DexDisplayType samsungDexDisplayType;

  /// Whether the app runs on ChromeOS (ARC/ARCVM).
  final bool isChromeOs;

  /// Whether the device declares `android.software.freeform_window_management`.
  final bool supportsFreeformWindows;

  /// Whether the device declares `android.hardware.type.pc`.
  final bool isPcDeviceType;

  /// Whether this task is in a freeform window right now.
  final bool inFreeformWindow;

  /// Whether the system draws a desktop caption bar over this window (API 30+).
  final bool captionBarVisible;

  /// Whether the UI mode is `UI_MODE_TYPE_DESK`.
  final bool isDeskUiMode;

  /// Whether the activity is in any multi-window mode.
  final bool inMultiWindow;

  /// Whether the activity is being shown on a non-default display.
  final bool onExternalDisplay;

  /// How many external/presentation displays are attached.
  final int externalDisplayCount;

  /// Whether a physical keyboard is attached.
  final bool hasHardwareKeyboard;

  /// Whether a mouse or trackpad is attached.
  final bool hasPointerDevice;

  /// Whether a vendor-specific probe reported an active desktop session.
  final bool vendorDesktopActive;

  /// The probe that answered, for example `HwPCUtils.isInWindowsCastMode`.
  final String? vendorProbe;

  /// System features that look desktop-mode related. These describe what the device
  /// *supports*, not what it is doing right now, and are meant for device reports.
  final List<String> vendorDesktopFeatures;

  /// `Build.MANUFACTURER`.
  final String manufacturer;

  /// `Build.BRAND`.
  final String brand;

  /// `Build.MODEL`.
  final String model;

  /// `Build.VERSION.SDK_INT`.
  final int sdkInt;

  /// Reads signals from the platform channel payload.
  factory DesktopModeSignals.fromMap(Map<Object?, Object?> map) =>
      DesktopModeSignals(
        samsungDexAvailable: map['samsungDexAvailable'] == true,
        samsungDexEnabled: map['samsungDexEnabled'] == true,
        samsungDexDisplayType: DexDisplayType._fromWire(
          map['samsungDexDisplayType'],
        ),
        isChromeOs: map['isChromeOs'] == true,
        supportsFreeformWindows: map['supportsFreeformWindows'] == true,
        isPcDeviceType: map['isPcDeviceType'] == true,
        inFreeformWindow: map['inFreeformWindow'] == true,
        captionBarVisible: map['captionBarVisible'] == true,
        isDeskUiMode: map['isDeskUiMode'] == true,
        inMultiWindow: map['inMultiWindow'] == true,
        onExternalDisplay: map['onExternalDisplay'] == true,
        externalDisplayCount:
            (map['externalDisplayCount'] as num?)?.toInt() ?? 0,
        hasHardwareKeyboard: map['hasHardwareKeyboard'] == true,
        hasPointerDevice: map['hasPointerDevice'] == true,
        vendorDesktopActive: map['vendorDesktopActive'] == true,
        vendorProbe: map['vendorProbe'] as String?,
        vendorDesktopFeatures: List<String>.unmodifiable(
          (map['vendorDesktopFeatures'] as List<Object?>? ?? const <Object?>[])
              .whereType<String>(),
        ),
        manufacturer: map['manufacturer'] as String? ?? '',
        brand: map['brand'] as String? ?? '',
        model: map['model'] as String? ?? '',
        sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      );

  /// The signals as a plain map, in the same shape the platform sends them.
  Map<String, Object?> toMap() => <String, Object?>{
    'samsungDexAvailable': samsungDexAvailable,
    'samsungDexEnabled': samsungDexEnabled,
    'samsungDexDisplayType': samsungDexDisplayType.name,
    'isChromeOs': isChromeOs,
    'supportsFreeformWindows': supportsFreeformWindows,
    'isPcDeviceType': isPcDeviceType,
    'inFreeformWindow': inFreeformWindow,
    'captionBarVisible': captionBarVisible,
    'isDeskUiMode': isDeskUiMode,
    'inMultiWindow': inMultiWindow,
    'onExternalDisplay': onExternalDisplay,
    'externalDisplayCount': externalDisplayCount,
    'hasHardwareKeyboard': hasHardwareKeyboard,
    'hasPointerDevice': hasPointerDevice,
    'vendorDesktopActive': vendorDesktopActive,
    'vendorProbe': vendorProbe,
    'vendorDesktopFeatures': vendorDesktopFeatures,
    'manufacturer': manufacturer,
    'brand': brand,
    'model': model,
    'sdkInt': sdkInt,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopModeSignals &&
          samsungDexAvailable == other.samsungDexAvailable &&
          samsungDexEnabled == other.samsungDexEnabled &&
          samsungDexDisplayType == other.samsungDexDisplayType &&
          isChromeOs == other.isChromeOs &&
          supportsFreeformWindows == other.supportsFreeformWindows &&
          isPcDeviceType == other.isPcDeviceType &&
          inFreeformWindow == other.inFreeformWindow &&
          captionBarVisible == other.captionBarVisible &&
          isDeskUiMode == other.isDeskUiMode &&
          inMultiWindow == other.inMultiWindow &&
          onExternalDisplay == other.onExternalDisplay &&
          externalDisplayCount == other.externalDisplayCount &&
          hasHardwareKeyboard == other.hasHardwareKeyboard &&
          hasPointerDevice == other.hasPointerDevice &&
          vendorDesktopActive == other.vendorDesktopActive &&
          vendorProbe == other.vendorProbe &&
          listEquals(vendorDesktopFeatures, other.vendorDesktopFeatures) &&
          manufacturer == other.manufacturer &&
          brand == other.brand &&
          model == other.model &&
          sdkInt == other.sdkInt;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    samsungDexAvailable,
    samsungDexEnabled,
    samsungDexDisplayType,
    isChromeOs,
    supportsFreeformWindows,
    isPcDeviceType,
    inFreeformWindow,
    captionBarVisible,
    isDeskUiMode,
    inMultiWindow,
    onExternalDisplay,
    externalDisplayCount,
    hasHardwareKeyboard,
    hasPointerDevice,
    vendorDesktopActive,
    vendorProbe,
    Object.hashAll(vendorDesktopFeatures),
    manufacturer,
    brand,
    model,
    sdkInt,
  ]);

  @override
  String toString() => 'DesktopModeSignals(${toMap()})';
}

/// The answer to "is this device in desktop mode right now?".
@immutable
class DesktopModeState {
  /// Creates a state. Prefer [DesktopModeState.fromMap] when decoding platform data.
  const DesktopModeState({
    required this.confidence,
    required this.implementation,
    this.reasons = const <String>[],
    this.signals = const DesktopModeSignals(),
  });

  /// The state reported on platforms this plugin does not cover (everything but Android).
  const DesktopModeState.notDesktop()
    : confidence = DesktopModeConfidence.none,
      implementation = DesktopModeImplementation.none,
      reasons = const <String>[],
      signals = const DesktopModeSignals();

  /// How sure the plugin is.
  final DesktopModeConfidence confidence;

  /// The desktop stack behind the detection.
  final DesktopModeImplementation implementation;

  /// Machine-readable tags for every signal that fired, for example
  /// `samsung_dex_enabled` or `external_display_with_input_devices`.
  final List<String> reasons;

  /// The raw signals behind [confidence].
  final DesktopModeSignals signals;

  /// Whether the device is in desktop mode, using [DesktopModeConfidence.likely] as the
  /// threshold. Use [isDesktopModeAtLeast] to choose a different one.
  bool get isDesktopMode => isDesktopModeAtLeast(DesktopModeConfidence.likely);

  /// Whether the detection reached at least [minimumConfidence].
  bool isDesktopModeAtLeast(DesktopModeConfidence minimumConfidence) =>
      confidence.isAtLeast(minimumConfidence) &&
      confidence != DesktopModeConfidence.none;

  /// Reads a state from the platform channel payload.
  factory DesktopModeState.fromMap(
    Map<Object?, Object?> map,
  ) => DesktopModeState(
    confidence: DesktopModeConfidence._fromWire(map['confidence']),
    implementation: DesktopModeImplementation._fromWire(map['implementation']),
    reasons: List<String>.unmodifiable(
      (map['reasons'] as List<Object?>? ?? const <Object?>[])
          .whereType<String>(),
    ),
    signals: DesktopModeSignals.fromMap(
      (map['signals'] as Map<Object?, Object?>?) ?? const <Object?, Object?>{},
    ),
  );

  /// The state as a plain map, in the same shape the platform sends it.
  Map<String, Object?> toMap() => <String, Object?>{
    'confidence': confidence.name,
    'implementation': implementation.name,
    'reasons': reasons,
    'signals': signals.toMap(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopModeState &&
          confidence == other.confidence &&
          implementation == other.implementation &&
          listEquals(reasons, other.reasons) &&
          signals == other.signals;

  @override
  int get hashCode =>
      Object.hash(confidence, implementation, Object.hashAll(reasons), signals);

  @override
  String toString() =>
      'DesktopModeState(confidence: ${confidence.name}, '
      'implementation: ${implementation.name}, reasons: $reasons)';
}

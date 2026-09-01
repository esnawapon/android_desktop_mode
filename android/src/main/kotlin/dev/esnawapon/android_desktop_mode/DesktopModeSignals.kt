package dev.esnawapon.android_desktop_mode

/**
 * How sure the plugin is that the device is currently presenting a desktop experience.
 *
 * The values are ordered: [NONE] < [HEURISTIC] < [LIKELY] < [CONFIRMED].
 */
enum class DesktopModeConfidence(val wireName: String) {
    /** No signal at all: the app looks like it is running as a regular phone/tablet app. */
    NONE("none"),

    /** Circumstantial evidence only (an external screen, a mouse, ...). */
    HEURISTIC("heuristic"),

    /** Strong platform evidence, but no vendor API confirmed it. */
    LIKELY("likely"),

    /** A vendor or platform API explicitly reported a desktop session. */
    CONFIRMED("confirmed"),
}

/** Which desktop stack produced the detection. */
enum class DesktopModeImplementation(val wireName: String) {
    NONE("none"),
    SAMSUNG_DEX("samsungDex"),
    CHROME_OS("chromeOs"),
    ANDROID_DESKTOP_WINDOWING("androidDesktopWindowing"),
    HUAWEI_PC_MODE("huaweiPcMode"),
    VENDOR_DESKTOP_MODE("vendorDesktopMode"),
    UNKNOWN("unknown"),
}

/** Samsung DeX reports where the DeX session is being rendered. */
enum class DexDisplayType(val wireName: String) {
    UNKNOWN("unknown"),

    /** DeX runs on the device's own screen (DeX on Tab / DeX on phone screen). */
    STANDALONE("standalone"),

    /** DeX runs on an external screen while the device screen stays usable. */
    DUAL("dual"),
}

/**
 * Every raw signal the plugin was able to read. Exposed to Dart as-is so apps (and bug
 * reports) can see exactly what the device answered.
 */
data class DesktopModeSignals(
    // -- Samsung DeX ------------------------------------------------------------------
    val samsungDexAvailable: Boolean = false,
    val samsungDexEnabled: Boolean = false,
    val samsungDexDisplayType: DexDisplayType = DexDisplayType.UNKNOWN,
    // -- ChromeOS ---------------------------------------------------------------------
    val isChromeOs: Boolean = false,
    // -- AOSP / Google desktop windowing ----------------------------------------------
    val supportsFreeformWindows: Boolean = false,
    val isPcDeviceType: Boolean = false,
    val inFreeformWindow: Boolean = false,
    val captionBarVisible: Boolean = false,
    val isDeskUiMode: Boolean = false,
    val inMultiWindow: Boolean = false,
    // -- Displays & peripherals -------------------------------------------------------
    val onExternalDisplay: Boolean = false,
    val externalDisplayCount: Int = 0,
    val hasHardwareKeyboard: Boolean = false,
    val hasPointerDevice: Boolean = false,
    // -- Other vendors ----------------------------------------------------------------
    val vendorDesktopActive: Boolean = false,
    val vendorProbe: String? = null,
    val vendorDesktopFeatures: List<String> = emptyList(),
    // -- Device -----------------------------------------------------------------------
    val manufacturer: String = "",
    val brand: String = "",
    val model: String = "",
    val sdkInt: Int = 0,
) {
    fun toMap(): Map<String, Any?> =
        mapOf(
            "samsungDexAvailable" to samsungDexAvailable,
            "samsungDexEnabled" to samsungDexEnabled,
            "samsungDexDisplayType" to samsungDexDisplayType.wireName,
            "isChromeOs" to isChromeOs,
            "supportsFreeformWindows" to supportsFreeformWindows,
            "isPcDeviceType" to isPcDeviceType,
            "inFreeformWindow" to inFreeformWindow,
            "captionBarVisible" to captionBarVisible,
            "isDeskUiMode" to isDeskUiMode,
            "inMultiWindow" to inMultiWindow,
            "onExternalDisplay" to onExternalDisplay,
            "externalDisplayCount" to externalDisplayCount,
            "hasHardwareKeyboard" to hasHardwareKeyboard,
            "hasPointerDevice" to hasPointerDevice,
            "vendorDesktopActive" to vendorDesktopActive,
            "vendorProbe" to vendorProbe,
            "vendorDesktopFeatures" to vendorDesktopFeatures,
            "manufacturer" to manufacturer,
            "brand" to brand,
            "model" to model,
            "sdkInt" to sdkInt,
        )
}

/** The resolved answer for a set of [DesktopModeSignals]. */
data class DesktopModeResult(
    val confidence: DesktopModeConfidence,
    val implementation: DesktopModeImplementation,
    val reasons: List<String>,
    val signals: DesktopModeSignals,
) {
    fun toMap(): Map<String, Any?> =
        mapOf(
            "confidence" to confidence.wireName,
            "implementation" to implementation.wireName,
            "reasons" to reasons,
            "signals" to signals.toMap(),
        )
}

/**
 * Turns raw signals into a verdict.
 *
 * Pure Kotlin on purpose: the whole decision table is covered by plain JVM unit tests, no
 * emulator or Robolectric needed.
 */
object DesktopModeResolver {
    fun resolve(s: DesktopModeSignals): DesktopModeResult {
        val reasons = mutableListOf<String>()
        var confidence = DesktopModeConfidence.NONE
        var implementation = DesktopModeImplementation.NONE

        fun raise(
            level: DesktopModeConfidence,
            impl: DesktopModeImplementation,
            reason: String,
        ) {
            reasons += reason
            if (level.ordinal > confidence.ordinal) {
                confidence = level
                implementation = impl
            } else if (level == confidence &&
                impl != DesktopModeImplementation.UNKNOWN &&
                (
                    implementation == DesktopModeImplementation.NONE ||
                        implementation == DesktopModeImplementation.UNKNOWN
                )
            ) {
                implementation = impl
            }
        }

        // --- Confirmed: a vendor or platform API said so. -------------------------------
        if (s.samsungDexEnabled) {
            raise(
                DesktopModeConfidence.CONFIRMED,
                DesktopModeImplementation.SAMSUNG_DEX,
                "samsung_dex_enabled",
            )
        }
        if (s.vendorDesktopActive) {
            val impl =
                if (s.manufacturer.equals("HUAWEI", true) || s.brand.equals("HONOR", true)) {
                    DesktopModeImplementation.HUAWEI_PC_MODE
                } else {
                    DesktopModeImplementation.VENDOR_DESKTOP_MODE
                }
            raise(
                DesktopModeConfidence.CONFIRMED,
                impl,
                "vendor_probe:" + (s.vendorProbe ?: "unknown"),
            )
        }
        if (s.isChromeOs) {
            raise(
                DesktopModeConfidence.CONFIRMED,
                DesktopModeImplementation.CHROME_OS,
                "chrome_os",
            )
        }
        if (s.inFreeformWindow) {
            raise(
                DesktopModeConfidence.CONFIRMED,
                DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING,
                "freeform_windowing_mode",
            )
        }
        if (s.captionBarVisible) {
            raise(
                DesktopModeConfidence.CONFIRMED,
                DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING,
                "caption_bar_visible",
            )
        }

        // --- Likely: strong platform hints, no explicit confirmation. -------------------
        if (s.isDeskUiMode) {
            raise(
                DesktopModeConfidence.LIKELY,
                DesktopModeImplementation.UNKNOWN,
                "desk_ui_mode",
            )
        }
        if (s.isPcDeviceType) {
            raise(
                DesktopModeConfidence.LIKELY,
                DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING,
                "feature_pc",
            )
        }
        if (s.onExternalDisplay && (s.hasPointerDevice || s.hasHardwareKeyboard)) {
            raise(
                DesktopModeConfidence.LIKELY,
                DesktopModeImplementation.UNKNOWN,
                "external_display_with_input_devices",
            )
        }

        // --- Heuristic: circumstantial only. --------------------------------------------
        if (s.onExternalDisplay) {
            raise(
                DesktopModeConfidence.HEURISTIC,
                DesktopModeImplementation.UNKNOWN,
                "running_on_external_display",
            )
        }
        if (s.externalDisplayCount > 0) {
            raise(
                DesktopModeConfidence.HEURISTIC,
                DesktopModeImplementation.UNKNOWN,
                "external_display_connected",
            )
        }
        if (s.hasPointerDevice && s.hasHardwareKeyboard && s.supportsFreeformWindows) {
            raise(
                DesktopModeConfidence.HEURISTIC,
                DesktopModeImplementation.UNKNOWN,
                "pointer_and_keyboard_on_freeform_capable_device",
            )
        }

        if (confidence == DesktopModeConfidence.NONE) {
            implementation = DesktopModeImplementation.NONE
        }
        return DesktopModeResult(confidence, implementation, reasons, s)
    }
}

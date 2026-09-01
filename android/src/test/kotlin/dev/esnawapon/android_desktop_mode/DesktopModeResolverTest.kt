package dev.esnawapon.android_desktop_mode

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The decision table is pure Kotlin, so it is covered without an emulator.
 *
 * Run with `./gradlew :android_desktop_mode:testDebugUnitTest` from `example/android/`.
 */
internal class DesktopModeResolverTest {
    private fun resolve(signals: DesktopModeSignals) = DesktopModeResolver.resolve(signals)

    @Test
    fun `a plain phone is not in desktop mode`() {
        val result = resolve(DesktopModeSignals(manufacturer = "Google", model = "Pixel 9"))

        assertEquals(DesktopModeConfidence.NONE, result.confidence)
        assertEquals(DesktopModeImplementation.NONE, result.implementation)
        assertTrue(result.reasons.isEmpty())
    }

    @Test
    fun `an active DeX session is confirmed`() {
        val result =
            resolve(
                DesktopModeSignals(
                    samsungDexAvailable = true,
                    samsungDexEnabled = true,
                    samsungDexDisplayType = DexDisplayType.DUAL,
                    manufacturer = "samsung",
                ),
            )

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.SAMSUNG_DEX, result.implementation)
        assertTrue(result.reasons.contains("samsung_dex_enabled"))
    }

    @Test
    fun `a Samsung device with DeX available but idle is not in desktop mode`() {
        val result =
            resolve(
                DesktopModeSignals(
                    samsungDexAvailable = true,
                    samsungDexEnabled = false,
                    manufacturer = "samsung",
                ),
            )

        assertEquals(DesktopModeConfidence.NONE, result.confidence)
    }

    @Test
    fun `ChromeOS is confirmed`() {
        val result = resolve(DesktopModeSignals(isChromeOs = true, supportsFreeformWindows = true))

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.CHROME_OS, result.implementation)
    }

    @Test
    fun `a freeform window means desktop windowing`() {
        val result = resolve(DesktopModeSignals(inFreeformWindow = true, supportsFreeformWindows = true))

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING, result.implementation)
        assertTrue(result.reasons.contains("freeform_windowing_mode"))
    }

    @Test
    fun `a system caption bar means desktop windowing`() {
        val result = resolve(DesktopModeSignals(captionBarVisible = true))

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING, result.implementation)
    }

    @Test
    fun `a Huawei probe hit is reported as Huawei PC mode`() {
        val result =
            resolve(
                DesktopModeSignals(
                    vendorDesktopActive = true,
                    vendorProbe = "HwPCUtils.isInWindowsCastMode",
                    manufacturer = "HUAWEI",
                ),
            )

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.HUAWEI_PC_MODE, result.implementation)
        assertTrue(result.reasons.contains("vendor_probe:HwPCUtils.isInWindowsCastMode"))
    }

    @Test
    fun `an unknown vendor probe hit stays generic`() {
        val result =
            resolve(
                DesktopModeSignals(
                    vendorDesktopActive = true,
                    vendorProbe = "SomeVendorUtils.isDesktop",
                    manufacturer = "Xiaomi",
                ),
            )

        assertEquals(DesktopModeImplementation.VENDOR_DESKTOP_MODE, result.implementation)
    }

    @Test
    fun `desk ui mode alone is only likely`() {
        val result = resolve(DesktopModeSignals(isDeskUiMode = true))

        assertEquals(DesktopModeConfidence.LIKELY, result.confidence)
    }

    @Test
    fun `an external display with a mouse is likely`() {
        val result =
            resolve(
                DesktopModeSignals(
                    onExternalDisplay = true,
                    externalDisplayCount = 1,
                    hasPointerDevice = true,
                ),
            )

        assertEquals(DesktopModeConfidence.LIKELY, result.confidence)
        assertTrue(result.reasons.contains("external_display_with_input_devices"))
    }

    @Test
    fun `an external display on its own is only a heuristic`() {
        val result = resolve(DesktopModeSignals(externalDisplayCount = 1))

        assertEquals(DesktopModeConfidence.HEURISTIC, result.confidence)
        assertFalse(result.confidence.ordinal >= DesktopModeConfidence.LIKELY.ordinal)
    }

    @Test
    fun `a named implementation wins over an anonymous one at the same confidence`() {
        val result = resolve(DesktopModeSignals(isDeskUiMode = true, isPcDeviceType = true))

        assertEquals(DesktopModeConfidence.LIKELY, result.confidence)
        assertEquals(DesktopModeImplementation.ANDROID_DESKTOP_WINDOWING, result.implementation)
    }

    @Test
    fun `a confirmed verdict is not downgraded by weaker signals`() {
        val result =
            resolve(
                DesktopModeSignals(
                    samsungDexEnabled = true,
                    isDeskUiMode = true,
                    onExternalDisplay = true,
                    manufacturer = "samsung",
                ),
            )

        assertEquals(DesktopModeConfidence.CONFIRMED, result.confidence)
        assertEquals(DesktopModeImplementation.SAMSUNG_DEX, result.implementation)
        assertEquals(3, result.reasons.size)
    }

    @Test
    fun `the wire format keeps every signal`() {
        val signals =
            DesktopModeSignals(
                samsungDexAvailable = true,
                samsungDexEnabled = true,
                samsungDexDisplayType = DexDisplayType.STANDALONE,
                vendorDesktopFeatures = listOf("com.samsung.feature.samsung_experience_mobile"),
                manufacturer = "samsung",
                sdkInt = 34,
            )
        val map = DesktopModeResolver.resolve(signals).toMap()

        assertEquals("confirmed", map["confidence"])
        assertEquals("samsungDex", map["implementation"])

        @Suppress("UNCHECKED_CAST")
        val encodedSignals = map["signals"] as Map<String, Any?>
        assertEquals("standalone", encodedSignals["samsungDexDisplayType"])
        assertEquals(34, encodedSignals["sdkInt"])
        assertEquals(21, encodedSignals.size)
    }
}

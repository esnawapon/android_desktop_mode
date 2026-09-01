package dev.esnawapon.android_desktop_mode

import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display
import android.view.InputDevice
import android.view.WindowInsets

/**
 * Reads every desktop-mode signal the device is willing to answer and hands them to
 * [DesktopModeResolver].
 *
 * The detector works without an [Activity] (signals that need a window are simply reported
 * as `false`), which keeps it usable from a background isolate or before the first frame.
 */
internal class DesktopModeDetector(
    private val context: Context,
) {
    /** Set by the plugin while an activity is attached; used for window-scoped signals. */
    var activity: Activity? = null

    fun detect(): DesktopModeResult = DesktopModeResolver.resolve(collectSignals())

    private fun collectSignals(): DesktopModeSignals {
        val configuration = context.resources.configuration
        val dex = SamsungDexProbe.probe(context)
        val vendor = VendorProbe.probe(context)

        return DesktopModeSignals(
            samsungDexAvailable = dex.available,
            samsungDexEnabled = dex.enabled,
            samsungDexDisplayType = dex.displayType,
            isChromeOs = isChromeOs(),
            supportsFreeformWindows = hasFeature(FEATURE_FREEFORM),
            isPcDeviceType = hasFeature(FEATURE_PC),
            inFreeformWindow = isInFreeformWindow(activity?.resources?.configuration ?: configuration),
            captionBarVisible = isCaptionBarVisible(),
            isDeskUiMode = isDeskUiMode(configuration),
            inMultiWindow = activity?.isInMultiWindowMode == true,
            onExternalDisplay = isOnExternalDisplay(),
            externalDisplayCount = externalDisplayCount(),
            hasHardwareKeyboard = hasHardwareKeyboard(configuration),
            hasPointerDevice = hasPointerDevice(),
            vendorDesktopActive = vendor.active,
            vendorProbe = vendor.probe,
            vendorDesktopFeatures = vendor.features,
            manufacturer = Build.MANUFACTURER ?: "",
            brand = Build.BRAND ?: "",
            model = Build.MODEL ?: "",
            sdkInt = Build.VERSION.SDK_INT,
        )
    }

    // -- ChromeOS -------------------------------------------------------------------------

    private fun isChromeOs(): Boolean =
        hasFeature(FEATURE_ARC) ||
            hasFeature(FEATURE_ARC_DEVICE_MANAGEMENT) ||
            Build.DEVICE?.startsWith("cheets") == true ||
            Build.BRAND.equals("chromium", ignoreCase = true)

    private fun hasFeature(name: String): Boolean =
        try {
            context.packageManager.hasSystemFeature(name)
        } catch (_: Throwable) {
            false
        }

    // -- Desktop windowing ----------------------------------------------------------------

    /**
     * True when this task runs in a freeform window, which is what Android's desktop
     * windowing (Android 15 QPR / 16+, and OEM builds that enable it) puts apps into.
     *
     * `Configuration.windowConfiguration` is a hidden API, so reflection is tried first and
     * the (unrestricted) `toString()` output is parsed as a fallback.
     */
    private fun isInFreeformWindow(configuration: Configuration): Boolean {
        windowingModeByReflection(configuration)?.let { return it == WINDOWING_MODE_FREEFORM }
        return FREEFORM_TOSTRING.containsMatchIn(configuration.toString())
    }

    private fun windowingModeByReflection(configuration: Configuration): Int? =
        try {
            val field = Configuration::class.java.getDeclaredField("windowConfiguration")
            field.isAccessible = true
            val windowConfiguration = field.get(configuration)
            windowConfiguration
                ?.javaClass
                ?.getDeclaredMethod("getWindowingMode")
                ?.also { it.isAccessible = true }
                ?.invoke(windowConfiguration) as? Int
        } catch (_: Throwable) {
            null
        }

    /**
     * Desktop windows are drawn with a caption (title) bar owned by the system. The inset is
     * public API from API 30 on and is a reliable "this window has a desktop header" signal.
     */
    private fun isCaptionBarVisible(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        val insets = activity?.window?.decorView?.rootWindowInsets ?: return false
        return try {
            insets.isVisible(WindowInsets.Type.captionBar()) &&
                insets.getInsets(WindowInsets.Type.captionBar()).top > 0
        } catch (_: Throwable) {
            false
        }
    }

    private fun isDeskUiMode(configuration: Configuration): Boolean {
        val fromConfiguration =
            configuration.uiMode and Configuration.UI_MODE_TYPE_MASK == Configuration.UI_MODE_TYPE_DESK
        if (fromConfiguration) return true
        val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        return uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_DESK
    }

    // -- Displays -------------------------------------------------------------------------

    private fun isOnExternalDisplay(): Boolean {
        val activity = activity ?: return false
        val display =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                activity.display
            } else {
                @Suppress("DEPRECATION")
                activity.windowManager.defaultDisplay
            }
        return display != null && display.displayId != Display.DEFAULT_DISPLAY
    }

    private fun externalDisplayCount(): Int =
        try {
            val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
            displayManager
                ?.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
                ?.size ?: 0
        } catch (_: Throwable) {
            0
        }

    // -- Peripherals ----------------------------------------------------------------------

    private fun hasHardwareKeyboard(configuration: Configuration): Boolean {
        if (configuration.keyboard == Configuration.KEYBOARD_QWERTY &&
            configuration.hardKeyboardHidden == Configuration.HARDKEYBOARDHIDDEN_NO
        ) {
            return true
        }
        return anyInputDevice { device ->
            device.keyboardType == InputDevice.KEYBOARD_TYPE_ALPHABETIC &&
                device.sources and InputDevice.SOURCE_KEYBOARD == InputDevice.SOURCE_KEYBOARD
        }
    }

    private fun hasPointerDevice(): Boolean =
        anyInputDevice { device ->
            val sources = device.sources
            sources and InputDevice.SOURCE_MOUSE == InputDevice.SOURCE_MOUSE ||
                sources and InputDevice.SOURCE_TOUCHPAD == InputDevice.SOURCE_TOUCHPAD
        }

    private fun anyInputDevice(predicate: (InputDevice) -> Boolean): Boolean =
        try {
            InputDevice.getDeviceIds().any { id ->
                val device = InputDevice.getDevice(id)
                device != null && !device.isVirtual && predicate(device)
            }
        } catch (_: Throwable) {
            false
        }

    private companion object {
        const val FEATURE_FREEFORM = "android.software.freeform_window_management"
        const val FEATURE_PC = "android.hardware.type.pc"
        const val FEATURE_ARC = "org.chromium.arc"
        const val FEATURE_ARC_DEVICE_MANAGEMENT = "org.chromium.arc.device_management"

        /** `WindowConfiguration.WINDOWING_MODE_FREEFORM`. */
        const val WINDOWING_MODE_FREEFORM = 5

        val FREEFORM_TOSTRING = Regex("mWindowingMode=freeform")
    }
}

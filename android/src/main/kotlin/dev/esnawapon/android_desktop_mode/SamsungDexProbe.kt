package dev.esnawapon.android_desktop_mode

import android.content.Context
import android.content.res.Configuration

/**
 * Samsung DeX detection.
 *
 * Samsung exposes two documented ways of asking whether DeX is running, and this probe uses
 * both. Everything goes through reflection because the classes and fields only exist in One
 * UI builds, and even the constants are read from the device instead of being hardcoded, so
 * the probe keeps working if Samsung renumbers them.
 *
 *  1. `Configuration.semDesktopModeEnabled` compared with `Configuration.SEM_DESKTOP_MODE_ENABLED`.
 *  2. The `desktopmode` system service (`SemDesktopModeManager.getDesktopModeState()`), which
 *     also reports whether DeX renders on the device screen (standalone) or on an external
 *     screen (dual).
 *
 * See https://developer.samsung.com/samsung-dex/modify-optimizing.html
 */
internal object SamsungDexProbe {
    /** Broadcast Samsung sends when a DeX session starts. */
    const val ACTION_ENTER_DESKTOP_MODE = "android.app.action.ENTER_KNOX_DESKTOP_MODE"

    /** Broadcast Samsung sends when a DeX session ends. */
    const val ACTION_EXIT_DESKTOP_MODE = "android.app.action.EXIT_KNOX_DESKTOP_MODE"

    private const val DESKTOP_MODE_SERVICE = "desktopmode"
    private const val STATE_CLASS = "com.samsung.android.desktopmode.SemDesktopModeState"

    data class Result(
        val available: Boolean,
        val enabled: Boolean,
        val displayType: DexDisplayType,
    )

    fun probe(context: Context): Result {
        val fromService = probeDesktopModeService(context)
        if (fromService != null) return fromService

        val fromConfiguration = probeConfiguration(context.resources.configuration)
        if (fromConfiguration != null) {
            return Result(available = true, enabled = fromConfiguration, DexDisplayType.UNKNOWN)
        }
        return Result(available = false, enabled = false, displayType = DexDisplayType.UNKNOWN)
    }

    /** `Configuration.semDesktopModeEnabled == Configuration.SEM_DESKTOP_MODE_ENABLED`. */
    private fun probeConfiguration(configuration: Configuration): Boolean? =
        try {
            val type = configuration.javaClass
            val expected = type.getField("SEM_DESKTOP_MODE_ENABLED").getInt(type)
            val actual = type.getField("semDesktopModeEnabled").getInt(configuration)
            expected == actual
        } catch (_: Throwable) {
            null
        }

    /** `SemDesktopModeManager.getDesktopModeState()`, available on One UI 2.0 and newer. */
    private fun probeDesktopModeService(context: Context): Result? =
        try {
            val manager = context.getSystemService(DESKTOP_MODE_SERVICE)
            if (manager == null) {
                null
            } else {
                val state =
                    manager.javaClass
                        .getMethod("getDesktopModeState")
                        .invoke(manager)
                if (state == null) {
                    Result(available = true, enabled = false, displayType = DexDisplayType.UNKNOWN)
                } else {
                    val stateClass = Class.forName(STATE_CLASS)
                    val enabledValue =
                        stateClass.getMethod("getEnabled").invoke(state) as? Int
                    val expectedEnabled = intConstant(stateClass, "ENABLED")
                    val enabled =
                        enabledValue != null &&
                            expectedEnabled != null &&
                            enabledValue == expectedEnabled
                    Result(available = true, enabled = enabled, displayType = displayType(stateClass, state))
                }
            }
        } catch (_: Throwable) {
            null
        }

    private fun displayType(
        stateClass: Class<*>,
        state: Any,
    ): DexDisplayType =
        try {
            val value = stateClass.getMethod("getDisplayType").invoke(state) as? Int
                ?: return DexDisplayType.UNKNOWN
            when (value) {
                intConstant(stateClass, "DISPLAY_TYPE_STANDALONE") -> DexDisplayType.STANDALONE
                intConstant(stateClass, "DISPLAY_TYPE_DUAL") -> DexDisplayType.DUAL
                else -> DexDisplayType.UNKNOWN
            }
        } catch (_: Throwable) {
            DexDisplayType.UNKNOWN
        }

    private fun intConstant(
        type: Class<*>,
        name: String,
    ): Int? =
        try {
            type.getField(name).getInt(null)
        } catch (_: Throwable) {
            null
        }
}

package dev.esnawapon.android_desktop_mode

import android.content.Context

/**
 * Best-effort detection for desktop modes other than Samsung DeX and ChromeOS.
 *
 * None of these vendors publish a developer API, so everything here is guarded reflection
 * plus a scan of the system feature list. A miss costs nothing: the plugin falls back to the
 * platform signals in [DesktopModeDetector]. Everything the probe learns is reported back to
 * Dart in `signals.vendorDesktopFeatures` / `signals.vendorProbe`, which is what device
 * reports for new vendors should be based on.
 */
internal object VendorProbe {
    /**
     * Zero-argument boolean methods on vendor framework classes that report an active
     * desktop/PC session. Ordered so the most specific check wins.
     */
    private val REFLECTIVE_PROBES =
        listOf(
            // Huawei / Honor "PC mode" (EMUI / MagicOS). HwPCUtils lives in the vendor framework.
            "android.util.HwPCUtils" to listOf("isInWindowsCastMode", "isPcCastModeInServer", "isPcCastMode"),
            "com.huawei.android.util.HwPCUtils" to listOf("isInWindowsCastMode", "isPcCastMode"),
        )

    /**
     * Substrings that identify a vendor desktop-mode *capability* in the system feature list.
     * These say the device can do it, not that it is doing it right now.
     */
    private val FEATURE_KEYWORDS =
        listOf("dex", "desktopmode", "desktop_mode", "pcmode", "pc_mode", "readyfor", "ready_for", "multiwindow")

    data class Result(
        val active: Boolean,
        val probe: String?,
        val features: List<String>,
    )

    /** The system feature list never changes at runtime, so it is read once. */
    @Volatile
    private var cachedFeatures: List<String>? = null

    fun probe(context: Context): Result {
        val hit = reflectiveHit()
        val features = cachedFeatures ?: desktopFeatures(context).also { cachedFeatures = it }
        return Result(
            active = hit != null,
            probe = hit,
            features = features,
        )
    }

    /** Returns `"Class.method"` for the first vendor probe that answered `true`. */
    private fun reflectiveHit(): String? {
        for ((className, methods) in REFLECTIVE_PROBES) {
            val type =
                try {
                    Class.forName(className)
                } catch (_: Throwable) {
                    continue
                }
            for (method in methods) {
                val value =
                    try {
                        type.getMethod(method).invoke(null) as? Boolean
                    } catch (_: Throwable) {
                        null
                    }
                if (value == true) return "${type.simpleName}.$method"
            }
        }
        return null
    }

    private fun desktopFeatures(context: Context): List<String> =
        try {
            context.packageManager.systemAvailableFeatures
                .mapNotNull { it.name }
                .filter { name ->
                    val lower = name.lowercase()
                    FEATURE_KEYWORDS.any { lower.contains(it) }
                }.sorted()
                .distinct()
        } catch (_: Throwable) {
            emptyList()
        }
}

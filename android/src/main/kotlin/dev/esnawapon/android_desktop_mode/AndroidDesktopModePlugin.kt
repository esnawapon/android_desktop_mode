package dev.esnawapon.android_desktop_mode

import android.content.BroadcastReceiver
import android.content.ComponentCallbacks
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.hardware.display.DisplayManager
import android.hardware.input.InputManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Android side of the `android_desktop_mode` plugin. */
class AndroidDesktopModePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var detector: DesktopModeDetector

    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var lastEmitted: Map<String, Any?>? = null
    private var watching = false

    // -- FlutterPlugin ---------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        detector = DesktopModeDetector(context)
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopWatching()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // -- ActivityAware ---------------------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        detector.activity = binding.activity
        scheduleRefresh()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        detector.activity = null
    }

    // -- MethodCallHandler -----------------------------------------------------------------

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "getState" -> result.success(detector.detect().toMap())
            else -> result.notImplemented()
        }
    }

    // -- EventChannel.StreamHandler --------------------------------------------------------

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        eventSink = events
        lastEmitted = null
        startWatching()
        emit(force = true)
    }

    override fun onCancel(arguments: Any?) {
        stopWatching()
        eventSink = null
        lastEmitted = null
    }

    // -- Change tracking -------------------------------------------------------------------

    private fun emit(force: Boolean = false) {
        val sink = eventSink ?: return
        val state = detector.detect().toMap()
        if (!force && state == lastEmitted) return
        lastEmitted = state
        sink.success(state)
    }

    /**
     * Signals arrive slightly before the window is re-laid-out (window insets in particular),
     * so every trigger is sampled immediately and once more shortly after.
     */
    private fun scheduleRefresh() {
        handler.post { emit() }
        handler.postDelayed({ emit() }, SETTLE_DELAY_MS)
    }

    private fun startWatching() {
        if (watching) return
        watching = true

        context.registerComponentCallbacks(componentCallbacks)

        val filter =
            IntentFilter().apply {
                addAction(SamsungDexProbe.ACTION_ENTER_DESKTOP_MODE)
                addAction(SamsungDexProbe.ACTION_EXIT_DESKTOP_MODE)
                addAction(Intent.ACTION_CONFIGURATION_CHANGED)
                addAction(Intent.ACTION_DOCK_EVENT)
            }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(desktopModeReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(desktopModeReceiver, filter)
        }

        (context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager)
            ?.registerDisplayListener(displayListener, handler)
        (context.getSystemService(Context.INPUT_SERVICE) as? InputManager)
            ?.registerInputDeviceListener(inputDeviceListener, handler)
    }

    private fun stopWatching() {
        if (!watching) return
        watching = false
        handler.removeCallbacksAndMessages(null)

        runCatching { context.unregisterComponentCallbacks(componentCallbacks) }
        runCatching { context.unregisterReceiver(desktopModeReceiver) }
        runCatching {
            (context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager)
                ?.unregisterDisplayListener(displayListener)
        }
        runCatching {
            (context.getSystemService(Context.INPUT_SERVICE) as? InputManager)
                ?.unregisterInputDeviceListener(inputDeviceListener)
        }
    }

    private val componentCallbacks =
        object : ComponentCallbacks {
            override fun onConfigurationChanged(newConfig: Configuration) = scheduleRefresh()

            @Deprecated("Required by ComponentCallbacks")
            override fun onLowMemory() = Unit
        }

    private val desktopModeReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context?,
                intent: Intent?,
            ) = scheduleRefresh()
        }

    private val displayListener =
        object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = scheduleRefresh()

            override fun onDisplayRemoved(displayId: Int) = scheduleRefresh()

            override fun onDisplayChanged(displayId: Int) = scheduleRefresh()
        }

    private val inputDeviceListener =
        object : InputManager.InputDeviceListener {
            override fun onInputDeviceAdded(deviceId: Int) = scheduleRefresh()

            override fun onInputDeviceRemoved(deviceId: Int) = scheduleRefresh()

            override fun onInputDeviceChanged(deviceId: Int) = scheduleRefresh()
        }

    private companion object {
        const val METHOD_CHANNEL = "dev.esnawapon.android_desktop_mode/methods"
        const val EVENT_CHANNEL = "dev.esnawapon.android_desktop_mode/events"
        const val SETTLE_DELAY_MS = 350L
    }
}

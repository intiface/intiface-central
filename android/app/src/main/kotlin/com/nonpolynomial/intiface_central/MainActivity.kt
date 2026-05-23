package com.nonpolynomial.intiface_central

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  init {
    System.loadLibrary("rust_lib_intiface_central")
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MdnsForegroundTaskLifecycleListener.init(applicationContext)
    FlutterForegroundTaskPlugin.addTaskLifecycleListener(MdnsForegroundTaskLifecycleListener)
    MdnsPlatformChannel.register(applicationContext, flutterEngine)
  }
}

private object MdnsPlatformChannel {
  private const val CHANNEL_NAME = "com.nonpolynomial.intiface_central/mdns_platform_service"

  fun register(context: Context, flutterEngine: FlutterEngine) {
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      CHANNEL_NAME,
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "acquireMdnsMulticastLock" -> {
          result.success(MdnsMulticastLockManager.acquire(context.applicationContext))
        }
        "releaseMdnsMulticastLock" -> {
          result.success(MdnsMulticastLockManager.release())
        }
        else -> result.notImplemented()
      }
    }
  }
}

private object MdnsMulticastLockManager {
  private const val TAG = "IntifaceCentralMdns"
  private const val MDNS_MULTICAST_LOCK_TAG = "IntifaceCentralMdns"
  private var mdnsMulticastLock: WifiManager.MulticastLock? = null

  @Synchronized
  fun acquire(context: Context): Boolean {
    return try {
      val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
      if (wifiManager == null) {
        Log.w(TAG, "Unable to acquire mDNS multicast lock: WifiManager unavailable")
        return false
      }

      val lock = mdnsMulticastLock
        ?: wifiManager.createMulticastLock(MDNS_MULTICAST_LOCK_TAG).also {
          it.setReferenceCounted(false)
          mdnsMulticastLock = it
        }

      if (!lock.isHeld) {
        lock.acquire()
      }

      true
    } catch (e: SecurityException) {
      Log.e(TAG, "Unable to acquire mDNS multicast lock", e)
      false
    } catch (e: RuntimeException) {
      Log.e(TAG, "Unable to acquire mDNS multicast lock", e)
      false
    }
  }

  @Synchronized
  fun release(): Boolean {
    return try {
      val lock = mdnsMulticastLock
      mdnsMulticastLock = null
      if (lock?.isHeld == true) {
        lock.release()
      }
      true
    } catch (e: RuntimeException) {
      Log.e(TAG, "Unable to release mDNS multicast lock", e)
      false
    }
  }
}

private object MdnsForegroundTaskLifecycleListener : FlutterForegroundTaskLifecycleListener {
  private var applicationContext: Context? = null

  fun init(context: Context) {
    applicationContext = context.applicationContext
  }

  override fun onEngineCreate(flutterEngine: FlutterEngine?) {
    val context = applicationContext ?: return
    if (flutterEngine != null) {
      MdnsPlatformChannel.register(context, flutterEngine)
    }
  }

  override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

  override fun onTaskRepeatEvent() {}

  override fun onTaskDestroy() {}

  override fun onEngineWillDestroy() {}
}

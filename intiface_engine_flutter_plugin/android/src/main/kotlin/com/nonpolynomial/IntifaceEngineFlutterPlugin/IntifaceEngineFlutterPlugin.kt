package com.nonpolynomial.IntifaceEngineFlutterPlugin

import androidx.annotation.NonNull
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ButtplugPlugin */
class IntifaceEngineFlutterPlugin: FlutterPlugin, MethodCallHandler {

  init {
    System.loadLibrary("intiface_engine_flutter_bridge");
  }

  // All we need this class to do is initialize, to load our library. After that we'll never make
  // any calls on it, so there's no reason to set up a MethodHandler.
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    result.notImplemented()
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}

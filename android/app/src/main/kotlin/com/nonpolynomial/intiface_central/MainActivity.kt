package com.nonpolynomial.intiface_central

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  init {
    System.loadLibrary("intiface_engine_flutter_bridge");
  }

}

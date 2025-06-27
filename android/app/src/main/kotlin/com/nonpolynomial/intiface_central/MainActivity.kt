package com.nonpolynomial.intiface_central

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
  init {
    System.loadLibrary("rust_lib_intiface_central");
  }

}

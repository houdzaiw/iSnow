package com.example.project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var foreground = false

    override fun onResume() {
        super.onResume()
        foreground = true
    }

    override fun onPause() {
        foreground = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "isnow/room_audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        if (!foreground) {
                            result.error("not_foreground", "Room audio must start in the foreground", null)
                        } else {
                            RoomAudioService.start(this, call.argument<Boolean>("microphone") == true, result)
                        }
                    }
                    "stop" -> {
                        RoomAudioService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

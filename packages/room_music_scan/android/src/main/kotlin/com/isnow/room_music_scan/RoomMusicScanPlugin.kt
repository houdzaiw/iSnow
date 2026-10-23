package com.isnow.room_music_scan

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.concurrent.Executors

class RoomMusicScanPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var generation = 0
    private val requestCode = 28419
    private val permission: String get() = if (Build.VERSION.SDK_INT >= 33) {
        Manifest.permission.READ_MEDIA_AUDIO
    } else Manifest.permission.READ_EXTERNAL_STORAGE

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        if (executor.isShutdown) executor = Executors.newSingleThreadExecutor()
        channel = MethodChannel(binding.binaryMessenger, "isnow/room_music_scan")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        generation++
        channel.setMethodCallHandler(null)
        pendingPermission?.error("ACTIVITY_UNAVAILABLE", "Audio permission request interrupted", null)
        pendingPermission = null
        executor.shutdownNow()
    }

    private fun permissionStatus(): String {
        if (context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) return "granted"
        val activity = binding?.activity ?: return "denied"
        val requested = context.getSharedPreferences("room_music_permissions", Context.MODE_PRIVATE)
            .getBoolean(permission, false)
        return if (requested && !activity.shouldShowRequestPermissionRationale(permission)) {
            "permanentlyDenied"
        } else "denied"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "permission" -> result.success(permissionStatus())
            "requestPermission" -> requestPermission(result)
            "openSettings" -> {
                try {
                    context.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${context.packageName}")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("SETTINGS_UNAVAILABLE", "Unable to open audio permission settings", null)
                }
            }
            "scan" -> runIo(result) {
                AudioCatalog.scan(context, call.argument<Number>("minBytes")?.toLong() ?: 102400)
            }
            "exportAudio" -> runIo(result) {
                AudioCatalog.export(context, call.argument<String>("uri").orEmpty(),
                    call.argument<String>("name").orEmpty())
            }
            else -> result.notImplemented()
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val status = permissionStatus()
        if (status != "denied") {
            result.success(status)
            return
        }
        val activity = binding?.activity
        if (activity == null || activity.isFinishing) {
            result.error("ACTIVITY_UNAVAILABLE", "Open the music list to grant audio access", null)
            return
        }
        if (pendingPermission != null) {
            result.error("PERMISSION_BUSY", "Audio permission request is already in progress", null)
            return
        }
        pendingPermission = result
        try {
            activity.requestPermissions(arrayOf(permission), requestCode)
        } catch (error: Exception) {
            pendingPermission = null
            result.error("PERMISSION_UNAVAILABLE", "Unable to request audio access", null)
        }
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray): Boolean {
        if (code != requestCode) return false
        val result = pendingPermission
        pendingPermission = null
        if (grants.isEmpty()) {
            result?.success("denied")
        } else {
            context.getSharedPreferences("room_music_permissions", Context.MODE_PRIVATE)
                .edit().putBoolean(permission, true).apply()
            result?.success(permissionStatus())
        }
        return true
    }

    private fun runIo(result: MethodChannel.Result, action: () -> Any) {
        val epoch = generation
        if (executor.isShutdown) {
            result.error("SCAN_UNAVAILABLE", "Music scanner is unavailable", null)
            return
        }
        executor.execute {
            try {
                val value = action()
                main.post {
                    if (epoch == generation) result.success(value)
                    else if (value is String) File(value).delete()
                }
            } catch (error: Exception) {
                main.post {
                    if (epoch == generation) result.error("AUDIO_IO_FAILED", "Unable to read local music", null)
                }
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        onDetachedFromActivityForConfigChanges()
        pendingPermission?.error("ACTIVITY_UNAVAILABLE", "Audio permission request interrupted", null)
        pendingPermission = null
    }
}

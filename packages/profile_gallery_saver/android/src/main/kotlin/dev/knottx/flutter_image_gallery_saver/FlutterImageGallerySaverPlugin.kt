package dev.knottx.flutter_image_gallery_saver

import android.content.ContentValues
import android.Manifest
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.io.OutputStream
import java.util.concurrent.Executors

class FlutterImageGallerySaverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pending: Pair<MethodCall, Result>? = null
    private val permissionRequest = 59621

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }
    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromActivity() {
        onDetachedFromActivityForConfigChanges()
        pending?.second?.error("ACTIVITY_CLOSED", "Gallery operation cancelled", null)
        pending = null
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != permissionRequest) return false
        val request = pending
        pending = null
        if (request != null) {
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) perform(request.first, request.second)
            else request.second.error("PERMISSION_DENIED", "Photo saving permission denied", null)
        }
        return true
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dev.knottx.flutter_image_gallery_saver")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "save_file" && call.method != "save_image") {
            result.notImplemented()
            return
        }
        val context = applicationContext
        if (Build.VERSION.SDK_INT >= 23 && Build.VERSION.SDK_INT < 29 &&
            context?.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            val activity = activityBinding?.activity
            if (activity == null || pending != null) {
                result.error("UNAVAILABLE", "Photo saving is unavailable", null)
                return
            }
            pending = Pair(call, result)
            activity.requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), permissionRequest)
            return
        }
        perform(call, result)
    }

    private fun perform(call: MethodCall, result: Result) {
      executor.execute {
        // File copying and bitmap decoding must not block Flutter's UI thread.
        val mainResult = object : Result {
            override fun success(value: Any?) { main.post { result.success(value) } }
            override fun error(code: String, message: String?, details: Any?) { main.post { result.error(code, message, details) } }
            override fun notImplemented() { main.post { result.notImplemented() } }
        }
        val result = mainResult
        when (call.method) {
            "save_image" -> {
                val imageBytes = call.argument<ByteArray>("image_bytes")
                if (imageBytes == null) {
                    result.error("INVALID_ARGUMENTS", "No image bytes provided", null)
                    return@execute
                }
                val bmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                if (bmp == null) {
                    result.error("INVALID_ARGUMENTS", "Failed to decode image bytes", null)
                    return@execute
                }
                try {
                    saveImage(bmp)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            }
            "save_file" -> {
                val filePath = call.argument<String>("file_path")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENTS", "No file path provided", null)
                    return@execute
                }
                try {
                    saveFile(filePath)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
      }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pending?.second?.error("ENGINE_CLOSED", "Gallery operation cancelled", null)
        pending = null
        executor.shutdown()
    }

    private fun saveImage(bmp: Bitmap) {
        val fileUri: Uri = generateUri("jpg")
            ?: throw Exception("Failed to generate file URI")
        val fos: OutputStream = applicationContext?.contentResolver?.openOutputStream(fileUri)
            ?: throw Exception("Failed to open output stream")
        try {
            if (!bmp.compress(Bitmap.CompressFormat.JPEG, 100, fos)) {
                throw Exception("Bitmap compression failed")
            }
            fos.flush()
            publish(fileUri)
        } catch (e: IOException) {
            throw e
        } finally {
            fos.close()
            bmp.recycle()
        }
    }

    private fun saveFile(filePath: String) {
        val context = applicationContext ?: throw Exception("Application context is null")
        val originalFile = File(filePath)
        if (!originalFile.exists()) throw Exception("$filePath does not exist")
        // Cached network images may have no extension. Detect their actual MIME.
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(filePath, options)
        val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(options.outMimeType)
            ?: originalFile.extension
        val fileUri = generateUri(extension)
            ?: throw Exception("Failed to generate file URI")
        try {
        FileInputStream(originalFile).use { fileInputStream ->
            context.contentResolver.openOutputStream(fileUri)?.use { outputStream ->
                val buffer = ByteArray(10240)
                var count: Int
                while (fileInputStream.read(buffer).also { count = it } > 0) {
                    outputStream.write(buffer, 0, count)
                }
                outputStream.flush()
            } ?: throw Exception("Failed to open output stream")
        }
        publish(fileUri)
        } catch (error: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) context.contentResolver.delete(fileUri, null, null)
            else File(fileUri.path ?: "").delete()
            throw error
        }
    }

    private fun generateUri(extension: String = ""): Uri? {
        val fileName = "${System.currentTimeMillis()}"
        val mimeType = getMIMEType(extension)
        val isVideo = mimeType?.startsWith("video") == true

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // For Android 10 and above, use the MediaStore API.
            val collectionUri = if (isVideo) {
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            val relativePath = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                mimeType?.let {
                    val mimeKey = if (isVideo) MediaStore.Video.Media.MIME_TYPE else MediaStore.Images.Media.MIME_TYPE
                    put(mimeKey, it)
                }
            }
            applicationContext?.contentResolver?.insert(collectionUri, values)
        } else {
            // For Android versions below Q, use the external storage.
            val publicDir = if (isVideo) {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
            } else {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            }
            val storePath = publicDir.absolutePath
            val appDir = File(storePath).apply {
                if (!exists()) mkdirs()
            }
            val file = if (extension.isNotBlank()) {
                File(appDir, "$fileName.${extension.lowercase()}")
            } else {
                File(appDir, fileName)
            }
            Uri.fromFile(file)
        }
    }

    private fun getMIMEType(extension: String): String? {
        return extension.takeIf { it.isNotBlank() }
            ?.lowercase()
            ?.let { MimeTypeMap.getSingleton().getMimeTypeFromExtension(it) }
    }

    private fun publish(uri: Uri) {
        val context = applicationContext ?: throw Exception("Application context is null")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.contentResolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } else sendBroadcast(context, uri)
    }

    private fun sendBroadcast(context: Context, uri: Uri) {
        val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE).apply {
            data = uri
        }
        context.sendBroadcast(intent)
    }
}

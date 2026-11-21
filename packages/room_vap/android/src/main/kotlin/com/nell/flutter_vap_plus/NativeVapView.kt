package com.nell.flutter_vap_plus

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.os.Handler
import android.os.Looper
import com.tencent.qgame.animplayer.AnimConfig
import com.tencent.qgame.animplayer.AnimView
import com.tencent.qgame.animplayer.inter.IAnimListener
import com.tencent.qgame.animplayer.util.ScaleType
import com.tencent.qgame.animplayer.inter.IFetchResource
import com.tencent.qgame.animplayer.mix.Resource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONArray
import java.io.File
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.findViewTreeLifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner

internal class NativeVapView(
    binaryMessenger: BinaryMessenger,
    context: Context,
    id: Int,
    private val creationParams: Map<String?, Any?>?
) : MethodChannel.MethodCallHandler, PlatformView ,DefaultLifecycleObserver{

    private val mContext: Context = context
    private val vapView: AnimView = AnimView(context)
    private val channel: MethodChannel =
        MethodChannel(binaryMessenger, "flutter_vap_controller_${id}")

    private var localPath = ""
    private var assetPath = ""
    private var loop = false


    private val mainHandler = Handler(Looper.getMainLooper())
    private val stops = VapStopCoordinator(mainHandler)
    private var disposed = false
    private var stopRequested = false
    private var videoStarted = false
    private var restartWhenDestroyed = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onStart(owner: LifecycleOwner) {
        super.onStart(owner)
//        Log.d("TAG", "onStart vapPath=$localPath  assetPath=$assetPath")
        if (loop && !disposed) {
            if (stops.playbackPending) restartWhenDestroyed = true
            else startStoredPlayback()
        }

    }
    override fun onStop(owner: LifecycleOwner) {
        super.onStop(owner)
//        Log.d("TAG", "onStop")
        stopRequested = true
        restartWhenDestroyed = false
        stops.stop(null) { vapView.stopPlay() }
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
//        Log.d("TAG", "onFlutterViewAttached")
        val lifecycleOwner = ProcessLifecycleOwner.get()
        lifecycleOwner.lifecycle.addObserver(this)

        vapView.setScaleType(
            ScaleType.valueOf(
                (creationParams?.get("scaleType") ?: "FIT_CENTER").toString()
            )
        )
        vapView.setAnimListener(object : IAnimListener {
            override fun onFailed(errorType: Int, errorMsg: String?) {
                val errorInfo = mapOf(
                    "status" to "failure",
                    "errorType" to errorType,
                    "errorMsg" to (errorMsg ?: "unknown error")
                )
                Log.d("TAG", "Anim onFailed: $errorInfo")
                mainHandler.post {
                    if (!videoStarted && !vapView.isRunning()) stops.destroyed()
                    if (!disposed) channel.invokeMethod(
                        "onFailed",
                        errorInfo
                    )
                }

            }

            override fun onVideoComplete() {
//                myScope?.launch {
//                    eventSink?.success(mapOf("status" to "complete"))
//                }
                mainHandler.post {
                    if (!disposed) channel.invokeMethod(
                        "onComplete",
                        mapOf("status" to "complete")
                    )
                }

            }

            override fun onVideoDestroy() {
                mainHandler.post {
                    videoStarted = false
                    if (!disposed) channel.invokeMethod(
                        "onDestroy",
                        mapOf("status" to "destroy")
                    )
                    stops.destroyed()
                    if (restartWhenDestroyed && loop && !disposed) {
                        restartWhenDestroyed = false
                        startStoredPlayback()
                    }
                }
            }

            override fun onVideoRender(frameIndex: Int, config: AnimConfig?) {
                // Handle video render if necessary
//                myScope?.launch {
//                    channel.invokeMethod(
//                        "onRender",
//                        mapOf(
//                            "status" to "render",
//                            "frameIndex" to frameIndex,
////                    "config" to config
//                        )
//                    )
//                }
            }

            override fun onVideoStart() {
                mainHandler.post {
                    videoStarted = true
                    if (stopRequested || disposed) vapView.stopPlay()
                    else channel.invokeMethod("onStart", mapOf("status" to "start"))
                }
            }
        })

    }

    override fun getView(): View {
        return vapView
    }

    override fun dispose() {
        disposed = true
        loop = false
        stopRequested = true
        restartWhenDestroyed = false
        stops.stop(null) { vapView.stopPlay() }
        Log.d("TAG", "dispose")
        ProcessLifecycleOwner.get().lifecycle.removeObserver(this)
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("TAG", "onMethodCall: ${call.method}")
        when (call.method) {
            "setVideoMode" -> {
                val mode = (call.arguments as? Number)?.toInt() ?: 1
                vapView.enableVersion1(true)
                vapView.setVideoMode(mode.coerceIn(1, 4))
                vapView.setMute(true)
                result.success(null)
            }
            "playPath" -> {
                val path = call.argument<String>("path")
                if (stopRequested && stops.playbackPending) {
                    result.error("VAP_STOP_PENDING", "Previous decoder is still stopping", null)
                } else if (path != null) {
                    localPath = path
                    assetPath = ""
                    startStoredPlayback()
                    result.success(null)

                } else {
                    result.error("INVALID_ARGUMENT", "Path is null", null)
                }
            }

            "playAsset" -> {
                val asset = call.argument<String>("asset")
                if (stopRequested && stops.playbackPending) {
                    result.error("VAP_STOP_PENDING", "Previous decoder is still stopping", null)
                } else if (asset != null) {
                    assetPath = "flutter_assets/$asset"
                    localPath = ""
                    startStoredPlayback()
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Asset is null", null)
                }
            }

            "stop" -> {
                loop = false
                stopRequested = true
                restartWhenDestroyed = false
                stops.stop(result) { vapView.stopPlay() }
            }

            "setFetchResource" -> {
                val rawJson = call.arguments.toString()
                val list: List<FetchResourceModel> = parseJsonToFetchResourceModelList(rawJson)

                vapView.setFetchResource(
                    fetchResource = FetchResources(
                        resources = list
                    )
                )
                result.success(null);
            }

            "setLoop" -> {
                loop = call.arguments as Boolean
                if (loop) {
                    vapView.setLoop(Int.MAX_VALUE)
                } else {
                    vapView.setLoop(1)
                }
                result.success(null);
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startStoredPlayback() {
        stopRequested = false
        videoStarted = false
        stops.playing()
        if (localPath.isNotEmpty()) vapView.startPlay(File(localPath))
        else if (assetPath.isNotEmpty()) vapView.startPlay(mContext.assets, assetPath)
    }


    private fun parseJsonToFetchResourceModelList(rawJson: String): List<FetchResourceModel> {
        val list = mutableListOf<FetchResourceModel>()
        try {
            val jsonArray = JSONArray(rawJson)
            for (i in 0 until jsonArray.length()) {
                val jsonObject = jsonArray.getJSONObject(i)
                val tag = jsonObject.getString("tag")
                val resource = jsonObject.getString("resource")

                val resourceModel = FetchResourceModel(tag,resource)
                list.add(resourceModel)
            }
        } catch (e: Exception) {
            println("JSON parsing error: ${e.message}")
            e.printStackTrace()
            return emptyList()
        }
        return list
    }

}


internal class FetchResources(
    private val resources: List<FetchResourceModel>
) : IFetchResource {


    override fun fetchImage(resource: Resource, result: (Bitmap?) -> Unit) {
        Log.d("TAG", "fetchResource: fetchImage ${resource.tag} -- $resources")
        resources.firstOrNull {
            it.tag == resource.tag
        }?.let {
            Log.d("TAG", "fetchImage: result ${it.resource}")
            result(BitmapFactory.decodeFile(it.resource))
        } ?: result(null)
    }

    override fun fetchText(resource: Resource, result: (String?) -> Unit) {
        Log.d("TAG", "fetchResource: fetchText ${resource.tag}")

        result(
            resources.firstOrNull {
                it.tag == resource.tag
            }?.resource
        )

    }

    override fun releaseResource(resources: List<Resource>) {
        resources.forEach {
            it.bitmap?.recycle()
        }
    }
}

internal class FetchResourceModel(
    /// vap资源文件中预设的tag
    val tag: String,
    /// 图片本地路径或者文本字符串
    val resource: String,


) {
    override fun toString(): String {
        return mapOf(
            "tag" to tag,
            "resource" to resource
        ).toString()
    }
}

package com.nell.flutter_vap_plus

import android.os.Handler
import io.flutter.plugin.common.MethodChannel

/** Native stop is a request; acknowledge Flutter only after decoder destruction. */
internal class VapStopCoordinator(private val mainHandler: Handler) {
    var playbackPending = false
        private set
    private val replies = mutableListOf<MethodChannel.Result>()
    private var deadline: Runnable? = null

    fun playing() {
        playbackPending = true
    }

    fun destroyed() {
        playbackPending = false
        complete(null)
    }

    fun stop(result: MethodChannel.Result?, stopPlayer: () -> Unit) {
        if (result != null) replies.add(result)
        if (!playbackPending) {
            complete(null)
            return
        }
        try {
            stopPlayer()
        } catch (error: Exception) {
            complete(error.message ?: "Native stop failed")
            return
        }
        if (replies.isNotEmpty() && deadline == null) {
            val timeout = Runnable { complete("Native VAP destruction timed out") }
            deadline = timeout
            mainHandler.postDelayed(timeout, 10_000)
        }
    }

    private fun complete(error: String?) {
        deadline?.let { mainHandler.removeCallbacks(it) }
        deadline = null
        val pending = replies.toList()
        replies.clear()
        for (reply in pending) {
            if (error == null) reply.success(null)
            else reply.error("VAP_STOP_FAILED", error, null)
        }
    }
}

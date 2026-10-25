package com.kurenai7968.volume_controller

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import io.flutter.plugin.common.EventChannel

class VolumeListener(private val context: Context, private val audioManager: AudioManager) : EventChannel.StreamHandler {
    private var volumeBroadcastReceiver: VolumeBroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val args = arguments as? Map<String, Any>
        val fetchInitialVolume = args?.get(EventArgument.FETCH_INITIAL_VOLUME) as? Boolean ?: false

        onCancel(null)
        val receiver = VolumeBroadcastReceiver(events, audioManager)
        val filter = IntentFilter(VOLUME_CHANGED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        volumeBroadcastReceiver = receiver

        if (fetchInitialVolume) {
            events?.success(audioManager.getVolume())
        }
    }

    override fun onCancel(arguments: Any?) {
        volumeBroadcastReceiver?.let { context.unregisterReceiver(it) }
        volumeBroadcastReceiver = null
    }
}

class VolumeBroadcastReceiver(private val events: EventChannel.EventSink?, private val audioManager: AudioManager) : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        events?.success(audioManager.getVolume())
    }
}

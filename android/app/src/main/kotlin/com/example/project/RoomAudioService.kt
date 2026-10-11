package com.example.project

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import io.flutter.plugin.common.MethodChannel

class RoomAudioService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val microphone = intent.getBooleanExtra("microphone", false) &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        try {
            val manager = getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel("room_audio", getString(R.string.room_audio_title), NotificationManager.IMPORTANCE_LOW)
                channel.setShowBadge(false)
                manager.createNotificationChannel(channel)
            }
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, "room_audio")
            } else {
                Notification.Builder(this)
            }
            val launch = Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            val pending = PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val notification = builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(getString(R.string.room_audio_title))
                .setContentText(getString(R.string.room_audio_active))
                .setContentIntent(pending)
                .setOngoing(true)
                .setShowWhen(false)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                if (microphone && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                }
                startForeground(7430, notification, types)
            } else {
                startForeground(7430, notification)
            }
            pendingResult?.success(microphone)
        } catch (error: Exception) {
            pendingResult?.error("foreground_audio_failed", error.message, null)
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        } finally {
            pendingResult = null
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    companion object {
        private var pendingResult: MethodChannel.Result? = null

        fun start(context: Context, microphone: Boolean, result: MethodChannel.Result) {
            pendingResult = result
            try {
                val intent = Intent(context, RoomAudioService::class.java).putExtra("microphone", microphone)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent)
                else context.startService(intent)
            } catch (error: Exception) {
                pendingResult = null
                result.error("foreground_audio_failed", error.message, null)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, RoomAudioService::class.java))
        }
    }
}

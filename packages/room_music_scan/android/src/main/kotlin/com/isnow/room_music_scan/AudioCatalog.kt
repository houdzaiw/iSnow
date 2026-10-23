package com.isnow.room_music_scan

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File
import java.util.Locale
import java.util.UUID

// Adapted from Nady's FileScanner: use MediaStore identities, not DATA paths.
internal object AudioCatalog {
    private val extensions = setOf("mp3", "m4a", "aac", "wav", "ogg", "flac", "mp4")

    fun scan(context: Context, minBytes: Long): List<Map<String, Any>> {
        val collection = if (Build.VERSION.SDK_INT >= 29) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val locationColumn = if (Build.VERSION.SDK_INT >= 29) {
            MediaStore.Audio.Media.RELATIVE_PATH
        } else MediaStore.Audio.Media.DATA
        val projection = arrayOf(
            MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.SIZE, MediaStore.Audio.Media.DURATION, locationColumn
        )
        val tracks = linkedMapOf<String, Map<String, Any>>()
        context.contentResolver.query(
            collection, projection, "${MediaStore.Audio.Media.SIZE} > ?",
            arrayOf(minBytes.coerceAtLeast(0).toString()),
            "${MediaStore.Audio.Media.DISPLAY_NAME} ASC"
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val directoryColumn = cursor.getColumnIndexOrThrow(locationColumn)
            while (cursor.moveToNext()) {
                if (Thread.currentThread().isInterrupted) break
                val name = cursor.getString(nameColumn) ?: continue
                if (name.substringAfterLast('.', "").lowercase(Locale.ROOT) !in extensions) continue
                val uri = ContentUris.withAppendedId(collection, cursor.getLong(idColumn)).toString()
                val location = cursor.getString(directoryColumn).orEmpty()
                tracks[uri] = mapOf(
                    "id" to uri, "uri" to uri, "name" to name,
                    "location" to if (Build.VERSION.SDK_INT >= 29) location else File(location).parent.orEmpty(),
                    "size" to cursor.getLong(sizeColumn),
                    "duration" to cursor.getLong(durationColumn).coerceAtLeast(0)
                )
            }
        } ?: error("System audio catalog is unavailable")
        return tracks.values.toList()
    }

    fun export(context: Context, source: String, name: String): String {
        val uri = Uri.parse(source)
        require(uri.scheme == "content" && uri.authority == "media" &&
            uri.pathSegments.contains("audio")) { "Invalid system audio URI" }
        val extension = name.substringAfterLast('.', "").lowercase(Locale.ROOT)
        require(extension in extensions) { "Unsupported audio file" }
        val folder = File(context.cacheDir, "room_music_import").apply { mkdirs() }
        val target = File(folder, "${UUID.randomUUID()}.$extension")
        try {
            val input = context.contentResolver.openInputStream(uri)
                ?: error("Audio file is unavailable")
            input.use { stream ->
                target.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        if (Thread.currentThread().isInterrupted) error("Audio import cancelled")
                        val count = stream.read(buffer)
                        if (count < 0) break
                        output.write(buffer, 0, count)
                    }
                }
            }
            require(target.length() > 0) { "Audio file is empty" }
            return target.absolutePath
        } catch (error: Exception) {
            target.delete()
            throw error
        }
    }
}

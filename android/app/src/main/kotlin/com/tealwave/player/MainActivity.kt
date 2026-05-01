package com.tealwave.player

import android.content.ContentUris
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.tealwave.player/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSongs" -> {
                    try {
                        result.success(querySongs())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getAlbumArt" -> {
                    try {
                        val albumId = call.argument<Long>("albumId") ?: 0L
                        val filePath = call.argument<String>("filePath") ?: ""
                        result.success(getAlbumArt(albumId, filePath))
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun querySongs(): List<Map<String, Any>> {
        val songs = mutableListOf<Map<String, Any>>()

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE
        )

        val selection =
            "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.SIZE} > 102400"

        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val uris = listOf(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Audio.Media.INTERNAL_CONTENT_URI
        )

        for (uri in uris) {
            try {
                val cursor: Cursor? = contentResolver.query(
                    uri, projection, selection, null, sortOrder
                )
                cursor?.use {
                    val idCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                    val titleCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                    val artistCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                    val albumCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                    val albumIdCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
                    val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                    val dataCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

                    while (it.moveToNext()) {
                        val id = it.getLong(idCol)
                        val title = it.getString(titleCol) ?: "Unknown"
                        val artist = it.getString(artistCol) ?: "Unknown Artist"
                        val album = it.getString(albumCol) ?: "Unknown Album"
                        val albumId = it.getLong(albumIdCol)
                        val duration = it.getLong(durationCol)
                        val data = it.getString(dataCol) ?: ""

                        if (duration < 10000) continue
                        if (data.isEmpty()) continue

                        val contentUri = ContentUris.withAppendedId(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id
                        ).toString()

                        songs.add(mapOf(
                            "id" to id,
                            "title" to title,
                            "artist" to artist,
                            "album" to album,
                            "albumId" to albumId,
                            "duration" to duration,
                            "data" to data,
                            "contentUri" to contentUri
                        ))
                    }
                }
            } catch (e: Exception) {
                // skip
            }
        }
        return songs
    }

    private fun getAlbumArt(albumId: Long, filePath: String): ByteArray? {
        // Method 1: Try MediaStore album art (works for internal storage)
        if (albumId > 0) {
            try {
                val artUri = ContentUris.withAppendedId(
                    Uri.parse("content://media/external/audio/albumart"),
                    albumId
                )
                val inputStream = contentResolver.openInputStream(artUri)
                if (inputStream != null) {
                    val bitmap = BitmapFactory.decodeStream(inputStream)
                    inputStream.close()
                    if (bitmap != null) {
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                        return stream.toByteArray()
                    }
                }
            } catch (e: Exception) {
                // fall through to next method
            }
        }

        // Method 2: Read embedded art directly from the MP3 file
        // This works for SD card songs
        if (filePath.isNotEmpty()) {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(filePath)
                val art = retriever.embeddedPicture
                retriever.release()
                if (art != null) {
                    // Compress to reduce size
                    val bitmap = BitmapFactory.decodeByteArray(art, 0, art.size)
                    if (bitmap != null) {
                        val stream = ByteArrayOutputStream()
                        // Scale down if too large to save memory
                        val scaled = if (bitmap.width > 512) {
                            Bitmap.createScaledBitmap(bitmap, 512, 512, true)
                        } else bitmap
                        scaled.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                        return stream.toByteArray()
                    }
                }
            } catch (e: Exception) {
                // no art found
            }
        }

        return null
    }
}

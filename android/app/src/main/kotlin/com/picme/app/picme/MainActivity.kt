package com.picme.app.picme

import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "picme/media_size"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBucketSize" -> {
                        val bucketId = call.argument<String?>("bucketId")
                        val mediaType = call.argument<Int>("mediaType") ?: 0
                        try {
                            result.success(getBucketSize(bucketId, mediaType))
                        } catch (e: Exception) {
                            result.error("ERR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Returns the total byte size of media in a given bucket / category.
     *
     * mediaType:
     *   0 -> photos + videos (common)
     *   1 -> photos only
     *   3 -> videos only
     *
     * bucketId: optional MediaStore BUCKET_ID. When null, all buckets are
     * summed.
     */
    private fun getBucketSize(bucketId: String?, mediaType: Int): Long {
        val uri = MediaStore.Files.getContentUri("external")
        val parts = mutableListOf<String>()
        val args = mutableListOf<String>()
        when (mediaType) {
            1 -> parts.add(
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} = " +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}"
            )
            3 -> parts.add(
                "${MediaStore.Files.FileColumns.MEDIA_TYPE} = " +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}"
            )
            else -> parts.add(
                "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = " +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE} OR " +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE} = " +
                    "${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})"
            )
        }
        if (!bucketId.isNullOrEmpty()) {
            parts.add("${MediaStore.Files.FileColumns.BUCKET_ID} = ?")
            args.add(bucketId)
        }
        val selection = parts.joinToString(" AND ")
        val projection = arrayOf(MediaStore.Files.FileColumns.SIZE)

        var total = 0L
        contentResolver.query(uri, projection, selection, args.toTypedArray(), null)
            ?.use { c ->
                val idx = c.getColumnIndex(MediaStore.Files.FileColumns.SIZE)
                if (idx < 0) return 0
                while (c.moveToNext()) {
                    val v = c.getLong(idx)
                    if (v > 0) total += v
                }
            }
        return total
    }
}

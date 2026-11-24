package com.example.reminders.geofence

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

data class GeofenceSpec(
    val id: Int,
    val title: String,
    val latitude: Double,
    val longitude: Double,
    val radiusMeters: Double,
)

/**
 * Registers reminders as Play Services geofences. Play Services owns the
 * monitoring, so a transition wakes our broadcast receiver even when the app
 * process has been killed by the system or the OEM battery manager.
 *
 * Two fences are created per reminder:
 *  - `rem_<id>_target`   - the reminder radius (minimum 150 m)
 *  - `rem_<id>_approach` - a 10 km "near target" fence that switches the app
 *                          into live/precise monitoring mode
 */
object GeofenceManager {
    private const val TAG = "GeofenceManager"
    private const val STORE_PREFS = "geofence_store"
    private const val KEY_SPECS = "specs"

    private const val TARGET_PREFIX = "rem_"
    private const val TARGET_SUFFIX = "_target"
    private const val APPROACH_SUFFIX = "_approach"

    private const val MIN_RADIUS_METERS = 150f
    private const val APPROACH_RADIUS_METERS = 10_000f
    private const val MAX_GEOFENCES = 100

    private const val TARGET_RESPONSIVENESS_MS = 180_000
    private const val APPROACH_RESPONSIVENESS_MS = 300_000

    fun client(context: Context): GeofencingClient =
        LocationServices.getGeofencingClient(context)

    fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    // ── Persistence ─────────────────────────────────────────────────────────

    fun save(context: Context, specs: List<GeofenceSpec>) {
        val array = JSONArray()
        for (spec in specs) {
            array.put(
                JSONObject().apply {
                    put("id", spec.id)
                    put("title", spec.title)
                    put("latitude", spec.latitude)
                    put("longitude", spec.longitude)
                    put("radiusMeters", spec.radiusMeters)
                },
            )
        }
        context.getSharedPreferences(STORE_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SPECS, array.toString())
            .apply()
    }

    fun load(context: Context): List<GeofenceSpec> {
        val raw = context.getSharedPreferences(STORE_PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SPECS, null)
            ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        GeofenceSpec(
                            id = obj.getInt("id"),
                            title = obj.optString("title", "Reminder"),
                            latitude = obj.getDouble("latitude"),
                            longitude = obj.getDouble("longitude"),
                            radiusMeters = obj.optDouble("radiusMeters", 150.0),
                        ),
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Could not parse stored geofences", e)
            emptyList()
        }
    }

    // ── Registration ────────────────────────────────────────────────────────

    /**
     * Replaces every registered reminder geofence with [specs].
     *
     * [onDone] is invoked on the main thread with an error message, or null on
     * success.
     */
    @SuppressLint("MissingPermission")
    fun register(
        context: Context,
        specs: List<GeofenceSpec>,
        onDone: (error: String?) -> Unit = {},
    ) {
        save(context, specs)
        val pendingIntent = pendingIntent(context)
        val geofencingClient = client(context)

        geofencingClient.removeGeofences(pendingIntent).addOnCompleteListener {
            if (specs.isEmpty()) {
                onDone(null)
                return@addOnCompleteListener
            }

            val includeApproach = specs.size * 2 <= MAX_GEOFENCES
            val fences = ArrayList<Geofence>(specs.size * 2)
            for (spec in specs) {
                fences.add(buildTargetFence(spec))
                if (includeApproach) {
                    fences.add(buildApproachFence(spec))
                }
            }

            val request = GeofencingRequest.Builder()
                .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
                .addGeofences(fences)
                .build()

            try {
                geofencingClient.addGeofences(request, pendingIntent)
                    .addOnSuccessListener {
                        Log.i(TAG, "Registered ${fences.size} geofences")
                        FlutterPrefs.writeString(
                            context,
                            "geofence_last_error",
                            "",
                        )
                        FlutterPrefs.writeString(
                            context,
                            "geofence_last_sync_at",
                            nowTimestamp(),
                        )
                        onDone(null)
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "Failed to register geofences", e)
                        FlutterPrefs.writeString(
                            context,
                            "geofence_last_error",
                            e.message ?: e.toString(),
                        )
                        onDone(e.message ?: "Failed to register geofences")
                    }
            } catch (e: SecurityException) {
                Log.e(TAG, "Missing location permission for geofences", e)
                FlutterPrefs.writeString(
                    context,
                    "geofence_last_error",
                    "Location permission missing: ${e.message}",
                )
                onDone("Location permission missing")
            }
        }
    }

    fun clear(context: Context) {
        save(context, emptyList())
        client(context).removeGeofences(pendingIntent(context))
    }

    fun status(context: Context): Map<String, Any?> {
        val hasBackgroundLocation = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val specs = load(context)
        val pendingId = FlutterPrefs.readLong(context, PendingTrigger.KEY_ID)
        val pendingAt = FlutterPrefs.readString(context, PendingTrigger.KEY_AT)
        val pendingAgeSeconds = pendingAt?.let { parseAgeSeconds(it) }
        return mapOf(
            "syncedCount" to specs.size,
            "expectedCount" to specs.size,
            "lastSyncAt" to FlutterPrefs.readString(context, "geofence_last_sync_at"),
            "pendingId" to pendingId,
            "pendingAgeSeconds" to pendingAgeSeconds,
            "lastEventAt" to FlutterPrefs.readString(context, "geofence_last_event_at"),
            "lastEvent" to FlutterPrefs.readString(context, "geofence_last_event"),
            "lastError" to FlutterPrefs.readString(context, "geofence_last_error"),
            "hasBackgroundLocation" to hasBackgroundLocation,
        )
    }

    private fun nowTimestamp(): String = java.text.SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        java.util.Locale.US,
    ).format(java.util.Date())

    private fun parseAgeSeconds(timestamp: String): Long? = try {
        val parsed = java.text.SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            java.util.Locale.US,
        ).parse(timestamp)
        if (parsed == null) null
        else max(0L, (java.util.Date().time - parsed.time) / 1000L)
    } catch (e: Exception) {
        Log.w(TAG, "Could not parse pending trigger timestamp", e)
        null
    }

    fun recordEvent(context: Context, message: String) {
        FlutterPrefs.writeString(
            context,
            "geofence_last_event_at",
            java.text.SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                java.util.Locale.US,
            ).format(java.util.Date()),
        )
        FlutterPrefs.writeString(context, "geofence_last_event", message)
    }

    // ── Request ids ─────────────────────────────────────────────────────────

    /** Returns (reminderId, isTarget) for one of our request ids. */
    fun parseRequestId(requestId: String?): Pair<Int, Boolean>? {
        if (requestId == null || !requestId.startsWith(TARGET_PREFIX)) return null
        val rest = requestId.removePrefix(TARGET_PREFIX)
        return when {
            rest.endsWith(TARGET_SUFFIX) ->
                rest.removeSuffix(TARGET_SUFFIX).toIntOrNull()?.let { it to true }

            rest.endsWith(APPROACH_SUFFIX) ->
                rest.removeSuffix(APPROACH_SUFFIX).toIntOrNull()?.let { it to false }

            else -> null
        }
    }

    // ── Fence builders ──────────────────────────────────────────────────────

    private fun buildTargetFence(spec: GeofenceSpec): Geofence =
        Geofence.Builder()
            .setRequestId("$TARGET_PREFIX${spec.id}$TARGET_SUFFIX")
            .setCircularRegion(
                spec.latitude,
                spec.longitude,
                max(spec.radiusMeters, MIN_RADIUS_METERS.toDouble()).toFloat(),
            )
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
            .setNotificationResponsiveness(TARGET_RESPONSIVENESS_MS)
            .build()

    private fun buildApproachFence(spec: GeofenceSpec): Geofence =
        Geofence.Builder()
            .setRequestId("$TARGET_PREFIX${spec.id}$APPROACH_SUFFIX")
            .setCircularRegion(
                spec.latitude,
                spec.longitude,
                APPROACH_RADIUS_METERS,
            )
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
            .setNotificationResponsiveness(APPROACH_RESPONSIVENESS_MS)
            .build()
}

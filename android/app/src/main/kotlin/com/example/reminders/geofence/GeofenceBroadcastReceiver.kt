package com.example.reminders.geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import id.flutter.flutter_background_service.BackgroundService

/**
 * Receives geofence transitions from Play Services. This receiver runs even
 * when the app process was killed, so it is the entry point for "the phone was
 * locked for hours" arrivals.
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {

    @Suppress("DEPRECATION")
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return

        if (event.hasError()) {
            GeofenceManager.recordEvent(
                context,
                "Geofence error ${event.errorCode}",
            )
            Log.e(TAG, "Geofence error code ${event.errorCode}")
            return
        }

        if (event.geofenceTransition != Geofence.GEOFENCE_TRANSITION_ENTER) return

        val triggered = event.triggeringGeofences
            ?.mapNotNull { GeofenceManager.parseRequestId(it.requestId) }
            .orEmpty()

        if (triggered.isEmpty()) return

        val target = triggered.firstOrNull { it.second }
        if (target != null) {
            Log.i(TAG, "Target geofence entered for reminder ${target.first}")
            GeofenceManager.recordEvent(
                context,
                "Target entered for reminder ${target.first}",
            )
            PendingTrigger.set(context, target.first)
        } else {
            val approachId = triggered.first().first
            Log.i(TAG, "Approach geofence entered for reminder $approachId")
            GeofenceManager.recordEvent(
                context,
                "Approach entered for reminder $approachId",
            )
        }

        startMonitorService(context)
    }

    /**
     * Starting a foreground service from a geofence broadcast is one of the
     * documented exemptions from the Android 12+ background start restriction.
     */
    private fun startMonitorService(context: Context) {
        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, BackgroundService::class.java),
            )
        } catch (e: Exception) {
            Log.e(TAG, "Could not start background monitor service", e)
            GeofenceManager.recordEvent(
                context,
                "Could not start service: ${e.message}",
            )
        }
    }

    private companion object {
        const val TAG = "GeofenceReceiver"
    }
}

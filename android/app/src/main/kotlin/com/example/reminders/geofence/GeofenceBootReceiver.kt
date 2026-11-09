package com.example.reminders.geofence

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Play Services drops registered geofences when the device reboots, so we
 * restore them from the locally persisted list.
 */
class GeofenceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                val specs = GeofenceManager.load(context)
                if (specs.isEmpty()) return
                Log.i(TAG, "Re-registering ${specs.size} geofences after boot")
                GeofenceManager.register(context, specs)
            }
        }
    }

    private companion object {
        const val TAG = "GeofenceBootReceiver"
    }
}

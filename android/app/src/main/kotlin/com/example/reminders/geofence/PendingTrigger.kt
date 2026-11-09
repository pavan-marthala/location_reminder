package com.example.reminders.geofence

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Hand-off between [GeofenceBroadcastReceiver] and the Flutter background
 * isolate: the receiver records which reminder was entered, then starts the
 * foreground service. When the isolate boots it consumes and clears the value.
 */
object PendingTrigger {
    private const val KEY_ID = "pending_geofence_trigger_id"
    private const val KEY_AT = "pending_geofence_trigger_at"

    fun set(context: Context, reminderId: Int) {
        FlutterPrefs.writeLong(context, KEY_ID, reminderId.toLong())
        FlutterPrefs.writeString(context, KEY_AT, now())
    }

    fun clear(context: Context) {
        FlutterPrefs.remove(context, KEY_ID)
    }

    private fun now(): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(Date())
}

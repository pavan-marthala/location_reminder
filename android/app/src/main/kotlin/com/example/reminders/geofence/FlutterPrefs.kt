package com.example.reminders.geofence

import android.content.Context

/**
 * Reads and writes the same SharedPreferences file that the Flutter
 * `shared_preferences` plugin uses, so the Dart isolates can observe values
 * written from native geofence callbacks while the app is dead.
 *
 * Flutter stores its keys with the `flutter.` prefix.
 */
object FlutterPrefs {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val PREFIX = "flutter."

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun writeLong(context: Context, key: String, value: Long) {
        prefs(context).edit().putLong(PREFIX + key, value).apply()
    }

    fun readLong(context: Context, key: String): Long? {
        val value = prefs(context).all[PREFIX + key]
        return (value as? Number)?.toLong()
    }

    fun writeString(context: Context, key: String, value: String) {
        prefs(context).edit().putString(PREFIX + key, value).apply()
    }

    fun readString(context: Context, key: String): String? {
        return prefs(context).all[PREFIX + key] as? String
    }

    fun remove(context: Context, key: String) {
        prefs(context).edit().remove(PREFIX + key).apply()
    }
}

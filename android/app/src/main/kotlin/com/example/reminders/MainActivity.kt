package com.example.reminders

import android.app.KeyguardManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.reminders/background_protection"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestBatteryOptimizationExemption" -> {
                    result.success(requestBatteryOptimizationExemption())
                }
                "openBatteryOptimizationSettings" -> {
                    result.success(openBatteryOptimizationSettings())
                }
                "openApplicationDetails" -> {
                    result.success(openApplicationDetails())
                }
                "getDeviceInfo" -> {
                    result.success(getDeviceInfo())
                }
                "openOppoAutoLaunchSettings" -> {
                    result.success(openOppoAutoLaunchSettings())
                }
                "openOppoAppBatterySettings" -> {
                    result.success(openOppoAppBatterySettings())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            return powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
        }
        return true
    }

    private fun requestBatteryOptimizationExemption(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (isIgnoringBatteryOptimizations()) return true
            return try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
                true
            } catch (e: Exception) {
                openBatteryOptimizationSettings()
            }
        }
        return true
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
                true
            } catch (e: Exception) {
                openApplicationDetails()
            }
        }
        return openApplicationDetails()
    }

    private fun openApplicationDetails(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getDeviceInfo(): Map<String, Any> {
        val manufacturer = Build.MANUFACTURER ?: ""
        val brand = Build.BRAND ?: ""
        val model = Build.MODEL ?: ""
        val sdkInt = Build.VERSION.SDK_INT

        val isOppoOrColorOS = isOppoOrColorOS(manufacturer, brand)

        return mapOf(
            "manufacturer" to manufacturer,
            "brand" to brand,
            "model" to model,
            "sdkInt" to sdkInt,
            "isOppoOrColorOS" to isOppoOrColorOS
        )
    }

    private fun isOppoOrColorOS(manufacturer: String, brand: String): Boolean {
        val m = manufacturer.lowercase()
        val b = brand.lowercase()
        if (m.contains("oppo") || m.contains("realme") || m.contains("oneplus") ||
            b.contains("oppo") || b.contains("realme") || b.contains("oneplus")) {
            return true
        }
        // Check system properties safely if reflection allows, or fallback
        try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val getMethod = systemProperties.getMethod("get", String::class.java)
            val oppoVer = getMethod.invoke(null, "ro.build.version.opporom") as? String
            val colorVer = getMethod.invoke(null, "ro.build.version.coloros") as? String
            if (!oppoVer.isNullOrEmpty() || !colorVer.isNullOrEmpty()) {
                return true
            }
        } catch (_: Exception) {}
        return false
    }

    private fun openOppoAutoLaunchSettings(): Boolean {
        // Safe list of candidate intents for ColorOS / RealmeUI / OxygenOS auto-launch settings
        val intents = listOf(
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.oppoguardelf", "com.coloros.powermanager.fuelgauge.PowerUsageModelActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"))
        )

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
            } catch (_: Exception) {
            }
        }
        // Safe fallback if specific OEM activity not found
        return openApplicationDetails()
    }

    private fun openOppoAppBatterySettings(): Boolean {
        val intents = listOf(
            Intent().setComponent(ComponentName("com.coloros.oppoguardelf", "com.coloros.powermanager.fuelgauge.PowerConsumptionFeatureActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.floatpage.FloatPageManagerActivity"))
        )

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (_: Exception) {}
        }
        return openApplicationDetails()
    }
}


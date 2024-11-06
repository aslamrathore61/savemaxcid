package com.savemax.cid.savemaxcid

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.savemax.cid/icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "switchIcon" -> {
                    val iconName = call.argument<String>("iconName")
                    if (iconName != null) {
                        switchIconTo(iconName)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Icon name is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun switchIconTo(activityName: String) {
        Log.d("ActivityName","$activityName")
        val packageManager = packageManager
        val fullComponent = "$packageName.$activityName"

        gregAppIcons.forEach { appIcon ->
            val state = if (appIcon.component == fullComponent)
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED

            packageManager.setComponentEnabledSetting(
                ComponentName(this, appIcon.component),
                state,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}

val gregAppIcons = listOf(
    AppIcon(component = "com.savemax.cid.savemaxcid.MainActivityCanada",),
    AppIcon(component = "com.savemax.cid.savemaxcid.MainActivityIndia",)
)

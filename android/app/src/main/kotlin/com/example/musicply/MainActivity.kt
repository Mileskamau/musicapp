package com.example.musicply

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.musiq.audio/output"
    private lateinit var audioManager: AudioManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentDevice" -> getCurrentDevice(result)
                    "getAvailableDevices" -> getAvailableDevices(result)
                    "setOutputDevice" -> {
                        val deviceId = call.argument<Int>("deviceId")
                        if (deviceId != null) {
                            setOutputDevice(deviceId, result)
                        } else {
                            result.error("INVALID_ARGUMENT", "deviceId is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getCurrentDevice(result: Result) {
        try {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val currentDevice = devices.firstOrNull { it.isSink }
            if (currentDevice != null) {
                result.success(mapDeviceToMap(currentDevice))
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    private fun getAvailableDevices(result: Result) {
        try {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val deviceList = devices.map { mapDeviceToMap(it) }
            result.success(deviceList)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    private fun setOutputDevice(deviceId: Int, result: Result) {
        try {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            val targetDevice = devices.find { it.id == deviceId }
            if (targetDevice != null) {
                result.success(true)
            } else {
                result.error("DEVICE_NOT_FOUND", "Device with ID $deviceId not found", null)
            }
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.message, null)
        }
    }

    private fun mapDeviceToMap(device: AudioDeviceInfo): Map<String, Any> {
        val type = when (device.type) {
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "wiredHeadphones"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "bluetooth"
            else -> "unknown"
        }
        return mapOf(
            "id" to device.id,
            "name" to (device.productName ?: "Unknown Device"),
            "type" to type,
            "isConnected" to true
        )
    }
}
package com.example.flutter_application_11

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.app/ringtone"
    private var toneGenerator: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var isPlaying = false
    private val handler = Handler(Looper.getMainLooper())
    private var toneRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playRingtone" -> {
                    val type = call.argument<String>("type") ?: "incoming"
                    playRingtone(type)
                    result.success(null)
                }
                "stopRingtone" -> {
                    stopRingtone()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun playRingtone(type: String) {
        try {
            // Stop any existing ringtone
            stopRingtone()

            isPlaying = true

            // ✅ Create tone generator
            toneGenerator = ToneGenerator(
                AudioManager.STREAM_VOICE_CALL,
                ToneGenerator.MAX_VOLUME
            )

            // ✅ Start vibration
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            
            if (type == "incoming") {
                // 📞 Incoming call - continuous vibration
                val pattern = longArrayOf(0, 1000, 1000) // vibrate 1s, pause 1s, repeat
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(
                        VibrationEffect.createWaveform(pattern, 0) // 0 = repeat from start
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }

                // Play phone ringtone sound (continuous)
                playIncomingTone()
            } else {
                // 📲 Outgoing call - WhatsApp style "tooo tooo"
                val pattern = longArrayOf(0, 200, 300, 200, 1500) // short vibration pattern
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(
                        VibrationEffect.createWaveform(pattern, 0) // repeat
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }

                // Play WhatsApp-style "tooo tooo" sound
                playOutgoingTone()
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // 📞 Play incoming call tone (continuous ringing)
    private fun playIncomingTone() {
        toneRunnable = object : Runnable {
            override fun run() {
                if (isPlaying) {
                    // Play ring tone
                    toneGenerator?.startTone(ToneGenerator.TONE_SUP_RINGTONE, 1500)
                    
                    // Repeat after 2 seconds
                    handler.postDelayed(this, 2000)
                }
            }
        }
        handler.post(toneRunnable!!)
    }

    // 📲 Play outgoing call tone (WhatsApp style "tooo tooo")
    private fun playOutgoingTone() {
        toneRunnable = object : Runnable {
            var count = 0
            
            override fun run() {
                if (isPlaying) {
                    // Play two beeps
                    if (count % 2 == 0) {
                        // First "tooo"
                        toneGenerator?.startTone(ToneGenerator.TONE_SUP_CALL_WAITING, 400)
                        handler.postDelayed(this, 500)
                    } else {
                        // Second "tooo"
                        toneGenerator?.startTone(ToneGenerator.TONE_SUP_CALL_WAITING, 400)
                        handler.postDelayed(this, 2000) // Wait 2 seconds before repeating
                    }
                    count++
                }
            }
        }
        handler.post(toneRunnable!!)
    }

    private fun stopRingtone() {
        try {
            isPlaying = false

            // Stop tone
            toneRunnable?.let {
                handler.removeCallbacks(it)
            }
            toneRunnable = null

            toneGenerator?.stopTone()
            toneGenerator?.release()
            toneGenerator = null

            // Stop vibration
            vibrator?.cancel()
            vibrator = null

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopRingtone()
    }
}
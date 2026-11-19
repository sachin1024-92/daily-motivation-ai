package io.github.sachin102492.seeti

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.flow.update

/**
 * Listens to the microphone while the user is cooking, counts whistles, and rings an alarm at
 * the target. Started only by the user tapping "Start counting" (a foreground service of type
 * microphone, as Android 14+ requires). Audio is analysed frame by frame in memory and is never
 * recorded, saved or sent anywhere.
 */
class ListenService : Service() {

    companion object {
        private const val ACTION_START = "io.github.sachin102492.seeti.action.START"
        private const val ACTION_STOP = "io.github.sachin102492.seeti.action.STOP"
        private const val EXTRA_TARGET = "target"
        private const val EXTRA_SENSITIVITY = "sensitivity"
        private const val EXTRA_SAFETY = "safety"
        private const val CHANNEL_LISTEN = "listening"
        private const val CHANNEL_ALARM = "alarm"
        private const val NOTIFICATION_ID = 7
        private const val SAMPLE_RATE = 16_000
        private const val ALARM_AUTO_STOP_MS = 3 * 60_000L

        fun start(context: Context, target: Int, sensitivity: Sensitivity, safetyMinutes: Int) {
            val intent = Intent(context, ListenService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TARGET, target)
                .putExtra(EXTRA_SENSITIVITY, sensitivity.ordinal)
                .putExtra(EXTRA_SAFETY, safetyMinutes)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.startService(Intent(context, ListenService::class.java).setAction(ACTION_STOP))
        }
    }

    @Volatile private var listening = false
    private var worker: Thread? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var player: MediaPlayer? = null
    private var tone: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private val autoStop = Runnable { stopAlarmSound() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> begin(intent)
            else -> finish() // ACTION_STOP, or a restart without an intent: nothing to resume.
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        listening = false
        stopAlarmSound()
        releaseWakeLock()
        super.onDestroy()
    }

    private fun begin(intent: Intent) {
        createChannels()
        val target = intent.getIntExtra(EXTRA_TARGET, 3).coerceIn(1, 20)
        val sensitivity = Sensitivity.entries.getOrElse(intent.getIntExtra(EXTRA_SENSITIVITY, 1)) { Sensitivity.MEDIUM }
        val safety = intent.getIntExtra(EXTRA_SAFETY, 0).coerceAtLeast(0)
        try {
            val type = if (Build.VERSION.SDK_INT >= 30) ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE else 0
            ServiceCompat.startForeground(this, NOTIFICATION_ID, listeningNotification(0, target), type)
        } catch (e: Exception) {
            // Android refuses a microphone service without permission or from the background.
            SeetiState.session.value = Session(error = "Could not start listening. Open Seeti and try again.")
            stopSelf()
            return
        }
        stopAlarmSound()
        listening = false
        worker?.join(500)
        SeetiState.session.value = Session(
            running = true,
            target = target,
            startedAtMillis = System.currentTimeMillis(),
            safetyMinutes = safety,
        )
        acquireWakeLock()
        listening = true
        worker = Thread({ listenLoop(sensitivity) }, "seeti-listen").apply { start() }
    }

    @SuppressLint("MissingPermission") // Checked at the top of the function.
    private fun listenLoop(sensitivity: Sensitivity) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            fail("Microphone permission is off. Allow it in Settings to count whistles.")
            return
        }
        val minBuffer = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val recorder = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBuffer, WhistleDetector.FRAME * 8),
            )
        } catch (e: Exception) {
            fail("The microphone is not available right now.")
            return
        }
        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            fail("The microphone is busy (another app may be using it).")
            return
        }
        val detector = WhistleDetector(SAMPLE_RATE, sensitivity)
        val frame = ShortArray(WhistleDetector.FRAME)
        var shownCount = 0
        try {
            recorder.startRecording()
            while (listening) {
                var filled = 0
                while (filled < frame.size && listening) {
                    val n = recorder.read(frame, filled, frame.size - filled)
                    if (n < 0) throw IllegalStateException("microphone read error $n")
                    filled += n
                }
                if (!listening) break
                val result = detector.process(frame)
                SeetiState.session.update { s ->
                    s.copy(
                        levelDb = result.levelDb,
                        hearing = result.whistleLike,
                        count = if (result.newWhistle) s.count + 1 else s.count,
                    )
                }
                val s = SeetiState.session.value
                if (s.count != shownCount) {
                    shownCount = s.count
                    post(listeningNotification(s.count, s.target))
                    if (result.newWhistle && s.count < s.target) buzz(150)
                }
                if (s.count >= s.target) {
                    raiseAlarm(AlarmReason.TARGET_REACHED)
                    break
                }
                if (s.safetyMinutes > 0 && System.currentTimeMillis() - s.startedAtMillis >= s.safetyMinutes * 60_000L) {
                    raiseAlarm(AlarmReason.SAFETY_TIMER)
                    break
                }
            }
        } catch (e: Exception) {
            if (listening) fail("Listening stopped unexpectedly. Please start again.")
        } finally {
            try {
                recorder.stop()
            } catch (ignored: Exception) {
            }
            recorder.release()
        }
    }

    private fun fail(message: String) {
        listening = false
        SeetiState.session.value = Session(error = message)
        handler.post { finish(keepError = true) }
    }

    private fun raiseAlarm(reason: AlarmReason) {
        listening = false // stop the mic before ringing, so the alarm is never counted as a whistle
        SeetiState.session.update { it.copy(running = false, hearing = false, alarm = reason) }
        post(alarmNotification(reason))
        handler.post { startAlarmSound() }
    }

    private fun finish(keepError: Boolean = false) {
        listening = false
        worker = null
        stopAlarmSound()
        releaseWakeLock()
        SeetiState.session.update {
            Session(target = it.target, error = if (keepError) it.error else null)
        }
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    // ---- Alarm --------------------------------------------------------------------------------

    private fun startAlarmSound() {
        stopAlarmSound()
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        player = try {
            if (uri == null) {
                null
            } else {
                MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                    setDataSource(this@ListenService, uri)
                    isLooping = true
                    prepare()
                    start()
                }
            }
        } catch (e: Exception) {
            null
        }
        if (player == null) {
            // No alarm sound on this phone: use a built-in tone instead.
            tone = try {
                ToneGenerator(AudioManager.STREAM_ALARM, 100).apply {
                    startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 20_000)
                }
            } catch (e: Exception) {
                null
            }
        }
        vibrator = systemVibrator()
        vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 700, 500), 0))
        handler.postDelayed(autoStop, ALARM_AUTO_STOP_MS)
    }

    private fun stopAlarmSound() {
        handler.removeCallbacks(autoStop)
        player?.let {
            try {
                it.stop()
            } catch (ignored: Exception) {
            }
            it.release()
        }
        player = null
        tone?.release()
        tone = null
        vibrator?.cancel()
        vibrator = null
    }

    private fun buzz(ms: Long) {
        systemVibrator()?.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    private fun systemVibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= 31) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            legacyVibrator()
        }

    @Suppress("DEPRECATION")
    private fun legacyVibrator(): Vibrator? = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator

    // ---- Wake lock (keeps counting with the screen off) ----------------------------------------

    private fun acquireWakeLock() {
        releaseWakeLock()
        val pm = getSystemService(PowerManager::class.java) ?: return
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "seeti:listening").apply {
            setReferenceCounted(false)
            acquire(2 * 60 * 60_000L) // never more than 2 hours
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    // ---- Notifications ------------------------------------------------------------------------

    private fun createChannels() {
        val nm = getSystemService(NotificationManager::class.java) ?: return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_LISTEN, "Counting whistles", NotificationManager.IMPORTANCE_LOW),
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ALARM, "Whistle alarm", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null) // the app plays the alarm sound itself
                enableVibration(false)
            },
        )
    }

    private fun listeningNotification(count: Int, target: Int): Notification =
        NotificationCompat.Builder(this, CHANNEL_LISTEN)
            .setSmallIcon(R.drawable.ic_stat_seeti)
            .setContentTitle("Whistles: $count of $target")
            .setContentText("Seeti is listening. Nothing is recorded.")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppIntent())
            .addAction(0, "Stop", stopIntent())
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()

    private fun alarmNotification(reason: AlarmReason): Notification {
        val title = if (reason == AlarmReason.TARGET_REACHED) "Whistles done! Turn off the gas" else "Safety timer: check the cooker"
        return NotificationCompat.Builder(this, CHANNEL_ALARM)
            .setSmallIcon(R.drawable.ic_stat_seeti)
            .setContentTitle(title)
            .setContentText("Tap Stop to silence the alarm.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setContentIntent(openAppIntent())
            .addAction(0, "Stop", stopIntent())
            .build()
    }

    private fun post(notification: Notification) {
        val allowed = Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        if (!allowed) return
        try {
            NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, notification)
        } catch (ignored: SecurityException) {
        }
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        this,
        0,
        Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun stopIntent(): PendingIntent = PendingIntent.getService(
        this,
        1,
        Intent(this, ListenService::class.java).setAction(ACTION_STOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}

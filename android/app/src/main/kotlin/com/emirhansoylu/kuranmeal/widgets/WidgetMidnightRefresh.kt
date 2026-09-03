package com.emirhansoylu.kuranmeal.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar

/**
 * Araçları gün dönümünde tazeleyen alarm.
 *
 * Neden gerekli: araç künyesinde `updatePeriodMillis` sıfır, yani sistem
 * araçları kendiliğinden yenilemiyor. Bu bilinçli — sistemin sunduğu en kısa
 * dönem 30 dakika ve içeriğimiz günde bir kez değişiyor; yarım saatte bir
 * uyanmak boşuna pil harcardı.
 *
 * Onun yerine günde tek bir alarm kurulur. Alarm yalnızca aracın kendini
 * yeniden çizmesini tetikler; veri okumaz, ağ kullanmaz, Flutter motorunu
 * başlatmaz. Araç yeniden çizilirken uygulamanın yazdığı gün numarasını
 * kontrol edip bayat veriyi ayırt eder.
 *
 * Alarm `setInexactRepeating` ile kurulur: dakika hassasiyeti gerekmiyor ve
 * bu sayede Android'in SCHEDULE_EXACT_ALARM iznine ihtiyaç kalmıyor — o izin
 * mağaza incelemesinde gerekçe isteyen bir izin.
 */
class WidgetMidnightRefreshReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            // Cihaz yeniden başladığında alarmlar silinir; yeniden kurulur.
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                WidgetMidnightRefresh.schedule(context)
                refreshAll(context)
            }

            // Saat dilimi ya da saat elle değiştirildiğinde gün dönümü kayar.
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            -> {
                WidgetMidnightRefresh.schedule(context)
                refreshAll(context)
            }

            WidgetMidnightRefresh.ACTION_REFRESH -> {
                refreshAll(context)
                // Tekrarlayan alarm kullanılsa da bir sonraki gün için
                // yeniden kurulur: cihaz uykudayken kaçırılan bir tetikleme
                // zincirin kopmasına yol açabiliyor.
                WidgetMidnightRefresh.schedule(context)
            }
        }
    }

    /** Üç aracın da yeniden çizilmesini ister. */
    private fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return

        val providers = listOf(
            DailyAyahWidgetProvider::class.java,
            ContinueReadingWidgetProvider::class.java,
            StreakWidgetProvider::class.java,
        )

        for (provider in providers) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isEmpty()) continue

            context.sendBroadcast(
                Intent(context, provider).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                },
            )
        }
    }
}

internal object WidgetMidnightRefresh {

    const val ACTION_REFRESH =
        "com.emirhansoylu.kuranmeal.widgets.ACTION_MIDNIGHT_REFRESH"

    /** Bir sonraki gün dönümü için alarmı kurar. */
    fun schedule(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE)
            as? AlarmManager ?: return

        val trigger = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            // Tam gece yarısı yerine birkaç dakika sonrası seçildi: cihazın
            // saati ile aracın gün hesabı arasındaki saniyelik farkın araca
            // bir gün eski veri çizdirmesini önler.
            set(Calendar.MINUTE, 2)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        try {
            alarms.setInexactRepeating(
                AlarmManager.RTC,
                trigger.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                pendingIntent(context),
            )
        } catch (_: SecurityException) {
            // Alarm kurulamazsa araç yalnızca uygulama açıldığında tazelenir;
            // temel işlev bozulmaz.
        }
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetMidnightRefreshReceiver::class.java)
            .apply { action = ACTION_REFRESH }

        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private const val REQUEST_CODE = 5001
}

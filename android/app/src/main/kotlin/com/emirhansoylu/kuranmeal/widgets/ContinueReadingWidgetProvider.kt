package com.emirhansoylu.kuranmeal.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.emirhansoylu.kuranmeal.R

/**
 * "Devam et" aracı: kullanıcının en son kaldığı yer.
 *
 * Günün ayeti aracının aksine burada bayatlık kontrolü yok — son okunan yer
 * tarihe bağlı değil. Kullanıcı uygulamayı bir ay açmasa bile "kaldığın yer"
 * hâlâ doğru bilgidir.
 */
class ContinueReadingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        widgetIds.forEach { render(context, manager, it) }
    }

    /**
     * İlk araç eklendiğinde gün dönümü alarmı kurulur.
     *
     * Üç araç da aynı alarmı kurar; alarm tek bir PendingIntent üzerinden
     * tanımlı olduğu için ikinci kurulum birincinin üstüne yazar, mükerrer
     * alarm oluşmaz.
     */
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetMidnightRefresh.schedule(context)
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val prefs = context.widgetPrefs()
        val views =
            RemoteViews(context.packageName, R.layout.widget_continue_reading)

        val surahName = prefs.stringOrNull(WidgetKeys.CONTINUE_SURAH_NAME)

        if (surahName != null) {
            views.setTextViewText(R.id.surah_name, surahName)
            views.setTextViewText(
                R.id.ayah_label,
                prefs.stringOrNull(WidgetKeys.CONTINUE_AYAH_LABEL) ?: "",
            )
            views.setViewVisibility(R.id.ayah_label, View.VISIBLE)

            views.setProgressBar(
                R.id.progress,
                100,
                (prefs.intOrNull(WidgetKeys.CONTINUE_PERCENT) ?: 0)
                    .coerceIn(0, 100),
                false,
            )
            views.setViewVisibility(R.id.progress, View.VISIBLE)
        } else {
            // Hiç okunmamış: çağrı metniyle uygulamaya davet edilir.
            views.setTextViewText(
                R.id.surah_name,
                context.getString(R.string.widget_continue_empty),
            )
            views.setViewVisibility(R.id.ayah_label, View.GONE)
            views.setViewVisibility(R.id.progress, View.GONE)
        }

        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetLaunch.openRoute(
                context,
                prefs.stringOrNull(WidgetKeys.CONTINUE_ROUTE) ?: "/",
            ),
        )

        manager.updateAppWidget(widgetId, views)
    }
}

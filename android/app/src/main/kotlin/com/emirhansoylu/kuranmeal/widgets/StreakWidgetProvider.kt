package com.emirhansoylu.kuranmeal.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.emirhansoylu.kuranmeal.R

/**
 * Okuma serisi aracı.
 *
 * Serinin kendisi uygulamada hesaplanır; araç yalnızca sayıyı gösterir.
 * "Bugün bekliyor" satırı bilerek eklendi: seri sayısını tek başına
 * göstermek bilgi verir ama bir şey yaptırmaz, bugünün durumu ise seriyi
 * kaybetmemek için ne yapılması gerektiğini söyler.
 */
class StreakWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.widget_streak)

        val planName = prefs.stringOrNull(WidgetKeys.STREAK_PLAN_NAME)

        if (planName != null) {
            val current = prefs.intOrNull(WidgetKeys.STREAK_CURRENT) ?: 0
            val todayDone =
                prefs.boolOrNull(WidgetKeys.STREAK_TODAY_DONE) ?: false

            views.setTextViewText(R.id.streak_count, current.toString())
            views.setViewVisibility(R.id.streak_count, View.VISIBLE)
            views.setViewVisibility(R.id.streak_unit, View.VISIBLE)
            views.setTextViewText(R.id.plan_name, planName)

            views.setTextViewText(
                R.id.today_status,
                context.getString(
                    if (todayDone) {
                        R.string.widget_streak_today_done
                    } else {
                        R.string.widget_streak_today_pending
                    },
                ),
            )
            views.setViewVisibility(R.id.today_status, View.VISIBLE)
        } else {
            // Henüz plan yok: rakam göstermek yerine plan seçmeye çağırılır.
            views.setViewVisibility(R.id.streak_count, View.GONE)
            views.setViewVisibility(R.id.streak_unit, View.GONE)
            views.setTextViewText(
                R.id.plan_name,
                context.getString(R.string.widget_streak_empty),
            )
            views.setViewVisibility(R.id.today_status, View.GONE)
        }

        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetLaunch.openRoute(
                context,
                prefs.stringOrNull(WidgetKeys.STREAK_ROUTE) ?: "/planlar",
            ),
        )

        manager.updateAppWidget(widgetId, views)
    }
}

package com.emirhansoylu.kuranmeal.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import com.emirhansoylu.kuranmeal.R

/**
 * Günün ayeti aracı.
 *
 * Gösterilen metin uygulamanın yazdığı veriden gelir; araç kendi başına
 * veritabanına erişemez. Bu yüzden iki durum ayrı ele alınır:
 *
 *  - Veri bugüne aitse doğrudan gösterilir.
 *  - Veri bayatsa (kullanıcı uygulamayı günlerdir açmamışsa) yanlış bir
 *    "günün ayeti" göstermek yerine kullanıcıdan uygulamayı açması istenir.
 *    Bayat ayeti göstermek daha kötü olurdu: kullanıcı her gün aynı ayeti
 *    görüp aracın bozuk olduğunu düşünürdü.
 *
 * Yenile düğmesi uygulamayı açmadan çalışır: uygulama önceden küçük bir
 * ayet havuzu yazar, araç bu havuzda sırayla döner.
 */
class DailyAyahWidgetProvider : AppWidgetProvider() {

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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_REFRESH) return

        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        advanceOffset(context)
        render(context, AppWidgetManager.getInstance(context), widgetId)
    }

    /**
     * Yenile kaymasını bir ilerletir.
     *
     * Kayma günle birlikte saklanır: gün değiştiğinde sıfırlanır, böylece
     * kullanıcı ertesi gün araca baktığında kaldığı yerden değil, o günün
     * ayetinden başlar.
     */
    private fun advanceOffset(context: Context) {
        val prefs = context.widgetPrefs()
        val today = todayDayNumber()

        val poolCount = prefs.intOrNull(WidgetKeys.DAILY_AYAH_POOL_COUNT) ?: 0
        if (poolCount <= 1) return

        val storedDay = prefs.longOrNull(WidgetKeys.REFRESH_OFFSET_DAY)
        val current = if (storedDay == today) {
            prefs.intOrNull(WidgetKeys.REFRESH_OFFSET) ?: 0
        } else {
            0
        }

        prefs.edit()
            .putInt(WidgetKeys.REFRESH_OFFSET, (current + 1) % poolCount)
            .putLong(WidgetKeys.REFRESH_OFFSET_DAY, today)
            .apply()
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val prefs = context.widgetPrefs()
        val views = RemoteViews(context.packageName, R.layout.widget_daily_ayah)

        val isFresh =
            prefs.longOrNull(WidgetKeys.DAILY_AYAH_DAY) == todayDayNumber()

        val poolCount = prefs.intOrNull(WidgetKeys.DAILY_AYAH_POOL_COUNT) ?: 0
        val offset = if (prefs.longOrNull(WidgetKeys.REFRESH_OFFSET_DAY)
            == todayDayNumber()
        ) {
            prefs.intOrNull(WidgetKeys.REFRESH_OFFSET) ?: 0
        } else {
            0
        }

        // Kayma sıfırsa doğrudan günün ayeti okunur; havuz yazılmamış eski
        // sürümlerden güncelleyen kullanıcılarda da araç çalışmaya devam eder.
        val text: String?
        val reference: String?
        val route: String?

        if (offset > 0 && offset < poolCount) {
            text = prefs.stringOrNull(WidgetKeys.poolText(offset))
            reference = prefs.stringOrNull(WidgetKeys.poolReference(offset))
            route = prefs.stringOrNull(WidgetKeys.poolRoute(offset))
        } else {
            text = prefs.stringOrNull(WidgetKeys.DAILY_AYAH_TEXT)
            reference = prefs.stringOrNull(WidgetKeys.DAILY_AYAH_REFERENCE)
            route = prefs.stringOrNull(WidgetKeys.DAILY_AYAH_ROUTE)
        }

        if (isFresh && text != null) {
            views.setTextViewText(R.id.ayah_text, text)
            views.setTextViewText(R.id.ayah_reference, reference ?: "")
            views.setViewVisibility(R.id.ayah_reference, View.VISIBLE)
            // Yenile yalnızca gezilecek başka ayet varken anlamlı.
            views.setViewVisibility(
                R.id.refresh,
                if (poolCount > 1) View.VISIBLE else View.GONE,
            )
        } else {
            views.setTextViewText(
                R.id.ayah_text,
                context.getString(R.string.widget_empty),
            )
            views.setViewVisibility(R.id.ayah_reference, View.GONE)
            views.setViewVisibility(R.id.refresh, View.GONE)
        }

        // Araç gövdesine dokunmak ayete gider; veri yoksa uygulamayı açar.
        views.setOnClickPendingIntent(
            R.id.widget_root,
            WidgetLaunch.openRoute(context, if (isFresh) route else "/"),
        )

        views.setOnClickPendingIntent(
            R.id.refresh,
            WidgetLaunch.broadcast(
                context,
                DailyAyahWidgetProvider::class.java,
                ACTION_REFRESH,
                widgetId,
            ),
        )

        manager.updateAppWidget(widgetId, views)
    }

    private companion object {
        const val ACTION_REFRESH =
            "com.emirhansoylu.kuranmeal.widgets.ACTION_REFRESH_DAILY_AYAH"
    }
}

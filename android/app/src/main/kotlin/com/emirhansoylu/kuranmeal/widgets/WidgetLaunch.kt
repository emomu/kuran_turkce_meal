package com.emirhansoylu.kuranmeal.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.emirhansoylu.kuranmeal.MainActivity

/**
 * Araçtan uygulamaya açılan bağlantılar.
 *
 * Araç bir uygulama içi yolu (`/sure/2?ayet=255`) doğrudan başlatamaz;
 * uygulamayı bir Intent ile açıp yolu veri olarak taşır. Flutter tarafında
 * home_widget eklentisi bu Intent'i yakalar ve yönlendiriciye devreder
 * (bkz. HomeWidgetService.routeFromUri).
 */
internal object WidgetLaunch {

    /** home_widget eklentisinin beklediği şema. */
    private const val SCHEME = "homeWidget"

    /**
     * Uygulamayı [route] yolunda açan PendingIntent.
     *
     * [requestCode] araç türüne ve yola göre benzersiz olmalı: aynı kodla
     * oluşturulan PendingIntent'ler sistem tarafından aynı sayılır ve ikinci
     * araç birincinin hedefine giderdi. Yolun hash'i kullanılarak farklı
     * hedefler farklı kod alır.
     */
    fun openRoute(context: Context, route: String?): PendingIntent {
        val target = route?.takeIf { it.isNotBlank() } ?: "/"

        return PendingIntent.getActivity(
            context,
            target.hashCode(),
            routeIntent(context, target),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Uygulamayı [route] yolunda açan ham Intent. */
    fun routeIntent(context: Context, route: String?): Intent {
        val target = route?.takeIf { it.isNotBlank() } ?: "/"

        return Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("$SCHEME://${target.removePrefix("/")}")
            // Uygulama zaten açıksa yeni bir kopya başlatılmaz; var olan
            // görev öne getirilir ve Intent ona iletilir. Aksi halde araca
            // her dokunuşta yığında yeni bir uygulama kopyası birikirdi.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
    }

    /**
     * Aracın kendi sağlayıcısına yayın gönderen PendingIntent.
     *
     * Yenile düğmesi gibi uygulamayı açmadan iş yapan düğmeler bunu kullanır.
     */
    fun broadcast(
        context: Context,
        provider: Class<*>,
        action: String,
        widgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, provider).apply {
            this.action = action
            putExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }

        return PendingIntent.getBroadcast(
            context,
            // Araç kimliği koda katılır; aynı türden iki araç eklendiğinde
            // birinin yenile düğmesi diğerini yenilemesin.
            action.hashCode() * 31 + widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

package com.emirhansoylu.kuranmeal.widgets

import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.emirhansoylu.kuranmeal.R

/**
 * Hızlı ayarlar karesi: bildirim panelinden günün ayetine tek dokunuş.
 *
 * Karenin alt yazısı günün ayetinin künyesini gösterir (Android 10+), böylece
 * kullanıcı paneli açtığında hangi ayet olduğunu daha dokunmadan görür.
 *
 * Manifest'te `android.permission.BIND_QUICK_SETTINGS_TILE` ile korunur;
 * sistem hizmeti yalnızca Android 7.0+ üzerinde örneklenir, o yüzden sınıf
 * düzeyinde ek bir sürüm kontrolüne gerek yok.
 */
class DailyAyahTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()

        val tile: Tile = qsTile ?: return
        val prefs = widgetPrefs()

        tile.label = getString(R.string.tile_daily_ayah)
        tile.state = Tile.STATE_INACTIVE

        // Alt yazı Android 10'da geldi; öncesinde bu alan yok.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val isFresh =
                prefs.longOrNull(WidgetKeys.DAILY_AYAH_DAY) == todayDayNumber()
            tile.subtitle =
                if (isFresh) prefs.stringOrNull(WidgetKeys.DAILY_AYAH_REFERENCE)
                else null
        }

        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()

        val prefs = widgetPrefs()
        val isFresh =
            prefs.longOrNull(WidgetKeys.DAILY_AYAH_DAY) == todayDayNumber()
        val route = prefs.stringOrNull(WidgetKeys.DAILY_AYAH_ROUTE)

        val pending = WidgetLaunch.openRoute(this, if (isFresh) route else "/")

        // Paneli kapatıp uygulamayı açar. Kilit ekranındaysa sistem önce
        // kilidi açtırır; doğrudan startActivity çağırmak kilitli ekranda
        // sessizce başarısız olurdu.
        //
        // Android 14 PendingIntent alan aşırı yüklemeyi getirdi ve Intent
        // alanı kullanımdan kaldırdı; ikisi de aynı işi yapar.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(
                WidgetLaunch.routeIntent(this, if (isFresh) route else "/"),
            )
        }
    }
}

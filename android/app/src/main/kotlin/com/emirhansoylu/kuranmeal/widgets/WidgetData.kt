package com.emirhansoylu.kuranmeal.widgets

import android.content.Context
import android.content.SharedPreferences
import java.util.Calendar
import java.util.TimeZone

/**
 * Araçların okuduğu ortak veri.
 *
 * Flutter tarafı (home_widget eklentisi) bu değerleri `HomeWidgetPreferences`
 * adlı SharedPreferences dosyasına yazar. Araçlar Flutter motorunu
 * çalıştırmadan buradan okur — bu sayede ana ekranda anında görünürler ve
 * arka planda pil harcamazlar.
 *
 * Anahtar adları lib/core/widgets_bridge/home_widget_keys.dart ile birebir
 * aynı olmalı. Bir taraf değişip diğeri değişmezse araç sessizce boş kalır,
 * derleme hatası vermez — bu yüzden adlar burada tek bir nesnede toplandı.
 */
internal object WidgetKeys {
    const val PREFS_NAME = "HomeWidgetPreferences"

    const val DAILY_AYAH_TEXT = "daily_ayah_text"
    const val DAILY_AYAH_REFERENCE = "daily_ayah_reference"
    const val DAILY_AYAH_ROUTE = "daily_ayah_route"
    const val DAILY_AYAH_DAY = "daily_ayah_day"

    const val CONTINUE_SURAH_NAME = "continue_surah_name"
    const val CONTINUE_AYAH_LABEL = "continue_ayah_label"
    const val CONTINUE_ROUTE = "continue_route"
    const val CONTINUE_PERCENT = "continue_percent"

    const val STREAK_PLAN_NAME = "streak_plan_name"
    const val STREAK_CURRENT = "streak_current"
    const val STREAK_LONGEST = "streak_longest"
    const val STREAK_ROUTE = "streak_route"
    const val STREAK_TODAY_DONE = "streak_today_done"

    const val UPDATED_AT = "updated_at"

    /**
     * Yenile düğmesinin gösterdiği ayet kayması.
     *
     * Flutter'ın yazdığı veriye dokunulmaz; kayma ayrı tutulur ki uygulama
     * bir sonraki eşitlemede günün ayetini yazdığında kullanıcının araçtan
     * seçtiği ayet kaybolmasın... daha doğrusu, kaybolması gerektiğinde
     * (gün değişince) kaymanın da sıfırlanabilmesi için hangi güne ait
     * olduğu birlikte saklanır.
     */
    const val REFRESH_OFFSET = "widget_refresh_offset"
    const val REFRESH_OFFSET_DAY = "widget_refresh_offset_day"

    /**
     * Yenile havuzu. Uygulama günün ayetiyle birlikte onu izleyen birkaç
     * ayeti de yazar; araç veritabanına erişemediği için yenile düğmesinin
     * gösterebileceği tek içerik budur.
     *
     * Anahtar biçimi HomeWidgetKeys.dailyAyahPool* ile aynı olmalı.
     */
    const val DAILY_AYAH_POOL_COUNT = "daily_ayah_pool_count"

    fun poolText(index: Int) = "daily_ayah_pool_${index}_text"

    fun poolReference(index: Int) = "daily_ayah_pool_${index}_ref"

    fun poolRoute(index: Int) = "daily_ayah_pool_${index}_route"
}

internal fun Context.widgetPrefs(): SharedPreferences =
    getSharedPreferences(WidgetKeys.PREFS_NAME, Context.MODE_PRIVATE)

/**
 * home_widget eklentisi değerleri tür bilgisiyle yazar; okurken tür
 * uyuşmazlığı `ClassCastException` fırlatır ve araç çöker. Uygulama
 * güncellemeleri arasında bir anahtarın türü değişirse (örneğin sayıyken
 * metne dönerse) araç eski veriyle karşılaşabilir, bu yüzden okumalar
 * savunmacı yapılır.
 */
internal fun SharedPreferences.stringOrNull(key: String): String? = try {
    getString(key, null)?.takeIf { it.isNotBlank() }
} catch (_: ClassCastException) {
    null
}

internal fun SharedPreferences.intOrNull(key: String): Int? = try {
    if (contains(key)) getInt(key, 0) else null
} catch (_: ClassCastException) {
    // Flutter tarafında sayılar bazen long olarak yazılır.
    try {
        if (contains(key)) getLong(key, 0L).toInt() else null
    } catch (_: ClassCastException) {
        null
    }
}

internal fun SharedPreferences.longOrNull(key: String): Long? = try {
    if (contains(key)) getLong(key, 0L) else null
} catch (_: ClassCastException) {
    try {
        if (contains(key)) getInt(key, 0).toLong() else null
    } catch (_: ClassCastException) {
        null
    }
}

internal fun SharedPreferences.boolOrNull(key: String): Boolean? = try {
    if (contains(key)) getBoolean(key, false) else null
} catch (_: ClassCastException) {
    null
}

/**
 * Bugünün epoch gün sayısı.
 *
 * DailyAyahWidgetData.dayNumberOf ile aynı hesap: yerel gün başı alınır ve
 * gün uzunluğuna bölünür. Araç bu değeri Flutter'ın yazdığıyla karşılaştırıp
 * verinin bayatlayıp bayatlamadığını anlar; böylece kullanıcı uygulamayı
 * günlerdir açmasa bile araç yanlış bir "günün ayeti" göstermez.
 */
internal fun todayDayNumber(): Long {
    val calendar = Calendar.getInstance(TimeZone.getDefault()).apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    return Math.floorDiv(calendar.timeInMillis, MILLIS_PER_DAY)
}

private const val MILLIS_PER_DAY = 24L * 60L * 60L * 1000L

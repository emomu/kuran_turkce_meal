# flutter_local_notifications, planlanmış bildirimleri geri yüklerken
# Gson ile serileştirilmiş sınıfları yansıma (reflection) yoluyla okur.
# R8 bu sınıfları kullanılmıyor sanıp ayıklarsa, cihaz yeniden başladıktan
# sonra hatırlatma geri kurulamaz.
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson'un genel tür bilgisine ihtiyacı var.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Java Beans, masaüstü JDK'ya ait; Android'de yok, R8 uyarısını susturur.
-dontwarn java.beans.**
-dontwarn javax.annotation.**

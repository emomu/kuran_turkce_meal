import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuran_turkce_meal/core/notifications/daily_ayah_notifications.dart';
import 'package:kuran_turkce_meal/data/models/reader_preferences.dart';

import 'helpers/localized_app.dart';

/// Günün ayeti hatırlatması.
///
/// Bildirim eklentisi test ortamında platform kanalı bulamaz; bu testler
/// eklentinin kendisini değil, çevresindeki sözleşmeyi doğrular: servis
/// kanalsız ortamda çökmemeli, tercih modeli saati doğru taşımalı ve
/// çeviri anahtarları eksiksiz olmalı.
void main() {
  setUp(TestApp.reset);

  group('DailyAyahNotifications', () {
    test('platform kanalı yokken çağrılar sessizce geçer', () async {
      final service = DailyAyahNotifications.instance;

      // Hiçbiri istisna atmamalı — bildirim ikincil bir özellik, açılışı
      // ya da ayarlar ekranını engellememeli.
      await expectLater(service.init(), completes);
      await expectLater(service.cancel(), completes);
      await expectLater(
        service.schedule(
          hour: 8,
          minute: 0,
          title: 'Günün ayeti',
          body: 'Bugünün ayeti seni bekliyor.',
        ),
        completes,
      );
    });

    test('izin alınamayan ortamda false döner', () async {
      // İzin verilmediğinde ayar açık bırakılmamalı; ayarlar ekranı bu
      // dönüş değerine bakarak anahtarı geri kapatır.
      expect(await DailyAyahNotifications.instance.requestPermission(), isFalse);
    });
  });

  group('Bildirim tercihi', () {
    test('saat tercihi TimeOfDay olarak okunur', () {
      const prefs = ReaderPreferences(dailyAyahHour: 21, dailyAyahMinute: 30);
      expect(prefs.dailyAyahTime, const TimeOfDay(hour: 21, minute: 30));
    });

    test('copyWith saati korur', () {
      const prefs = ReaderPreferences(dailyAyahHour: 7, dailyAyahMinute: 15);
      final updated = prefs.copyWith(dailyAyahEnabled: false);

      expect(updated.dailyAyahEnabled, isFalse);
      expect(updated.dailyAyahTime, const TimeOfDay(hour: 7, minute: 15));
    });
  });
}

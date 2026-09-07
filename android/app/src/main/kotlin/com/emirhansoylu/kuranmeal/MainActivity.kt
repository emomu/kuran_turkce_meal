package com.emirhansoylu.kuranmeal

import com.ryanheise.audioservice.AudioServiceActivity

/// Tilavet arka planda çaldığı için `FlutterActivity` yerine
/// `AudioServiceActivity` kullanılır.
///
/// Bildirim çubuğundaki denetime ya da kilit ekranındaki kontrole
/// dokunulduğunda sistem uygulamayı bu etkinlik üzerinden öne getirir;
/// düz `FlutterActivity` ile o dokunuşlar uygulamaya ulaşmaz ve ses
/// yalnızca uygulama açıkken yönetilebilirdi.
class MainActivity : AudioServiceActivity()

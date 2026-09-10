/// Sohbet akışındaki tek bir mesaj.
library;

import 'assistant_intent.dart';

/// Mesajı kimin yazdığı.
enum MessageAuthor { user, assistant }

/// Cevabın altında gösterilen eylem.
///
/// Asistan cevabı bir çıkmaz sokak olmamalı: kullanıcı okuduğu şeyi
/// derinleştirebilmeli. Bu eylemler sohbeti sürdürmenin ya da uygulamanın
/// ilgili ekranına geçmenin yoludur.
class AssistantAction {
  const AssistantAction({
    required this.label,
    required this.kind,
    this.route,
    this.followUpQuery,
  });

  final String label;
  final AssistantActionKind kind;

  /// Gidilecek rota. [AssistantActionKind.navigate] için zorunlu.
  final String? route;

  /// Asistana yeniden sorulacak metin. [AssistantActionKind.ask] için.
  final String? followUpQuery;
}

enum AssistantActionKind {
  /// Uygulamanın bir ekranına gider.
  navigate,

  /// Sohbette yeni bir soru sorar.
  ask,

  /// Bu cevabın bütün sonuçlarını ayrı bir sayfada açar.
  ///
  /// Eskiden bu eylem sohbete üç ayet daha ekliyordu ("daha fazla göster").
  /// 60 sonucu balon balon dizmek sohbeti okunmaz hâle getiriyordu; liste
  /// artık kendi sayfasında duruyor ve sohbet cevabın özeti olarak kalıyor.
  openAll,
}

/// Sohbet mesajı.
class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.author,
    required this.text,
    this.ayahs = const [],
    this.actions = const [],
    this.isTyping = false,
    this.note,
    this.allAyahs = const [],
    this.resultTitle,
  });

  final int id;
  final MessageAuthor author;

  /// Gösterilecek metin. Şablondan kurulur; hiçbir bölümü üretilmiş değildir.
  final String text;

  /// Cevabın dayandığı ayetler. Kartlar hâlinde gösterilir ve tıklanabilir.
  ///
  /// Metin bu listeye bakarak kurulur: liste boşsa cevap da bir şey iddia
  /// etmez. Kaynaksız bir cümlenin ekrana çıkması mümkün değil.
  final List<AnswerAyah> ayahs;

  /// Cevabın altındaki eylemler.
  final List<AssistantAction> actions;

  /// Asistan yazıyor göstergesi.
  final bool isTyping;

  /// Cevabın altına düşülen uyarı.
  ///
  /// Hüküm sorularında ve kavram aramalarında kullanılır: gösterilen
  /// ayetlerin bir fetva değil, okuma başlangıcı olduğunu söyler.
  final String? note;

  /// Bu cevabın bütün sonuçları — balonda gösterilmeyenler dahil.
  ///
  /// Sohbette yalnızca ilk birkaçı görünür; tamamı "Tümünü gör" ile açılan
  /// sayfada listelenir. Mesajın kendisinde durur ki eski bir cevabın
  /// listesi de sonradan açılabilsin.
  final List<AnswerAyah> allAyahs;

  /// Sonuç sayfasının başlığı: "sabır", "Muhammed", "Bakara 255".
  final String? resultTitle;

  bool get isUser => author == MessageAuthor.user;

  AssistantMessage copyWith({
    String? text,
    List<AnswerAyah>? ayahs,
    List<AssistantAction>? actions,
    bool? isTyping,
    String? note,
    List<AnswerAyah>? allAyahs,
    String? resultTitle,
  }) =>
      AssistantMessage(
        id: id,
        author: author,
        text: text ?? this.text,
        ayahs: ayahs ?? this.ayahs,
        actions: actions ?? this.actions,
        isTyping: isTyping ?? this.isTyping,
        note: note ?? this.note,
        allAyahs: allAyahs ?? this.allAyahs,
        resultTitle: resultTitle ?? this.resultTitle,
      );
}

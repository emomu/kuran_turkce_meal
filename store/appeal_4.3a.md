# App Review yanıtı — Guideline 4.3(a)

Submission ID: 75f0ecb9-dbfe-437b-9624-7edd14d39e17
Version: 1.0.2 (1)

App Store Connect'te "Reply" ile gönderilecek metin aşağıda. İngilizce
yazıldı; App Review ile yazışma dili İngilizce olduğunda yanıt süresi
kısalıyor.

Reply kutusunun sınırı 4.000 karakter. Aşağıdaki metin bu sınırın altında
(ölçüm için: `python3 -c "print(len(open('...').read()))"`).

---

## Gönderilecek metin

Hello,

Thank you for the review. We respectfully request a re-evaluation of the
4.3(a) decision, and offer information we believe was not available during
the review.

**This app's source code is public under the MIT license:**
https://github.com/emomu/kuran_turkce_meal

We mention this first because guideline 4.3 names "the same source code or
assets as other apps" as a primary spam factor. Every line was written by us
and can be independently verified. It is not built from a template, shares no
codebase with any other submission, and is the only app on our account.

**None of the listed contributing factors apply:** no purchased template, no
multiple similar apps, no multiple accounts, and all assets (Flutter/Dart
source, UI, data pipeline) are original.

**On the concept.** Qur'an translation apps are a crowded category, and we did
not build another verse-by-verse reader. The app is built around features that,
to our knowledge, are not available together in any existing App Store app:

1. **Revelation-order reading by default.** Mushaf order is arranged roughly by
   chapter length, obscuring the sequence in which the text was revealed. We
   order chapters by revelation, showing both numbers on every card, so a reader
   can follow how language and subject matter developed over twenty-three years.

2. **Word-level Arabic root analysis.** Tapping a word reveals its root and
   every other verse containing it: 1,651 roots over 50,271 word occurrences,
   derived from the Quranic Arabic Corpus (corpus.quran.com).

3. **Prophet narratives in chronological sequence.** For each of 25 prophets,
   the verses telling their story are assembled in revelation order, showing how
   a narrative was introduced and later expanded — invisible in mushaf order.

4. **A curated subject index.** 56 subjects, 8 sections, 2,299 verse references.
   Each subject separates verses manually curated as defining it from verses
   found by text search, and tells the user which is which — because an app in
   this category should be honest about where its claims come from.

5. **An offline assistant that is explicitly not a language model.** It maps a
   question to search terms through an auditable lexicon and shows the verses it
   finds, composing no sentences and offering no interpretation. No question
   leaves the device.

6. **No data collection.** No analytics, crash reporting, ad SDK, or accounts.
   The only network requests are recitation files the user chooses to download.
   This is verifiable in the public source — precisely why we open-sourced it.

**On the review environment.** The review was performed on an iPad Air 11-inch
(M3). If any layout issue on iPad contributed to an impression of a repackaged
app, we would like to know and will address it immediately. We would rather fix
a real problem than argue about an impression.

**What we ask.** If the decision stands, we would be grateful for any specific
detail — a comparable app, a screen, or an element of the metadata — that led
to it. Without that we cannot identify what to change. We are willing to make
changes; we need to know what they are.

Thank you for your time and for the work you do reviewing submissions.

Best regards,
Emirhan Soylu

---

## Notlar (gönderilmeyecek)

**Neden bu sırayla yazıldı.** Açık kaynak en başta, çünkü Apple'ın kendi
listelediği spam faktörlerinden birini doğrudan çürütüyor ve doğrulanabilir.
Özellik listesi ikinci sırada: önce "spam değiliz" kanıtı, sonra "neden
özgünüz" argümanı.

**iPad paragrafı bilinçli.** İnceleme bir iPad'de yapıldı ve 4.3 kararlarının
bir kısmı "özensiz görünüyor" izleniminden doğuyor. Savunmaya geçmek yerine
düzeltmeyi teklif etmek hem dürüst hem de incelemeciyi somut bir cevaba
yöneltiyor.

**Son paragraf en önemlisi.** 4.3(a) itirazlarında en sık alınan sonuç,
"karar değişmedi" diyen tek satırlık bir yanıt. Somut bir ayrıntı istemek,
en azından bir sonraki turda neyi düzelteceğini öğrenme şansı veriyor.

**Abartı yok.** Metindeki her sayı veriden doğrulandı: 1.651 kök, 50.271
kelime, 25 peygamber, 56 konu, 8 bölüm, 2.299 ayet referansı. Bir tanesi
bile yanlış çıkarsa itirazın tamamı güvenilirliğini kaybeder.

**Denenebilecek bir sonraki adım:** karar değişmezse App Review Board'a
(Resolution Center üzerinden) taşımak. Ayrı bir mekanizma ve bazen farklı
bir sonuç veriyor.

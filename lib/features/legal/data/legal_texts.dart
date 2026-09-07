/// Gizlilik politikası, kullanım şartları ve kaynak bildirimi metinleri.
///
/// Metinler uygulamanın içine gömülür, bir sunucudan çekilmez. Uygulama
/// tamamen çevrimdışı çalıştığı için yasal metinlerin de internet olmadan
/// okunabilmesi gerekir — mağazaların istediği "erişilebilir gizlilik
/// politikası" şartı da böylece her koşulda karşılanır.
///
/// Metinler uygulamanın gerçek davranışını anlatır: hiçbir veri toplanmaz,
/// hiçbir veri cihazdan çıkmaz, hesap yoktur, analitik ve reklam yoktur.
/// Bu metinler değişirse [lastUpdated] da güncellenmelidir.
library;

class LegalTexts {
  const LegalTexts._();

  /// Metinlerin son gözden geçirilme tarihi. Mağaza incelemelerinde ve
  /// kullanıcıya karşı, politikanın hangi sürüme ait olduğunu gösterir.
  static const lastUpdated = '1 Eylül 2026';
  static const lastUpdatedEn = 'September 1, 2026';

  static const contactEmail = 'emir.soylu.2014@gmail.com';

  static String privacy(String languageCode) =>
      languageCode == 'en' ? _privacyEn : _privacyTr;

  static String terms(String languageCode) =>
      languageCode == 'en' ? _termsEn : _termsTr;

  static String sources(String languageCode) =>
      languageCode == 'en' ? _sourcesEn : _sourcesTr;

  /// Tilavet sesinin kaynağı, indirme koşulları ve saklanması.
  ///
  /// Ayrı bir metin olarak tutuldu: kullanıcı bu bilgiyi telif sayfasında
  /// değil, ses ayarlarının yanında arar. İçeriğin bir bölümü telifle
  /// ilgili (kayıtların kaynağı), bir bölümü ise tamamen pratik (veri
  /// kullanımı, cihazda kapladığı yer, nasıl silineceği).
  static String audioInfo(String languageCode) =>
      languageCode == 'en' ? _audioInfoEn : _audioInfoTr;

  static const _privacyTr = '''
# Gizlilik Politikası

**Son güncelleme:** $lastUpdated

## Kısaca

Bu uygulama hakkınızda hiçbir bilgi toplamaz. Hesap açmanız gerekmez,
internet bağlantısı gerekmez ve yazdıklarınız cihazınızdan çıkmaz.

## Toplanmayan veriler

Uygulama şunların **hiçbirini** toplamaz, saklamaz veya aktarmaz:

- Ad, e-posta, telefon numarası veya başka kimlik bilgisi
- Konum bilgisi
- Cihaz tanımlayıcıları veya reklam kimliği
- Kullanım istatistiği, analitik veya çökme kaydı
- Rehber, fotoğraf, mikrofon veya kamera erişimi

Uygulamada reklam ağı, analitik aracı veya üçüncü taraf takip kodu
bulunmaz.

## Cihazınızda kalan veriler

Uygulamayı kullanırken oluşan şu bilgiler yalnızca **kendi cihazınızda**
saklanır:

- Yer imleriniz, vurgularınız ve ayetlere yazdığınız notlar
- Okuma ilerlemeniz ve plan takibiniz
- Tema, punto, satır aralığı gibi görüntüleme tercihleriniz
- Bildirim tercihiniz ve seçtiğiniz saat

Bu veriler cihazın uygulama alanındaki bir veritabanında tutulur. Bize
veya başka bir tarafa gönderilmez; biz bu verilere erişemeyiz.
Uygulamayı sildiğinizde bu verilerin tümü cihazdan silinir.

Cihazınızın yedekleme ayarları açıksa (iCloud veya Google yedekleme),
uygulama verisi işletim sisteminin yedeklemesine dahil olabilir. Bu
yedekleme bizim değil, cihaz üreticinizin denetimindedir.

## Bildirimler

"Günün ayeti" hatırlatmasını açarsanız bildirim tamamen cihazınızda
planlanır. Bunun için sunucumuz yoktur; push bildirimi kullanılmaz ve
bildirim açtığınız bilgisi dışarı çıkmaz. Hatırlatmayı istediğiniz an
Ayarlar'dan kapatabilirsiniz.

## Paylaşma

Bir ayeti paylaştığınızda, metin cihazınızın kendi paylaşım penceresine
verilir ve hangi uygulamaya göndereceğinize siz karar verirsiniz. Bu
işlem sizin başlattığınız anda gerçekleşir; seçtiğiniz uygulamanın
gizlilik politikası o noktadan sonra geçerlidir.

## İnternet erişimi

Uygulamanın çalışması için internet bağlantısı gerekmez. Tüm meal metni,
arama dizini ve kök verisi uygulamayla birlikte gelir.

## Çocuklar

Uygulama her yaştan kullanıcıya uygundur ve hiç kimseden — çocuklar dahil —
kişisel veri toplamadığı için çocuklara yönelik ek bir veri işleme
yapılmaz.

## Haklarınız

Kişisel veri toplamadığımız için tarafımızda silinecek, düzeltilecek veya
taşınacak bir veriniz bulunmaz. Cihazınızdaki verileri istediğiniz zaman
uygulama içinden ya da uygulamayı silerek kaldırabilirsiniz.

## Değişiklikler

Bu politika değişirse güncellenmiş metin uygulamanın yeni sürümüyle
birlikte yayımlanır ve yukarıdaki tarih güncellenir.

## İletişim

Sorularınız için: $contactEmail
''';

  static const _privacyEn = '''
# Privacy Policy

**Last updated:** $lastUpdatedEn

## In short

This app collects no information about you. No account is required, no
internet connection is required, and nothing you write leaves your device.

## Data we do not collect

The app does **not** collect, store, or transmit any of the following:

- Name, email, phone number, or any other identifying information
- Location data
- Device identifiers or advertising IDs
- Usage statistics, analytics, or crash reports
- Access to contacts, photos, microphone, or camera

The app contains no advertising networks, analytics tools, or third-party
tracking code.

## Data that stays on your device

The following is stored **only on your own device**:

- Your bookmarks, highlights, and notes on verses
- Your reading progress and plan tracking
- Display preferences such as theme, font size, and line spacing
- Your notification preference and chosen time

This data lives in a database inside the app's own storage area. It is not
sent to us or anyone else, and we cannot access it. Deleting the app
removes all of it from your device.

If your device backup is enabled (iCloud or Google backup), app data may be
included in your operating system's backup. That backup is controlled by
your device vendor, not by us.

## Notifications

If you enable the "Verse of the day" reminder, the notification is
scheduled entirely on your device. We operate no server for it; no push
notifications are used, and the fact that you enabled it never leaves your
device. You can turn the reminder off at any time in Settings.

## Sharing

When you share a verse, the text is handed to your device's own share
sheet and you decide which app receives it. This happens only when you
start it, and the privacy policy of the app you choose applies from that
point onward.

## Internet access

The app does not require an internet connection to function. All
translation text, search index, and root data ship with the app.

## Children

The app is suitable for users of all ages, and because it collects no
personal data from anyone — including children — no additional processing
of children's data takes place.

## Your rights

Because we collect no personal data, there is nothing on our side to
delete, correct, or transfer. You can remove the data on your device at
any time from within the app or by deleting the app.

## Changes

If this policy changes, the updated text ships with a new version of the
app and the date above is updated.

## Contact

Questions: $contactEmail
''';

  static const _termsTr = '''
# Kullanım Şartları

**Son güncelleme:** $lastUpdated

## Kabul

Bu uygulamayı kullanarak aşağıdaki şartları kabul etmiş olursunuz. Şartları
kabul etmiyorsanız uygulamayı kullanmayınız.

## Kullanım izni

Uygulamayı kişisel ve ticari olmayan amaçlarla, cihazınızda kullanmanız için
size devredilemez bir kullanım izni verilir. Uygulamayı kaynak koda
dönüştüremez, çoğaltıp dağıtamaz veya içindeki metinleri ayrı bir ürün
olarak yeniden yayımlayamazsınız.

## İçeriğin niteliği

Uygulama Kur'an-ı Kerim'in Arapça metnini ve Türkçe/İngilizce meal
metinlerini sunar.

**Meal bir çeviridir, Kur'an'ın kendisi değildir.** Her meal, çevirenin
anlayışını yansıtır ve orijinal metnin yerini tutmaz. Uygulamadaki
metinler bilgi ve okuma amaçlıdır; dinî bir hüküm kaynağı veya fetva
niteliği taşımaz. Dinî konularda ehil kişilere danışmanız tavsiye edilir.

Metinlerin doğru aktarılması için özen gösterilmiştir; ancak dizgi hatası
veya eksik bulunmadığı garanti edilmez. Fark ettiğiniz hataları bize
bildirebilirsiniz.

## Kendi içeriğiniz

Ayetlere yazdığınız notlar size aittir ve yalnızca cihazınızda tutulur.
Bu içeriğe erişimimiz olmadığı için sorumluluğu ve yedeklenmesi size
aittir. Uygulamayı sildiğinizde notlarınız da silinir.

## Fikri mülkiyet

Kur'an'ın Arapça metni telif konusu değildir. Meal, çeviri ve kök analizi
metinlerinin hakları ilgili hak sahiplerine aittir; uygulama içindeki
"Kaynaklar ve Telif" bölümünde belirtilmiştir. Uygulamanın tasarımı, kodu
ve arayüzü geliştiricisine aittir.

## Garanti reddi

Uygulama "olduğu gibi" sunulur. Kesintisiz veya hatasız çalışacağı, belirli
bir amaca uygun olacağı yönünde açık ya da örtülü bir garanti verilmez.

## Sorumluluk sınırı

Yürürlükteki hukukun izin verdiği ölçüde, uygulamanın kullanımından doğan
dolaylı zararlardan, veri kaybından veya kâr kaybından sorumlu tutulamayız.
Cihazınızdaki verilerinizin yedeklenmesi sizin sorumluluğunuzdadır.

## Değişiklikler

Şartlar güncellenebilir. Güncellenen metin uygulamanın yeni sürümüyle
yayımlanır; uygulamayı kullanmaya devam etmeniz yeni şartları kabul
ettiğiniz anlamına gelir.

## Uygulanacak hukuk

Bu şartlar Türkiye Cumhuriyeti hukukuna tabidir.

## İletişim

$contactEmail
''';

  static const _termsEn = '''
# Terms of Use

**Last updated:** $lastUpdatedEn

## Acceptance

By using this app you accept the terms below. If you do not accept them,
please do not use the app.

## License to use

You are granted a non-transferable license to use the app on your device
for personal, non-commercial purposes. You may not reverse-engineer the
app, redistribute it, or republish the texts it contains as a separate
product.

## Nature of the content

The app presents the Arabic text of the Qur'an along with Turkish and
English translations.

**A translation is an interpretation, not the Qur'an itself.** Every
translation reflects the understanding of its translator and does not
replace the original text. The texts in this app are for reading and
information; they are not a source of religious rulings. For religious
questions, please consult qualified scholars.

Care has been taken in reproducing the texts, but they are not guaranteed
to be free of typographical errors or omissions. Please report any errors
you find.

## Your own content

Notes you write on verses belong to you and are kept only on your device.
Because we have no access to them, their safekeeping and backup are your
responsibility. Deleting the app deletes your notes.

## Intellectual property

The Arabic text of the Qur'an is not subject to copyright. Rights to the
translation and root-analysis texts belong to their respective holders and
are listed in the "Sources & Copyright" section inside the app. The design,
code, and interface of the app belong to its developer.

## Disclaimer of warranty

The app is provided "as is". No express or implied warranty is given that
it will operate uninterrupted or error-free, or that it is fit for a
particular purpose.

## Limitation of liability

To the extent permitted by applicable law, we are not liable for indirect
damages, loss of data, or loss of profit arising from use of the app.
Backing up the data on your device is your responsibility.

## Changes

These terms may be updated. Updated text ships with a new version of the
app; continuing to use the app means you accept the new terms.

## Governing law

These terms are governed by the laws of the Republic of Türkiye.

## Contact

$contactEmail
''';

  static const _sourcesTr = '''
# Kaynaklar ve Telif

## Kur'an'ın Arapça metni

Kur'an-ı Kerim'in Arapça metni telif hakkı konusu değildir ve serbestçe
kullanılabilir.

## Meal metinleri

Uygulamadaki Türkçe ve İngilizce meal metinleri, hak sahiplerine ait
eserlerdir. Meal bir çeviri çalışmasıdır ve çevirenin fikrî emeğini
taşır.

Uygulamadaki bir metnin size ait olduğunu ve izinsiz kullanıldığını
düşünüyorsanız lütfen bizimle iletişime geçin; bildiriminiz üzerine metin
incelenir ve gerekirse kaldırılır.

İletişim: $contactEmail

## Kök analizi verisi

Kelime kökü ve morfoloji verisi **Quranic Arabic Corpus**
(corpus.quran.com) kaynağından alınmıştır. Bu veri GNU General Public
License altında dağıtılmaktadır ve kaynağın belirtilmesini şart koşar.

## Yazı tipleri

Arayüz ve okuma metni için kullanılan yazı tipleri (Inter, Source Serif 4)
SIL Open Font License altında dağıtılmaktadır.

## Açık kaynak bileşenler

Uygulama Flutter ile geliştirilmiştir ve açık kaynak paketler kullanır.
Tüm bileşenlerin lisans metinleri Ayarlar > Açık Kaynak Lisansları
bölümünde listelenir.
''';

  static const _sourcesEn = '''
# Sources & Copyright

## The Arabic text of the Qur'an

The Arabic text of the Qur'an is not subject to copyright and may be used
freely.

## Translation texts

The Turkish and English translations in this app are works belonging to
their rights holders. A translation is a work of interpretation and carries
the intellectual effort of its translator.

If you believe a text in this app belongs to you and is used without
permission, please contact us; the text will be reviewed upon your notice
and removed if necessary.

Contact: $contactEmail

## Root analysis data

Word root and morphology data is taken from the **Quranic Arabic Corpus**
(corpus.quran.com). This data is distributed under the GNU General Public
License and requires attribution.

## Typefaces

The typefaces used for the interface and reading text (Inter, Source Serif
4) are distributed under the SIL Open Font License.

## Open source components

The app is built with Flutter and uses open source packages. License texts
for all components are listed under Settings > Open Source Licenses.
''';

  static const _audioInfoTr = '''
# Ses Hakkında

## Kayıtlar nereden geliyor

Tilavet kayıtları **EveryAyah** arşivinden (everyayah.com) indirilir. Bu
arşiv, tanınmış karilerin ayet ayet bölünmüş stüdyo kayıtlarını ücretsiz
olarak sunar ve Kur'an uygulamalarında yaygın biçimde kullanılır.

Kayıtlar uygulamayla birlikte gelmez. Her kari için tam Kur'an yüzlerce
megabayt tutar; hepsi pakete konsaydı uygulama hiçbir mağazanın kabul
etmeyeceği bir boyuta ulaşırdı.

## İndirme ne zaman yapılır

Ses **yalnızca siz bir sureyi dinlemeyi seçtiğinizde** indirilir. İndirme
başlamadan önce hangi karinin okuduğu ve yaklaşık kaç megabayt yer
tutacağı size sorulur; onaylamazsanız hiçbir şey indirilmez.

Uygulamanın geri kalanı tamamen çevrimdışı çalışır. Meal metinleri, kök
analizi ve arama verisi uygulamayla birlikte gelir; bunlar için hiçbir
zaman internete bağlanılmaz. **Ses indirmesi, uygulamanın ağ kullandığı
tek yerdir.**

## Veri kullanımı

İndirme mobil veri bağlantınız üzerinden yapılıyorsa bu, veri paketinizden
düşer. Mobil veri kullandığınız algılandığında indirme onayında ayrıca
uyarılırsınız.

Bir sureyi bir kez indirdikten sonra tekrar indirilmez; sonraki
dinlemeleriniz tamamen çevrimdışıdır.

## Dosyalar nerede saklanır

İndirilen ses dosyaları cihazınızın uygulama destek dizininde tutulur.
Bunlar yeniden indirilebilir dosyalar olduğu için **iCloud veya cihaz
yedeklemesine dahil edilmez** — yüzlerce megabaytlık ses, yedeğinizi
gereksiz yere şişirmemelidir.

Her kari için ayrı bir klasör tutulur. Kariyi değiştirirseniz eski
kayıtlar silinmez; istediğiniz zaman geri dönebilirsiniz.

## Nasıl silinir

Ayarlar > Dinle bölümündeki **İndirilen sesler** satırından toplam boyutu
görebilir ve tümünü silebilirsiniz. Sildikten sonra dilediğiniz zaman
yeniden indirebilirsiniz.

Uygulamayı kaldırdığınızda indirilen tüm sesler de silinir.
''';

  static const _audioInfoEn = '''
# About Audio

## Where the recordings come from

Recitation audio is downloaded from the **EveryAyah** archive
(everyayah.com). It offers verse-by-verse studio recordings by
well-known reciters, free of charge, and is widely used by Qur'an
applications.

The recordings do not ship with the app. A full Qur'an runs to hundreds
of megabytes per reciter; bundling them all would push the app past a
size any store would accept.

## When downloads happen

Audio is downloaded **only when you choose to listen to a surah**. Before
a download starts you are told who recites it and roughly how many
megabytes it will take; nothing is downloaded unless you confirm.

The rest of the app works entirely offline. Translations, root analysis
and search data ship with the app and never require a connection.
**Downloading audio is the only place this app uses the network.**

## Data usage

If the download runs over your mobile connection it counts against your
data plan. When mobile data is detected, the download prompt warns you.

Once a surah is downloaded it is never fetched again; later listening is
fully offline.

## Where files are stored

Downloaded audio lives in your device's application support directory.
Because these files can always be downloaded again, they are **excluded
from iCloud and device backups** — hundreds of megabytes of audio should
not inflate your backup.

Each reciter has its own folder. Switching reciters does not delete what
you already have; you can switch back at any time.

## How to remove them

Settings > Listen shows the total size under **Downloaded audio**, where
you can delete everything at once. You can download again whenever you
like.

Uninstalling the app removes all downloaded audio as well.
''';
}

/**
 * Site metinleri. Türkçe metinler store/app_store_tr.md ve
 * store/STORE_LISTING.md dosyalarındaki mağaza açıklamalarından alındı;
 * İngilizce karşılıkları aynı içeriğin çevirisi.
 *
 * Metinler bileşenlerin içine gömülmedi: dil düğmesi tek bir sözlükten
 * okuyor, yeni bir dil eklemek yalnızca bu nesneye anahtar eklemek demek.
 */
export const content = {
  tr: {
    nav: {
      features: 'Özellikler',
      screens: 'Ekranlar',
      privacy: 'Gizlilik',
      faq: 'Sorular',
      support: 'Destek',
      download: 'İndir',
    },

    hero: {
      badge: 'Ücretsiz · Reklamsız · Açık kaynak',
      title: "Kur'an'ı indiği sırayla okuyun",
      lede: "Sureleri iniş sırasına dizen, her kelimenin Arapça kökünü açan ve tamamen çevrimdışı çalışan bir Türkçe meal uygulaması. Hesap yok, reklam yok, veri toplanmıyor.",
      primary: 'App Store',
      secondary: 'Google Play',
      note: 'iOS 13+ ve Android 8+ · 6.236 ayet cihazınızda',
    },

    stats: [
      { value: '6.236', label: 'ayet çevrimdışı' },
      { value: '114', label: 'sure, iki sırada' },
      { value: '5', label: 'kâri, indirilebilir' },
      { value: '0', label: 'toplanan veri' },
    ],

    featuresTitle: 'Metni açan özellikler',
    featuresLede:
      'Her özellik tek bir soruya cevap veriyor: metin nasıl daha iyi anlaşılır?',

    features: [
      {
        icon: 'order',
        title: 'İniş sırası okuma',
        body: "Mushaf sırası kabaca sure uzunluğuna göre düzenlenir, metnin geliş sırasını göstermez. İniş sırasıyla okunduğunda kısa ve yoğun Mekke sureleriyle başlanır, ayetler giderek uzar; yirmi üç yıllık sürecin nasıl ilerlediği takip edilebilir.",
      },
      {
        icon: 'root',
        title: 'Kök analizi',
        body: "Bir kelimeye dokunun, Arapça kökünü ve o kökün Kur'an'da geçtiği bütün ayetleri görün. Bir kavramın farklı bağlamlarda hangi anlamları kazandığını görmek, sözlük karşılığından fazlasını anlatır.",
      },
      {
        icon: 'search',
        title: "Türkçe'ye göre arama",
        body: '6.236 ayette anında sonuç. Büyük harf, şapkalı harfler ve noktasız i sorun çıkarmaz: "IŞIK" araması "ışık" kelimesini, "adalet" araması "adâlet" yazımını bulur.',
      },
      {
        icon: 'plan',
        title: 'Okuma planları',
        body: 'Dört hazır plan: kronolojik 365 gün, kronolojik 180 gün, mushaf 30 gün ve mushaf 90 gün. Her planda günlük ilerleme kaydedilir, kaldığınız yerden devam edersiniz.',
      },
      {
        icon: 'audio',
        title: 'Beş kâri, çevrimdışı',
        body: 'Alafasy, Husary, Abdul Basit, Sudais ve Minshawi. İndirdiğiniz sureleri bağlantısız dinleyin; siz başlatmadıkça hiçbir ses dosyası inmez, mobil veri öncesi uyarı gösterilir.',
      },
      {
        icon: 'note',
        title: 'Vurgu, yer imi ve not',
        body: 'Ayete uzun basın: beş renkle vurgulayın, yer imi ekleyin, kendi notunuzu yazın, paylaşın veya kopyalayın. Hepsi yalnızca sizin cihazınızda kalır.',
      },
    ],

    screensTitle: 'Uygulamayı gezin',
    screensLede:
      'Aşağıdaki telefon gerçek uygulamanın arayüzü. Sekmelere basın, sıralamayı değiştirin, bir sureye girin.',
    screensHint: 'Dokunarak deneyin →',

    privacyTitle: 'Hiçbir veri toplanmıyor',
    privacyLede:
      'Bir Kur\'an uygulamasının hangi veriyi topladığı, iddia edilmesi değil doğrulanabilmesi gereken bir konu. Kod MIT lisansıyla açık; inceleyebilir, dilerseniz kendiniz derleyebilirsiniz.',
    privacyPoints: [
      { title: 'Analitik yok', body: 'Hiçbir kullanım istatistiği toplanmaz, çökme raporu gönderilmez.' },
      { title: 'Hesap yok', body: 'Giriş ekranı yok. Uygulamayı açın ve okumaya başlayın.' },
      { title: 'Reklam ağı yok', body: 'Üçüncü taraf hiçbir SDK gömülü değil.' },
      { title: 'Veri cihazda', body: 'Notlar, yer imleri, vurgular ve ilerleme yalnızca cihazınızda saklanır.' },
    ],
    privacyFootnote:
      'İnternete çıkılan tek yer sizin başlattığınız tilavet indirmeleridir; ses dosyaları everyayah.com üzerinden gelir ve bu isteklerde kişisel hiçbir bilgi taşınmaz.',
    privacyLinks: { policy: 'Gizlilik politikası', terms: 'Kullanım şartları', source: 'Kaynak kod' },

    faqTitle: 'Sık sorulanlar',
    faq: [
      {
        q: 'İniş sırası nedir, neden önemli?',
        a: 'Mushaf sırası kabaca uzunluğa göre dizilidir. İniş sırası ise ayetlerin geldiği sırayı takip eder; kısa Mekke sureleriyle başlar, dil ve konular süreç içinde değişir. Uygulama varsayılan olarak bu sıraya dizer, mushaf sırasına ayarlardan tek dokunuşla geçilir.',
      },
      {
        q: 'İnternet gerekiyor mu?',
        a: 'Hayır. 6.236 ayetin tamamı, tefsir ve kök verisi uygulamayla birlikte gelir. İnternet yalnızca isteğe bağlı tilavet indirmelerinde kullanılır.',
      },
      {
        q: 'Uygulama ücretli mi?',
        a: 'Hayır. Ücretsiz, uygulama içi satın alma ve reklam yok.',
      },
      {
        q: 'Notlarım yedekleniyor mu?',
        a: 'Notlar, yer imleri ve ilerleme yalnızca cihazınızda tutulur. Sunucu olmadığı için bulut yedeği yoktur; uygulamayı sildiğinizde bu veriler de silinir.',
      },
      {
        q: 'Hangi meal kullanılıyor?',
        a: 'Türkçe meal ve tefsir metinleri uygulamayla birlikte paketlenir. Kaynak kod MIT lisanslıdır; meal ve tefsir metinleri bu lisansın kapsamı dışındadır.',
      },
    ],

    supportTitle: 'Uygulama ücretsiz ve öyle kalacak',
    supportLede:
      'Reklam yok, hesap yok, takip yok. Uygulama bir kişinin boş vakitlerinde yazılıyor ve herkese açık dağıtılıyor; geliştirici hesabı, ses barındırma ve test cihazları bir maliyet oluşturuyor. Dilerseniz gönüllü bir katkıyla destek olabilirsiniz.',
    supportChannels: {
      buymeacoffee: {
        title: 'Buy Me a Coffee',
        subtitle: 'Kartla tek seferlik katkı',
        action: 'Aç',
      },
      papara: {
        title: 'Papara',
        subtitle: 'Papara ile hızlı gönderim',
        action: 'Aç',
      },
      iban: {
        title: 'Banka havalesi (IBAN)',
        subtitle: '',
        holderLabel: 'Alıcı:',
        action: 'Kopyala',
      },
    },
    supportCopied: 'Kopyalandı',
    supportNote:
      'Bağış tamamen gönüllüdür ve karşılığında uygulamada hiçbir özellik açılmaz — bağış yapsanız da yapmasanız da her şeye aynı şekilde erişirsiniz.',

    ctaTitle: 'Okumaya başlayın',
    ctaLede: 'Ücretsiz, reklamsız, hesapsız. İndirin ve açın.',

    footerTagline: "Kur'an-ı Kerim Türkçe meali · iniş sırası, kök analizi, çevrimdışı",
    footerRights: 'Kaynak kod MIT lisansıyla açıktır.',
  },

  en: {
    nav: {
      features: 'Features',
      screens: 'Screens',
      privacy: 'Privacy',
      faq: 'FAQ',
      support: 'Support',
      download: 'Download',
    },

    hero: {
      badge: 'Free · No ads · Open source',
      title: 'Read the Qur’an in the order it was revealed',
      lede: 'A Turkish translation app that orders surahs chronologically, opens up the Arabic root of every word, and works fully offline. No account, no ads, no data collection.',
      primary: 'App Store',
      secondary: 'Google Play',
      note: 'iOS 13+ and Android 8+ · 6,236 verses on your device',
    },

    stats: [
      { value: '6,236', label: 'verses offline' },
      { value: '114', label: 'surahs, two orders' },
      { value: '5', label: 'reciters, downloadable' },
      { value: '0', label: 'data collected' },
    ],

    featuresTitle: 'Features that open up the text',
    featuresLede: 'Every feature answers one question: how is this text better understood?',

    features: [
      {
        icon: 'order',
        title: 'Chronological reading',
        body: 'The mushaf order is arranged roughly by length and does not show the order in which the text arrived. Read chronologically, you begin with the short, dense Meccan surahs; verses grow longer and the twenty-three year process becomes visible.',
      },
      {
        icon: 'root',
        title: 'Root analysis',
        body: 'Tap a word to see its Arabic root and every verse where that root appears. Watching how a concept shifts across contexts says far more than a dictionary entry.',
      },
      {
        icon: 'search',
        title: 'Turkish-aware search',
        body: 'Instant results across 6,236 verses. Case, circumflexes and dotless i are handled: searching "ISIK" finds "ışık", "adalet" finds "adâlet".',
      },
      {
        icon: 'plan',
        title: 'Reading plans',
        body: 'Four presets: chronological 365 and 180 days, mushaf order 30 and 90 days. Daily progress is saved and you continue where you left off.',
      },
      {
        icon: 'audio',
        title: 'Five reciters, offline',
        body: 'Alafasy, Husary, Abdul Basit, Sudais and Minshawi. Listen without a connection once downloaded; nothing downloads unless you start it, and mobile data is flagged first.',
      },
      {
        icon: 'note',
        title: 'Highlights, bookmarks, notes',
        body: 'Long-press a verse: highlight in five colours, bookmark it, write your own note, share or copy. All of it stays on your device.',
      },
    ],

    screensTitle: 'Take a look around',
    screensLede: 'The phone below is the real interface. Switch tabs, flip the ordering, open a surah.',
    screensHint: 'Tap to explore →',

    privacyTitle: 'No data is collected',
    privacyLede:
      'What a Qur’an app collects should be verifiable, not merely claimed. The source is open under MIT; inspect it, or build it yourself.',
    privacyPoints: [
      { title: 'No analytics', body: 'No usage statistics are gathered and no crash reports are sent.' },
      { title: 'No account', body: 'There is no sign-in screen. Open the app and start reading.' },
      { title: 'No ad network', body: 'No third-party SDK is embedded.' },
      { title: 'Data stays local', body: 'Notes, bookmarks, highlights and progress are stored only on your device.' },
    ],
    privacyFootnote:
      'The only network access is a recitation download you start yourself; audio comes from everyayah.com and those requests carry no personal information.',
    privacyLinks: { policy: 'Privacy policy', terms: 'Terms of use', source: 'Source code' },

    faqTitle: 'Frequently asked',
    faq: [
      {
        q: 'What is revelation order and why does it matter?',
        a: 'The mushaf order is arranged roughly by length. Revelation order follows the sequence in which verses arrived: it begins with short Meccan surahs, and language and subject matter shift over time. The app uses this order by default; mushaf order is one tap away in settings.',
      },
      {
        q: 'Does it need an internet connection?',
        a: 'No. All 6,236 verses, the commentary and the root data ship with the app. The network is used only for optional recitation downloads.',
      },
      { q: 'Is the app paid?', a: 'No. It is free, with no in-app purchases and no ads.' },
      {
        q: 'Are my notes backed up?',
        a: 'Notes, bookmarks and progress live only on your device. There is no server, so there is no cloud backup; deleting the app deletes them too.',
      },
      {
        q: 'Which translation is used?',
        a: 'The Turkish translation and commentary are bundled with the app. The source code is MIT licensed; the translation and commentary texts fall outside that licence.',
      },
    ],

    supportTitle: 'The app is free, and will stay free',
    supportLede:
      'No ads, no accounts, no tracking. It is written by one person in their spare time and given away to everyone; developer account fees, audio hosting and test devices all cost money. If you would like, you can support it with a voluntary contribution.',
    supportChannels: {
      buymeacoffee: {
        title: 'Buy Me a Coffee',
        subtitle: 'One-time contribution by card',
        action: 'Open',
      },
      papara: {
        title: 'Papara',
        subtitle: 'Quick transfer with Papara',
        action: 'Open',
      },
      iban: {
        title: 'Bank transfer (IBAN)',
        subtitle: '',
        holderLabel: 'Recipient:',
        action: 'Copy',
      },
    },
    supportCopied: 'Copied',
    supportNote:
      'Donating is entirely voluntary and unlocks nothing in the app — you get exactly the same access whether you contribute or not.',

    ctaTitle: 'Start reading',
    ctaLede: 'Free, ad-free, account-free. Download and open.',

    footerTagline: 'Turkish translation of the Qur’an · chronological order, root analysis, offline',
    footerRights: 'Source code is open under the MIT licence.',
  },
}

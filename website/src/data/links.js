/**
 * Dış bağlantılar.
 *
 * Tek yerde toplandı: aynı adres birden fazla bölümde geçiyor ve
 * biri güncellenip diğeri unutulduğunda fark edilmesi zor.
 */
export const links = {
  github: 'https://github.com/emomu/kuran_turkce_meal',

  // Uygulama yayınlanınca gerçek mağaza adresleriyle değiştirilecek.
  appStore: '#download',
  playStore: '#download',
}

/**
 * Bağış kanalları.
 *
 * Uygulamadaki `lib/features/donate/data/donation_links.dart` ile aynı
 * bilgiyi taşır; ikisi elle eşlenir. Bir kanal burada açılıp uygulamada
 * kapalı kalırsa kullanıcı iki yerde farklı seçenek görür.
 *
 * `kind` alanı davranışı belirler: `link` yeni sekmede açılır, `copy`
 * panoya kopyalanır. Kapalı kanallar hiç çizilmez — çalışmayan bir bağış
 * düğmesi göstermek, hiç göstermemekten kötüdür.
 */
export const donationChannels = [
  {
    id: 'buymeacoffee',
    kind: 'link',
    value: 'https://buymeacoffee.com/emomu',
    enabled: true,
  },
  {
    id: 'papara',
    kind: 'link',
    value: 'https://ppr.ist/KULLANICI_ADINIZ',
    enabled: false,
  },
  {
    id: 'iban',
    kind: 'copy',
    value: 'TR07 0001 0090 1003 0726 1050 10',
    // Havalede alıcı adı IBAN'la eşleşmezse banka işlemi reddedebiliyor;
    // bu yüzden ad da gösterilir ve kopyalanan metne dahil edilir.
    holder: 'Emirhan Soylu',
    enabled: true,
  },
]

/** Görünecek kanallar. */
export const activeDonationChannels = donationChannels.filter((c) => c.enabled)

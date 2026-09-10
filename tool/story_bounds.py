#!/usr/bin/env python3
"""Peygamber kıssalarının ayet sınırları.

`build_prophets.py` kıssa listesini meal metnindeki ad geçişlerinden üretir.
O yöntem kıssanın *nerede anıldığını* bulur ama *nerede başlayıp bittiğini*
bulamaz: anlatı sürerken ad tekrarlanmaz ("melek dedi ki", "sonra doğum
sancısı onu...") ve o ayetler listeden düşer.

Somut örnek — Meryem 16-35 tek bir kesintisiz anlatıdır; ad taraması ondan
yalnızca 22, 27, 30 ve 34'ü alır. Kullanıcı kopuk cümleler okur: gebe kaldığı
söylenir, sonra doğrudan kavmine dönüşüne atlanır; doğum sahnesi (23-26)
görünmez.

Bu dosya o boşluğu kapatır: her kıssanın gerçek sınırları elle yazılır.
Sınırlar ayet ayet okunarak çizildi; ölçüt "anlatı burada başlıyor, burada
bitiyor" oldu — adın geçip geçmemesi değil.

KULLANIM
--------
`build_prophets.py` bu dosyayı okur. Bir sure için sınır tanımlıysa o aralık
bütünüyle kıssaya girer; tanımlı değilse eski davranış sürer (yalnızca adın
geçtiği ayetler).

BİÇİM
-----
    "prophet_id": {
        sure_no: [(başlangıç, bitiş), ...],
    }

Aralıklar kapalıdır: (16, 35) → 16, 17, ..., 35.

SINIRLARIN NİTELİĞİ
-------------------
Kıssa sınırı çizmek bir yorum işidir; müfessirler de her yerde aynı sınırı
vermez. Buradaki aralıklar anlatının kendisine bakılarak seçildi: konu
değiştiğinde, hitap kıssadan cemaate döndüğünde ya da yeni bir bahis
açıldığında kıssa bitmiş sayıldı. Tartışmalı yerlerde dar olan tercih
edildi — eksik göstermek, alakasız ayet eklemekten yeğdir.
"""

# Kıssa sınırları. Doldurulmamış peygamberler eski davranışı sürdürür.
STORY_BOUNDS: dict[str, dict[int, list[tuple[int, int]]]] = {
    "isa": {
        # 33 seçilmiş soylarla açılır, 62 "İşte İsa hakkında söylenen gerçek
        # kıssa budur" ile kapanır. 63'ten sonra hitap kitap ehline döner.
        3: [(33, 62)],
        # 16 "Meryem kıssasını da an" ile açılır, 34 "İsa'ya dair Allah'ın
        # sözü" ile kapanır. Ad taraması buradan yalnızca 4 ayet alıyordu;
        # doğum sahnesi (23-26) tamamen düşüyordu.
        19: [(16, 34)],
        # Mâide 110-119: Allah'ın Îsâ'ya nimetleri, sofra mucizesi ve
        # kıyamet gününde sorgulanışı. 120'de hitap genelleşir.
        5: [(110, 119)],
    },
    # A'râf 59-93 peygamber kıssalarını art arda dizer ve her biri aynı
    # kalıpla açılıp kapanır: "kavmine gönderdik" → tebliğ → yalanlama →
    # "onu ve beraberindekileri kurtardık". Sınırlar o kalıptan okundu.
    "nuh": {
        7: [(59, 64)],
        # Şuarâ kıssaları aynı kalıpla dizilir: "kavmi peygamberleri
        # yalancılıkla itham etti" ile açılır, "Şüphesiz bunda bir âyet
        # vardır / Rabbin mutlak galip ve engin merhamet sahibidir" beyitiyle
        # kapanır. Sınırlar o beyitten okundu.
        26: [(105, 122)],
        # Hûd suresi de kıssaları dizer; her biri "kavmine gönderdik" ile
        # açılıp helâk ya da kurtuluşla kapanır.
        11: [(25, 49)],
        37: [(75, 82)],
        # Nûh suresi baştan sona kıssadır: gönderiliş, tebliğ, kavmin
        # direnişi ve tufan duası.
        71: [(1, 28)],
        # Kamer kıssaları "kavmi de yalanladı" ile açılır, "Andolsun biz
        # Kur'ân'ı öğüt almak için kolaylaştırdık" nakaratıyla kapanır.
        54: [(9, 17)],
    },
    "hud": {
        7: [(65, 72)],
        26: [(123, 140)],
        11: [(50, 60)],
        # Ahkâf 21-26: "Âd kavminin kardeşi Hud'u hatırla".
        46: [(21, 26)],
        54: [(18, 22)],
    },
    "salih": {
        7: [(73, 79)],
        26: [(141, 159)],
        11: [(61, 68)],
        27: [(45, 53)],
        54: [(23, 32)],
    },
    "lut": {
        7: [(80, 84)],
        26: [(160, 175)],
        # Hûd 77-83: melekler Lût'a gelir, kavmi helâk olur. İbrâhim'e
        # gelen müjde (69-76) ile aynı anlatının devamıdır ama Lût'un payı
        # 77'de başlar.
        11: [(77, 83)],
        27: [(54, 58)],
        21: [(74, 75)],
        # Hicr 58-77: melekler İbrâhim'den ayrılıp Lût kavmine gider.
        15: [(58, 77)],
        37: [(133, 138)],
        # Ankebût 28-35: Lût'un tebliği ve kavminin helâki.
        29: [(28, 35)],
        # Zâriyât 31-37: meleklerin Lût kavmine gidişi ve helâk.
        51: [(31, 37)],
        54: [(33, 40)],
    },
    "suayb": {
        7: [(85, 93)],
        # Eyke halkı; Medyen kıssasının Şuarâ'daki anlatımı.
        26: [(176, 191)],
        11: [(84, 95)],
        # Kasas 22-28: Medyen'e varış, kızlarının sürüsü ve Mûsâ ile
        # anlaşma. Şuayb'ın adı yalnızca 26-27'de geçer; anlatının çoğu ad
        # taramasına girmiyordu.
        28: [(22, 28)],
    },
    "musa": {
        # 103 "Musa'yı Firavun'a gönderdik" ile açılır; anlatı sihirbazlar,
        # denizden geçiş, levhalar ve buzağı olayıyla kesintisiz sürer.
        # 171'de İsrailoğullarına verilen söz anlatılır, 172'de yeni bahis
        # (zürriyet misakı) açılır.
        7: [(103, 171)],
        # Tâhâ: kıssanın en uzun tek parça anlatımlarından biri. 9'da
        # "Musa'nın hikâyesi sana geldi mi" ile açılır, 98'de kapanır.
        20: [(9, 98)],
        # Kasas 3 "Musa ile Firavun'un haberlerinden bir kısmını sana
        # okuyalım" ile açılır. Doğumu, Mısır'dan kaçışı, Medyen yılları ve
        # dönüşü kesintisiz anlatılır; 44'te "sen batı yönünde
        # bulunmuyordun" diyerek hitap Peygamber'e döner.
        28: [(3, 43)],
        # Şuarâ 10 "Rabbin Musa'ya nida edip" ile açılır, 68'de kapanış
        # beyitiyle biter; 69'da İbrâhim kıssası başlar.
        26: [(10, 68)],
        # Hûd 96-99: kısa bir Mûsâ-Firavun değinmesi; 100'de sure kıssaları
        # toplayan bir cümleye döner.
        11: [(96, 99)],
        # Neml 7-14: Tûr'daki nida ve dokuz mucize.
        27: [(7, 14)],
        # Bakara 49-74: İsrailoğullarına hitapla anlatılan Mûsâ bölümü.
        # Denizden geçiş, kırk gece, buzağı ve sığır olayı birbirini izler.
        2: [(49, 74)],
        # Kehf 60-82: Mûsâ ile Hızır kıssası. Anlatı boyunca Mûsâ'nın adı
        # seyrek geçer ("adam dedi ki", "duvar ise...") — ad taraması bu
        # kıssanın yarısını kaçırıyordu. 83'te Zülkarneyn bahsi açılır.
        18: [(60, 82)],
        37: [(114, 122)],
        # Yûnus 75-92: Mûsâ ve Hârûn birlikte gönderilir; sihirbazlar ve
        # denizden geçiş. İkisinin de öznesi olduğu bir blok.
        10: [(75, 92)],
        # Mâide 20-26: kutsal toprağa girme emri ve kavmin çekinmesi.
        5: [(20, 26)],
        # Mü'min 23-46: Firavun ailesinden iman eden adamın uyarısı; 47'de
        # sahne kıyamete/cehenneme geçer.
        40: [(23, 46)],
        # İsrâ 101-104: dokuz mucize ve Firavun'un boğulması.
        17: [(101, 104)],
        # İbrâhim 5-8: "Allah'ın günlerini hatırlat" emri.
        14: [(5, 8)],
    },
    "ibrahim": {
        # Şuarâ 69 "onlara İbrahim'in kıssasını da naklet" ile açılır,
        # 104'te kapanış beyitiyle biter.
        26: [(69, 104)],
        # Hûd 69-76: elçilerin İbrâhim'e müjdesi ve Lût kavmi için tartışma.
        11: [(69, 76)],
        # Enbiyâ 51-73: putların kırılması ve ateşe atılma. 74'te Lût'a
        # geçilir.
        21: [(51, 73)],
        # Hicr 51-57: "İbrahim'in misafirlerinden de haber ver" — meleklerin
        # müjdesi. 58'de Lût kavmine geçilir.
        15: [(51, 57)],
        # Bakara 124-132: Kâbe'nin temellerinin yükseltilmesi ve İsmâil ile
        # birlikte dua; 133'te Yakûb'a geçilir.
        2: [(124, 132)],
        # Sâffât 83-113: putların reddi, ateş ve kurban olayı. Sâffât
        # kıssaları "Selam olsun ..." beyitiyle kapanır.
        37: [(83, 113)],
        # Ankebût 16-27: tebliğ, ateşe atılma ve İshak-Yakub müjdesi.
        29: [(16, 27)],
        # Meryem 41 "Kur'ân'da İbrahim'i(n kıssasını da) an" ile açılır,
        # 50'de kapanır; 51'de Mûsâ'ya geçilir.
        19: [(41, 50)],
        # Zâriyât 24-30: "İbrahim'in şerefli misafirlerinin haberi sana
        # geldi mi" — meleklerin müjdesi. 31'de Lût kavmine geçilir.
        51: [(24, 30)],
        # En'âm 74-83: yıldız, ay ve güneş üzerinden tevhide varış.
        6: [(74, 83)],
    },
    "adem": {
        # Bakara 30 "yeryüzünde bir halife yaratacağım" ile açılır, 38'de
        # yeryüzüne inişle kapanır; 39'da hitap inkârcılara döner.
        2: [(30, 38)],
        # Tâhâ 115-123: aynı kıssanın ikinci anlatımı; 124'te hitap
        # genelleşir.
        20: [(115, 123)],
        # A'râf 11-25: yaratılış, secde emri, İblis'in reddi ve iniş.
        7: [(11, 25)],
    },
    "suleyman": {
        # Neml 15 "Davud'a ve Süleyman'a bir ilim verdik" ile açılır; karınca
        # vadisi, Hüdhüd ve Sebe melikesi anlatısı 44'te köşk sahnesiyle
        # kapanır, 45'te Sâlih kıssası başlar.
        27: [(15, 44)],
        # Sâd 30-40: atlar imtihanı, tahta bırakılan ceset ve rüzgârın
        # emrine verilişi. Enbiyâ 78-82 ise iki ayetlik değinmedir; sınır
        # tanımlanmadı.
        38: [(30, 40)],
    },
    "davud": {
        # Neml'de kıssa Süleyman'ındır, Dâvûd yalnızca açılışta anılır; ona
        # sınır verilmez. Sâd 21-26 ise kendi kıssasıdır: davacıların gelişi
        # ve verdiği hüküm. Adı 22 ve 24'te geçer, aradaki anlatı ad
        # taramasına girmiyordu.
        38: [(21, 26)],
    },
    "yunus": {
        # Sâffât 139-148: balık kıssası. Adı yalnızca açılışta ve 147'de
        # geçer; arada "o", "kendisi" denir ve ad taraması bloğun çoğunu
        # kaçırırdı.
        37: [(139, 148)],
    },
    "ismail": {
        # Bakara 124-132'de İbrâhim ile birlikte Kâbe'yi yükseltir.
        2: [(124, 132)],
    },
    # Hârûn'a Mûsâ kıssasının tamamı verilmez: kardeşi olarak anlatının
    # içinde geçer ama kıssa Mûsâ'nındır. Mûsâ'nın 189 ayetini ona da vermek
    # payını 213'e çıkarıyor ve kıssayı yanlış gösteriyordu. Yalnızca
    # kendisinin de öznesi olduğu blok ayrılır.
    "harun": {
        # Sâffât 114-122 ve Yûnus 75-92: Mûsâ ile birlikte gönderildiği,
        # ikisinin de öznesi olduğu bloklar. Kalan Mûsâ bölümlerinde Hârûn
        # edilgendir (kavmine vekil bırakılır, buzağı olayında suçlanır);
        # oralarda kıssa Mûsâ'nındır ve ona verilmez. Verilseydi 24 ayetlik
        # payı 200'ün üstüne çıkar, kıssa yanlış görünürdü.
        37: [(114, 122)],
        10: [(75, 92)],
        # Tâhâ 90-94: buzağı olayında kavme direnişi ve Mûsâ'ya cevabı.
        # Anlatının öznesi Hârûn'dur, bu yüzden Mûsâ'nın Tâhâ bloğundan
        # ayrıca ona da verilir.
        20: [(90, 94)],
    },
    "yusuf": {
        # Kur'an'ın tek surede baştan sona anlatılan kıssası. 4'te rüya ile
        # açılır, 101'de Yûsuf'un duasıyla kapanır; 102'de hitap Peygamber'e
        # döner ("sana vahiyle bildirdiğimiz gayb haberlerindendir").
        #
        # 6 ve 40. surelerde adı geçer ama kıssa anlatılmaz: En'âm 84-86 bir
        # peygamber listesi, Gâfir 34 geçmişe bir atıftır. Oralarda sınır
        # tanımlanmadı, tek ayet olarak kalırlar.
        12: [(4, 101)],
    },
}

#!/usr/bin/env python3
"""Konu fihristinin kürasyonlu çekirdeği.

`build_topics.py` konu listesini iki kaynaktan üretir: burada elle yazılmış
ayet aralıkları ve meal metninde terim taraması. İkisi ayrı şeyler yapar ve
ayrı durmaları gerekir.

NEDEN ELLE YAZILMIŞ BİR ÇEKİRDEK
--------------------------------
Terim taraması "kelimenin geçtiği ayetleri" bulur, "konunun anlatıldığı
ayetleri" değil. Fark, fihristin bütün meselesi:

  * Eyyûb kıssası sabrın en uzun anlatımıdır ama o ayetlerde "sabır"
    kelimesi geçmez. Tarama onu kaçırır.
  * "Miras" fihristine bakan kullanıcı Nisâ 11-12'yi bekler; o ayetlerde
    "miras" kelimesi geçmez, paylar sayılır.
  * Buna karşılık "gün" kelimesi yüzlerce ayette geçer ve hiçbiri "kıyamet"
    fihristine ait değildir.

Bu dosya, her konunun kimliğini taşıyan ayetleri adıyla sabitler. Tarama
onun üstüne genişletme yapar; çekirdek her zaman listenin başında durur.

SEÇİM ÖLÇÜTÜ
------------
Bir aralık buraya "bu ayetler bu konu hakkındadır" diyebildiğimizde girer.
Konuya değinen değil, konuyu kuran ayetler. Şüpheli olan taramaya bırakılır:
oradan gelen bir yanlış, listenin sonunda durur ve kullanıcı onu bağlamıyla
görür; buradan gelen bir yanlış, fihristin verdiği sözü bozar.

BİÇİM
-----
    "konu_id": {
        sure_no: [(başlangıç, bitiş), ...],
    }

Aralıklar kapalıdır: (11, 12) → 11 ve 12.
"""

# Konuların çekirdek ayetleri.
#
# Sıra önemsizdir; `build_topics.py` hepsini mushaf ya da iniş sırasına
# dizer. Aynı ayet birden çok konuda olabilir ve bu doğrudur — Bakara 255
# hem tevhid hem duadır.
TOPIC_BOUNDS = {
    # --- İNANÇ ---
    "tevhid": {
        112: [(1, 4)],    # İhlâs: tevhidin en yoğun ifadesi
        2: [(255, 255)],  # Âyetü'l-Kürsî
        59: [(22, 24)],   # Haşr'ın son ayetleri: esmâ
        3: [(18, 18)],
        16: [(51, 53)],
        21: [(22, 22)],
        23: [(91, 92)],
    },
    "melekler": {
        2: [(285, 285)],
        35: [(1, 1)],
        66: [(6, 6)],
        13: [(11, 11)],
        82: [(10, 12)],
        50: [(17, 18)],
    },
    "kader": {
        57: [(22, 23)],   # "Yeryüzünde ve kendi nefislerinizde..."
        9: [(51, 51)],
        54: [(49, 49)],
        64: [(11, 11)],
        65: [(3, 3)],
    },
    "vahiy": {
        53: [(1, 12)],    # Necm: vahyin geliş biçimi
        42: [(51, 52)],
        26: [(192, 196)],
        75: [(16, 19)],
        2: [(97, 97)],
    },

    # --- İBADET ---
    "namaz": {
        2: [(238, 239)],
        4: [(101, 103)],
        17: [(78, 79)],
        29: [(45, 45)],
        62: [(9, 10)],
        107: [(4, 7)],
        20: [(132, 132)],
    },
    "zekat": {
        2: [(261, 274)],  # İnfakın en uzun bölümü
        9: [(60, 60)],    # Zekâtın sarf yerleri
        57: [(18, 18)],
        64: [(16, 17)],
        92: [(5, 11)],
    },
    "oruc": {
        2: [(183, 187)],  # Orucun tek kapsamlı bölümü
    },
    "hac": {
        2: [(196, 203)],
        3: [(96, 97)],
        22: [(26, 33)],
        5: [(1, 2)],
    },
    "dua": {
        2: [(186, 186), (201, 201)],  # "Kullarım sana beni sorarsa..."
        40: [(60, 60)],
        7: [(55, 56)],
        25: [(77, 77)],
        1: [(1, 7)],      # Fâtiha: duanın kendisi
        20: [(25, 28)],
    },
    "kuran": {
        17: [(9, 9)],
        2: [(1, 5)],
        54: [(17, 17)],
        59: [(21, 21)],
        4: [(82, 82)],
        47: [(24, 24)],
        73: [(4, 4)],
    },

    # --- AHLAK ---
    "sabir": {
        2: [(153, 157)],  # "Sabır ve namazla yardım isteyin"
        3: [(200, 200)],
        103: [(1, 3)],
        70: [(5, 5)],
        21: [(83, 84)],   # Eyyûb: sabrın kıssası, kelime geçmeden
        38: [(41, 44)],   # Eyyûb'un devamı
        12: [(18, 18)],   # Yakûb'un "güzel sabır"ı
        31: [(17, 17)],
    },
    "sukur": {
        14: [(7, 7)],     # "Şükrederseniz artırırım"
        2: [(152, 152)],
        16: [(18, 18)],
        27: [(40, 40)],
        31: [(12, 12)],
        55: [(13, 13)],
    },
    "tovbe": {
        39: [(53, 53)],   # "Rahmetinden umut kesmeyin"
        66: [(8, 8)],
        4: [(17, 18)],
        25: [(68, 71)],
        3: [(135, 136)],
        42: [(25, 25)],
        11: [(3, 3)],
    },
    "dogruluk": {
        9: [(119, 119)],
        33: [(70, 71)],
        2: [(42, 42)],
        17: [(35, 36)],
        83: [(1, 6)],     # Mutaffifîn: ölçüde dürüstlük
    },
    "adalet": {
        4: [(58, 58), (135, 135)],  # Emanet; "kendi aleyhinize de olsa"
        5: [(8, 8)],
        16: [(90, 90)],
        49: [(9, 9)],
        57: [(25, 25)],
        6: [(152, 152)],
    },
    "merhamet": {
        90: [(13, 17)],
        7: [(156, 156)],
        21: [(107, 107)],
        6: [(12, 12)],
        24: [(22, 22)],
        3: [(159, 159)],
    },
    "kibir": {
        31: [(18, 19)],
        17: [(37, 38)],
        7: [(146, 146)],
        28: [(76, 83)],   # Kârûn: kibrin kıssası
        40: [(35, 35)],
    },
    "giybet": {
        49: [(11, 12)],   # Hucurât: dilin âfetleri
        24: [(11, 20)],   # İfk hadisesi
        104: [(1, 3)],
        33: [(58, 58)],
    },
    "ofke": {
        3: [(133, 134)],  # "Öfkelerini yutanlar"
        42: [(37, 43)],
        41: [(34, 35)],
        7: [(199, 200)],
    },
    "ihlas": {
        98: [(5, 5)],
        39: [(2, 3)],
        2: [(264, 264)],  # Başa kakmak ameli siler
        107: [(4, 7)],
        18: [(110, 110)],
    },
    "tevekkul": {
        65: [(2, 3)],     # "Kim Allah'a güvenirse O ona yeter"
        3: [(159, 160)],
        11: [(123, 123)],
        8: [(2, 4)],
        9: [(51, 51)],
    },

    # --- İNSAN İLİŞKİLERİ ---
    "anne_baba": {
        17: [(23, 24)],   # "Öf bile deme"
        31: [(14, 15)],
        46: [(15, 15)],
        29: [(8, 8)],
        2: [(83, 83)],
    },
    "evlilik": {
        30: [(21, 21)],   # "Aranıza sevgi ve merhamet koydu"
        4: [(19, 21), (34, 35)],
        2: [(187, 187)],
        24: [(32, 33)],
        25: [(74, 74)],
    },
    "bosanma": {
        2: [(228, 232), (236, 237)],
        65: [(1, 7)],     # Talâk suresi
        4: [(35, 35), (128, 130)],
    },
    "cocuk": {
        31: [(13, 19)],   # Lokmân'ın oğluna öğütleri
        17: [(31, 31)],
        18: [(46, 46)],
        42: [(49, 50)],
        25: [(74, 74)],
    },
    "komsu": {
        4: [(36, 36)],    # Komşu hakkının sayıldığı ayet
        107: [(1, 7)],
        2: [(177, 177)],
    },
    "yetim": {
        93: [(6, 10)],
        4: [(2, 2), (6, 10)],
        2: [(220, 220)],
        89: [(17, 20)],
        76: [(8, 9)],
    },
    "kadin": {
        4: [(1, 1), (7, 7), (19, 21)],  # Mirasta kadının payı dahil
        33: [(35, 35)],   # "Müslüman erkekler ve müslüman kadınlar"
        16: [(58, 59)],
        60: [(12, 12)],
        58: [(1, 4)],     # Mücâdile: kocasını şikâyet eden kadın
    },

    # --- HUKUK VE TOPLUM ---
    "miras": {
        4: [(7, 14), (176, 176)],  # Ana bölüm ve kelâle
        2: [(180, 182)],
        5: [(106, 108)],
    },
    "borc": {
        2: [(280, 281), (282, 283)],  # Kur'an'ın en uzun ayeti: borcun yazılması
        4: [(58, 58)],
    },
    "faiz": {
        2: [(275, 281)],  # Faizin tek kapsamlı bölümü
        3: [(130, 132)],
        30: [(39, 39)],
        4: [(161, 161)],
    },
    "yemin": {
        5: [(89, 89)],
        2: [(224, 225)],
        16: [(91, 94)],
        68: [(10, 13)],
        66: [(1, 2)],
    },
    "savas": {
        2: [(190, 194)],  # Savaşın sınırları
        8: [(61, 62)],    # "Barışa yanaşırlarsa sen de yanaş"
        9: [(5, 6)],
        22: [(39, 41)],
        4: [(90, 94)],
        60: [(8, 9)],
    },
    "yonetim": {
        4: [(58, 59)],    # Emanet ve itaat
        42: [(38, 38)],   # "İşleri aralarında danışma iledir"
        3: [(159, 159)],
        5: [(42, 44)],
        38: [(26, 26)],
    },

    # --- AHİRET ---
    "olum": {
        3: [(185, 185)],  # "Her nefis ölümü tadacaktır"
        21: [(35, 35)],
        62: [(8, 8)],
        4: [(78, 78)],
        56: [(83, 87)],
        23: [(99, 100)],
        50: [(19, 19)],
    },
    "kiyamet": {
        81: [(1, 14)],    # Tekvîr
        82: [(1, 5)],     # İnfitâr
        99: [(1, 8)],     # Zilzâl
        101: [(1, 11)],   # Kâria
        75: [(1, 15)],    # Kıyâme
        56: [(1, 7)],
        39: [(68, 70)],
    },
    "cennet": {
        55: [(46, 78)],
        56: [(10, 40)],
        76: [(5, 22)],
        47: [(15, 15)],
        13: [(23, 24)],
        43: [(68, 73)],
    },
    "cehennem": {
        104: [(4, 9)],
        56: [(41, 56)],
        14: [(16, 17)],
        4: [(56, 56)],
        67: [(6, 11)],
        78: [(21, 30)],
    },
    "hesap": {
        99: [(6, 8)],     # "Zerre kadar hayır işleyen onu görür"
        21: [(47, 47)],   # Adalet terazileri
        17: [(13, 14)],
        18: [(49, 49)],
        36: [(65, 65)],
        45: [(28, 29)],
        69: [(18, 29)],
    },

    # --- YARATILIŞ VE KÂİNAT ---
    "yaratilis": {
        2: [(30, 39)],    # Âdem'in yaratılışı
        23: [(12, 16)],   # İnsanın aşamaları
        32: [(7, 9)],
        15: [(26, 29)],
        96: [(1, 5)],
        71: [(13, 14)],
    },
    "tabiat": {
        2: [(164, 164)],  # "Göklerin ve yerin yaratılışında..."
        30: [(20, 25)],   # Âyetler dizisi
        3: [(190, 191)],
        16: [(10, 18)],
        88: [(17, 20)],
        21: [(30, 33)],
        55: [(1, 13)],
    },
    "rizik": {
        65: [(2, 3)],
        29: [(60, 62)],
        51: [(22, 23)],
        11: [(6, 6)],
        17: [(30, 31)],
        42: [(27, 27)],
    },
    "ilim": {
        96: [(1, 5)],     # İlk vahiy: "Oku"
        20: [(114, 114)],
        39: [(9, 9)],
        58: [(11, 11)],
        35: [(28, 28)],
        17: [(36, 36)],
        18: [(60, 82)],   # Mûsâ ve Hızır: bilginin sınırı
    },

    # --- DURUMLAR ---
    "zorluk": {
        94: [(1, 8)],     # "Zorlukla beraber bir kolaylık vardır"
        2: [(214, 214), (286, 286)],  # "Gücünün üstünde yük yüklemez"
        65: [(7, 7)],
        3: [(139, 140)],
    },
    "uzuntu": {
        9: [(40, 40)],    # "Üzülme, Allah bizimle"
        3: [(139, 139)],
        16: [(127, 128)],
        12: [(86, 87)],   # Yakûb'un hüznü
        15: [(97, 99)],
    },
    "korku": {
        2: [(155, 157)],
        3: [(173, 175)],
        41: [(30, 31)],
        10: [(62, 64)],
        20: [(46, 46)],
    },
    "yalnizlik": {
        50: [(16, 16)],   # "Şah damarından daha yakınız"
        2: [(186, 186)],
        9: [(40, 40)],
        93: [(1, 11)],    # Duhâ: terk edilmediğin
        20: [(46, 46)],
    },
    "hastalik": {
        26: [(78, 82)],   # "Hastalandığımda bana O şifa verir"
        17: [(82, 82)],
        21: [(83, 84)],   # Eyyûb
        10: [(57, 57)],
        2: [(184, 185)],
    },
    "pismanlik": {
        39: [(53, 56)],
        4: [(110, 110)],
        7: [(23, 23)],    # Âdem'in tövbesi
        12: [(97, 98)],
        66: [(8, 8)],
    },
    "haksizlik": {
        4: [(148, 149)],
        42: [(39, 43)],
        16: [(126, 127)],
        14: [(42, 43)],
        22: [(39, 40)],
    },
    "gurbet": {
        4: [(97, 100)],   # Hicret: yeryüzü geniştir
        29: [(56, 57)],
        2: [(115, 115)],  # "Nereye dönerseniz O'nun yüzü oradadır"
        9: [(40, 40)],
    },
    "basarisizlik": {
        2: [(216, 216)],  # "Hoşlanmadığınız şey sizin için hayırlı olabilir"
        94: [(5, 6)],
        3: [(139, 140)],
        12: [(87, 87)],
    },
    "yasli": {
        17: [(23, 24)],
        30: [(54, 54)],
        36: [(68, 68)],
        16: [(70, 70)],
        19: [(2, 6)],     # Zekeriyyâ'nın yaşlılıkta duası
    },
    "karar": {
        42: [(38, 38)],   # Danışma
        3: [(159, 159)],  # "Karar verince Allah'a güven"
        2: [(216, 216)],
        18: [(23, 24)],
        8: [(29, 29)],
    },
    "hicret": {
        9: [(40, 40)],
        8: [(72, 75)],
        16: [(41, 42)],
        4: [(97, 100)],
        59: [(8, 9)],
    },
    "seytan": {
        7: [(11, 27)],    # Düşmanlığın başlangıcı
        2: [(168, 169)],
        14: [(22, 22)],   # Şeytanın hesap günündeki savunması
        35: [(5, 6)],
        114: [(1, 6)],
        17: [(61, 65)],
    },
}

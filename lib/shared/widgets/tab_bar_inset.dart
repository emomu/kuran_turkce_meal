import 'package:flutter/material.dart';

/// Sekmeli bir ekranın kaydırılabilir içeriğinin altına bırakması gereken
/// boşluk.
///
/// Çubuk `bottomNavigationBar` yuvasındadır ve `Scaffold` gövdeyi zaten
/// çubuğun üstünde bitirir; çubuk yüksekliğinin burada ikinci kez eklenmesi
/// altta ölü alan bırakırdı. Geriye yalnızca güvenli alan kalır.
///
/// Kabuk dışında (tek başına çizilen bir ekranda ya da testte) `Scaffold`
/// bulunmayabilir; o zaman ekranın kendi güvenli alanı okunur.
double bottomInsetFor(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

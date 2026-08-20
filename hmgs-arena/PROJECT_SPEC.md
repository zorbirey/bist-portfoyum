# HMGS ARENA — Proje Gereksinimleri

## Ürün yönü

HMGS ARENA, hukuk mezunlarının Hukuk Mesleklerine Giriş Sınavı'na oyunlaştırılmış ama ciddi bir sınav çalışma deneyimiyle hazırlanmasını amaçlar.

Motto:

- **PER ASPERA AD ASTRA**
- **Zorluklardan yıldızlara**

## Soru bankası

- Uzun vadeli hedef: **5.000 doğrulanmış özgün soru**.
- ÖSYM soruları kopyalanmayacak; özgün sorular mevzuat ve resmi kaynaklara dayalı üretilecek.
- Her soruda benzersiz ID, ders, konu, zorluk, açıklama ve kaynak alanı bulunacak.
- Zorluk seviyeleri: **Çok Kolay, Kolay, Orta, Zor, Çok Zor**.
- Dengeli rastgele seçimde her zorluk seviyesinden eşit sayıda soru seçilecek.
- Normal çalışmada yakın zamanda görülen sorular mümkün olduğunca tekrar gösterilmeyecek.
- Kullanıcı yanlış yaptığında aynı soru hemen tekrar sorulmayacak; aynı ders/konudan farklı bir soru ile pekiştirme yapılacak.

## Zayıf konular ve bilgi kartları

- Kullanıcının ders + konu bazındaki doğru/yanlış istatistikleri tutulacak.
- Yeterli örneklem oluştuğunda başarı oranı düşük başlıklar **Zayıf Konular** altında gösterilecek.
- Bilgi kartları yanlış sorunun bire bir tekrarı yerine konu özeti, temel kaynaklar ve aynı konudan yeni sorularla çalışmayı destekleyecek.

## Çalışma ve Arena modu

- Çalışma modu: sınırsız veya düşük reklam yoğunluklu soru çözümü.
- Arena modu: can, XP, seri, rozet ve sıralama gibi oyunlaştırma mekanikleri.
- Kullanıcının temel öğrenme açıklamaları reklam arkasına kilitlenmeyecek.

## HMGS tam deneme

- **120 soru**.
- **5 seçenek: A, B, C, D, E**.
- **155 dakika toplam süre**.
- Ortalama hedef süre: **77,5 saniye / soru**.
- Soru hedef süresi ekranın sağ üst köşesinde gösterilecek.
- Kullanıcı soruyu işaretlememişse hedef sürenin son 10 saniyesinde ekran kırmızı yanıp sönecek.
- 60. soruya ulaşıldığında 77 dakika 30 saniye aşılmışsa zaman uyarısı gösterilecek.
- Toplam süre dolduğu anda sınav otomatik bitecek.
- Sınav sırasında reklam gösterilmeyecek; sınav bittikten sonra doğal geçiş noktasında tek tam ekran reklam gösterilecek ve sonra sonuç ekranı açılacak.
- Sonuçlarda en az doğru, yanlış, boş, başarı oranı ve kullanılan süre gösterilecek.

## Reklam yaklaşımı

- Geliştirme sırasında yalnız Google test reklam birimleri kullanılacak.
- Tam deneme sırasında reklam yok.
- Tam deneme bitişinde en fazla bir interstitial geçiş reklamı.
- Ödüllü reklamlar gönüllü eylemlerde kullanılabilir: can kazanma, ekstra XP vb.
- Çalışma modunda reklam sıklığı kullanıcıyı soru akışından koparmayacak şekilde doğal geçiş noktalarında sınırlandırılacak.

## Mevcut teknik durum

Flutter tabanlı proje çekirdeği `hmgs-arena/` altında tutuluyor. Soru bankası manifest/batch yaklaşımıyla büyütülebilir. Tam deneme yalnızca doğrulanmış 5 seçenekli soru havuzu 120 soruya ulaştığında açılır.

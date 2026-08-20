# BIST TAKİP 2.0

Bu klasör, çalışan 1.1.5 sürümünü bozmadan geliştirilen yeni Flutter tabanlı ticari sürümün geliştirme alanıdır.

## Ürün yönü

BIST TAKİP 2.0; fiyat ekranı olmaktan çok portföy, gerçek getiri, temettü geliri ve hedef takibi odaklı bir yatırım takip uygulaması olarak tasarlanır.

## Tamamlanan çekirdekler

- Flutter ile Android + iOS ortak kod tabanı
- İşlem bazlı kayıt modeli: alış, satış, komisyon, temettü
- Ağırlıklı ortalama maliyet ve gerçekleşmiş kâr hesap motoru
- İşlem ekleme ekranı
- İşlem geçmişi ve kayıt silme
- SharedPreferences tabanlı kalıcı yerel kayıt
- 1.1.5 JSON yedek seçme, önizleme ve açılış bakiyesine dönüştürme
- Mevcut 2.0 verisinin üzerine yazmadan önce onay
- Mevcut `prices.json` beslemesini soyut MarketFeed katmanı üzerinden okuma
- Portföy kartlarında 1.1.5 bilgileri + kâr/zarara göre renklenen güncel fiyat kutusu
- Portföy değeri, günlük değişim ve toplam kâr/zarar için temel hesaplar

## Sonraki hedefler

1. Günlük portföy snapshot sistemi
2. BIST 100 benchmark karşılaştırması
3. Dağılım ekranı: maliyet / güncel değer / sektör
4. Gelişmiş Temettü Merkezi ve Temettü Maaşım
5. Hedef düzenleme ve ilerleme hesapları
6. Bildirim altyapısı
7. Bulut hesap/senkronizasyon ve biyometri
8. Ticari veri sağlayıcısına geçiş
9. Android/iOS test derleme akışı

## Veri geçiş notu

1.1.5 sürümü eski alış/satış işlemlerinin tarihsel detayını saklamadığı için mevcut adet ve ortalama maliyet, 2.0'a tek bir “açılış bakiyesi” alış işlemi olarak aktarılır. Bu tarihten sonraki tüm hareketler 2.0 işlem defterinde ayrı ayrı tutulur.

## Mimari not

Şimdilik piyasa verisi mevcut GitHub `prices.json` akışından okunur. Ekranlar doğrudan bu kaynağa bağlı değildir; `MarketFeed` arayüzü kullanılır. Ticari lisanslı veri kaynağına geçişte yalnızca veri katmanının değiştirilmesi hedeflenir.

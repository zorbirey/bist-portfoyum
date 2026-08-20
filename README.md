# BIST Portföy

Kişisel BIST portföy ve net temettü takip uygulaması.

## BIST TAKİP 2.1

BIST TAKİP 2.1 geliştirme çalışması tamamlandı ve bu sürüm özellik geliştirmesine kapatıldı.

- Sürüm: `2.1.0+11`
- Geliştirme dalı: `bist-takip-2.1`
- Son ürün odağı: portföy, dağılım, temettü, hedef, geçmiş ve ayarlar
- Hedef ekranı: 1.1.5 hedef mantığı, yıllık/aylık hedef, hedef kademeleri, tek hisse/eşit dağılım planı
- Android CI: statik analiz, test, split release APK ve Google Play AAB üretimi

## Yayın notu

GitHub Actions başarılı tamamlandığında iki artifact üretilir:

- `BIST-TAKIP-2.1-RELEASE-APK`: cihaz mimarisine göre küçük release APK dosyaları
- `BIST-TAKIP-2.1-PLAY-AAB`: Google Play yüklemesi için Android App Bundle

Ticari yayında BIST piyasa verileri için lisanslı veri sağlayıcısı kullanılmalıdır.

## Arşiv

2.1 son sürüm noktası ayrıca `release/bist-takip-2.1.0` dalında saklanır. Yeni özellik geliştirmeleri bu sürüme eklenmemelidir.

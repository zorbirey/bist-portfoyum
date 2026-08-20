# BIST TAKİP 2.0

Bu klasör, çalışan 1.1.5 sürümünü bozmadan geliştirilen yeni Flutter tabanlı ticari sürümün başlangıç noktasıdır.

## Ürün yönü

BIST TAKİP 2.0; fiyat ekranı olmaktan çok portföy, gerçek getiri, temettü geliri ve hedef takibi odaklı bir yatırım takip uygulaması olarak tasarlanır.

## İlk mimari kararlar

- Flutter ile Android + iOS ortak kod tabanı
- İşlem bazlı kayıt: alış, satış, komisyon, temettü
- Ortalama maliyet ve gerçekleşmiş kâr işlem defterinden hesaplanır
- 1.1.5 JSON yedekleri açılış bakiyesi olarak içe aktarılabilir
- Eski sürüm `main` dalında korunur; 2.0 geliştirmesi `bist-takip-2.0` dalındadır
- Ticari sürümde veri kaynağı, kullanıcı hesabı, bulut senkronizasyonu, bildirim ve biyometri ayrı altyapı katmanları olarak eklenecektir

## İlk hedefler

1. İşlem ekleme/düzenleme/silme ekranı
2. İşlem defterinden portföy hesaplama
3. Günlük portföy snapshot sistemi
4. BIST 100 benchmark karşılaştırması
5. Temettü Merkezi ve Temettü Maaşım
6. 1.1.5 yedek içe aktarma ekranı

## Çalıştırma

Bu klasör Flutter kaynak iskeletidir. Platform dosyaları eklendiğinde standart Flutter akışıyla çalışacaktır:

```bash
flutter pub get
flutter run
```

## Veri geçiş notu

1.1.5 sürümü eski alış/satış işlemlerinin tarihsel detayını saklamadığı için, mevcut adet ve ortalama maliyet 2.0'a tek bir “açılış bakiyesi” alış işlemi olarak aktarılır. Bu tarihten sonraki tüm hareketler 2.0 işlem defterinde ayrı ayrı tutulur.

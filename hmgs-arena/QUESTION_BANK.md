# HMGS ARENA Soru Bankası Standardı

## Hedef

- Nihai hedef: en az 5.000 özgün ve kaynaklı soru
- Aynı soru ID'si bir kez kullanılabilir
- Her soruda 4 seçenek, tek doğru cevap, açıklama ve kaynak/madde zorunludur
- ÖSYM soruları kopyalanmaz; sorular mevzuat ve güvenilir hukuk kaynakları esas alınarak özgün yazılır

## Zorluk seviyeleri

1. `cok_kolay` — Çok Kolay
   - Doğrudan kanun kuralını, temel tanımı veya sayısal eşiği ölçer.
   - Tek adımlı bilgi hatırlama.

2. `kolay` — Kolay
   - Temel kuralı basit bir uygulama veya doğru eşleştirme içinde ölçer.
   - Güçlü çeldirici kullanılabilir ancak istisna bilgisi beklenmez.

3. `orta` — Orta
   - İki yakın kavramın ayrımı, temel istisna veya kısa uygulama sorusu.
   - Adayın kuralı ezberden öte yorumlaması gerekir.

4. `zor` — Zor
   - Kısa vaka, süre/şart karşılaştırması veya birden fazla unsurun birlikte değerlendirilmesi.
   - Çeldiriciler aynı hukuk alanındaki yakın kavramlardan seçilir.

5. `cok_zor` — Çok Zor
   - Çok aşamalı vaka, istisna + kural birlikte değerlendirme veya birden fazla hukuki unsurun ayrıştırılması.
   - Soru kökü gereksiz uzun olmaz; güçlük bilgi yoğunluğu ve muhakemeden gelir.

## Rastgele test kuralı

Rastgele testte beş zorluk seviyesi eşit temsil edilir. Bu nedenle rastgele test soru sayıları 5'in katı olmalıdır.

Örnek:

- 10 soru: her seviyeden 2
- 20 soru: her seviyeden 4
- 30 soru: her seviyeden 6
- 50 soru: her seviyeden 10

`QuestionSetBuilder` bu kuralı kod seviyesinde zorunlu tutar.

## Tekrar ve öğrenme kuralı

- Öncelik hiç görülmemiş sorudadır.
- Son 150 soru yakın tekrar penceresinde tutulur.
- Yanlış cevaplanan sorunun aynısı tekrar sorulmaz.
- Bunun yerine aynı `subject + topic` alanından farklı bir soru seçilir.
- En az 5 denemede başarı oranı %70'in altına düşen konu `Zayıf Konuların` bölümünde gösterilir.

## Soru JSON şeması

```json
{
  "id": "medeni-001",
  "subject": "Medeni Hukuk",
  "topic": "Erginlik",
  "difficulty": "cok_kolay",
  "question": "...",
  "options": ["A", "B", "C", "D"],
  "correctIndex": 0,
  "explanation": "...",
  "sourceLabel": "Türk Medeni Kanunu",
  "sourceRef": "m.11"
}
```

## Parti sistemi

Soru bankası tek dev dosya yerine manifest üzerinden yüklenir. Yeni partiler oluşturuldukça `assets/question_manifest.json` içindeki `files` listesine eklenir. Bu sayede 5.000+ soru uygulama kodunu değiştirmeden büyütülebilir.

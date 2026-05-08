# Picme

Picme, galerindeki fotoğraf ve videoları hızlıca temizlemek için tasarlanmış bir swipe uygulamasıdır.  
Amaç basit: tek tek karar ver, gereksizleri kuyruğa al, sonra toplu sil.

## Ne İşe Yarar?

Telefon galerisi zamanla gereksiz ekran görüntüleri, tekrar eden videolar ve "sonra bakarım" diye biriken içeriklerle doluyor.  
Picme bu kalabalığı hızlıca azaltman için pratik bir akış sunar:

- sola kaydır: silme kuyruğuna ekle
- sağa kaydır: tut
- tek dokun: tam ekran önizle
- kararını geri almak istersen: revert ile son hamleyi geri al

## Kullanım Akışı

1. Uygulamayı aç ve bir kategori seç (`All Media`, `Photos`, `Videos`, `Screenshots`, `Downloads`).
2. Kartları tek tek kaydırarak karar ver:
   - **Sola**: silinecekler listesine gider
   - **Sağa**: tutulur
3. Gerekirse sağ üstteki **revert** butonuyla son hamleleri adım adım geri al.
4. Sağ alttaki kuyruk butonundan silme kuyruğunu aç.
5. Kuyruktaki içerikleri kontrol et, istersen tek tek çıkar.
6. Eminsen toplu şekilde kalıcı silme işlemini yap.

## Öne Çıkan Deneyim

- Tek elle, hızlı kullanım
- Akıcı kart geçişleri
- Karar odaklı sade arayüz
- Toplu silmeden önce güvenli kontrol (queue yaklaşımı)
- Uygulamayı kapatınca kuyruğun korunması

## Revert Mantığı

Revert butonu son hamleleri sıra ile geri alır:

- sola atılan içerik geri gelirse soldan içeri kayar
- sağa atılan içerik geri gelirse sağdan içeri kayar

Böylece yaptığın hamlenin tersini görsel olarak net şekilde hissedersin.

## Kimler İçin?

- Galerisini düzenli tutmak isteyenler
- Depolama alanını boşaltmak isteyenler
- Uzun uzun klasör gezmeden hızlı karar vermek isteyenler

---

Picme, gereksiz karmaşa olmadan galerini kontrol altına alman için tasarlandı.

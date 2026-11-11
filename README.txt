# N'fess Bahçe – Güncelleme Paketi

Bu paket, mevcut Supabase bağlantılı uygulamanın üzerine yüklenmek üzere hazırlanmıştır.

## Bu sürümde
- Rezervasyon formunda aktif paket seçimi
- Paket seçildiğinde liste fiyatının önerilmesi
- Özel/indirimli fiyatın elle değiştirilebilmesi
- Fiyat alanı boş bırakılırsa seçilen paketin güncel fiyatının kaydedilmesi
- Rezervasyon listesi ve CSV raporunda paket adının gösterilmesi
- Admin hesabıyla giriş yapıldığında görünen Ekip Yönetimi bölümü
- Personel hesaplarını onaylama / reddetme / erişimi kapatma
- Onaylı personele ayrıca müşteri ekleme izni verme veya kaldırma
- Mevcut Supabase Auth giriş ve kayıt ekranının korunması

## Kurulum – iki işlem

### 1. Supabase SQL güncellemesi
Supabase Dashboard → SQL Editor → New query bölümünde
`supabase/team_and_auth_update.sql` dosyasının tamamını çalıştırın.

Bu SQL:
- Yeni kayıt olan hesapları `staff / pending` olarak oluşturur.
- Mevcut admin profilini değiştirmez.
- Adminin ekip listesini okuyabilmesini sağlar.
- Personel onayını güvenli RPC fonksiyonlarıyla yapar.
- Müşteri ekleme iznini ayrıca admin kontrolüne bağlar.

**Önemli:** Bu dosya mevcut tabloları silmez ve rezervasyon/müşteri/ödeme kayıtlarına dokunmaz.

### 2. GitHub dosyalarını güncelleme
ZIP içindeki `index.html`, `app.js` ve `style.css` dosyalarını GitHub deposunun ana dizinindeki aynı adlı dosyaların üzerine yükleyin. `supabase` klasörünü de depoya ekleyin. Commit edin ve GitHub Pages'in yayınlanmasını bekleyin.

## Kullanım
1. Yönetici Supabase Auth e-posta ve şifresiyle giriş yapar. Kullanıcı ID'si Supabase oturumundan otomatik doğrulanır; ID'yi ayrıca yazmak gerekmez.
2. Personel giriş ekranındaki “Personel kaydı oluştur” bağlantısından ad, e-posta ve şifreyle kayıt olur.
3. Personel kaydı `pending` durumunda kalır. Admin Ekip Yönetimi bölümünden onaylar veya reddeder.
4. Onaylı personelin müşteri eklemesine izin vermek isterseniz aynı bölümdeki müşteri ekleme izni düğmesini açın.
5. Rezervasyon oluştururken paket seçin. Paket seçimi liste fiyatını alana öneri olarak getirir; özel fiyat için bu tutarı değiştirebilirsiniz. Alanı boş bırakırsanız seçilen paketin o anki fiyatı kaydedilir.

## Güvenlik notu
Tarayıcıda yalnızca Supabase publishable key bulunur. `service_role` / secret key kesinlikle eklenmemelidir. Veritabanı güvenliği RLS ve SQL'deki güvenli fonksiyonlarla uygulanır.

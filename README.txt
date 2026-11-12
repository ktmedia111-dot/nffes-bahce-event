# N'fess Bahçe Event — Rezervasyon Yönetimi

Uygulama GitHub Pages arayüzünü, Supabase Auth girişini ve Supabase veritabanını kullanır. `main` dalındaki kod tek başına yeterli değildir; Supabase tabloları, RLS izinleri ve ilk yönetici hesabı da hazırlanmalıdır.

## Tek seferlik kurulum

### 1. Supabase veritabanını hazırla

Supabase Dashboard → SQL Editor → New query bölümünde `supabase/setup.sql` dosyasının tamamını çalıştırın. Bu script tabloları/eksik sütunları oluşturur, kayıtları korur ve uygulamanın rol bazlı RLS politikalarını kurar.

Script, altı uygulama tablosundaki eski RLS politikalarını kendi güvenli rol kurallarıyla değiştirir. Rezervasyon, müşteri, paket, ödeme veya gider satırlarını silmez.

### 2. İlk yönetici hesabını aç

GitHub Pages adresinde **Personel kaydı oluştur** ile kendi hesabınızı oluşturup e-posta doğrulamasını tamamlayın. İlk kullanıcı güvenlik nedeniyle otomatik yönetici yapılmaz. Supabase SQL Editor'de aşağıdaki sorguda e-posta adresini kendi hesabınızla değiştirip çalıştırın:

```sql
update public.profiles p
set role = 'admin', approval_status = 'approved', can_add_customers = true
from auth.users u
where p.id = u.id and lower(u.email) = lower('yonetici@example.com');
```

Bu sorgunun tek satır güncellediğini kontrol edin. Sonra uygulamadan çıkıp tekrar giriş yapın. Zaten `admin / approved` hesabınız varsa bu adımı atlayın.

### 3. GitHub Pages'i aç

GitHub deposunda Settings → Pages bölümünde yayın kaynağını `Deploy from a branch`, dalı `main`, klasörü `/(root)` olarak seçin. Sayfa yayınlandıktan sonra `https://ktmedia111-dot.github.io/nffes-bahce-event/` adresini açın.

## Kullanım

- Yönetici giriş yaptıktan sonra Paketler & Fiyatlar bölümünden paket ekleyebilir.
- Yeni rezervasyonda mevcut müşteri önerilerinden seçim yapabilir veya aynı **Müşteri adı** alanına yeni isim yazabilir. Ad, telefon ve rezervasyon kaydı birlikte saklanır.
- Personel onay bekler. Yönetici Ekip Yönetimi'nden personeli onaylayabilir; müşteri kartı ekleme iznini ayrıca verebilir. Bu izin yoksa personel yine rezervasyon oluşturabilir; müşteri adı ve telefon rezervasyon üzerinde saklanır.
- Rezervasyon formunda paket seçildiğinde fiyat boşsa paket fiyatı önerilir. Fiyatı elle değiştirebilirsiniz.
- Ödeme ve gider ekranı yalnızca yöneticiye açıktır. Finans kayıtlarını ekip üyeleri okuyamaz veya değiştiremez.

## Güvenlik ve sorun giderme

- Tarayıcıda yalnızca Supabase publishable key bulunur. `service_role` veya secret key eklemeyin.
- Girişten sonra “Profil okunamadı” görülürse `supabase/setup.sql` tamamlanmamış olabilir. Supabase SQL Editor'deki hata mesajını kontrol edin.
- İlk yönetici oluşturulmadıysa yeni hesap “Yönetici onayı bekleniyor” ekranında kalır. Yukarıdaki yönetici sorgusunu bir kez çalıştırın.
- Rezervasyon, paket, ödeme veya gider kaydında sütun hatası görülürse `supabase/setup.sql` dosyasını yeniden çalıştırın; script mevcut uygulama verilerini silmez.
- E-posta doğrulama ile parola politikaları Supabase Authentication → Providers / Email ayarlarından yönetilir.

## Veritabanı dosyaları

- `supabase/setup.sql`: Önerilen tek kurulum/güncelleme scripti; şema ve ekip/RLS güncellemesini birlikte içerir.
- `supabase/schema.sql`: Sadece uygulama tabloları ve sütunları.
- `supabase/team_and_auth_update.sql`: Ekip yönetimi, ilk giriş profili ve RLS kuralları. `setup.sql` zaten bu bölümü içerir; aynı kurulumda iki kez çalıştırmayın.
- `supabase/team_management_update.sql`: Eski uyumluluk dosyası; yeni kurulumda `setup.sql` kullanın.

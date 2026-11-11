# NFFES Bahçe Event – Rezervasyon Kayıt Sistemi

## Hızlı başlangıç
1. ZIP'i bilgisayarınıza çıkarın.
2. `index.html` dosyasını açın. Kurulum gerektirmez.
3. GitHub'da yeni bir repository oluşturun.
4. ZIP'ten çıkan dosyaları repository'nin ana dizinine yükleyin.
5. GitHub → Settings → Pages → Deploy from a branch → `main` ve `/ (root)` seçin.
6. Kaydedin. GitHub Pages adresiniz birkaç dakika içinde oluşur.

## Dahil olan özellikler
- Yönetim paneli ve özet göstergeler
- Rezervasyon ekleme, düzenleme, silme ve arama
- Aynı tarihte çakışan rezervasyon için uyarı
- Aylık etkinlik takvimi
- Müşteri kayıtları
- Paket ve fiyat tanımlama
- Anlaşma tutarı, kapora ve kalan bakiye takibi
- Gider kayıtları ve finans özeti
- Etkinlik türü raporları ve CSV dışa aktarma
- JSON yedek indirme / yedekten geri yükleme
- Mobil uyumlu arayüz

## Önemli: Ücretsiz sürümün veri saklama şekli
Bu ilk paket, verileri tarayıcının yerel hafızasında (localStorage) tutar. Aynı bilgisayar ve aynı tarayıcıda çalışır. Tarayıcı verileri silinirse kayıtlar kaybolabilir; bu nedenle Ayarlar bölümünden düzenli JSON yedeği alın.

GitHub Pages yalnızca statik dosya barındırır. Birden fazla personelin farklı telefon ve bilgisayarlardan aynı canlı veriyi görmesi için ortak bir veritabanı gerekir. Bunun için ücretsiz Supabase kullanılabilir. Supabase projesi açılması, veritabanı tablolarının kurulması ve proje anahtarlarının eklenmesi gerekir. Bu ZIP, Supabase için başlangıç SQL dosyasını içerir; canlı ortak veritabanı bağlantısı bu ilk sürümde etkin değildir.

## Supabase başlangıç şeması
`supabase/schema.sql` dosyasını Supabase Dashboard → SQL Editor alanında çalıştırabilirsiniz. Bu yalnızca veritabanı tablolarını hazırlar; uygulamaya ortak kullanıcı girişi ve senkronizasyon eklemek için ayrıca bağlantı yapılandırması gerekir.

## Güvenlik notu
Bu sürümde yönetici/personel oturum açma sistemi yoktur. Hassas müşteri verilerini herkese açık bir GitHub Pages sayfasında tutmayın. Çok kullanıcılı kullanıma geçmeden önce Supabase Auth ve Row Level Security politikaları kurulmalıdır.

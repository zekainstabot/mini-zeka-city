extends RefCounted
class_name LanguageManager

const LANGUAGES = ["fa", "en", "tr"]

const TEXTS = {
	"توسعه": {"en":"Development","tr":"Gelişim"},
	"دستاوردها": {"en":"Achievements","tr":"Başarılar"},
	"شهر من": {"en":"My City","tr":"Şehrim"},
	"بازار و انبار": {"en":"Market & Storage","tr":"Pazar ve Depo"},
	"بانک": {"en":"Bank","tr":"Banka"},
	"⚙️ تنظیمات بازی": {"en":"⚙️ Game Settings","tr":"⚙️ Oyun Ayarları"},
	"🏙️ تغییر نام شهر": {"en":"🏙️ Rename City","tr":"🏙️ Şehri Yeniden Adlandır"},
	"زبان بازی": {"en":"Game Language","tr":"Oyun Dili"},
	"فارسی": {"en":"Persian","tr":"Farsça"},
	"فارسی ✓": {"en":"Persian ✓","tr":"Farsça ✓"},
	"انگلیسی": {"en":"English","tr":"İngilizce"},
	"انگلیسی ✓": {"en":"English ✓","tr":"İngilizce ✓"},
	"ترکی": {"en":"Turkish","tr":"Türkçe"},
	"ترکی ✓": {"en":"Turkish ✓","tr":"Türkçe ✓"},
	"زبان به‌روزرسانی شد.": {"en":"Language updated.","tr":"Dil güncellendi."},
	"در حالت خودکار، بازی با چرخش گوشی هماهنگ می‌شود؛ حتی وقتی گوشی را ۱۸۰ درجه می‌چرخانی. دو حالت دیگر جهت صفحه را ثابت نگه می‌دارند.": {"en":"In Auto mode, the game follows your phone's rotation, including a 180° turn. The other modes lock the screen orientation.","tr":"Otomatik modda oyun, telefonunuzu 180° döndürseniz bile ekran yönünü takip eder. Diğer modlar ekran yönünü sabitler."},
	"🔄 خودکار": {"en":"🔄 Auto","tr":"🔄 Otomatik"},
	"📱 افقی": {"en":"📱 Landscape","tr":"📱 Yatay"},
	"📱 عمودی": {"en":"📱 Portrait","tr":"📱 Dikey"},
	"🏗️ توسعه شهر": {"en":"🏗️ City Development","tr":"🏗️ Şehir Gelişimi"},
	"تمام ابزارهای ساخت، گسترش و مدیریت زیرساخت‌های شهر در این بخش قرار دارند.": {"en":"All tools for construction, expansion, and city infrastructure management are here.","tr":"İnşaat, genişleme ve şehir altyapısı yönetimi için tüm araçlar burada."},
	"🏗️ ساختمان‌ها و ساخت‌وساز": {"en":"🏗️ Buildings & Construction","tr":"🏗️ Binalar ve İnşaat"},
	"🛣️ توسعه شهر و حمل‌ونقل": {"en":"🛣️ City Expansion & Transport","tr":"🛣️ Şehir Genişlemesi ve Ulaşım"},
	"دسترسی‌های مدیریت شهر": {"en":"City Management","tr":"Şehir Yönetimi"},
	"🏛️ شهرداری و خدمات شهری": {"en":"🏛️ Municipality & City Services","tr":"🏛️ Belediye ve Şehir Hizmetleri"},
	"🏢 اقتصاد خصوصی و کسب‌وکارها": {"en":"🏢 Private Economy & Businesses","tr":"🏢 Özel Ekonomi ve İşletmeler"},
	"📋 گزارش‌ها و مشکلات شهر": {"en":"📋 City Reports & Issues","tr":"📋 Şehir Raporları ve Sorunlar"},
	"📦 مدیریت انبار و تولید": {"en":"📦 Storage & Production","tr":"📦 Depo ve Üretim"},
	"🚚 واردات و صادرات": {"en":"🚚 Imports & Exports","tr":"🚚 İthalat ve İhracat"},
	"❔ راهنمای کامل مینی زکا سیتی": {"en":"❔ Mini Zeka City Guide","tr":"❔ Mini Zeka City Rehberi"},
	"اینجا هر زمان گیر کردی برگرد؛ از شروع بازی تا اقتصاد، ساختمان‌ها و رقابت شهرها را قدم‌به‌قدم توضیح داده‌ایم.": {"en":"Come back whenever you need help. This guide explains the game step by step, from getting started to the economy, buildings, and city competition.","tr":"Yardıma ihtiyaç duyduğunda buraya dön. Bu rehber başlangıçtan ekonomiye, binalardan şehir rekabetine kadar her şeyi adım adım açıklar."},
	"🏙️ برگشت به شهر من": {"en":"🏙️ Back to My City","tr":"🏙️ Şehrime Dön"},
	"🚀 شروع سریع برای بازیکن تازه‌وارد": {"en":"🚀 Quick Start for New Players","tr":"🚀 Yeni Oyuncular İçin Hızlı Başlangıç"},
	"شروع ماجراجویی در شهر": {"en":"Start Your City Adventure","tr":"Şehir Macerana Başla"},
	"به شهر خودت خوش اومدی! برای شروع، مأموریت‌ها رو ببین و اولین زمینت رو بخر.": {"en":"Welcome to your city! To get started, check your missions and buy your first plot of land.","tr":"Şehrine hoş geldin! Başlamak için görevlerine göz at ve ilk arsasını satın al."},
	"رفتن به مأموریت‌ها  ←": {"en":"Go to Missions  →","tr":"Görevlere Git  →"},
	"وضعیت کلی شهر": {"en":"City Overview","tr":"Şehir Genel Durumu"},
	"جمعیت": {"en":"Population","tr":"Nüfus"},
	"شاغل": {"en":"Employed","tr":"Çalışan"},
	"بیکار": {"en":"Unemployed","tr":"İşsiz"},
	"شروع دوباره شهر": {"en":"Restart City","tr":"Şehri Yeniden Başlat"},
	"تمام پیشرفت فعلی این شهر پاک می‌شود.": {"en":"All current progress in this city will be erased.","tr":"Bu şehirdeki tüm mevcut ilerleme silinecek."},
	"بله، شروع دوباره": {"en":"Yes, Restart","tr":"Evet, Yeniden Başlat"},
	"خیر، انصراف": {"en":"No, Cancel","tr":"Hayır, Vazgeç"},
	"بستن منو": {"en":"Close Menu","tr":"Menüyü Kapat"},
	"راهنمای کامل بازی": {"en":"Full Game Guide","tr":"Tam Oyun Rehberi"},
	"باز کردن منوی بازی": {"en":"Open Game Menu","tr":"Oyun Menüsünü Aç"},
	"برای ساخت این ساختمان جمعیت کافی نیست.": {"en":"There are not enough residents to build this building.","tr":"Bu binayı inşa etmek için yeterli nüfus yok."},
	"ساخت‌وساز تکمیل شد.": {"en":"Construction completed.","tr":"İnşaat tamamlandı."},
	"یک روز جدید در شهر آغاز شد.": {"en":"A new day has begun in the city.","tr":"Şehirde yeni bir gün başladı."}
}

static func translate(source: String, language: String = "fa") -> String:
	if language == "fa" or not TEXTS.has(source):
		return source
	var translations: Dictionary = TEXTS[source]
	return str(translations.get(language, source))

static func is_rtl(language: String) -> bool:
	return language == "fa"

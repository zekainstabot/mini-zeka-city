extends Reference
class_name MiniZekaCityEngine

const CitizenSociety = preload("res://scripts/CitizenSociety.gd")

const SAVE_PATH = "user://mini_zeka_city_save.json"
const STORAGE_RESERVE = 50
const DISTRICT_HOUSE_LIMIT = 20
const DISTRICT_OTHER_LIMIT = 20
const DISTRICT_EMERGENCY_LIMIT = 10
const DISTRICT_BUILDING_TYPE_LIMIT = 2
const DISTRICT_EMERGENCY_BUILDINGS = ["clinic","hospital","police_station","fire_station"]
const OUTSIDE_CITY_BUILDINGS = ["woodcutter","sawmill","carpenter","stone_mine","iron_mine","factory","fish_processing_plant","power_station","sewage_plant","waste_facility"]
const FORESTRY_RESERVES = {"wood": 20, "lumber": 10, "furniture": 0}

const SERVICE_GROUPS = {
	"food": {"name":"خوراک","buildings":["grocery_store","bakery","restaurant"]},
	"water": {"name":"آب‌رسانی","buildings":["water_tower"]},
	"power": {"name":"برق","buildings":["power_station"]},
	"health": {"name":"درمان","buildings":["clinic","hospital"]},
	"education": {"name":"آموزش","buildings":["school","university"]},
	"safety": {"name":"امنیت","buildings":["police_station","fire_station"]},
	"leisure": {"name":"تفریح","buildings":["small_park","playground","sports_center","cultural_center"]},
	"sanitation": {"name":"بهداشت محیط","buildings":["sewage_plant","waste_facility"]}
}
const MISSION_DEFINITIONS = [
	{"id":"buy_land_tutorial","type":"main","title":"۱. توسعه محدوده شهر","description":"یک قطعه زمین بخر تا با گسترش محدوده و ظرفیت ساخت آشنا شوی.","goal":1,"reward":300,"xp":25,"hint":"از بخش ساختمان‌ها، خرید زمین را انجام بده."},
	{"id":"build_house_tutorial","type":"main","title":"۲. تأمین فضای سکونت","description":"یک خانه کوچک دیگر بساز و ظرفیت اسکان شهر را افزایش بده.","goal":1,"reward":400,"xp":30,"hint":"ساختمان‌ها ← خانه‌ها؛ قبل از ساخت، هزینه و ظرفیت را بررسی کن."},
	{"id":"build_farm_tutorial","type":"main","title":"۳. زنجیره تأمین خوراک","description":"یک مزرعه بساز تا تولید مواد غذایی و اهمیت نیروی کار را یاد بگیری.","goal":1,"reward":500,"xp":35,"hint":"مزرعه در دسته کشاورزی است؛ برای تولید به کارگر نیاز دارد."},
	{"id":"hire_worker_tutorial","type":"main","title":"۴. نیروی انسانی","description":"حداقل دو شهروند را شاغل کن و با ارتباط نیروی کار و تولید آشنا شو.","goal":2,"reward":550,"xp":40,"hint":"در بخش شهروندان، وضعیت اشتغال و ظرفیت شغلی ساختمان‌ها را بررسی کن."},
	{"id":"population_tutorial","type":"main","title":"۵. رشد جمعیت و خدمات","description":"جمعیت را به ۸ نفر برسان؛ رشد جمعیت، نیاز به خانه و خدمات شهری را بیشتر می‌کند.","goal":8,"reward":650,"xp":45,"hint":"ظرفیت خانه‌ها و نیازهای شهروندان را هم‌زمان مدیریت کن."},
	{"id":"market_tutorial","type":"main","title":"۶. بازار و منابع","description":"بازار مواد معدنی بساز و با خریدوفروش منابع و مدیریت انبار آشنا شو.","goal":1,"reward":700,"xp":50,"hint":"بازار مواد معدنی در دسته کسب‌وکارهاست؛ قیمت خرید و فروش را مقایسه کن."},
	{"id":"transport_tutorial","type":"main","title":"۷. تجارت بین‌شهری","description":"پایانه حمل‌ونقل بساز تا مسیر تجارت و ظرفیت ارسال کالا را باز کنی.","goal":1,"reward":850,"xp":55,"hint":"پایانه حمل‌ونقل برای تجارت بین‌شهری و جابه‌جایی محموله‌ها کاربرد دارد."},
	{"id":"level_tutorial","type":"main","title":"۸. شهردار باتجربه","description":"شهر را به سطح ۳ برسان؛ با تجربه گرفتن از فعالیت‌ها، ساختمان‌های تازه آزاد می‌شوند.","goal":3,"reward":1000,"xp":70,"hint":"نوار تجربه شهر را دنبال کن و توسعه را با توان مالی هماهنگ نگه دار."},
	{"id":"main_water","type":"main","title":"۹. آب‌رسانی پایدار","description":"یک برج آب بساز و یاد بگیر خدمات پایه چگونه نیاز شهروندان را تأمین می‌کنند.","goal":1,"reward":450,"xp":35,"hint":"خدمات شهری ← برج آب؛ نیروی کار و هزینه روزانه را هم بررسی کن."},
	{"id":"main_power","type":"main","title":"۱۰. تأمین انرژی","description":"یک نیروگاه بساز تا برق شهر را تأمین کنی و با خدمات زیربنایی آشنا شوی.","goal":1,"reward":550,"xp":40,"hint":"نیروگاه در خدمات شهری است و برای فعالیت به کارگر نیاز دارد."},
	{"id":"main_storage","type":"main","title":"۱۱. مدیریت انبار","description":"یک انبار متوسط بساز تا ظرفیت ذخیره‌سازی منابع را افزایش بدهی.","goal":1,"reward":600,"xp":45,"hint":"انبارها ← انبار متوسط؛ ظرفیت و قوانین ذخیره‌سازی را بررسی کن."},
	{"id":"main_school","type":"main","title":"۱۲. آموزش شهروندان","description":"یک مدرسه بساز و ظرفیت خدمت آموزشی شهر را افزایش بده.","goal":1,"reward":650,"xp":45,"hint":"خدمات شهری ← مدرسه؛ کیفیت آموزش به پوشش خدمات بستگی دارد."},
	{"id":"main_clinic","type":"main","title":"۱۳. مراقبت سلامت","description":"یک درمانگاه بساز تا نیاز درمانی شهروندان بهتر پوشش داده شود.","goal":1,"reward":700,"xp":50,"hint":"درمانگاه را در خدمات شهری بساز و وضعیت سلامت را دنبال کن."},
	{"id":"main_wood","type":"main","title":"۱۴. آغاز تولید داخلی","description":"یک چوب‌بری بساز تا تولید چوب در شهر آغاز شود.","goal":1,"reward":700,"xp":50,"hint":"چوب‌بری بیرون محدوده شهری ساخته می‌شود و به نیروی کار نیاز دارد."},
	{"id":"main_stone","type":"main","title":"۱۵. استخراج مواد معدنی","description":"یک معدن سنگ بساز تا با استخراج منابع طبیعی آشنا شوی.","goal":1,"reward":750,"xp":55,"hint":"معدن سنگ در بخش معادن قرار دارد و نیروی کار آن را بررسی کن."},
	{"id":"main_sawmill","type":"main","title":"۱۶. فرآوری چوب","description":"یک کارخانه الوارسازی بساز تا چوب خام را به الوار تبدیل کنی.","goal":1,"reward":850,"xp":60,"hint":"برای تولید الوار به چوب ورودی نیاز داری؛ زنجیره تأمین را مدیریت کن."},
	{"id":"main_carpenter","type":"main","title":"۱۷. تولید کالای نهایی","description":"یک کارگاه مبلمان بساز تا زنجیره چوب و الوار را به محصول نهایی برسانی.","goal":1,"reward":950,"xp":65,"hint":"کارگاه مبلمان به الوار نیاز دارد؛ تولید و موجودی انبار را هماهنگ کن."},
	{"id":"main_city_bank","type":"main","title":"۱۸. مدیریت مالی شهر","description":"یک بانک شهری بساز و با خدمات مالی و مدیریت نقدینگی آشنا شو.","goal":1,"reward":1000,"xp":70,"hint":"بانک شهری در خدمات شهری است؛ پیش از ساخت هزینه‌های روزانه را بسنج."},
	{"id":"main_central_bank","type":"main","title":"۱۹. نظام بانکی پیشرفته","description":"پس از رسیدن به سطح لازم، بانک مرکزی بساز تا خدمات بانکی پیشرفته فعال شود.","goal":1,"reward":1200,"xp":80,"hint":"بانک مرکزی از سطح ۴ آزاد می‌شود؛ ابتدا سطح و خزانه را تقویت کن."},
	{"id":"main_level_five","type":"main","title":"۲۰. شهردار باتجربه","description":"شهر را به سطح ۵ برسان؛ حالا آماده مدیریت خدمات و زیرساخت‌های پیشرفته هستی.","goal":5,"reward":1500,"xp":100,"hint":"تجربه را از فعالیت‌ها و مأموریت‌ها بگیر و توسعه را با توان مالی هماهنگ کن."},
	{"id":"side_population","type":"side","title":"محله پرجمعیت","description":"جمعیت شهر را به ۱۲ نفر برسان و برای خدمات و اشتغال برنامه‌ریزی کن.","goal":12,"reward":600,"xp":45,"hint":"خانه کافی بساز و نیازهای شهروندان را زیر نظر بگیر."},
	{"id":"side_reserve","type":"side","title":"ذخیره مالی مطمئن","description":"موجودی خزانه را به ۱۵۰۰۰ سکه برسان.","goal":15000,"reward":500,"xp":40,"hint":"هزینه‌های ثابت را کنترل کن و از مالیات، تولید و تجارت درآمد بگیر."},
	{"id":"side_sewage","type":"side","title":"بهداشت فاضلاب","description":"یک تصفیه‌خانه فاضلاب بساز.","goal":1,"reward":450,"xp":30,"hint":"تصفیه‌خانه در خدمات شهری است و هزینه نگهداری دارد."},
	{"id":"side_waste","type":"side","title":"مدیریت پسماند","description":"یک مرکز پسماند بساز تا خدمات بهداشت محیط کامل‌تر شود.","goal":1,"reward":420,"xp":30,"hint":"مرکز پسماند را در دسته خدمات شهری پیدا می‌کنی."},
	{"id":"side_park","type":"side","title":"فضای سبز شهری","description":"یک پارک کوچک بساز تا نیاز تفریح شهروندان بهتر تأمین شود.","goal":1,"reward":250,"xp":20,"hint":"پارک کوچک در تفریح و فرهنگ قرار دارد."},
	{"id":"side_playground","type":"side","title":"تفریح خانواده‌ها","description":"یک زمین بازی بساز و ظرفیت تفریحی شهر را افزایش بده.","goal":1,"reward":280,"xp":20,"hint":"زمین بازی هزینه کمی دارد اما به نیروی کار نیازمند است."},
	{"id":"side_sports","type":"side","title":"ورزش همگانی","description":"یک مجموعه ورزشی بساز.","goal":1,"reward":650,"xp":45,"hint":"مجموعه ورزشی در سطح ۵ آزاد می‌شود."},
	{"id":"side_hospital","type":"side","title":"درمان پیشرفته","description":"یک بیمارستان بساز تا ظرفیت درمان شهر افزایش پیدا کند.","goal":1,"reward":900,"xp":60,"hint":"بیمارستان در سطح ۶ آزاد می‌شود."},
	{"id":"side_police","type":"side","title":"امنیت محله","description":"یک کلانتری بساز تا ظرفیت خدمات امنیتی بیشتر شود.","goal":1,"reward":650,"xp":45,"hint":"کلانتری از سطح ۵ قابل ساخت است."},
	{"id":"side_fire","type":"side","title":"آمادگی در بحران","description":"یک ایستگاه آتش‌نشانی بساز.","goal":1,"reward":650,"xp":45,"hint":"آتش‌نشانی در خدمات شهری و ساختمان‌های اضطراری قرار دارد."},
	{"id":"side_university","type":"side","title":"آموزش عالی","description":"یک دانشگاه بساز و ظرفیت آموزش عالی شهر را گسترش بده.","goal":1,"reward":1100,"xp":75,"hint":"دانشگاه در سطح ۷ آزاد می‌شود."},
	{"id":"side_cultural","type":"side","title":"هویت فرهنگی شهر","description":"یک مرکز فرهنگی بساز تا خدمات فرهنگی و تفریحی توسعه یابد.","goal":1,"reward":1000,"xp":70,"hint":"مرکز فرهنگی در سطح ۸ آزاد می‌شود."},
	{"id":"side_iron_mine","type":"side","title":"استخراج آهن","description":"یک معدن آهن بساز تا سنگ‌آهن تولید شود.","goal":1,"reward":600,"xp":40,"hint":"معدن آهن در سطح ۳ آزاد می‌شود."},
	{"id":"side_fish_lake","type":"side","title":"پرورش و صید ماهی","description":"یک دریاچه ماهیگیری بساز تا تولید ماهی افزایش یابد.","goal":1,"reward":700,"xp":45,"hint":"دریاچه ماهیگیری در سطح ۲ آزاد می‌شود."},
	{"id":"side_fishing_dock","type":"side","title":"اسکله صیادی","description":"یک اسکله صیادی بساز و ظرفیت صید ماهی را بیشتر کن.","goal":1,"reward":500,"xp":35,"hint":"اسکله صیادی در دسته کشاورزی قرار دارد."},
	{"id":"side_fish_market","type":"side","title":"بازار محصولات دریایی","description":"یک بازار ماهی بساز تا فروش ماهی در شهر فعال شود.","goal":1,"reward":450,"xp":30,"hint":"بازار ماهی در کسب‌وکارها قرار دارد."},
	{"id":"side_fish_processing","type":"side","title":"فرآوری محصولات دریایی","description":"یک کارخانه فرآوری ماهی بساز تا محصول فرآوری‌شده تولید کنی.","goal":1,"reward":800,"xp":55,"hint":"برای فرآوری به ماهی خام نیاز داری."},
	{"id":"side_grocery","type":"side","title":"دسترسی به مواد غذایی","description":"یک فروشگاه مواد غذایی بساز تا دسترسی شهروندان به خوراک بهتر شود.","goal":1,"reward":300,"xp":20,"hint":"فروشگاه مواد غذایی در کسب‌وکارها قرار دارد."},
	{"id":"side_bakery","type":"side","title":"نان تازه شهر","description":"یک نانوایی بساز تا خدمات خوراکی شهر متنوع‌تر شود.","goal":1,"reward":350,"xp":25,"hint":"نانوایی به کارگر نیاز دارد."},
	{"id":"side_restaurant","type":"side","title":"رونق رستوران‌داری","description":"یک رستوران بساز تا ظرفیت خدمات خوراکی افزایش یابد.","goal":1,"reward":550,"xp":35,"hint":"رستوران هزینه ساخت و حقوق روزانه بیشتری دارد."},
	{"id":"side_office","type":"side","title":"اشتغال اداری","description":"یک ساختمان اداری بساز و فرصت شغلی جدید ایجاد کن.","goal":1,"reward":650,"xp":45,"hint":"ساختمان اداری ظرفیت شغلی بالایی دارد."},
	{"id":"time_login_five","type":"side","title":"حضور منظم شهردار","description":"در ۵ روز تقویمی متفاوت و پشت سر هم وارد بازی شو. ورود چندباره در یک روز فقط یک‌بار حساب می‌شود.","goal":5,"reward":150,"xp":12,"hint":"هر روز وارد شهر شو؛ اگر یک روز کامل جا بیفتد، شمارش پیوستگی از نو شروع می‌شود."},
	{"id":"time_play_three","type":"side","title":"شهردار پیگیر","description":"در ۳ روزِ بازی متوالی، هر روز دست‌کم ۵ دقیقه با بازی تعامل فعال داشته باش. زمان آفلاین و رهاکردن بازی حساب نمی‌شود.","goal":3,"reward":220,"xp":18,"hint":"در طول هر روز بازی، فعالانه با منوها و بخش‌های شهر کار کن؛ با پایان روز، فعالیت ثبت می‌شود."},
	{"id":"time_login_seven","type":"side","title":"وفاداری به شهر","description":"ورود به بازی را به ۷ روز تقویمی متوالی برسان.","goal":7,"reward":250,"xp":20,"hint":"این مأموریت پس از چند روز حضور منظم تکمیل می‌شود؛ ورود تکراری در یک روز امتیاز اضافه ندارد."},
	{"id":"time_play_five","type":"side","title":"مدیریت پیوسته شهر","description":"در ۵ روزِ بازی متوالی، هر روز دست‌کم ۵ دقیقه تعامل فعال داشته باش.","goal":5,"reward":360,"xp":28,"hint":"هر روز بازی را واقعاً مدیریت کن؛ روزهایی که کمتر از ۵ دقیقه فعال باشی زنجیره را قطع می‌کنند."},
	{"id":"side_loan_paid","type":"side","title":"تسویه بدهی شهرداری","description":"یکی از وام‌های شهرداری را به‌طور کامل تسویه کن.","goal":1,"reward":180,"xp":15,"hint":"در بخش بانک، مانده وام و توان پرداخت خزانه را بررسی کن."},
	{"id":"side_export_eight","type":"side","title":"تاجر بین‌شهری","description":"در مجموع ۸ واحد کالا به شهرهای همسایه صادر کن.","goal":8,"reward":220,"xp":18,"hint":"از بخش حمل‌ونقل، تقاضا و قیمت شهرهای همسایه را مقایسه کن."},
	{"id":"side_collect_profit","type":"side","title":"برداشت سود کسب‌وکار","description":"حداقل یک بار سود یک کسب‌وکار را به خزانه منتقل کن.","goal":1,"reward":150,"xp":12,"hint":"در بخش ساختمان‌ها، سود جمع‌شده کسب‌وکار را برداشت کن."},
	{"id":"side_positive_cashflow","type":"side","title":"انضباط مالی","description":"تراز خالص خزانه را برای ۳ روز متوالی مثبت نگه دار.","goal":3,"reward":250,"xp":20,"hint":"در گزارش مالی، درآمدها را با حقوق، نگهداری و اقساط مقایسه کن."},
	{"id":"side_high_satisfaction","type":"side","title":"شهروندان راضی","description":"میانگین رضایت شهروندان را برای ۳ روز متوالی به حداقل ۷۵ برسان.","goal":3,"reward":300,"xp":22,"hint":"نیازهای خوراک، آب، برق، درمان، آموزش، امنیت، تفریح و بهداشت را متعادل نگه دار."},
	{"id":"side_expand_districts","type":"side","title":"گسترش محله‌ها","description":"ساختمان‌های شهر را به دست‌کم ۲ محله گسترش بده.","goal":2,"reward":350,"xp":25,"hint":"با پر شدن ظرفیت ساخت محله فعلی، ساختمان‌های بعدی در محله تازه قرار می‌گیرند."},
	{"id":"side_private_tax","type":"side","title":"درآمد مالیاتی پایدار","description":"از فعالیت کسب‌وکارهای خصوصی، در مجموع ۱۰۰ سکه مالیات دریافت کن.","goal":100,"reward":200,"xp":16,"hint":"درخواست‌های کسب‌وکار شهروندان را مدیریت کن تا فعالیت اقتصادی و پرداخت مالیات شکل بگیرد."},
	# Archived duplicate missions stay claimable in old saves, but are hidden for new cities.
	{"id":"side_water","type":"legacy","legacy":true,"title":"خدمات پایه شهر (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":220,"xp":20,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_school","type":"legacy","legacy":true,"title":"سرمایه‌گذاری آموزشی (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":450,"xp":35,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_clinic","type":"legacy","legacy":true,"title":"سلامت شهروندان (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":420,"xp":35,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_wood","type":"legacy","legacy":true,"title":"تولید منابع داخلی (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":300,"xp":25,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_bank","type":"legacy","legacy":true,"title":"آشنایی با بانکداری (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":550,"xp":45,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_power","type":"legacy","legacy":true,"title":"برق‌رسانی شهر (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":350,"xp":25,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_stone_mine","type":"legacy","legacy":true,"title":"استخراج سنگ (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":350,"xp":25,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_sawmill","type":"legacy","legacy":true,"title":"کارخانه الوارسازی (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":500,"xp":35,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."},
	{"id":"side_carpenter","type":"legacy","legacy":true,"title":"کارگاه مبلمان (نسخه قبلی)","description":"پاداش این مأموریت از نسخه قبلی باقی مانده است.","goal":1,"reward":700,"xp":50,"hint":"پاداش ذخیره‌شده نسخه قبلی را دریافت کن."}
]

const RESOURCES = {
	"stone": {"name": "سنگ", "buy": 18, "sell": 12},
	"iron_ore": {"name": "سنگ‌آهن", "buy": 42, "sell": 30},
	"wood": {"name": "چوب", "buy": 22, "sell": 15},
	"lumber": {"name": "الوار", "buy": 50, "sell": 36},
	"furniture": {"name": "مبلمان", "buy": 130, "sell": 95},
	"food": {"name": "مواد غذایی", "buy": 10, "sell": 6},
	"fish": {"name": "ماهی تازه", "buy": 32, "sell": 24},
	"processed_fish": {"name": "ماهی فرآوری‌شده", "buy": 58, "sell": 44}
}

var TRADE_CITIES = {
	"mehrabad": {"name":"مهرآباد","price_factor":1.20,"daily_capacity":25,"travel_days":1,"demand":{"stone":20,"iron_ore":10,"wood":25,"lumber":15,"furniture":8},"supply":{"stone":35,"iron_ore":12,"wood":8,"lumber":10,"furniture":5}},
	"navid": {"name":"نویدشهر","price_factor":1.35,"daily_capacity":18,"travel_days":2,"demand":{"stone":8,"iron_ore":25,"wood":10,"lumber":20,"furniture":18},"supply":{"stone":8,"iron_ore":40,"wood":10,"lumber":25,"furniture":22}},
	"golestan": {"name":"گلستان","price_factor":1.12,"daily_capacity":30,"travel_days":1,"demand":{"stone":15,"iron_ore":8,"wood":18,"lumber":12,"furniture":25},"supply":{"stone":18,"iron_ore":8,"wood":30,"lumber":18,"furniture":35}}
}

func _init():
	_add_iran_provincial_capitals()
	# Keep legacy trade-city fish demand separate; provincial demand is defined per province.
	for city_id in ["mehrabad","navid","golestan"]:
		TRADE_CITIES[city_id].demand["fish"] = 12 + int(TRADE_CITIES[city_id].daily_capacity % 9)
		TRADE_CITIES[city_id].demand["processed_fish"] = 6 + int(TRADE_CITIES[city_id].daily_capacity % 7)
		TRADE_CITIES[city_id].supply["fish"] = 10 + int(TRADE_CITIES[city_id].daily_capacity % 8)
		TRADE_CITIES[city_id].supply["processed_fish"] = 5 + int(TRADE_CITIES[city_id].daily_capacity % 6)

func _add_iran_provincial_capitals():
	var capitals = [
		{"id":"tabriz","name":"تبریز — آذربایجان شرقی"},
		{"id":"urmia","name":"ارومیه — آذربایجان غربی"},
		{"id":"ardabil","name":"اردبیل — اردبیل"},
		{"id":"isfahan","name":"اصفهان — اصفهان"},
		{"id":"karaj","name":"کرج — البرز"},
		{"id":"ilam","name":"ایلام — ایلام"},
		{"id":"bushehr","name":"بوشهر — بوشهر"},
		{"id":"tehran","name":"تهران — تهران"},
		{"id":"shahrekord","name":"شهرکرد — چهارمحال و بختیاری"},
		{"id":"birjand","name":"بیرجند — خراسان جنوبی"},
		{"id":"mashhad","name":"مشهد — خراسان رضوی"},
		{"id":"bojnord","name":"بجنورد — خراسان شمالی"},
		{"id":"ahvaz","name":"اهواز — خوزستان"},
		{"id":"zanjan","name":"زنجان — زنجان"},
		{"id":"semnan","name":"سمنان — سمنان"},
		{"id":"zahedan","name":"زاهدان — سیستان و بلوچستان"},
		{"id":"shiraz","name":"شیراز — فارس"},
		{"id":"qazvin","name":"قزوین — قزوین"},
		{"id":"qom","name":"قم — قم"},
		{"id":"sanandaj","name":"سنندج — کردستان"},
		{"id":"kerman","name":"کرمان — کرمان"},
		{"id":"kermanshah","name":"کرمانشاه — کرمانشاه"},
		{"id":"yasuj","name":"یاسوج — کهگیلویه و بویراحمد"},
		{"id":"gorgan","name":"گرگان — گلستان"},
		{"id":"rasht","name":"رشت — گیلان"},
		{"id":"khorramabad","name":"خرم‌آباد — لرستان"},
		{"id":"sari","name":"ساری — مازندران"},
		{"id":"arak","name":"اراک — مرکزی"},
		{"id":"bandar_abbas","name":"بندرعباس — هرمزگان"},
		{"id":"hamedan","name":"همدان — همدان"},
		{"id":" yazd","name":"یزد — یزد"}
	]
	for i in range(capitals.size()):
		var city = capitals[i]
		var city_id = str(city["id"]).strip_edges()
		var province_needs = {
			"tabriz":["iron_ore","lumber","furniture"],
			"urmia":["food","fish","furniture"],
			"ardabil":["food","wood"],
			"isfahan":["iron_ore","lumber","furniture"],
			"karaj":["food","furniture","processed_fish"],
			"ilam":["stone","wood"],
			"bushehr":["food","fish","processed_fish"],
			"tehran":["food","lumber","furniture"],
			"shahrekord":["food","fish","wood"],
			"birjand":["stone","food"],
			"mashhad":["food","lumber","furniture"],
			"bojnord":["food","wood","lumber"],
			"ahvaz":["stone","iron_ore","food"],
			"zanjan":["iron_ore","lumber"],
			"semnan":["stone","furniture"],
			"zahedan":["food","fish","wood"],
			"shiraz":["food","furniture","processed_fish"],
			"qazvin":["food","lumber","furniture"],
			"qom":["food","furniture"],
			"sanandaj":["food","wood","furniture"],
			"kerman":["stone","iron_ore","processed_fish"],
			"kermanshah":["food","wood","lumber"],
			"yasuj":["food","fish","wood"],
			"gorgan":["food","fish","lumber"],
			"rasht":["food","fish","processed_fish"],
			"khorramabad":["stone","food","wood"],
			"sari":["fish","processed_fish","wood"],
			"arak":["iron_ore","furniture"],
			"bandar_abbas":["food","fish","processed_fish"],
			"hamedan":["food","lumber"],
			"yazd":["stone","iron_ore","furniture"]
		}
		var demand = {}
		for resource_id in RESOURCES.keys():
			demand[resource_id] = 0
		var requested_goods = province_needs.get(city_id, ["food","wood"])
		for need_index in range(requested_goods.size()):
			var resource_id = str(requested_goods[need_index])
			demand[resource_id] = 8 + int((i * 7 + need_index * 5) % 18)
		var supply = {
			"stone": 8 + ((i * 11) % 28),
			"iron_ore": 5 + ((i * 13) % 35),
			"wood": 8 + ((i * 17) % 32),
			"lumber": 5 + ((i * 7) % 24),
			"furniture": 4 + ((i * 19) % 25)
		}
		TRADE_CITIES[city_id] = {
			"name": city["name"],
			"price_factor": 1.05 + float((i * 3) % 9) * 0.04,
			"daily_capacity": 18 + ((i * 7) % 23),
			"travel_days": 1 + int(i / 10),
			"demand": demand,
			"supply": supply
		}

const BUILDINGS = {
	"small_house": {"name":"خانه کوچک","category":"خانه‌ها","cost":100,"unlock":0,"capacity":2,"jobs":0,"wage":0},
	"normal_house": {"name":"خانه معمولی","category":"خانه‌ها","cost":250,"unlock":5,"capacity":4,"jobs":0,"wage":0,"level_unlock":2},
	"low_apartment": {"name":"آپارتمان کم‌ارتفاع","category":"خانه‌ها","cost":800,"unlock":20,"capacity":8,"jobs":0,"wage":0,"level_unlock":3},
	"high_apartment": {"name":"آپارتمان بلند","category":"خانه‌ها","cost":3000,"unlock":100,"capacity":14,"jobs":0,"wage":0,"level_unlock":5},
	"residential_tower": {"name":"برج مسکونی","category":"خانه‌ها","cost":10000,"unlock":500,"capacity":22,"jobs":0,"wage":0,"level_unlock":8},
	"transport_depot": {"name":"پایانه حمل‌ونقل","category":"حمل‌ونقل","cost":1800,"unlock":15,"jobs":4,"wage":40,"level_unlock":2},
	"taxi_station": {"name":"ایستگاه تاکسی","category":"حمل‌ونقل","cost":650,"unlock":5,"jobs":2,"wage":28},
	"bus_station": {"name":"ایستگاه اتوبوس","category":"حمل‌ونقل","cost":900,"unlock":10,"jobs":3,"wage":32},
	"farm": {"name":"مزرعه","category":"کشاورزی","cost":1200,"unlock":8,"jobs":4,"wage":35,"output":"food","amount":8,"level_unlock":2},
	"fish_lake": {"name":"دریاچه ماهیگیری","category":"کشاورزی","cost":3200,"unlock":12,"jobs":6,"wage":42,"output":"fish","amount":8,"level_unlock":2},
	"fishing_dock": {"name":"اسکله صیادی","category":"کشاورزی","cost":1800,"unlock":15,"jobs":4,"wage":38,"output":"fish","amount":5,"level_unlock":2},
	"shopping_mall": {"name":"مرکز خرید","category":"کسب‌وکارها","cost":8000,"unlock":150,"jobs":30,"wage":65,"daily_revenue":2600,"level_unlock":6},
	"small_warehouse": {"name":"انبار کوچک","category":"انبارها","cost":500,"unlock":0,"storage":100,"jobs":0,"wage":0},
	"central_bank": {"name":"بانک مرکزی","category":"خدمات شهری","cost":5000,"unlock":100,"jobs":8,"wage":55,"level_unlock":4},
	"municipal_bank": {"name":"بانک شهری","category":"خدمات شهری","cost":1500,"unlock":40,"jobs":3,"wage":42,"level_unlock":3},
	"medium_warehouse": {"name":"انبار متوسط","category":"انبارها","cost":2000,"unlock":0,"storage":500,"jobs":0,"wage":0,"level_unlock":2},
	"large_warehouse": {"name":"انبار بزرگ","category":"انبارها","cost":6000,"unlock":0,"storage":2000,"jobs":0,"wage":0,"level_unlock":4},
	"huge_warehouse": {"name":"انبار عظیم","category":"انبارها","cost":20000,"unlock":0,"storage":10000,"jobs":0,"wage":0,"level_unlock":7},
	"woodcutter": {"name":"چوب‌بری","category":"کارخانه‌ها","cost":900,"unlock":8,"jobs":4,"wage":32,"output":"wood","amount":2},
	"sawmill": {"name":"کارخانه الوارسازی","category":"کارخانه‌ها","cost":1800,"unlock":20,"jobs":3,"wage":42,"input":"wood","input_amount":2,"output":"lumber","amount":1,"level_unlock":3},
	"carpenter": {"name":"کارگاه مبلمان","category":"کارخانه‌ها","cost":2600,"unlock":35,"jobs":3,"wage":48,"input":"lumber","input_amount":2,"output":"furniture","amount":1,"level_unlock":4},
	"stone_mine": {"name":"معدن سنگ","category":"معادن","cost":1200,"unlock":10,"jobs":4,"wage":38,"output":"stone","amount":2},
	"iron_mine": {"name":"معدن آهن","category":"معادن","cost":2200,"unlock":30,"jobs":5,"wage":45,"output":"iron_ore","amount":1,"level_unlock":3},
	"grocery_store": {"name":"فروشگاه مواد غذایی","category":"کسب‌وکارها","cost":300,"unlock":5,"jobs":3,"wage":30,"service_need":"food","service_capacity":12},
	"bakery": {"name":"نانوایی","category":"کسب‌وکارها","cost":400,"unlock":10,"jobs":4,"wage":35,"service_need":"food","service_capacity":16},
	"restaurant": {"name":"رستوران","category":"کسب‌وکارها","cost":1000,"unlock":25,"jobs":6,"wage":45,"service_need":"food","service_capacity":20},
	"office": {"name":"ساختمان اداری","category":"کسب‌وکارها","cost":1800,"unlock":40,"jobs":20,"wage":60,"daily_revenue":1800},
	"factory": {"name":"کارخانه","category":"کسب‌وکارها","cost":6000,"unlock":100,"jobs":25,"wage":55,"daily_revenue":1800,"level_unlock":6},
	"mineral_market": {"name":"بازار مواد معدنی","category":"کسب‌وکارها","cost":500,"unlock":0,"jobs":1,"wage":35},
	"fish_market": {"name":"بازار ماهی","category":"کسب‌وکارها","cost":1100,"unlock":12,"jobs":4,"wage":38,"daily_revenue":420,"level_unlock":2},
	"fish_processing_plant": {"name":"کارخانه فرآوری ماهی","category":"کارخانه‌ها","cost":4200,"unlock":25,"jobs":8,"wage":48,"input":"fish","input_amount":3,"output":"processed_fish","amount":2,"level_unlock":3},
	"water_tower": {"name":"برج آب","category":"خدمات شهری","cost":500,"unlock":5,"jobs":2,"wage":30,"service_need":"water","service_capacity":35},
	"power_station": {"name":"نیروگاه","category":"خدمات شهری","cost":1000,"unlock":10,"jobs":4,"wage":40,"service_need":"power","service_capacity":40},
	"sewage_plant": {"name":"تصفیه‌خانه فاضلاب","category":"خدمات شهری","cost":1800,"unlock":25,"jobs":3,"wage":42,"service_need":"sanitation","service_capacity":35},
	"waste_facility": {"name":"مرکز پسماند","category":"خدمات شهری","cost":1500,"unlock":30,"jobs":3,"wage":38,"service_need":"sanitation","service_capacity":30},
	"school": {"name":"مدرسه","category":"خدمات شهری","cost":1200,"unlock":20,"jobs":5,"wage":40,"service_need":"education","service_capacity":22},
	"clinic": {"name":"درمانگاه","category":"خدمات شهری","cost":1400,"unlock":25,"jobs":4,"wage":45,"service_need":"health","service_capacity":18},
	"hospital": {"name":"بیمارستان","category":"خدمات شهری","cost":5000,"unlock":100,"jobs":12,"wage":55,"service_need":"health","service_capacity":45,"level_unlock":6},
	"police_station": {"name":"کلانتری","category":"خدمات شهری","cost":2500,"unlock":80,"jobs":6,"wage":48,"service_need":"safety","service_capacity":30,"level_unlock":5},
	"fire_station": {"name":"آتش‌نشانی","category":"خدمات شهری","cost":2500,"unlock":80,"jobs":6,"wage":48,"service_need":"safety","service_capacity":25,"level_unlock":5},
	"small_park": {"name":"پارک کوچک","category":"تفریح و فرهنگ","cost":250,"unlock":10,"jobs":1,"wage":20,"service_need":"leisure","service_capacity":12},
	"playground": {"name":"زمین بازی","category":"تفریح و فرهنگ","cost":350,"unlock":15,"jobs":1,"wage":20,"service_need":"leisure","service_capacity":15},
	"sports_center": {"name":"مجموعه ورزشی","category":"تفریح و فرهنگ","cost":2500,"unlock":100,"jobs":5,"wage":40,"service_need":"leisure","service_capacity":28,"level_unlock":5},
	"university": {"name":"دانشگاه","category":"خدمات شهری","cost":6000,"unlock":150,"jobs":15,"wage":60,"service_need":"education","service_capacity":45,"level_unlock":7},
	"cultural_center": {"name":"مرکز فرهنگی","category":"تفریح و فرهنگ","cost":4500,"unlock":300,"jobs":8,"wage":50,"service_need":"leisure","service_capacity":30,"level_unlock":8}
}

var state = {}

func new_game():
	state = {
		"version": 17,
		"districts": [],
		"day": 1,
		"clock_last_unix": OS.get_unix_time(),
		"clock_cycle_seconds": 0,
		"pending_offline_income": 0,
		"pending_offline_days": 0,
		"daily_trade_city_ids": [],
		"daily_trade_city_day": 0,
		"daily_trade_city_level": 0,
		"money": 10000,
		"population": 4,
		"citizen_recruitment_mode": "auto",
		"citizen_requests": [],
		"constructions": [],
		"land_owned": 10,
		"level": 1,
		"xp": 0,
		"reputation": 50,
		"satisfaction": 50,
		"last_login_day_serial": -1,
		"login_streak": 0,
		"active_play_seconds_today": 0.0,
		"consecutive_active_game_days": 0,
		"trade_exported_units_total": 0,
		"business_profit_collections_total": 0,
		"profitable_day_streak": 0,
		"high_satisfaction_day_streak": 0,
		"road_level": 1,
		"transport_used_today": 0,
		"needs": {"food":65,"water":70,"power":70,"health":70,"education":50,"safety":70,"leisure":50,"sanitation":70},
		"services": {},
		"missions": [],
		"central_bank_rebuild_days_left": 0,
		"bank_loans": [],
		"bank_deposits": [],
		"bank_transactions": [],
		"forest_trees": 100,
		"mines": [],
		"buildings": [
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_warehouse","workers":0,"balance":0}
		],
		"resources": {"stone":0,"iron_ore":0,"wood":0,"lumber":0,"furniture":0,"food":0,"fish":0,"processed_fish":0},
		"market_stock": {"stone":60,"iron_ore":60,"wood":60,"lumber":60,"furniture":60,"food":60,"fish":60,"processed_fish":60},
		"trade_remaining": {"mehrabad":25,"navid":18,"golestan":30},
		"trade_demand_remaining": {"mehrabad":{"stone":20,"iron_ore":10,"wood":25,"lumber":15,"furniture":8},"navid":{"stone":8,"iron_ore":25,"wood":10,"lumber":20,"furniture":18},"golestan":{"stone":15,"iron_ore":8,"wood":18,"lumber":12,"furniture":25}},
		"last_trade_report": "هنوز معامله بین‌شهری انجام نشده است.",
		"city_export_stock": {"mehrabad":{"stone":35,"iron_ore":12,"wood":8,"lumber":10,"furniture":5},"navid":{"stone":8,"iron_ore":40,"wood":10,"lumber":25,"furniture":22},"golestan":{"stone":18,"iron_ore":8,"wood":30,"lumber":18,"furniture":35}},
		"trade_shipments": [],
		"import_contracts": [],
		"last_import_report": "هنوز محموله‌ای سفارش داده نشده است.",
		"citizens": [],
		"last_economy": {"tax_income":0,"business_income":0,"resource_income":0,"gross_income":0,"accepted_income":0,"wages_due":0,"wages_paid":0,"fleet_maintenance":0,"road_maintenance":0,"maintenance_paid":0,"net_cashflow":0},
		"last_report": "شهر جدید ساخته شد. به مینی زکا سیتی خوش آمدی.",
		"report_events": [{"timestamp":OS.get_unix_time(),"day":1,"message":"شهر جدید ساخته شد. به مینی زکا سیتی خوش آمدی."}]
	}
	_sync_population()
	CitizenSociety.new().ensure_state(self)
	_ensure_building_locations()
	_sync_missions()
	return state

func load_game():
	var file = File.new()
	if not file.file_exists(SAVE_PATH):
		return false
	if file.open(SAVE_PATH, File.READ) != OK:
		return false
	var parsed = parse_json(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) < 1 or int(parsed.get("version", 0)) > 17:
		return false
	state = parsed
	_normalize_state()
	_sync_population()
	CitizenSociety.new().ensure_state(self)
	_ensure_building_locations()
	_sync_missions()
	return true


# Convert the local calendar date to a monotonic day number without relying on UTC.
func _get_local_calendar_day_serial():
	var date = OS.get_date()
	var year = int(date.get("year", 1970))
	var month = int(date.get("month", 1))
	var day = int(date.get("day", 1))
	if month <= 2:
		year -= 1
	var era = int(floor(float(year) / 400.0))
	var year_of_era = year - era * 400
	var adjusted_month = month + (-3 if month > 2 else 9)
	var day_of_year = int((153 * adjusted_month + 2) / 5) + day - 1
	var day_of_era = year_of_era * 365 + int(year_of_era / 4) - int(year_of_era / 100) + day_of_year
	return era * 146097 + day_of_era

func register_login_today():
	return register_login_day_serial(_get_local_calendar_day_serial())

# Public deterministic variant also makes calendar streak rules testable.
func register_login_day_serial(day_serial):
	var today = int(day_serial)
	var previous = int(state.get("last_login_day_serial", -1))
	if previous == today:
		return false
	if previous == today - 1:
		state["login_streak"] = int(state.get("login_streak", 0)) + 1
	else:
		state["login_streak"] = 1
	state["last_login_day_serial"] = today
	_update_missions()
	save_game()
	return true

func record_active_play_seconds(seconds):
	if seconds <= 0.0:
		return
	state["active_play_seconds_today"] = float(state.get("active_play_seconds_today", 0.0)) + min(float(seconds), 1.0)

func add_report_event(message, persist=true):
	var clean_message = str(message).strip_edges()
	if clean_message == "":
		return
	if typeof(state.get("report_events", null)) != TYPE_ARRAY:
		state["report_events"] = []
	state.report_events.append({"timestamp":OS.get_unix_time(),"day":int(state.get("day", 1)),"message":clean_message})
	while state.report_events.size() > 100:
		state.report_events.pop_front()
	if persist:
		save_game()

func save_game():
	var file = File.new()
	if file.open(SAVE_PATH, File.WRITE) != OK:
		return false
	file.store_string(to_json(state))
	file.close()
	return true

func _normalize_state():
	if typeof(state.get("report_events", null)) != TYPE_ARRAY:
		state["report_events"] = []
	while state.report_events.size() > 100:
		state.report_events.pop_front()
	if typeof(state.get("buildings", null)) != TYPE_ARRAY:
		state.buildings = []
	if typeof(state.get("citizens", null)) != TYPE_ARRAY:
		state.citizens = []
	if typeof(state.get("citizen_requests", null)) != TYPE_ARRAY:
		state["citizen_requests"] = []
	if typeof(state.get("constructions", null)) != TYPE_ARRAY:
		state["constructions"] = []
	if not state.has("land_owned"):
		state["land_owned"] = 10
	state["land_owned"] = max(3, int(state.get("land_owned", 10)))
	if not (str(state.get("citizen_recruitment_mode", "auto")) in ["auto", "manual"]):
		state["citizen_recruitment_mode"] = "auto"
	if typeof(state.get("resources", null)) != TYPE_DICTIONARY:
		state.resources = {}
	if typeof(state.get("storage_rules", null)) != TYPE_DICTIONARY:
		state["storage_rules"] = {}
	for resource_id in RESOURCES.keys():
		var saved_rule = state.storage_rules.get(resource_id, {})
		if typeof(saved_rule) != TYPE_DICTIONARY:
			saved_rule = {}
		state.storage_rules[resource_id] = {"minimum":max(0,int(saved_rule.get("minimum",10))),"maximum":max(10,int(saved_rule.get("maximum",40))),"low_action":str(saved_rule.get("low_action","market")),"high_action":str(saved_rule.get("high_action","market"))}
		if int(state.storage_rules[resource_id].maximum) <= int(state.storage_rules[resource_id].minimum):
			state.storage_rules[resource_id].maximum = int(state.storage_rules[resource_id].minimum) + 5
	if typeof(state.get("market_stock", null)) != TYPE_DICTIONARY:
		state.market_stock = {}
	if typeof(state.get("trade_remaining", null)) != TYPE_DICTIONARY:
		state["trade_remaining"] = {}
	if typeof(state.get("trade_demand_remaining", null)) != TYPE_DICTIONARY:
		state["trade_demand_remaining"] = {}
	if typeof(state.get("city_export_stock", null)) != TYPE_DICTIONARY:
		state["city_export_stock"] = {}
	if typeof(state.get("trade_shipments", null)) != TYPE_ARRAY:
		state["trade_shipments"] = []
	if typeof(state.get("import_contracts", null)) != TYPE_ARRAY:
		state["import_contracts"] = []
	if not state.has("last_import_report"):
		state["last_import_report"] = "هنوز محموله‌ای سفارش داده نشده است."
	if not state.has("clock_last_unix"):
		state["clock_last_unix"] = OS.get_unix_time()
	if not state.has("clock_cycle_seconds"):
		state["clock_cycle_seconds"] = 0
	if not state.has("pending_offline_income"):
		state["pending_offline_income"] = 0
	if not state.has("pending_offline_days"):
		state["pending_offline_days"] = 0
	if typeof(state.get("bank_loans", null)) != TYPE_ARRAY:
		state["bank_loans"] = []
	if typeof(state.get("bank_deposits", null)) != TYPE_ARRAY:
		state["bank_deposits"] = []
	if typeof(state.get("bank_transactions", null)) != TYPE_ARRAY:
		state["bank_transactions"] = []
	while state.bank_transactions.size() > 100:
		state.bank_transactions.pop_front()
	if typeof(state.get("daily_trade_city_ids", null)) != TYPE_ARRAY:
		state["daily_trade_city_ids"] = []
	if not state.has("daily_trade_city_day"):
		state["daily_trade_city_day"] = 0
	if not state.has("daily_trade_city_level"):
		state["daily_trade_city_level"] = 0
	if not state.has("road_level"):
		state["road_level"] = 1
	if not state.has("transport_used_today"):
		state["transport_used_today"] = 0
	if not state.has("central_bank_rebuild_days_left"):
		state["central_bank_rebuild_days_left"] = 0
	if not state.has("forest_trees"):
		state["forest_trees"] = 100
	if not state.has("satisfaction"):
		state["satisfaction"] = 50
	if typeof(state.get("last_economy", null)) != TYPE_DICTIONARY:
		state["last_economy"] = {"tax_income":0,"business_income":0,"resource_income":0,"gross_income":0,"accepted_income":0,"wages_due":0,"wages_paid":0,"fleet_maintenance":0,"road_maintenance":0,"maintenance_paid":0,"net_cashflow":0}
	for ledger_key in ["fleet_maintenance","road_maintenance","maintenance_paid"]:
		state.last_economy[ledger_key] = int(state.last_economy.get(ledger_key,0))
	if typeof(state.get("services", null)) != TYPE_DICTIONARY:
		state["services"] = {}
	if typeof(state.get("needs", null)) != TYPE_DICTIONARY:
		state["needs"] = {"food":65,"water":70,"power":70,"health":70,"education":50,"safety":70,"leisure":50,"sanitation":70}
	for need_id in ["food","water","power","health","education","safety","leisure","sanitation"]:
		state.needs[need_id] = int(clamp(int(state.needs.get(need_id, 60)), 0, 100))
	for citizen in state.citizens:
		citizen["wallet"] = int(clamp(int(citizen.get("wallet", 100)), 0, 2000))
	for building in state.buildings:
		building["balance"] = max(0, int(building.get("balance", 0)))
	if typeof(state.get("missions", null)) != TYPE_ARRAY:
		state["missions"] = []
	state["last_login_day_serial"] = int(state.get("last_login_day_serial", -1))
	state["login_streak"] = max(0, int(state.get("login_streak", 0)))
	state["active_play_seconds_today"] = max(0.0, float(state.get("active_play_seconds_today", 0.0)))
	state["consecutive_active_game_days"] = max(0, int(state.get("consecutive_active_game_days", 0)))
	state["trade_exported_units_total"] = max(0, int(state.get("trade_exported_units_total", 0)))
	state["business_profit_collections_total"] = max(0, int(state.get("business_profit_collections_total", 0)))
	state["profitable_day_streak"] = max(0, int(state.get("profitable_day_streak", 0)))
	state["high_satisfaction_day_streak"] = max(0, int(state.get("high_satisfaction_day_streak", 0)))
	if typeof(state.get("mines", null)) != TYPE_ARRAY:
		state["mines"] = []
	# Save schema migration: add dynamic market, trade and shipping state.
	state["version"] = 17
	if typeof(state.get("districts", null)) != TYPE_ARRAY:
		state["districts"] = []
	for id in RESOURCES.keys():
		state.market_stock[id] = int(clamp(int(state.market_stock.get(id, 60)), 0, 100))
	for city_id in TRADE_CITIES.keys():
		state.trade_remaining[city_id] = int(clamp(int(state.trade_remaining.get(city_id, TRADE_CITIES[city_id].daily_capacity)), 0, int(TRADE_CITIES[city_id].daily_capacity)))
		if typeof(state.city_export_stock.get(city_id, null)) != TYPE_DICTIONARY:
			state.city_export_stock[city_id] = TRADE_CITIES[city_id].supply.duplicate(true)
		else:
			for resource_id in RESOURCES.keys():
				state.city_export_stock[city_id][resource_id] = max(0, int(state.city_export_stock[city_id].get(resource_id, TRADE_CITIES[city_id].supply.get(resource_id,0))))
		if typeof(state.trade_demand_remaining.get(city_id, null)) != TYPE_DICTIONARY:
			state.trade_demand_remaining[city_id] = TRADE_CITIES[city_id].demand.duplicate(true)
		else:
			for resource_id in RESOURCES.keys():
				state.trade_demand_remaining[city_id][resource_id] = int(clamp(int(state.trade_demand_remaining[city_id].get(resource_id, TRADE_CITIES[city_id].demand.get(resource_id,0))),0,int(TRADE_CITIES[city_id].demand.get(resource_id,0))))
	state["central_bank_rebuild_days_left"] = max(0, int(state.get("central_bank_rebuild_days_left", 0)))
	state["forest_trees"] = int(clamp(int(state.get("forest_trees", 100)), 0, 100))
	state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)), 0, 100))
	# Migrate existing mine buildings into persistent mine records.
	for i in range(state.buildings.size()):
		var building_id = str(state.buildings[i].get("id", ""))
		if building_id in ["stone_mine", "iron_mine"] and not _has_mine(i):
			_register_mine(i, building_id)
	for key in ["day","money","population","level","xp","reputation"]:
		if not state.has(key):
			state[key] = {"day":1,"money":10000,"population":0,"level":1,"xp":0,"reputation":50}[key]
	for id in RESOURCES.keys():
		if not state.resources.has(id):
			state.resources[id] = 0
		if not state.market_stock.has(id):
			state.market_stock[id] = 100

func _sync_population():
	var capacity = 0
	for building in state.buildings:
		var definition = BUILDINGS.get(building.id, {})
		capacity += int(definition.get("capacity", 0))
	state.population = min(max(0, int(state.population)), capacity)
	while state.citizens.size() > state.population:
		state.citizens.pop_back()
	while state.citizens.size() < state.population:
		state.citizens.append({"id":_next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})

func _next_citizen_request_id():
	var highest = 0
	for request in state.get("citizen_requests", []):
		highest = max(highest, int(request.get("id", 0)))
	return highest + 1

func set_citizen_recruitment_mode(mode):
	if str(mode) != "auto" and str(mode) != "manual":
		return {"ok":false,"message":"حالت جذب نامعتبر است."}
	state["citizen_recruitment_mode"] = str(mode)
	save_game()
	return {"ok":true,"message":"حالت جذب شهروندان: "+("خودکار" if str(mode) == "auto" else "دستی")}

func accept_citizen_request(request_index):
	if request_index < 0 or request_index >= state.citizen_requests.size():
		return {"ok":false,"message":"درخواست پیدا نشد."}
	if int(state.population) >= get_housing_capacity():
		return {"ok":false,"message":"ظرفیت خانه‌ها پر است؛ ابتدا خانه بیشتری بساز."}
	var request = state.citizen_requests[request_index]
	state.citizen_requests.remove(request_index)
	state.population += 1
	state.citizens.append({"id":_next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
	assign_jobs()
	save_game()
	return {"ok":true,"message":"متقاضی شماره %d پذیرفته شد و به شهر اضافه شد." % int(request.get("id",0))}

func reject_citizen_request(request_index):
	if request_index < 0 or request_index >= state.citizen_requests.size():
		return {"ok":false,"message":"درخواست پیدا نشد."}
	var request = state.citizen_requests[request_index]
	state.citizen_requests.remove(request_index)
	save_game()
	return {"ok":true,"message":"درخواست متقاضی شماره %d رد شد." % int(request.get("id",0))}

func _process_citizen_recruitment(report):
	var housing = get_housing_capacity()
	var pending_requests = state.citizen_requests.size() if str(state.get("citizen_recruitment_mode", "auto")) == "manual" else 0
	var available_slots = max(0, housing - int(state.population) - pending_requests)
	# A city receives 5 to 10 potential residents per game day, limited by free housing.
	if available_slots <= 0 or int(state.reputation) < 25:
		return
	var daily_target = 5 + int(randi() % 6)
	var arrivals = min(daily_target, available_slots)
	if str(state.get("citizen_recruitment_mode", "auto")) == "manual":
		for request_number in range(arrivals):
			var request_id = _next_citizen_request_id()
			state.citizen_requests.append({"id":request_id,"day":int(state.day)})
		report.append("%d درخواست جذب شهروند ثبت شد؛ از بخش شهروندان بررسی‌شان کن." % arrivals)
		return
	for arrival_number in range(arrivals):
		state.population += 1
		state.citizens.append({"id":_next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
	report.append("%d شهروند جدید به‌صورت خودکار به شهر مهاجرت کردند." % arrivals)
	assign_jobs()

func _next_citizen_id():
	var highest = 0
	for citizen in state.citizens:
		highest = max(highest, int(citizen.get("id", 0)))
	return highest + 1

func get_housing_capacity():
	var total = 0
	for building in state.buildings:
		total += int(BUILDINGS.get(building.id, {}).get("capacity", 0))
	return total

func _district_letter(index):
	var value = int(index) + 1
	var result = ""
	while value > 0:
		var remainder = (value - 1) % 26
		result = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substr(remainder, 1) + result
		value = int((value - 1) / 26)
	return result

func _find_district_index(district_id):
	for i in range(state.get("districts", []).size()):
		if str(state.districts[i].get("id", "")) == str(district_id):
			return i
	return -1

func _is_house_building(building_id):
	return int(BUILDINGS.get(str(building_id), {}).get("capacity", 0)) > 0

func _district_can_accept(district, building_id):
	var id = str(building_id)
	var is_house = _is_house_building(id)
	var house_count = int(district.get("house_count", 0))
	var other_count = int(district.get("other_count", 0))
	var emergency_count = int(district.get("emergency_count", 0))
	var type_counts = district.get("building_type_counts", {})
	if is_house:
		return house_count < DISTRICT_HOUSE_LIMIT
	var type_count = int(type_counts.get(id, 0))
	if type_count >= DISTRICT_BUILDING_TYPE_LIMIT:
		return false
	if id in DISTRICT_EMERGENCY_BUILDINGS:
		return emergency_count < DISTRICT_EMERGENCY_LIMIT
	return other_count < DISTRICT_OTHER_LIMIT

func _assign_building_location(building_id):
	var id = str(building_id)
	if id in OUTSIDE_CITY_BUILDINGS:
		return {"zone":"industrial","district_id":"","district_name":"منطقه صنعتی خارج شهر"}
	if typeof(state.get("districts", null)) != TYPE_ARRAY:
		state["districts"] = []
	var chosen_index = -1
	for i in range(state.districts.size()):
		if _district_can_accept(state.districts[i], id):
			chosen_index = i
			break
	if chosen_index < 0:
		var district_number = state.districts.size()
		var district_id = _district_letter(int(district_number / 50)) + str((district_number % 50) + 1)
		state.districts.append({"id":district_id,"name":"محله "+district_id,"building_count":0,"house_count":0,"other_count":0,"emergency_count":0,"building_type_counts":{}})
		chosen_index = state.districts.size() - 1
	var district = state.districts[chosen_index]
	if _is_house_building(id):
		district["house_count"] = int(district.get("house_count", 0)) + 1
	elif id in DISTRICT_EMERGENCY_BUILDINGS:
		district["emergency_count"] = int(district.get("emergency_count", 0)) + 1
	else:
		district["other_count"] = int(district.get("other_count", 0)) + 1
	if not _is_house_building(id):
		var type_counts = district.get("building_type_counts", {})
		type_counts[id] = int(type_counts.get(id, 0)) + 1
		district["building_type_counts"] = type_counts
	district["building_count"] = int(district.get("house_count", 0)) + int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))
	state.districts[chosen_index] = district
	return {"zone":"district","district_id":str(district.id),"district_name":str(district.name)}

func _ensure_building_locations():
	# Rebuild neighborhood assignments from actual saved buildings so older
	# saves also adopt the new 20-house / 20-other-building rules.
	state["districts"] = []
	for collection_name in ["buildings", "constructions", "private_businesses"]:
		var collection = state.get(collection_name, [])
		for i in range(collection.size()):
			var item = collection[i]
			if collection_name == "private_businesses" and bool(item.get("rented_municipal", false)):
				continue
			var building_id = str(item.get("id", item.get("building_id", "")))
			var location = _assign_building_location(building_id)
			for key in location.keys():
				item[key] = location[key]
			collection[i] = item
		state[collection_name] = collection

func get_districts_overview():
	_ensure_building_locations()
	var result = []
	for district in state.get("districts", []):
		var names = []
		for building in state.get("buildings", []):
			if str(building.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(BUILDINGS.get(str(building.get("id", "")), {}).get("name", "ساختمان")))
		for construction in state.get("constructions", []):
			if str(construction.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(BUILDINGS.get(str(construction.get("id", "")), {}).get("name", "پروژه در حال ساخت"))+" (در حال ساخت)")
		for business in state.get("private_businesses", []):
			if bool(business.get("rented_municipal", false)):
				continue
			if str(business.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(business.get("name", BUILDINGS.get(str(business.get("building_id", "")), {}).get("name", "کسب‌وکار"))))
		var row = district.duplicate(true)
		row["building_names"] = names
		row["building_count"] = names.size()
		result.append(row)
	var industrial_names = []
	for building in state.get("buildings", []):
		if str(building.get("zone", "")) == "industrial":
			industrial_names.append(str(BUILDINGS.get(str(building.get("id", "")), {}).get("name", "ساختمان")))
	for construction in state.get("constructions", []):
		if str(construction.get("zone", "")) == "industrial":
			industrial_names.append(str(BUILDINGS.get(str(construction.get("id", "")), {}).get("name", "ساختمان"))+" (در حال ساخت)")
	for business in state.get("private_businesses", []):
		if bool(business.get("rented_municipal", false)):
			continue
		if str(business.get("zone", "")) == "industrial":
			industrial_names.append(str(business.get("name", "کسب‌وکار خصوصی")))
	return {"districts":result,"industrial_buildings":industrial_names,"district_count":result.size()}

func get_district_capacity_summary(district_id):
	_ensure_building_locations()
	for district in state.get("districts", []):
		if str(district.get("id", "")) == str(district_id):
			return {
				"house_count": int(district.get("house_count", 0)),
				"other_count": int(district.get("other_count", 0)),
				"emergency_count": int(district.get("emergency_count", 0)),
				"building_type_counts": district.get("building_type_counts", {}).duplicate(true)
			}
	return {"house_count":0,"other_count":0,"emergency_count":0,"building_type_counts":{}}

func get_building_definitions():
	return BUILDINGS

func get_resource_definitions():
	return RESOURCES

func has_central_bank():
	return get_building_count("central_bank") > 0

func get_treasury_capacity():
	var capacity = 10000
	if has_central_bank():
		capacity += 40000
	capacity += get_building_count("municipal_bank") * 5000
	return capacity

func get_locked_money():
	return max(0, int(state.money) - get_treasury_capacity())

func get_available_money():
	return max(0, int(state.money) - get_locked_money())

func _spend_money(amount):
	var value = int(amount)
	if value < 0 or get_available_money() < value:
		return false
	state.money = int(state.money) - value
	return true

func _add_money(amount):
	var value = int(amount)
	if value <= 0:
		return 0
	var accepted = min(value, max(0, get_treasury_capacity() - int(state.money)))
	state.money = int(state.money) + accepted
	return accepted

func get_transport_truck_count():
	var staffed_workers = 0
	for i in range(state.buildings.size()):
		if str(state.buildings[i].get("id","")) == "transport_depot":
			staffed_workers += _workers_for_building(i)
	return min(get_building_count("transport_depot") * 2, int(floor(float(staffed_workers) / 2.0)))

func get_transport_daily_capacity():
	return get_transport_truck_count() * (8 + int(state.get("road_level",1)) * 2)

func get_transport_capacity_remaining():
	return max(0, get_transport_daily_capacity() - int(state.get("transport_used_today",0)))

func get_fleet_maintenance():
	return get_transport_truck_count() * 15

func get_road_maintenance():
	return int(state.get("road_level",1)) * 5

func upgrade_roads():
	var level = int(state.get("road_level",1))
	if level >= 3:
		return {"ok":false,"message":"شبکه جاده‌ای شهر در بالاترین سطح است."}
	var next_level = level + 1
	var cost = 1500 if next_level == 2 else 3500
	if int(state.level) < next_level:
		return {"ok":false,"message":"برای ارتقای جاده به سطح %d باید سطح شهر هم به %d برسد." % [next_level,next_level]}
	if not _spend_money(cost):
		return {"ok":false,"message":"پول آزاد خزانه برای ارتقای جاده کافی نیست."}
	state.road_level = next_level
	save_game()
	return {"ok":true,"message":"شبکه جاده‌ای به سطح %d ارتقا یافت؛ ظرفیت هر کامیون افزایش پیدا کرد." % next_level}

func get_forest_tree_count():
	return int(state.get("forest_trees", 0))


func get_storage_rule(resource_id):
	if not RESOURCES.has(str(resource_id)):
		return {}
	if typeof(state.get("storage_rules", null)) != TYPE_DICTIONARY:
		state["storage_rules"] = {}
	if not state.storage_rules.has(str(resource_id)):
		state.storage_rules[str(resource_id)] = {"minimum":10,"maximum":40,"low_action":"market","high_action":"market"}
	return state.storage_rules[str(resource_id)]

func set_storage_rule(resource_id, field, value):
	if not RESOURCES.has(str(resource_id)) or not str(field) in ["minimum","maximum"]:
		return {"ok":false,"message":"تنظیم انبار نامعتبر است."}
	var rule = get_storage_rule(str(resource_id))
	var amount = max(0,int(value))
	if str(field) == "minimum":
		rule.minimum = min(amount,max(0,int(rule.maximum)-5))
	else:
		rule.maximum = max(amount,int(rule.minimum)+5)
	state.storage_rules[str(resource_id)] = rule
	save_game()
	return {"ok":true,"message":"حد موجودی "+RESOURCES[str(resource_id)].name+" ذخیره شد."}

func toggle_storage_action(resource_id, level):
	var rule = get_storage_rule(str(resource_id))
	if str(level) == "low":
		rule.low_action = "factory" if str(rule.get("low_action","market")) == "market" else "market"
	else:
		rule.high_action = "shop" if str(rule.get("high_action","market")) == "market" else "market"
	state.storage_rules[str(resource_id)] = rule
	save_game()
	return {"ok":true,"message":"روش مدیریت موجودی "+RESOURCES[str(resource_id)].name+" تغییر کرد."}

func apply_storage_rule(resource_id, manual=false):
	if not RESOURCES.has(str(resource_id)):
		return {"ok":false,"message":"ماده پیدا نشد."}
	var id = str(resource_id)
	var rule = get_storage_rule(id)
	var current = int(state.resources.get(id,0))
	var minimum = int(rule.get("minimum",10))
	var maximum = int(rule.get("maximum",40))
	if current < minimum:
		if str(rule.get("low_action","market")) == "market":
			var amount = min(minimum-current,min(int(state.market_stock.get(id,0)),get_free_storage()))
			var price = get_market_price(id,"buy")
			amount = min(amount,int(floor(float(get_available_money())/float(max(1,price)))))
			if amount > 0:
				_spend_money(amount*price)
				state.market_stock[id] = int(state.market_stock.get(id,0))-amount
				state.resources[id] = current+amount
				return {"ok":true,"message":"برای انبار %d واحد %s از بازار خریداری شد." % [amount,RESOURCES[id].name]}
			return {"ok":false,"message":"برای تأمین "+RESOURCES[id].name+" موجودی بازار، فضای انبار یا پول کافی نیست."}
		return {"ok":true,"message":"تولید "+RESOURCES[id].name+" در کارخانه‌ها در اولویت قرار گرفت؛ تولید اضافه فقط با مواد اولیه و نیروی کار ممکن است."}
	if current > maximum:
		var surplus = current-maximum
		if str(rule.get("high_action","market")) == "shop":
			if id != "food" or get_building_count("grocery_store") <= 0:
				return {"ok":false,"message":"برای فروش این ماده از فروشگاه، فروشگاه مواد غذایی لازم است؛ فعلاً از بازار استفاده کن."}
			# Keep surplus food for the normal citizen-purchase process at staffed grocery stores.
			return {"ok":true,"message":"مازاد خوراک در انبار ماند تا فروشگاه‌ها آن را به شهروندان بفروشند."}
		# Market route uses the same stock and treasury limits as manual market sales.
		var sell_mode = "sell"
		var unit_sell_price = max(1, get_market_price(id, sell_mode))
		var market_room = max(0, 100 - int(state.market_stock.get(id, 0)))
		var treasury_room = max(0, get_treasury_capacity() - int(state.money))
		var sold = min(surplus, min(market_room, int(floor(float(treasury_room) / float(unit_sell_price)))))
		if sold > 0:
			var revenue = sold*get_market_price(id,"sell")
			state.resources[id] = current-sold
			state.market_stock[id] = int(state.market_stock.get(id,0))+sold
			_add_money(revenue)
			return {"ok":true,"message":"%d واحد %s به فروش رسید و %d سکه درآمد ایجاد کرد." % [sold,RESOURCES[id].name,revenue]}
		return {"ok":false,"message":"بازار یا خزانه ظرفیت فروش "+RESOURCES[id].name+" را ندارد."}
	return {"ok":true,"message":"موجودی "+RESOURCES[id].name+" در محدوده تنظیم‌شده است."}


func get_storage_capacity():
	var total = 0
	for building in state.buildings:
		total += int(BUILDINGS.get(building.id, {}).get("storage", 0))
	return total

func get_storage_used():
	var total = 0
	for value in state.resources.values():
		total += int(value)
	return total

func get_free_storage():
	return max(0, get_storage_capacity() - get_storage_used())

func get_building_count(id):
	var count = 0
	for building in state.buildings:
		if building.id == id:
			count += 1
	return count

func get_employed_count():
	var count = 0
	for citizen in state.citizens:
		if str(citizen.get("job", "")) != "" or int(citizen.get("private_job_id", 0)) > 0:
			count += 1
	return count

func get_unemployed_count():
	return max(0, state.population - get_employed_count())

func get_job_capacity():
	var total = 0
	for building in state.buildings:
		if int(building.get("rented_to", 0)) > 0:
			continue
		total += int(BUILDINGS.get(building.id, {}).get("jobs", 0))
	for business in state.get("private_businesses", []):
		total += int(business.get("jobs", 0))
	return total

func get_land_size(id):
	var sizes = {
		"small_house":1,"normal_house":2,"low_apartment":3,"high_apartment":4,"residential_tower":5,
		"small_warehouse":1,"medium_warehouse":2,"large_warehouse":3,"huge_warehouse":5,
		"fish_lake":4,"fishing_dock":2,"fish_market":2,"fish_processing_plant":3,
		"mineral_market":1,"small_park":1,"playground":1,"grocery_store":1,"bakery":1,"water_tower":1,
		"farm":2,"woodcutter":2,"stone_mine":2,"transport_depot":2,"restaurant":2,"office":2,
		"municipal_bank":2,"power_station":2,"sawmill":2,"sewage_plant":2,"waste_facility":2,
		"school":3,"clinic":3,"iron_mine":3,"carpenter":3,"sports_center":3,"fire_station":3,"police_station":3,
		"central_bank":4,"factory":4,"hospital":4,"university":5,"shopping_mall":5,"cultural_center":4,"taxi_station":1,"bus_station":2
	}
	return int(sizes.get(str(id), 1))

func get_land_used():
	var used = 0
	for building in state.get("buildings", []):
		used += get_land_size(str(building.get("id", "")))
	for project in state.get("constructions", []):
		used += get_land_size(str(project.get("id", "")))
	for project in state.get("civic_projects", []):
		used += get_land_size(str(project.get("building_id", "")))
	return used

func get_land_free():
	return max(0, int(state.get("land_owned", 10)) - get_land_used())

func get_land_unit_price():
	return 300 + max(0, int(state.get("land_owned", 10)) - 10) * 40

func buy_land(plots=1):
	var amount = int(plots)
	if amount < 1 or amount > 10:
		return {"ok":false,"message":"هر بار می‌توانی بین ۱ تا ۱۰ قطعه زمین بخری."}
	var owned = int(state.get("land_owned", 10))
	var unit_price = get_land_unit_price()
	var total = unit_price * amount
	if not _spend_money(total):
		return {"ok":false,"message":"پول آزاد خزانه برای خرید زمین کافی نیست؛ هزینه هر قطعه %d سکه است." % unit_price}
	state["land_owned"] = owned + amount
	save_game()
	return {"ok":true,"message":"%d قطعه زمین به قیمت %d سکه خریداری شد. زمین آزاد: %d قطعه." % [amount,total,get_land_free()]}

func build(id):
	if not BUILDINGS.has(id):
		return {"ok":false,"message":"این ساختمان تعریف نشده است."}
	var data = BUILDINGS[id]
	if int(state.population) < int(data.get("unlock", 0)):
		return {"ok":false,"message":"برای ساخت این ساختمان جمعیت کافی نیست."}
	if int(state.level) < int(data.get("level_unlock", 1)):
		return {"ok":false,"message":"برای ساخت این ساختمان باید به سطح %d برسی." % int(data.get("level_unlock", 1))}
	if id == "central_bank" and int(state.get("central_bank_rebuild_days_left", 0)) > 0:
		return {"ok":false,"message":"برای ساخت دوباره بانک مرکزی باید %d روز صبر کنی." % int(state.central_bank_rebuild_days_left)}
	if id in ["fishing_dock","fish_market","fish_processing_plant"] and get_building_count("fish_lake") <= 0:
		return {"ok":false,"message":"ابتدا باید یک دریاچه ماهیگیری بسازی."}
	if id == "fish_processing_plant" and get_building_count("fishing_dock") <= 0:
		return {"ok":false,"message":"برای کارخانه فرآوری، ابتدا اسکله صیادی بساز."}
	var required_land = get_land_size(id)
	if get_land_free() < required_land:
		return {"ok":false,"message":"زمین کافی نداری؛ این ساختمان %d قطعه زمین می‌خواهد و فقط %d قطعه آزاد داری. ابتدا زمین بخر." % [required_land,get_land_free()]}
	if not _spend_money(int(data.cost)):
		return {"ok":false,"message":"پول آزاد خزانه کافی نیست؛ ممکن است بخشی از پول به‌دلیل ظرفیت خزانه قفل شده باشد."}
	var construction_times = {
		"small_house":60,"normal_house":120,"low_apartment":180,"high_apartment":240,"residential_tower":300,
		"small_warehouse":60,"mineral_market":60,"small_park":60,"playground":60,"taxi_station":60,"bus_station":60,
		"grocery_store":60,"bakery":60,"water_tower":60,
		"farm":120,"fish_lake":180,"fishing_dock":120,"fish_market":120,"fish_processing_plant":240,"woodcutter":120,"stone_mine":120,"transport_depot":120,
		"restaurant":120,"office":120,"municipal_bank":120,"power_station":120,
		"medium_warehouse":120,"sawmill":120,"sewage_plant":120,"waste_facility":120,
		"school":180,"clinic":180,"iron_mine":180,"carpenter":180,"sports_center":180,
		"large_warehouse":180,"fire_station":180,"police_station":180,
		"central_bank":240,"factory":240,"hospital":240,"university":300,
		"huge_warehouse":300,"shopping_mall":300,"cultural_center":300
	}
	var location = _assign_building_location(id)
	var location_label = str(location.get("district_name", "منطقه صنعتی خارج شهر"))
	var earned_xp = _building_xp_reward(data)
	var xp_message = _award_xp(earned_xp)
	if construction_times.has(id):
		var seconds = int(construction_times[id])
		state.constructions.append({"id":id,"finish_at":OS.get_unix_time()+seconds,"zone":location.zone,"district_id":location.district_id,"district_name":location.district_name})
		save_game()
		return {"ok":true,"message":data.name+" شروع شد؛ زمان ساخت: %d دقیقه. محل ساخت: %s. هزینه پرداخت شد. +%d تجربه. %s" % [int(ceil(float(seconds)/60.0)),location_label,earned_xp,xp_message]}
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 0
	state.buildings.append({"id":id,"workers":0,"balance":0,"zone":location.zone,"district_id":location.district_id,"district_name":location.district_name})
	var new_index = state.buildings.size() - 1
	if id in ["stone_mine", "iron_mine"]:
		_register_mine(new_index, id)
	_sync_population()
	assign_jobs()
	_update_missions()
	save_game()
	return {"ok":true,"message":data.name+" با موفقیت در %s ساخته شد. +%d تجربه. %s" % [location_label,earned_xp,xp_message]}

func process_constructions():
	var now = OS.get_unix_time()
	var remaining = []
	var completed = []
	for construction in state.get("constructions", []):
		if int(construction.get("finish_at", 0)) > now:
			remaining.append(construction)
			continue
		var id = str(construction.get("id", ""))
		if BUILDINGS.has(id):
			state.buildings.append({"id":id,"workers":0,"balance":0,"zone":str(construction.get("zone","district")),"district_id":str(construction.get("district_id","")),"district_name":str(construction.get("district_name",""))})
			var new_index = state.buildings.size() - 1
			if id in ["stone_mine", "iron_mine"]:
				_register_mine(new_index, id)
			if id == "central_bank":
				state.central_bank_rebuild_days_left = 0
			completed.append(str(BUILDINGS[id].name)+" ("+str(construction.get("district_name","منطقه صنعتی خارج شهر"))+")")
	state["constructions"] = remaining
	if completed.size() > 0:
		_sync_population()
		assign_jobs()
		_update_missions()
		state["last_report"] = "ساخت‌وساز تکمیل شد: " + "، ".join(completed)
		save_game()
		return true
	return false

func get_construction_status():
	var result = []
	var now = OS.get_unix_time()
	for construction in state.get("constructions", []):
		var id = str(construction.get("id", ""))
		if not BUILDINGS.has(id):
			continue
		result.append({"name":str(BUILDINGS[id].name),"remaining":max(0,int(construction.get("finish_at",0))-now)})
	return result

func demolish(index):
	if index < 0 or index >= state.buildings.size():
		return {"ok":false,"message":"ساختمان پیدا نشد."}
	if int(state.buildings[index].get("rented_to", 0)) > 0:
		return {"ok":false,"message":"این ملک شهرداری در قرارداد اجاره است و تا پایان قرارداد قابل تخریب نیست."}
	var id = state.buildings[index].id
	if id == "small_house" and get_building_count(id) <= 1:
		return {"ok":false,"message":"آخرین خانه شهر را نمی‌توان تخریب کرد."}
	state.buildings.remove(index)
	_ensure_building_locations()
	for request_index in range(state.get("business_requests", []).size() - 1, -1, -1):
		var civic_request = state.business_requests[request_index]
		if str(civic_request.get("type", "")) != "rent":
			continue
		var requested_building_index = int(civic_request.get("building_index", -1))
		if requested_building_index == index:
			for citizen_index in range(state.citizens.size()):
				if int(state.citizens[citizen_index].get("id", 0)) == int(civic_request.get("citizen_id", 0)):
					state.citizens[citizen_index]["civic_request_pending"] = false
					state.citizens[citizen_index]["next_civic_request_day"] = int(state.day) + 1
			state.business_requests.remove(request_index)
		elif requested_building_index > index:
			civic_request["building_index"] = requested_building_index - 1
			state.business_requests[request_index] = civic_request
	for business_index in range(state.private_businesses.size()):
		var private_business = state.private_businesses[business_index]
		if bool(private_business.get("rented_municipal", false)):
			var rented_index = int(private_business.get("building_index", -1))
			if rented_index > index:
				private_business["building_index"] = rented_index - 1
				state.private_businesses[business_index] = private_business
	for mine_index in range(state.mines.size() - 1, -1, -1):
		if int(state.mines[mine_index].get("building_index", -1)) == index:
			state.mines.remove(mine_index)
		elif int(state.mines[mine_index].get("building_index", -1)) > index:
			state.mines[mine_index].building_index -= 1
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 7
		var excess = max(0, int(state.money) - get_treasury_capacity())
		if excess > 0:
			state.last_report = "با تخریب بانک مرکزی، %d سکه تا پایان مهلت بازسازی قفل شد." % excess
	_sync_population()
	assign_jobs()
	save_game()
	return {"ok":true,"message":"ساختمان تخریب شد. بازپرداختی انجام نشد."}

func assign_jobs():
	for citizen in state.citizens:
		citizen.job = ""
		citizen.job_building_index = -1
	var workplaces = []
	for i in range(state.buildings.size()):
		if int(state.buildings[i].get("rented_to", 0)) > 0:
			continue
		var data = BUILDINGS.get(state.buildings[i].id, {})
		for slot in range(int(data.get("jobs", 0))):
			workplaces.append(i)
	# The menu-based game has no road coordinates. Assign open job
	# slots in a stable, fair order instead of inventing fake distances.
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		if int(citizen.get("private_job_id", 0)) > 0:
			continue
		if workplaces.empty():
			break
		var building_index = workplaces[0]
		citizen.job_building_index = building_index
		citizen.job = str(state.buildings[building_index].id)
		state.citizens[citizen_index] = citizen
		workplaces.remove(0)

func _workers_for_building(building_index):
	var count = 0
	for citizen in state.citizens:
		if int(citizen.get("job_building_index", -1)) == building_index:
			count += 1
	return count

func _has_mine(building_index):
	for mine in state.mines:
		if int(mine.get("building_index", -1)) == building_index:
			return true
	return false

func _register_mine(building_index, building_id):
	var is_iron = building_id == "iron_mine"
	state.mines.append({
		"building_index": building_index,
		"resource": ("iron_ore" if is_iron else "stone"),
		"active": true,
		"remaining": (150 if is_iron else -1),
		"initial_reserve": (150 if is_iron else -1),
		"extracted": 0
	})

func get_mines():
	return state.get("mines", [])

func refill_iron_mine(mine_index):
	if mine_index < 0 or mine_index >= state.mines.size():
		return {"ok":false,"message":"معدن پیدا نشد."}
	var mine = state.mines[mine_index]
	if str(mine.get("resource", "")) != "iron_ore":
		return {"ok":false,"message":"این معدن نیاز به شارژ سنگ‌آهن ندارد."}
	if int(mine.get("remaining", 0)) > 0:
		return {"ok":false,"message":"ذخیره سنگ‌آهن معدن هنوز تمام نشده است."}
	if not _spend_money(1000):
		return {"ok":false,"message":"برای شارژ معدن به ۱۰۰۰ سکه پول آزاد نیاز داری."}
	mine.remaining = int(mine.get("initial_reserve", 150))
	mine.active = int(mine.remaining) > 0
	state.mines[mine_index] = mine
	save_game()
	return {"ok":true,"message":"ذخیره معدن آهن دوباره شارژ شد."}

func _advance_mines(report):
	for i in range(state.mines.size()):
		var mine = state.mines[i]
		var building_index = int(mine.get("building_index", -1))
		if building_index < 0 or building_index >= state.buildings.size() or _workers_for_building(building_index) <= 0:
			continue
		if not bool(mine.get("active", false)):
			continue
		var resource_id = str(mine.get("resource", ""))
		var required_workers = max(1, int(BUILDINGS.get(str(state.buildings[building_index].get("id", "")), {}).get("jobs", 1)))
		var actual_workers = _workers_for_building(building_index)
		var base_production = (5 if resource_id == "stone" else 3)
		var production = max(1, int(floor(float(base_production) * float(actual_workers) / float(required_workers))))
		production = min(production, get_free_storage())
		if resource_id == "iron_ore":
			production = min(production, int(mine.get("remaining", 0)))
		if production <= 0:
			# A full warehouse pauses extraction without disabling the mine.
			# Production resumes automatically as soon as storage is freed.
			if get_free_storage() <= 0:
				report.append("استخراج معدن موقتاً متوقف شد؛ انبار پر است.")
			else:
				mine.active = false
				if resource_id == "iron_ore":
					report.append("ذخیره معدن آهن تمام شده است؛ برای ادامه آن را شارژ کن.")
			state.mines[i] = mine
			continue
		state.resources[resource_id] = int(state.resources.get(resource_id, 0)) + production
		mine.extracted = int(mine.get("extracted", 0)) + production
		if resource_id == "iron_ore":
			mine.remaining = int(mine.remaining) - production
			if int(mine.remaining) <= 0:
				mine.remaining = 0
				mine.active = false
				report.append("ذخیره معدن آهن تمام شد؛ برای ادامه استخراج آن را با ۱۰۰۰ سکه شارژ کن.")
		report.append("معدن %s واحد %s استخراج کرد." % [production, RESOURCES[resource_id].name])
		state.mines[i] = mine


func _get_service_capacity(need_id):
	var capacity = 0
	for i in range(state.buildings.size()):
		var building_id = str(state.buildings[i].get("id", ""))
		if int(state.buildings[i].get("rented_to", 0)) > 0:
			continue
		var data = BUILDINGS.get(building_id, {})
		if str(data.get("service_need", "")) != need_id:
			continue
		var jobs = int(data.get("jobs", 0))
		if jobs > 0 and _workers_for_building(i) <= 0:
			continue
		capacity += int(data.get("service_capacity", 0))
	for business in state.get("private_businesses", []):
		var private_data = BUILDINGS.get(str(business.get("building_id", "")), {})
		if str(private_data.get("service_need", "")) != need_id:
			continue
		var private_jobs = max(1, int(private_data.get("jobs", 1)))
		var private_workers = business.get("employees", []).size()
		if private_workers > 0:
			capacity += int(round(float(private_data.get("service_capacity", 0)) * float(private_workers) / float(private_jobs)))
	return capacity

func _update_city_services(report):
	var population = max(1, int(state.population))
	var service_state = {}
	var needs = state.get("needs", {})
	var need_ids = ["food","water","power","health","education","safety","leisure","sanitation"]
	var daily_decay = {"food":8,"water":10,"power":4,"health":3,"education":2,"safety":2,"leisure":4,"sanitation":3}
	var total_need = 0
	for need_id in need_ids:
		var capacity = _get_service_capacity(need_id)
		if need_id == "food":
			var food_limit = int(floor(float(state.resources.get("food",0)) * 100.0 / float(population)))
			capacity = min(capacity, food_limit)
		var coverage = int(clamp(round(float(capacity) * 100.0 / float(population)), 0, 100))
		service_state[need_id] = coverage
		var current = int(needs.get(need_id, 60))
		var decay = int(daily_decay.get(need_id, 2))
		var recovery = int(round(float(coverage) * 0.12))
		needs[need_id] = int(clamp(current - decay + recovery, 0, 100))
	# A staffed police station provides a modest night-patrol safety benefit.
	var night_patrol_active = false
	for building_index in range(state.buildings.size()):
		if str(state.buildings[building_index].get("id", "")) == "police_station" and _workers_for_building(building_index) > 0:
			night_patrol_active = true
			break
	if night_patrol_active:
		needs["safety"] = int(min(100, int(needs.get("safety", 0)) + 2))
		report.append("گشت شبانه کلانتری فعال بود؛ امنیت شهر ۲ واحد بهبود یافت.")
	total_need = 0
	for need_id in need_ids:
		total_need += int(needs.get(need_id, 0))
	state.needs = needs
	state.services = service_state
	var average = int(round(float(total_need) / float(need_ids.size())))
	state.satisfaction = average
	if average < 30:
		state.reputation = max(0, int(state.reputation) - 2)
	elif average < 45:
		state.reputation = max(0, int(state.reputation) - 1)
	elif average >= 80:
		state.reputation = min(100, int(state.reputation) + 1)
	var names = {"food":"خوراک","water":"آب","power":"برق","health":"سلامت","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت"}
	var summaries = []
	for need_id in need_ids:
		summaries.append("%s %d%%" % [names[need_id], int(needs[need_id])])
	report.append("نیاز شهروندان: " + " | ".join(summaries))
	report.append("رضایت میانگین: %d از ۱۰۰" % average)

func _sync_missions():
	if typeof(state.get("missions", null)) != TYPE_ARRAY:
		state["missions"] = []
	# Remove obsolete missions from older tutorial versions.
	var valid_ids = []
	for definition in MISSION_DEFINITIONS:
		valid_ids.append(str(definition.id))
	var saved_by_id = {}
	for saved_mission in state.missions:
		var saved_id = str(saved_mission.get("id", ""))
		if saved_id in valid_ids:
			saved_by_id[saved_id] = saved_mission
	# Keep old progress but always restore the canonical main-then-side order.
	state.missions = []
	for definition in MISSION_DEFINITIONS:
		var mission_id = str(definition.id)
		if saved_by_id.has(mission_id):
			var saved = saved_by_id[mission_id]
			saved["type"] = str(definition.get("type", "main"))
			state.missions.append(saved)
		else:
			state.missions.append({"id":mission_id,"type":definition.get("type","main"),"progress":0,"completed":false,"claimed":false,"unlocked":str(definition.get("type","main")) == "side"})
	_update_missions()

func _get_mission_progress(mission_id):
	match mission_id:
		"buy_land_tutorial":
			return max(0, int(state.get("land_owned", 10)) - 10)
		"build_house_tutorial":
			return max(0, get_building_count("small_house") - 2)
		"build_farm_tutorial":
			return get_building_count("farm")
		"hire_worker_tutorial":
			return get_employed_count()
		"population_tutorial":
			return int(state.population)
		"market_tutorial":
			return get_building_count("mineral_market")
		"transport_tutorial":
			return get_building_count("transport_depot")
		"level_tutorial":
			return int(state.level)
		"side_population":
			return int(state.population)
		"side_reserve":
			return int(state.get("money", 0))
		"main_water", "side_water":
			return get_building_count("water_tower")
		"main_power", "side_power":
			return get_building_count("power_station")
		"main_storage":
			return get_building_count("medium_warehouse")
		"main_school", "side_school":
			return get_building_count("school")
		"main_clinic", "side_clinic":
			return get_building_count("clinic")
		"main_wood", "side_wood":
			return get_building_count("woodcutter")
		"main_stone", "side_stone_mine":
			return get_building_count("stone_mine")
		"main_sawmill", "side_sawmill":
			return get_building_count("sawmill")
		"main_carpenter", "side_carpenter":
			return get_building_count("carpenter")
		"main_city_bank", "side_bank":
			return get_building_count("municipal_bank")
		"main_central_bank":
			return get_building_count("central_bank")
		"main_level_five":
			return int(state.level)
		"side_sewage":
			return get_building_count("sewage_plant")
		"side_waste":
			return get_building_count("waste_facility")
		"side_park":
			return get_building_count("small_park")
		"side_playground":
			return get_building_count("playground")
		"side_sports":
			return get_building_count("sports_center")
		"side_hospital":
			return get_building_count("hospital")
		"side_police":
			return get_building_count("police_station")
		"side_fire":
			return get_building_count("fire_station")
		"side_university":
			return get_building_count("university")
		"side_cultural":
			return get_building_count("cultural_center")
		"side_iron_mine":
			return get_building_count("iron_mine")
		"side_fish_lake":
			return get_building_count("fish_lake")
		"side_fishing_dock":
			return get_building_count("fishing_dock")
		"side_fish_market":
			return get_building_count("fish_market")
		"side_fish_processing":
			return get_building_count("fish_processing_plant")
		"side_grocery":
			return get_building_count("grocery_store")
		"side_bakery":
			return get_building_count("bakery")
		"side_restaurant":
			return get_building_count("restaurant")
		"side_office":
			return get_building_count("office")
		"time_login_five", "time_login_seven":
			return int(state.get("login_streak", 0))
		"time_play_three", "time_play_five":
			return int(state.get("consecutive_active_game_days", 0))
		"side_loan_paid":
			var paid_loans = 0
			for loan in state.get("bank_loans", []):
				if str(loan.get("status", "")) == "paid":
					paid_loans += 1
			return paid_loans
		"side_export_eight":
			return int(state.get("trade_exported_units_total", 0))
		"side_collect_profit":
			return int(state.get("business_profit_collections_total", 0))
		"side_positive_cashflow":
			return int(state.get("profitable_day_streak", 0))
		"side_high_satisfaction":
			return int(state.get("high_satisfaction_day_streak", 0))
		"side_expand_districts":
			return int(state.get("districts", []).size())
		"side_private_tax":
			var private_tax_total = 0
			for business in state.get("private_businesses", []):
				private_tax_total += int(business.get("tax_paid_total", 0))
			return private_tax_total
	return 0

func _update_missions():
	# All active missions form one guided sequence: only the first unclaimed
	# mission is visible. Claiming its reward unlocks the next mission.
	var previous_claimed = true
	for i in range(state.missions.size()):
		var mission = state.missions[i]
		var mission_id = str(mission.get("id", ""))
		var definition = {}
		for candidate in MISSION_DEFINITIONS:
			if str(candidate.id) == mission_id:
				definition = candidate
				break
		if definition.empty():
			continue
		if bool(definition.get("legacy", false)):
			# Preserve unclaimed rewards from older versions without adding
			# archived missions back into the new progression.
			mission["unlocked"] = bool(mission.get("completed", false)) and not bool(mission.get("claimed", false))
			state.missions[i] = mission
			continue
		mission["unlocked"] = previous_claimed
		var progress = min(int(definition.goal), _get_mission_progress(mission_id))
		mission["progress"] = progress
		mission["completed"] = progress >= int(definition.goal)
		previous_claimed = bool(mission.get("claimed", false))
		state.missions[i] = mission

func get_missions():
	_update_missions()
	return state.get("missions", [])

func claim_mission(mission_index):
	if mission_index < 0 or mission_index >= state.missions.size():
		return {"ok":false,"message":"ماموریت پیدا نشد."}
	var mission = state.missions[mission_index]
	if not bool(mission.get("unlocked", false)):
		return {"ok":false,"message":"ابتدا مرحله قبلی آموزش را کامل کن."}
	if not bool(mission.get("completed", false)):
		return {"ok":false,"message":"این ماموریت هنوز کامل نشده است."}
	if bool(mission.get("claimed", false)):
		return {"ok":false,"message":"پاداش این ماموریت قبلاً دریافت شده است."}
	var reward = 0
	var xp_reward = 0
	for definition in MISSION_DEFINITIONS:
		if str(definition.id) == str(mission.get("id", "")):
			reward = int(definition.reward)
			xp_reward = int(definition.get("xp", 0))
			break
	var treasury_room = max(0, get_treasury_capacity() - int(state.get("money", 0)))
	if treasury_room < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت کامل جایزه کافی نیست؛ ابتدا مقداری پول خرج کن یا ظرفیت خزانه را افزایش بده."}
	var accepted = _add_money(reward)
	if accepted < reward:
		return {"ok":false,"message":"جایزه کامل به خزانه واریز نشد؛ مأموریت همچنان آماده دریافت می‌ماند."}
	mission.claimed = true
	state.missions[mission_index] = mission
	var xp_message = _award_xp(xp_reward)
	_update_missions()
	save_game()
	return {"ok":true,"message":"پاداش دریافت شد: %d از %d سکه و %d تجربه. %s" % [accepted, reward, xp_reward, xp_message]}


func get_civic_overview():
	return CitizenSociety.new().get_overview(self)

func resolve_civic_request(request_id, approved):
	return CitizenSociety.new().resolve_request(self, int(request_id), bool(approved))

func adjust_business_tax(delta):
	return CitizenSociety.new().adjust_tax_rate(self, int(delta))

func adjust_business_permit_fee(delta):
	return CitizenSociety.new().adjust_permit_fee(self, int(delta))

func adjust_private_land_price(delta):
	return CitizenSociety.new().adjust_private_land_price(self, int(delta))

func _building_xp_reward(data):
	# Bigger and more expensive projects grant more experience, with a sensible cap.
	return int(clamp(5 + int(int(data.get("cost", 0)) / 500), 5, 25))

func _award_xp(amount):
	var previous_level = int(state.get("level", 1))
	state.xp = int(state.get("xp", 0)) + max(0, int(amount))
	var levels_gained = 0
	while state.xp >= get_xp_required_for_next_level():
		state.xp -= get_xp_required_for_next_level()
		state.level += 1
		levels_gained += 1
	_update_missions()
	if levels_gained > 0:
		var newly_unlocked = []
		for building_id in BUILDINGS.keys():
			var definition = BUILDINGS[building_id]
			var required_level = int(definition.get("level_unlock", 1))
			if required_level > previous_level and required_level <= int(state.level) and int(state.population) >= int(definition.get("unlock", 0)):
				newly_unlocked.append(str(definition.name))
		var message = "سطح شهر به %d رسید!" % int(state.level)
		if newly_unlocked.size() > 0:
			message += " ساختمان‌های تازه: " + "، ".join(newly_unlocked)
		return message
	return "پیشرفت سطح: %d از %d" % [int(state.xp), get_xp_required_for_next_level()]

func get_xp_required_for_next_level():
	return max(100, int(state.get("level", 1)) * 100)

func get_daily_xp_gain():
	# XP grows with city size, but is deliberately capped so a large city
	# cannot skip many levels in a single day.
	var population_bonus = int(sqrt(float(max(0, int(state.get("population", 0))))) * 2.0)
	var building_bonus = min(10, state.get("buildings", []).size())
	return int(clamp(5 + population_bonus + building_bonus, 5, 60))

func collect_offline_income():
	var pending = max(0, int(state.get("pending_offline_income", 0)))
	if pending <= 0:
		return {"ok":false,"amount":0,"message":"درآمد آفلاین قابل دریافتی وجود ندارد."}
	var accepted = _add_money(pending)
	state["pending_offline_income"] = pending - accepted
	if int(state.pending_offline_income) <= 0:
		state["pending_offline_days"] = 0
	save_game()
	if accepted <= 0:
		return {"ok":false,"amount":0,"message":"ظرفیت خزانه پر است؛ ابتدا ظرفیت خزانه را افزایش بده."}
	return {"ok":true,"amount":accepted,"message":"درآمد آفلاین دریافت شد: %d سکه." % accepted}

func _calculate_transport_income(report):
	var station_income = 0
	var road_income = 0
	# Daily passenger demand includes the 3-minute night period, when fewer residents travel.
	var passenger_pool = max(0, int(floor(float(state.get("population", 0)) * 0.6)))
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var building_id = str(building.get("id", ""))
		var workers = _workers_for_building(building_index)
		if workers <= 0:
			continue
		if building_id == "taxi_station" or building_id == "bus_station":
			var passenger_capacity = workers * (5 if building_id == "taxi_station" else 9)
			var passengers = min(passenger_pool, passenger_capacity)
			var fare = 5 if building_id == "taxi_station" else 3
			var revenue = passengers * fare
			passenger_pool -= passengers
			station_income += revenue
			if revenue > 0:
				var station_name = str(BUILDINGS[building_id].name)
				report.append("%s: جابه‌جایی %d مسافر و درآمد %d سکه." % [station_name, passengers, revenue])
	if get_building_count("transport_depot") > 0:
		var active_trucks = get_transport_truck_count()
		var depot_income = active_trucks * 25
		station_income += depot_income
		if depot_income > 0:
			report.append("پایانه حمل‌ونقل: خدمات %d کامیون فعال، درآمد %d سکه." % [active_trucks, depot_income])
	var freight_units = int(state.get("transport_used_today", 0))
	if freight_units > 0:
		road_income = freight_units * max(1, int(state.get("road_level", 1)))
		report.append("عوارض جاده‌ای برای عبور %d واحد بار: %d سکه." % [freight_units, road_income])
	return {"station_income":station_income, "road_income":road_income}


func get_daily_development_support():
	# Temporary development support prevents a young city from becoming insolvent.
	# It tapers off with level and only tops the treasury up toward 3,000 coins.
	var support_by_level = {1:250, 2:180, 3:100}
	var level = int(state.get("level", 1))
	var level_support = int(support_by_level.get(level, 0))
	var treasury_gap = max(0, 3000 - int(state.get("money", 0)))
	return min(level_support, treasury_gap)

func end_day(is_offline=false):
	var report = []
	var treasury_opening = int(state.get("money", 0))
	assign_jobs()
	var development_support_due = get_daily_development_support()
	var development_support_paid = _add_money(development_support_due)
	if development_support_paid > 0:
		report.append("کمک‌هزینه توسعه شهر: %d سکه." % development_support_paid)
	var total_wages = 0
	var paid_wages = 0
	var treasury_for_payroll = get_available_money()
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		if str(citizen.get("job", "")) == "":
			continue
		var wage = int(BUILDINGS.get(citizen.job, {}).get("wage", 0))
		var wallet_room = max(0, 500 - int(citizen.get("wallet", 0)))
		var payable_wage = min(wage, wallet_room)
		total_wages += payable_wage
		var payment = min(payable_wage, treasury_for_payroll)
		citizen.wallet = int(citizen.get("wallet", 0)) + payment
		state.citizens[citizen_index] = citizen
		treasury_for_payroll -= payment
		paid_wages += payment
	state.money = int(state.money) - paid_wages
	var fleet_maintenance = get_fleet_maintenance()
	var road_maintenance = get_road_maintenance()
	var maintenance_due = fleet_maintenance + road_maintenance
	var maintenance_paid = min(maintenance_due, get_available_money())
	state.money = int(state.money) - maintenance_paid
	if maintenance_paid < maintenance_due:
		state.reputation = max(0, state.reputation - 1)
		report.append("هزینه نگهداری ناوگان و جاده کامل پرداخت نشد: %d از %d سکه." % [maintenance_paid,maintenance_due])
	else:
		report.append("نگهداری ناوگان و جاده: %d سکه." % maintenance_paid)
	if paid_wages < total_wages:
		state.reputation = max(0, state.reputation - 3)
		report.append("کسری حقوق: %d از %d سکه پرداخت شد." % [paid_wages,total_wages])
	else:
		report.append("حقوق روزانه به کیف پول کارکنان واریز شد: "+str(paid_wages)+" سکه.")

	_advance_mines(report)
	# Forest regrowth is gradual and capped; logging consumes actual trees.
	state.forest_trees = min(100, int(state.forest_trees) + 2)
	var tax_income = int(state.population) * 5
	var business_income_total = 0
	var resource_income_total = 0
	var citizen_market = _process_citizen_purchases(report)
	var consumer_tax_income = int(citizen_market.tax)
	var income = tax_income + consumer_tax_income
	var transport_income = _calculate_transport_income(report)
	var station_income = int(transport_income.station_income)
	var road_income = int(transport_income.road_income)
	income += station_income + road_income
	if tax_income > 0:
		report.append("مالیات شهری دریافت شد: "+str(tax_income)+" سکه.")
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var data = BUILDINGS.get(building.id, {})
		var workers = _workers_for_building(building_index)
		var required_workers = int(data.get("jobs", 0))
		if required_workers > 0 and workers == 0:
			continue
		# Business revenue scales with actual staffing, preventing a partly
		# staffed large business from earning its full theoretical revenue.
		var business_income = int(data.get("daily_revenue", 0))
		if business_income > 0 and required_workers > 0:
			business_income = int(round(float(business_income) * float(workers) / float(required_workers)))
		if str(building.id) == "fish_market":
			var fish_needed = max(1, int(ceil(2.0 * float(workers) / float(max(1, required_workers)))))
			if int(state.resources.get("fish", 0)) < fish_needed:
				business_income = 0
				report.append("بازار ماهی امروز فروش نداشت؛ ماهی تازه کافی در انبار نیست.")
			else:
				state.resources["fish"] = int(state.resources.get("fish", 0)) - fish_needed
		if business_income > 0:
			income += business_income
			business_income_total += business_income
			report.append(data.name+" درآمد داشت: "+str(business_income)+" سکه.")

		var output = str(data.get("output", ""))
		if output == "" or workers == 0:
			continue
		var input = str(data.get("input", ""))
		var amount = int(data.get("amount", 0))
		if required_workers > 0:
			amount = max(1, int(floor(float(amount) * float(workers) / float(required_workers))))
		var output_rule = get_storage_rule(output)
		if int(state.resources.get(output,0)) < int(output_rule.get("minimum",10)) and str(output_rule.get("low_action","market")) == "factory":
			amount = int(ceil(float(amount) * 1.5))
		if str(building.id) == "woodcutter" and int(state.forest_trees) <= 0:
			report.append("چوب‌بری متوقف شد؛ جنگل برای رشد دوباره درخت‌ها به زمان نیاز دارد.")
			continue
		var scaled_input_amount = int(data.get("input_amount", 0))
		if input != "" and required_workers > 0:
			scaled_input_amount = max(1, int(ceil(float(scaled_input_amount) * float(workers) / float(required_workers))))
		if input != "":
			if int(state.resources.get(input, 0)) < scaled_input_amount:
				continue
		if get_free_storage() < amount:
			continue
		# Consume only the inputs required for the staffed production level.
		if input != "":
			state.resources[input] = int(state.resources.get(input, 0)) - scaled_input_amount
		if str(building.id) == "woodcutter":
			var felled = min(int(state.forest_trees), amount)
			state.forest_trees -= felled
			amount = felled
			if amount <= 0:
				continue
		state.resources[output] = int(state.resources.get(output, 0)) + amount
		report.append(data.name+" تولید کرد: "+str(amount)+" "+RESOURCES[output].name+".")

	# Apply each warehouse threshold after today's production.
	var treasury_before_storage_rules = int(state.get("money", 0))
	for storage_resource_id in RESOURCES.keys():
		var storage_result = apply_storage_rule(str(storage_resource_id), false)
		if bool(storage_result.get("ok",false)) and str(storage_result.get("message","")).find("خریداری شد") >= 0:
			report.append(str(storage_result.message))
	var storage_rule_cashflow = int(state.get("money", 0)) - treasury_before_storage_rules

	var has_market = get_building_count("mineral_market") > 0
	if has_market:
		for id in RESOURCES.keys():
			var reserve = _get_reserve(id)
			var surplus = max(0, int(state.resources.get(id, 0)) - reserve)
			var market_room = max(0, 100 - int(state.market_stock.get(id, 0)))
			var unit_price = get_market_price(id, "sell")
			var treasury_room_for_sales = max(0, get_treasury_capacity() - int(state.money) - income)
			var affordable_sale = int(floor(float(treasury_room_for_sales) / float(unit_price)))
			var sell_amount = min(min(surplus, market_room), min(10, affordable_sale))
			if sell_amount > 0:
				state.resources[id] -= sell_amount
				state.market_stock[id] = int(state.market_stock.get(id, 0)) + sell_amount
				var revenue = sell_amount * unit_price
				income += revenue
				resource_income_total += revenue
				report.append(str(sell_amount)+" واحد "+RESOURCES[id].name+" فروخته شد؛ درآمد: "+str(revenue)+" سکه.")
	# Transfer business profits automatically, but preserve any amount the treasury cannot accept.
	var automatic_business_profit = 0
	for profit_index in range(state.buildings.size()):
		var profit_building = state.buildings[profit_index]
		automatic_business_profit += max(0, int(profit_building.get("balance", 0)))
	if automatic_business_profit > 0:
		income += automatic_business_profit
	var accepted_income = _add_money(income)
	var bank_repayment_paid = _process_bank_day(report)
	var non_business_income = max(0, income - automatic_business_profit)
	var business_profit_remaining = min(automatic_business_profit, max(0, accepted_income - min(accepted_income, non_business_income)))
	var automatic_business_profit_transferred = business_profit_remaining
	for profit_index in range(state.buildings.size()):
		if business_profit_remaining <= 0:
			break
		var profit_building = state.buildings[profit_index]
		var pending_profit = max(0, int(profit_building.get("balance", 0)))
		if pending_profit <= 0:
			continue
		var transferred = min(pending_profit, business_profit_remaining)
		profit_building.balance = pending_profit - transferred
		state.buildings[profit_index] = profit_building
		business_profit_remaining -= transferred
	if automatic_business_profit_transferred > 0:
		state["business_profit_collections_total"] = int(state.get("business_profit_collections_total", 0)) + 1
		report.append("سود کسب‌وکارها به‌صورت خودکار به خزانه منتقل شد: %d سکه." % automatic_business_profit_transferred)
	if automatic_business_profit_transferred < automatic_business_profit:
		report.append("به‌دلیل پر بودن ظرفیت خزانه، %d سکه سود در حساب کسب‌وکارها باقی ماند." % (automatic_business_profit - automatic_business_profit_transferred))
	if accepted_income < income:
		report.append("ظرفیت خزانه پر است؛ %d سکه از درآمد امروز دریافت نشد." % (income - accepted_income))
	state.last_economy = {
		"tax_income": tax_income,
		"consumer_tax_income": consumer_tax_income,
		"consumer_spending": int(citizen_market.spending),
		"consumer_business_revenue": int(citizen_market.business_revenue),
		"consumer_buyers": int(citizen_market.buyers),
		"food_units_consumed": int(citizen_market.food_units),
		"food_stock": int(state.resources.get("food",0)),
		"business_income": business_income_total,
		"development_support": development_support_paid,
		"automatic_business_profit": automatic_business_profit_transferred,
		"resource_income": resource_income_total,
		"storage_rule_cashflow": storage_rule_cashflow,
		"station_income": station_income,
		"road_income": road_income,
		"gross_income": income + development_support_paid,
		"accepted_income": accepted_income + development_support_paid,
		"wages_due": total_wages,
		"wages_paid": paid_wages,
		"fleet_maintenance": fleet_maintenance,
		"road_maintenance": road_maintenance,
		"maintenance_paid": maintenance_paid,
		"bank_repayment": bank_repayment_paid,
		"net_cashflow": accepted_income + development_support_paid - paid_wages - maintenance_paid - bank_repayment_paid
	}
	var total_accepted_income = accepted_income + development_support_paid
	for restock_id in RESOURCES.keys():
		state.market_stock[restock_id] = min(100, int(state.market_stock.get(restock_id, 0)) + 5)
	_refresh_trade_capacity()

	_process_citizen_recruitment(report)
	var citizen_economy = CitizenSociety.new().process_day(self, report)
	var private_tax_accepted = int(citizen_economy.get("private_business_tax", 0))
	var citizen_loan_repayments = int(citizen_economy.get("citizen_loan_repayments", 0))
	var citizen_loan_disbursements = int(citizen_economy.get("citizen_loan_disbursements", 0))
	state.last_economy["private_business_tax"] = private_tax_accepted
	state.last_economy["citizen_loan_repayments"] = citizen_loan_repayments
	state.last_economy["citizen_loan_disbursements"] = citizen_loan_disbursements
	state.last_economy["gross_income"] = int(state.last_economy.get("gross_income", 0)) + private_tax_accepted + citizen_loan_repayments
	state.last_economy["accepted_income"] = int(state.last_economy.get("accepted_income", 0)) + private_tax_accepted + citizen_loan_repayments
	if not has_central_bank() and int(state.central_bank_rebuild_days_left) > 0:
		state.central_bank_rebuild_days_left -= 1
		if int(state.central_bank_rebuild_days_left) == 0:
			var before = int(state.money)
			state.money = min(int(state.money), get_treasury_capacity())
			var destroyed = before - int(state.money)
			if destroyed > 0:
				report.append("مهلت بازسازی بانک مرکزی تمام شد؛ %d سکه مازاد از خزانه حذف شد." % destroyed)
			else:
				report.append("مهلت بازسازی بانک مرکزی تمام شد؛ ظرفیت عادی خزانه فعال شد.")
	_update_city_services(report)
	if not is_offline:
		var active_seconds = int(state.get("active_play_seconds_today", 0))
		if active_seconds >= 300:
			state["consecutive_active_game_days"] = int(state.get("consecutive_active_game_days", 0)) + 1
		else:
			state["consecutive_active_game_days"] = 0
		state["active_play_seconds_today"] = 0.0
	else:
		# An offline day breaks the active-play streak and cannot bank minutes.
		state["active_play_seconds_today"] = 0.0
		state["consecutive_active_game_days"] = 0
	state.day += 1
	state.transport_used_today = 0
	_process_trade_arrivals(report)
	_dispatch_import_contracts(report)
	# Neighboring cities replenish their export inventories gradually.
	for city_id in TRADE_CITIES.keys():
		for resource_id in RESOURCES.keys():
			var city_stock = state.city_export_stock.get(city_id, TRADE_CITIES[city_id].supply)
			city_stock[resource_id] = min(int(TRADE_CITIES[city_id].supply.get(resource_id,0)), int(city_stock.get(resource_id,0)) + max(1,int(TRADE_CITIES[city_id].supply.get(resource_id,0) / 5)))
			state.city_export_stock[city_id] = city_stock
	var xp_earned = get_daily_xp_gain()
	var previous_level = int(state.level)
	state.xp += xp_earned
	var levels_gained = 0
	while state.xp >= get_xp_required_for_next_level():
		state.xp -= get_xp_required_for_next_level()
		state.level += 1
		levels_gained += 1
	report.append("امتیاز تجربه امروز: %d | پیشرفت سطح: %d از %d." % [xp_earned, int(state.xp), get_xp_required_for_next_level()])
	if levels_gained > 0:
		report.append("تبریک! شهر %d سطح ارتقا یافت؛ سطح فعلی: %d." % [levels_gained, state.level])
		var newly_unlocked = []
		for building_id in BUILDINGS.keys():
			var definition = BUILDINGS[building_id]
			var required_level = int(definition.get("level_unlock", 1))
			if required_level > previous_level and required_level <= int(state.level) and int(state.population) >= int(definition.get("unlock", 0)):
				newly_unlocked.append(str(definition.name))
		if newly_unlocked.size() > 0:
			report.append("ساختمان‌های تازه در دسترس: " + "، ".join(newly_unlocked))
	_update_missions()
	state.last_economy["treasury_opening"] = treasury_opening
	state.last_economy["treasury_closing"] = int(state.get("money", 0))
	state.last_economy["net_cashflow"] = int(state.get("money", 0)) - treasury_opening
	if int(state.last_economy.net_cashflow) > 0:
		state["profitable_day_streak"] = int(state.get("profitable_day_streak", 0)) + 1
	else:
		state["profitable_day_streak"] = 0
	if int(state.get("satisfaction", 0)) >= 75:
		state["high_satisfaction_day_streak"] = int(state.get("high_satisfaction_day_streak", 0)) + 1
	else:
		state["high_satisfaction_day_streak"] = 0
	_update_missions()
	report.append("خلاصه مالی: درآمد ثبت‌شده %d | حقوق %d | نگهداری %d | اقساط شهرداری %d | اقساط شهروندان %d | وام پرداختی به شهروندان %d | تغییر خالص خزانه %d سکه." % [int(state.last_economy.accepted_income), paid_wages, maintenance_paid, bank_repayment_paid, citizen_loan_repayments, citizen_loan_disbursements, int(state.last_economy.net_cashflow)])
	for report_message in report:
		add_report_event(str(report_message), false)
	state.last_report = "\n".join(report)
	save_game()
	return state.last_report

func _process_citizen_purchases(report):
	var shops = []
	var total_weight = 0
	for i in range(state.buildings.size()):
		var building = state.buildings[i]
		var data = BUILDINGS.get(str(building.get("id", "")), {})
		if str(data.get("service_need", "")) != "food":
			continue
		var required = int(data.get("jobs", 0))
		var workers = _workers_for_building(i)
		if required <= 0 or workers <= 0:
			continue
		var weight = int(max(1, int(data.get("service_capacity", 1)) * workers / required))
		shops.append({"index":i,"weight":weight})
		total_weight += weight
	if shops.empty() or total_weight <= 0:
		return {"spending":0,"tax":0,"buyers":0,"business_revenue":0,"food_units":0}
	var spending = 0
	var sales_tax = 0
	var buyers = 0
	var business_revenue_total = 0
	var food_units = 0
	var food_need = int(state.get("needs", {}).get("food", 60))
	var food_stock = int(state.resources.get("food",0))
	var citizen_count = state.citizens.size()
	var rotation_count = int(max(1, citizen_count))
	var start_index = int(state.day) % rotation_count
	for step in range(citizen_count):
		var citizen_index = int((start_index + step) % rotation_count)
		var citizen = state.citizens[citizen_index]
		var wallet = int(citizen.get("wallet", 0))
		var demand_units = 1 + int(floor(float(100 - food_need) / 50.0))
		var affordable_units = int(floor(float(wallet) / 10.0))
		var purchase_units = min(min(demand_units, affordable_units), food_stock)
		if purchase_units <= 0:
			continue
		var purchase = purchase_units * 10
		food_stock -= purchase_units
		var ticket = (int(citizen.get("id", citizen_index + 1)) + int(state.day)) % total_weight
		var selected_index = int(shops[0].index)
		for shop in shops:
			if ticket < int(shop.weight):
				selected_index = int(shop.index)
				break
			ticket -= int(shop.weight)
		var tax = int(floor(float(purchase) * 0.10))
		var business_revenue = purchase - tax
		state.buildings[selected_index].balance = int(state.buildings[selected_index].get("balance", 0)) + business_revenue
		citizen.wallet = wallet - purchase
		state.citizens[citizen_index] = citizen
		spending += purchase
		sales_tax += tax
		business_revenue_total += business_revenue
		food_units += purchase_units
		buyers += 1
	state.resources.food = food_stock
	if buyers > 0:
		report.append("شهروندان %d خرید خوراک انجام دادند؛ %d واحد غذا مصرف شد و %d سکه گردش مالی ایجاد کرد." % [buyers,food_units,spending])
	elif food_stock <= 0:
		report.append("ذخیره غذا تمام شده است؛ شهروندان از فروشگاه‌ها خریدی انجام ندادند.")
	return {"spending":spending,"tax":sales_tax,"buyers":buyers,"business_revenue":business_revenue_total,"food_units":food_units}
func collect_business_profit(building_index):
	if building_index < 0 or building_index >= state.buildings.size():
		return {"ok":false,"message":"ساختمان پیدا نشد."}
	var building = state.buildings[building_index]
	var balance = max(0, int(building.get("balance", 0)))
	if balance <= 0:
		return {"ok":false,"message":"این کسب‌وکار هنوز سود قابل برداشت ندارد."}
	var accepted = _add_money(balance)
	if accepted <= 0:
		return {"ok":false,"message":"ظرفیت خزانه پر است؛ فعلاً امکان برداشت سود وجود ندارد."}
	building.balance = balance - accepted
	state.buildings[building_index] = building
	state["business_profit_collections_total"] = int(state.get("business_profit_collections_total", 0)) + 1
	_update_missions()
	save_game()
	return {"ok":true,"message":"%d سکه سود به خزانه منتقل شد." % accepted}

func _workers_for(id):
	var count = 0
	for citizen in state.citizens:
		if citizen.job == id:
			count += 1
	return count

func _get_reserve(id):
	if id in ["stone","iron_ore"]:
		return STORAGE_RESERVE
	if id == "food":
		return max(0, int(state.get("population",0)) * 2)
	return int(FORESTRY_RESERVES.get(id, 0))



func get_import_price(city_id, resource_id):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id):
		return 0
	var city = TRADE_CITIES[city_id]
	var stock = int(state.get("city_export_stock", {}).get(city_id, city.supply).get(resource_id, 0))
	if stock <= 0:
		return 0
	var base = int(RESOURCES[resource_id].buy)
	var scarcity = 1.0 + max(0.0, 1.0 - float(stock) / max(1.0, float(city.supply.get(resource_id, 1)))) * 0.35
	return max(1, int(round(float(base) * float(city.price_factor) * scarcity)))

func get_import_cities():
	return TRADE_CITIES

func get_import_price_label(city_id, resource_id):
	var price = get_import_price(city_id, resource_id)
	if price <= 0:
		return "ناموجود"
	return str(price)+" سکه/واحد"

func order_import(city_id, resource_id, requested_amount):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id) or requested_amount <= 0:
		return {"ok":false,"message":"سفارش واردات نامعتبر است."}
	var city = TRADE_CITIES[city_id]
	var city_stock = state.city_export_stock.get(city_id, city.supply)
	var available = int(city_stock.get(resource_id, 0))
	var amount = min(min(int(requested_amount), available), get_transport_capacity_remaining())
	if amount <= 0:
		return {"ok":false,"message":"کالا یا ظرفیت کامیون‌های آزاد برای واردات کافی نیست؛ پایانه حمل‌ونقل و نیروی کار آن را بررسی کن."}
	if get_free_storage() < amount:
		return {"ok":false,"message":"برای محموله فضای کافی در انبار نداری."}
	var unit_price = get_import_price(city_id, resource_id)
	var shipping_fee = max(1, int(ceil(float(amount * unit_price) * 0.10)))
	var total_cost = amount * unit_price + shipping_fee
	if get_available_money() < total_cost:
		return {"ok":false,"message":"پول آزاد خزانه برای خرید و کرایه حمل کافی نیست."}
	_spend_money(total_cost)
	city_stock[resource_id] = available - amount
	state.city_export_stock[city_id] = city_stock
	var shipment = {"id":_next_shipment_id(),"city_id":city_id,"resource_id":resource_id,"amount":amount,"arrival_day":int(state.day)+int(city.travel_days),"paid":total_cost}
	state.trade_shipments.append(shipment)
	state.transport_used_today = int(state.get("transport_used_today",0)) + amount
	state.last_import_report = "%d واحد %s از %s سفارش داده شد؛ تحویل روز %d؛ هزینه با حمل: %d سکه." % [amount,RESOURCES[resource_id].name,city.name,int(shipment.arrival_day),total_cost]
	save_game()
	return {"ok":true,"message":state.last_import_report}

func _next_shipment_id():
	var highest = 0
	for shipment in state.trade_shipments:
		highest = max(highest, int(shipment.get("id",0)))
	return highest + 1

func create_import_contract(city_id, resource_id, daily_amount, duration_days):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id):
		return {"ok":false,"message":"شهر یا کالای قرارداد معتبر نیست."}
	if get_transport_truck_count() <= 0:
		return {"ok":false,"message":"برای قرارداد واردات ابتدا پایانه حمل‌ونقل بساز و حداقل ۲ کارمند به ناوگان اختصاص بده."}
	if daily_amount > get_transport_daily_capacity():
		return {"ok":false,"message":"مقدار روزانه قرارداد از ظرفیت ناوگان بیشتر است؛ کامیون یا سطح جاده را افزایش بده."}
	if daily_amount < 1 or daily_amount > 10 or duration_days < 3 or duration_days > 30:
		return {"ok":false,"message":"قرارداد باید روزانه ۱ تا ۱۰ واحد و بین ۳ تا ۳۰ روز باشد."}
	for contract in state.import_contracts:
		if bool(contract.get("active",true)) and str(contract.get("city_id","")) == city_id and str(contract.get("resource_id","")) == resource_id:
			return {"ok":false,"message":"برای این کالا از این شهر قرارداد فعالی داری."}
	var contract = {"id":_next_contract_id(),"city_id":city_id,"resource_id":resource_id,"daily_amount":int(daily_amount),"days_left":int(duration_days),"active":true,"created_day":int(state.day)}
	state.import_contracts.append(contract)
	save_game()
	return {"ok":true,"message":"قرارداد %d روزه ثبت شد؛ سفارش‌ها روزانه با بررسی پول و فضای انبار ارسال می‌شوند." % int(duration_days)}

func _next_contract_id():
	var highest = 0
	for contract in state.import_contracts:
		highest = max(highest, int(contract.get("id",0)))
	return highest + 1

func cancel_import_contract(contract_index):
	if contract_index < 0 or contract_index >= state.import_contracts.size():
		return {"ok":false,"message":"قرارداد پیدا نشد."}
	state.import_contracts[contract_index]["active"] = false
	save_game()
	return {"ok":true,"message":"قرارداد لغو شد؛ محموله‌های در راه طبق سفارش قبلی تحویل می‌شوند."}

func _process_trade_arrivals(report):
	var remaining_shipments = []
	for shipment in state.trade_shipments:
		if int(shipment.get("arrival_day",0)) > int(state.day):
			remaining_shipments.append(shipment)
			continue
		var amount = int(shipment.get("amount",0))
		if get_free_storage() < amount:
			shipment["arrival_day"] = int(state.day) + 1
			remaining_shipments.append(shipment)
			report.append("محموله %d به‌دلیل پر بودن انبار یک روز در گمرک متوقف شد." % int(shipment.get("id",0)))
			continue
		var resource_id = str(shipment.get("resource_id",""))
		if RESOURCES.has(resource_id):
			state.resources[resource_id] = int(state.resources.get(resource_id,0)) + amount
			report.append("محموله %d رسید: %d واحد %s." % [int(shipment.get("id",0)),amount,RESOURCES[resource_id].name])
	state.trade_shipments = remaining_shipments

func _dispatch_import_contracts(report):
	for contract_index in range(state.import_contracts.size()):
		var contract = state.import_contracts[contract_index]
		if not bool(contract.get("active",false)) or int(contract.get("days_left",0)) <= 0:
			continue
		var city_id = str(contract.get("city_id",""))
		var resource_id = str(contract.get("resource_id",""))
		if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id):
			contract["active"] = false
			state.import_contracts[contract_index] = contract
			continue
		var amount = int(contract.get("daily_amount",1))
		var stock = state.city_export_stock.get(city_id,TRADE_CITIES[city_id].supply)
		amount = min(min(amount,int(stock.get(resource_id,0))),min(get_free_storage(),get_transport_capacity_remaining()))
		var price = get_import_price(city_id,resource_id)
		var total = amount * price + max(1,int(ceil(float(amount * price)*0.10)))
		if amount <= 0 or price <= 0 or get_available_money() < total:
			report.append("قرارداد واردات %s امروز به‌دلیل کمبود کالا، پول یا فضای انبار اجرا نشد." % RESOURCES[resource_id].name)
		else:
			_spend_money(total)
			stock[resource_id] = int(stock.get(resource_id,0)) - amount
			state.city_export_stock[city_id] = stock
			state.trade_shipments.append({"id":_next_shipment_id(),"city_id":city_id,"resource_id":resource_id,"amount":amount,"arrival_day":int(state.day)+int(TRADE_CITIES[city_id].travel_days),"paid":total})
			state.transport_used_today = int(state.get("transport_used_today",0)) + amount
			report.append("قرارداد واردات %s: محموله %d واحدی ارسال شد." % [RESOURCES[resource_id].name,amount])
		contract["days_left"] = int(contract.get("days_left",0)) - 1
		if int(contract.days_left) <= 0:
			contract["active"] = false
		state.import_contracts[contract_index] = contract

func _record_bank_transaction(kind, amount, description):
	if typeof(state.get("bank_transactions", null)) != TYPE_ARRAY:
		state["bank_transactions"] = []
	state.bank_transactions.append({"day":int(state.get("day",1)),"kind":str(kind),"amount":int(amount),"description":str(description)})
	while state.bank_transactions.size() > 100:
		state.bank_transactions.pop_front()

func get_bank_loan_limit():
	if not has_central_bank():
		return 0
	var capacity_room = max(0, get_treasury_capacity() - int(state.get("money",0)))
	var city_limit = 5000 + int(state.get("level",1)) * 2000 + int(state.get("population",0)) * 100
	return min(capacity_room, city_limit)

func take_bank_loan(amount, duration_days):
	if not has_central_bank():
		return {"ok":false,"message":"برای دریافت وام ابتدا بانک مرکزی بساز."}
	var active_loans = 0
	for loan in state.get("bank_loans", []):
		if str(loan.get("status","active")) == "active":
			active_loans += 1
	if active_loans >= 2:
		return {"ok":false,"message":"حداکثر ۲ وام فعال می‌توانی داشته باشی؛ ابتدا یکی را تسویه کن."}
	var term = int(duration_days)
	var rates = {7:8,14:14,30:25}
	if not rates.has(term):
		return {"ok":false,"message":"مدت وام باید ۷، ۱۴ یا ۳۰ روز باشد."}
	var principal = int(amount)
	if principal < 1000 or principal > get_bank_loan_limit():
		return {"ok":false,"message":"مبلغ وام باید حداقل ۱۰۰۰ و حداکثر %d سکه باشد." % get_bank_loan_limit()}
	var interest = int(ceil(float(principal * int(rates[term])) / 100.0))
	var total_due = principal + interest
	var accepted = _add_money(principal)
	if accepted != principal:
		return {"ok":false,"message":"ظرفیت خزانه برای پرداخت کامل وام کافی نیست."}
	var loan = {"id":state.get("bank_loans",[]).size()+1,"principal":principal,"interest":interest,"total_due":total_due,"remaining":total_due,"daily_installment":int(ceil(float(total_due)/float(term))),"duration":term,"days_left":term,"status":"active","missed_days":0}
	state.bank_loans.append(loan)
	_record_bank_transaction("loan",principal,"دریافت وام %d روزه با سود %d درصد" % [term,int(rates[term])])
	save_game()
	return {"ok":true,"message":"وام %d سکه‌ای با سود %d سکه ثبت شد؛ بازپرداخت روزانه حدود %d سکه به مدت %d روز." % [principal,interest,loan.daily_installment,term]}

func repay_bank_loan_manual(loan_index):
	if loan_index < 0 or loan_index >= state.get("bank_loans",[]).size():
		return {"ok":false,"message":"وام پیدا نشد."}
	var loan = state.bank_loans[loan_index]
	if str(loan.get("status","")) != "active":
		return {"ok":false,"message":"این وام فعال نیست."}
	if int(loan.get("last_manual_payment_day", 0)) == int(state.get("day", 1)):
		return {"ok":false,"message":"قسط این وام امروز یک‌بار دستی پرداخت شده است."}
	var due = min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))
	var payment = min(due,get_available_money())
	if payment <= 0:
		return {"ok":false,"message":"برای پرداخت قسط، موجودی آزاد خزانه کافی نیست."}
	_spend_money(payment)
	loan["remaining"] = int(loan.get("remaining",0)) - payment
	loan["days_left"] = max(0,int(loan.get("days_left",0))-1)
	loan["last_manual_payment_day"] = int(state.get("day",1))
	if int(loan.get("remaining",0)) <= 0:
		loan["status"] = "paid"
	state.bank_loans[loan_index] = loan
	_record_bank_transaction("repayment",payment,"پرداخت دستی قسط وام شماره %d" % int(loan.get("id",loan_index+1)))
	save_game()
	return {"ok":true,"message":"قسط دستی به مبلغ %d سکه پرداخت شد؛ مانده وام: %d سکه." % [payment,int(loan.get("remaining",0))]}

func repay_bank_loan_early(loan_index):
	if loan_index < 0 or loan_index >= state.get("bank_loans",[]).size():
		return {"ok":false,"message":"وام پیدا نشد."}
	var loan = state.bank_loans[loan_index]
	if str(loan.get("status","")) != "active":
		return {"ok":false,"message":"این وام فعال نیست."}
	var due = int(loan.get("remaining",0))
	if get_available_money() < due:
		return {"ok":false,"message":"برای تسویه کامل وام، %d سکه پول آزاد لازم داری." % due}
	_spend_money(due)
	loan["remaining"] = 0
	loan["status"] = "paid"
	state.bank_loans[loan_index] = loan
	_record_bank_transaction("repayment",due,"تسویه زودهنگام وام شماره %d" % int(loan.get("id",loan_index+1)))
	save_game()
	return {"ok":true,"message":"وام با پرداخت %d سکه تسویه شد." % due}

func create_bank_deposit(amount, duration_days):
	if game_has_no_municipal_bank():
		return {"ok":false,"message":"برای سپرده‌گذاری ابتدا بانک شهری بساز."}
	var term = int(duration_days)
	var rates = {7:3,14:7,30:15}
	var principal = int(amount)
	if not rates.has(term):
		return {"ok":false,"message":"مدت سپرده باید ۷، ۱۴ یا ۳۰ روز باشد."}
	if principal < 500 or get_available_money() < principal:
		return {"ok":false,"message":"مبلغ سپرده حداقل ۵۰۰ سکه است و باید پول آزاد کافی داشته باشی."}
	if not _spend_money(principal):
		return {"ok":false,"message":"برداشت مبلغ سپرده از خزانه انجام نشد."}
	var interest = int(floor(float(principal * int(rates[term])) / 100.0))
	var deposit = {"id":state.get("bank_deposits",[]).size()+1,"principal":principal,"interest":interest,"duration":term,"maturity_day":int(state.day)+term,"status":"active"}
	state.bank_deposits.append(deposit)
	_record_bank_transaction("deposit",principal,"افتتاح سپرده %d روزه با سود %d درصد" % [term,int(rates[term])])
	save_game()
	return {"ok":true,"message":"سپرده %d سکه‌ای ثبت شد؛ سود سررسید %d سکه است." % [principal,interest]}

func withdraw_bank_deposit(deposit_index):
	if deposit_index < 0 or deposit_index >= state.get("bank_deposits",[]).size():
		return {"ok":false,"message":"سپرده پیدا نشد."}
	var deposit = state.bank_deposits[deposit_index]
	if str(deposit.get("status","")) == "withdrawn":
		return {"ok":false,"message":"این سپرده قبلاً برداشت شده است."}
	var matured = int(state.day) >= int(deposit.get("maturity_day",0))
	var payout = int(deposit.get("principal",0)) + (int(deposit.get("interest",0)) if matured else 0)
	if get_treasury_capacity() - int(state.money) < payout:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای پرداخت %d سکه کافی نیست." % payout}
	_add_money(payout)
	deposit["status"] = "withdrawn"
	deposit["withdrawn_day"] = int(state.day)
	state.bank_deposits[deposit_index] = deposit
	_record_bank_transaction("withdrawal",payout,"برداشت سپرده شماره %d%s" % [int(deposit.get("id",deposit_index+1))," با سود" if matured else " پیش از سررسید؛ بدون سود"])
	save_game()
	return {"ok":true,"message":"%d سکه به خزانه برگشت%s." % [payout,"؛ سود هم دریافت شد" if matured else "؛ چون زودتر برداشت کردی سودی تعلق نگرفت"]}

func _process_bank_day(report):
	var total_paid = 0
	for index in range(state.get("bank_loans",[]).size()):
		var loan = state.bank_loans[index]
		if str(loan.get("status","")) != "active":
			continue
		if int(loan.get("last_manual_payment_day", 0)) == int(state.get("day", 1)):
			report.append("قسط وام شماره %d امروز دستی پرداخت شده است؛ برداشت خودکار تکرار نشد." % int(loan.get("id",index+1)))
			continue
		var due = min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))
		var payment = min(due,get_available_money())
		if payment > 0:
			_spend_money(payment)
			loan["remaining"] = int(loan.get("remaining",0)) - payment
			loan["days_left"] = max(0,int(loan.get("days_left",0))-1)
			loan["missed_days"] = 0
			total_paid += payment
			_record_bank_transaction("repayment",payment,"قسط روزانه وام شماره %d" % int(loan.get("id",index+1)))
			if int(loan.remaining) <= 0:
				loan["status"] = "paid"
				report.append("وام شماره %d به‌طور کامل تسویه شد." % int(loan.get("id",index+1)))
			else:
				report.append("قسط وام: %d سکه؛ مانده بدهی: %d سکه." % [payment,int(loan.remaining)])
		else:
			loan["missed_days"] = int(loan.get("missed_days",0)) + 1
			loan["days_left"] = int(loan.get("days_left",0)) + 1
			report.append("قسط وام پرداخت نشد؛ به‌دلیل کمبود پول، سررسید یک روز تمدید شد و جریمه‌ای نگرفت.")
		state.bank_loans[index] = loan
	for index in range(state.get("bank_deposits",[]).size()):
		var deposit = state.bank_deposits[index]
		if str(deposit.get("status","")) == "active" and int(state.day) + 1 >= int(deposit.get("maturity_day",0)):
			deposit["status"] = "matured"
			report.append("سپرده شماره %d سررسید شد؛ اصل و %d سکه سود آماده برداشت است." % [int(deposit.get("id",index+1)),int(deposit.get("interest",0))])
		state.bank_deposits[index] = deposit
	if total_paid > 0:
		state["bank_daily_repayment"] = total_paid
	return total_paid

func game_has_no_municipal_bank():
	return get_building_count("municipal_bank") <= 0

func get_market_price(id, action):
	if not RESOURCES.has(id):
		return 0
	var stock = int(state.get("market_stock", {}).get(id, 60))
	var target_stock = 60
	var scarcity = float(target_stock - stock) / float(target_stock)
	var multiplier = clamp(1.0 + scarcity * 0.55, 0.65, 1.55)
	var base_price = int(RESOURCES[id].get("buy" if action == "buy" else "sell", 0))
	return max(1, int(round(float(base_price) * multiplier)))

func get_trade_cities():
	return TRADE_CITIES

func get_daily_trade_city_ids():
	var current_day = int(state.get("day", 1))
	var current_level = int(state.get("level", 1))
	var saved_ids = state.get("daily_trade_city_ids", [])
	if int(state.get("daily_trade_city_day", 0)) == current_day and int(state.get("daily_trade_city_level", 0)) == current_level and saved_ids.size() > 0:
		var valid_saved = true
		for saved_id in saved_ids:
			if not TRADE_CITIES.has(str(saved_id)) or str(saved_id) in ["mehrabad","navid","golestan"]:
				valid_saved = false
				break
		if valid_saved:
			return saved_ids.duplicate()
	var available_ids = TRADE_CITIES.keys()
	# Provincial trade screens must list real provinces, not the three old demo cities.
	for legacy_city_id in ["mehrabad","navid","golestan"]:
		available_ids.erase(legacy_city_id)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(current_day * 7919 + current_level * 104729)
	for index in range(available_ids.size() - 1, 0, -1):
		var swap_index = rng.randi_range(0, index)
		var temp = available_ids[index]
		available_ids[index] = available_ids[swap_index]
		available_ids[swap_index] = temp
	var visible_count = 3
	if current_level >= 30:
		visible_count = 22
	elif current_level >= 20:
		visible_count = 16
	elif current_level >= 15:
		visible_count = 12
	elif current_level >= 10:
		visible_count = 8
	elif current_level >= 6:
		visible_count = 5
	var selected = available_ids.slice(0, min(visible_count, available_ids.size()) - 1)
	state["daily_trade_city_ids"] = selected
	state["daily_trade_city_day"] = current_day
	state["daily_trade_city_level"] = current_level
	save_game()
	return selected.duplicate()

func get_trade_export_price(city_id, resource_id):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id):
		return 0
	var city = TRADE_CITIES[city_id]
	if int(city.demand.get(resource_id, 0)) <= 0:
		return 0
	var demand = int(state.get("trade_demand_remaining", {}).get(city_id, city.demand).get(resource_id, 0))
	if demand <= 0:
		return 0
	var local_price = get_market_price(resource_id, "sell")
	var demand_factor = 1.0 + min(0.25, float(demand) / 100.0)
	return max(1, int(round(float(local_price) * float(city.price_factor) * demand_factor)))

func trade_with_city(city_id, resource_id, requested_amount):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id) or requested_amount <= 0:
		return {"ok":false,"message":"درخواست تجارت نامعتبر است."}
	var city = TRADE_CITIES[city_id]
	if int(city.demand.get(resource_id, 0)) <= 0:
		return {"ok":false,"message":city.name+" به این کالا نیازی ندارد و آن را نمی‌پذیرد."}
	var demand_by_resource = state.trade_demand_remaining.get(city_id, city.demand)
	var demand = int(demand_by_resource.get(resource_id, 0))
	if demand <= 0:
		return {"ok":false,"message":city.name+" سهمیه خرید این کالا را امروز تکمیل کرده است."}
	var remaining = int(state.trade_remaining.get(city_id, city.daily_capacity))
	var available = int(state.resources.get(resource_id, 0))
	var unit_price = get_trade_export_price(city_id, resource_id)
	var treasury_room = max(0, get_treasury_capacity() - int(state.money))
	var affordable_amount = int(floor(float(treasury_room) / float(unit_price)))
	var amount = min(min(min(int(requested_amount),remaining),min(available,demand)),min(affordable_amount,get_transport_capacity_remaining()))
	if amount <= 0:
		return {"ok":false,"message":"موجودی کالا، تقاضای شهر یا ظرفیت خزانه کافی نیست."}
	var final_revenue = amount * unit_price
	_add_money(final_revenue)
	state.resources[resource_id] = available - amount
	state["trade_exported_units_total"] = int(state.get("trade_exported_units_total", 0)) + amount
	state.trade_remaining[city_id] = remaining - amount
	demand_by_resource[resource_id] = demand - amount
	state.trade_demand_remaining[city_id] = demand_by_resource
	state.transport_used_today = int(state.get("transport_used_today",0)) + amount
	state.last_trade_report = "%d واحد %s به %s صادر شد؛ درآمد: %d سکه." % [amount,RESOURCES[resource_id].name,city.name,final_revenue]
	save_game()
	return {"ok":true,"message":state.last_trade_report,"amount":amount,"revenue":final_revenue}

func _refresh_trade_capacity():
	for city_id in TRADE_CITIES.keys():
		state.trade_remaining[city_id] = int(TRADE_CITIES[city_id].daily_capacity)
		state.trade_demand_remaining[city_id] = TRADE_CITIES[city_id].demand.duplicate(true)

func buy_resource(id, amount):
	if not RESOURCES.has(id) or amount <= 0:
		return {"ok":false,"message":"درخواست خرید نامعتبر است."}
	var unit_price = get_market_price(id, "buy")
	var cost = unit_price * amount
	if get_available_money() < cost:
		return {"ok":false,"message":"پول آزاد کافی نیست."}
	if int(state.market_stock.get(id, 0)) < amount:
		return {"ok":false,"message":"موجودی بازار کافی نیست."}
	if get_free_storage() < amount:
		return {"ok":false,"message":"فضای خالی انبار کافی نیست."}
	_spend_money(cost)
	state.market_stock[id] -= amount
	state.resources[id] = int(state.resources.get(id, 0)) + amount
	save_game()
	return {"ok":true,"message":"خرید انجام شد: "+str(amount)+" واحد "+RESOURCES[id].name}

func sell_resource(id, amount):
	if not RESOURCES.has(id) or amount <= 0:
		return {"ok":false,"message":"درخواست فروش نامعتبر است."}
	if int(state.resources.get(id, 0)) < amount:
		return {"ok":false,"message":"موجودی انبار کافی نیست."}
	if int(state.market_stock.get(id, 0)) + amount > 100:
		amount = max(0, 100 - int(state.market_stock.get(id, 0)))
	if amount <= 0:
		return {"ok":false,"message":"بازار ظرفیت خرید ندارد."}
	var unit_price = get_market_price(id, "sell")
	var treasury_room = max(0, get_treasury_capacity() - int(state.money))
	var affordable_amount = int(floor(float(treasury_room) / float(unit_price)))
	amount = min(amount, affordable_amount)
	if amount <= 0:
		return {"ok":false,"message":"ظرفیت خزانه پر است؛ فعلاً امکان دریافت درآمد فروش وجود ندارد."}
	state.resources[id] -= amount
	state.market_stock[id] += amount
	var revenue = amount * unit_price
	var accepted = _add_money(revenue)
	save_game()
	return {"ok":true,"message":"فروش %d واحد انجام شد؛ درآمد دریافتی: %d سکه." % [amount, accepted]}

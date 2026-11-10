# Mini ZekaCity

A text-first city management game built with Godot 3.6.

Mini ZekaCity is a separate project from the original ZekaCity. It brings the original game's city-management systems into a menu-driven interface: buildings, residents, employment, production chains, resources, storage, market, treasury, services, missions, and saving.

## Run
Open `project.godot` in Godot 3.6.x and run the project.

## Current milestone
- Text/menu-based city dashboard
- Building catalog with population unlocks and construction costs
- Residents and workplace assignment
- Daily production and payroll
- Resource storage limits and forestry reserves
- Market buy/sell and treasury
- Local save/load
- Single-player foundation; online multiplayer is planned as a separate authenticated service layer.


## اقتصاد و خزانه
- ظرفیت پایه خزانه ۱۰٬۰۰۰ سکه است؛ بانک مرکزی ۴۰٬۰۰۰ و هر بانک شهری ۵٬۰۰۰ سکه به ظرفیت اضافه می‌کند.
- با تخریب بانک مرکزی، بازسازی آن تا ۷ روز ممکن نیست؛ پس از پایان مهلت، پول مازاد بر ظرفیت عادی حذف می‌شود.
- درآمدی که از سقف ظرفیت خزانه بیشتر باشد دریافت نمی‌شود و در گزارش روزانه اعلام می‌شود.
- فروش خودکار منابع فقط با داشتن بازار مواد معدنی انجام می‌شود؛ ذخایر مواد خام و زنجیره چوب‌بری حفظ می‌شوند.
- تولید، مواد اولیه را فقط وقتی مصرف می‌کند که فضای کافی برای محصول نهایی در انبار وجود داشته باشد.

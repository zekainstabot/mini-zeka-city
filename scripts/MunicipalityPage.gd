extends RefCounted

# Builds municipal policy, resident requests, property and public projects.
static func build(owner, s):
	var game = owner.game
	var civic = game.get_civic_overview()
	owner._add_label("🏛️ شهرداری و مدیریت اقتصاد شهر", 22)
	owner._municipality_section("🟨 زمین و قیمت‌گذاری", "land")
	owner._add_label("زمین خصوصی آماده فروش: %d قطعه | قیمت هر قطعه: %d سکه" % [int(civic.get("private_land_available",0)),int(civic.get("private_land_price",300))], 17)
	owner._add_button("کاهش قیمت زمین خصوصی ۵۰ سکه", owner, "adjust_private_land_price", [-50])
	owner._add_button("افزایش قیمت زمین خصوصی ۵۰ سکه", owner, "adjust_private_land_price", [50])
	owner._end_municipality_section()
	owner._municipality_section("💰 مالیات و مجوزها", "tax")
	owner._add_label("نرخ مالیات کسب‌وکارهای خصوصی: %d درصد" % int(civic.get("tax_rate",8)), 18)
	var tax_down = owner._add_button("کاهش مالیات خصوصی ۱٪", owner, "adjust_business_tax", [-1])
	var tax_up = owner._add_button("افزایش مالیات خصوصی ۱٪", owner, "adjust_business_tax", [1])
	tax_down.disabled = int(civic.get("tax_rate",8)) <= 0
	tax_up.disabled = int(civic.get("tax_rate",8)) >= 30
	owner._add_label("هزینه صدور مجوز: %d سکه | درآمد مالیات امروز: %d سکه" % [int(civic.get("permit_fee",50)),int(civic.get("daily_tax",0))], 16)
	owner._add_button("کاهش هزینه مجوز ۱۰ سکه", owner, "adjust_business_permit_fee", [-10])
	owner._add_button("افزایش هزینه مجوز ۱۰ سکه", owner, "adjust_business_permit_fee", [10])
	owner._add_label("درآمد فروش زمین و صدور مجوز جدا از مالیات محاسبه می‌شود.", 15)
	owner._end_municipality_section()
	owner._municipality_section("📨 درخواست‌های شهروندان", "requests")
	owner._add_label("درخواست‌های شهروندان برای بررسی شهرداری: %d" % int(civic.get("request_count",0)), 19)
	if civic.get("requests", []).is_empty():
		owner._add_label("درخواستی در انتظار بررسی نیست.", 16)
	for municipal_request in civic.get("requests", []):
		owner._add_label("%s | شهروند شماره %d | روز %d | مبلغ: %d سکه" % [str(municipal_request.get("title","درخواست شهروند")),int(municipal_request.get("citizen_id",0)),int(municipal_request.get("day",s.day)),int(municipal_request.get("amount",0))], 17)
		owner._add_button("تأیید درخواست", owner, "resolve_civic_request", [int(municipal_request.get("id",0)), true])
		owner._add_button("رد درخواست", owner, "resolve_civic_request", [int(municipal_request.get("id",0)), false])
	owner._end_municipality_section()
	owner._municipality_section("🏢 املاک و درآمد اجاره", "properties")
	owner._add_label("مجموع درآمد اجاره املاک شهرداری (جدا از مالیات): %d سکه" % int(civic.get("rent_income",0)), 16)
	owner._add_label("املاک تجاری شهرداری:", 18)
	var municipal_property_count = 0
	for property_index in range(s.buildings.size()):
		var property = s.buildings[property_index]
		var property_data = game.get_building_definitions().get(str(property.get("id","")), {})
		var property_category = str(property_data.get("category",""))
		if property_category != "کسب‌وکارها" and property_category != "کارخانه‌ها":
			continue
		municipal_property_count += 1
		if int(property.get("rented_to",0)) > 0:
			owner._add_label("%s | اجاره‌داده‌شده به شهروند %d | تا روز %d" % [str(property_data.get("name","ملک")),int(property.get("rented_to",0)),int(property.get("rent_until_day",0))],15)
		else:
			owner._add_label("%s | متعلق به شهرداری | آماده اجاره با درخواست شهروند" % str(property_data.get("name","ملک")),15)
	if municipal_property_count == 0:
		owner._add_label("هنوز ملک تجاری متعلق به شهرداری ساخته نشده است.", 16)
	owner._end_municipality_section()
	owner._municipality_section("🏗️ پروژه‌های عمرانی", "projects")
	owner._add_label("پروژه‌های عمرانی در حال اجرا: %d" % int(civic.get("project_count",0)), 17)
	for civic_project in civic.get("projects", []):
		owner._add_label("%s | تحویل روز %d | اعتبار مالیاتی: %d سکه" % [str(game.get_building_definitions().get(str(civic_project.get("building_id","")),{}).get("name","پروژه")),int(civic_project.get("finish_day",0)),int(civic_project.get("tax_credit",0))], 15)
	owner._end_municipality_section()

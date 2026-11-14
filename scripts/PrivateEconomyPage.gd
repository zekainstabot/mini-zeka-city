extends RefCounted

# Builds private businesses, citizen investment requests, and community projects.
static func build(owner, s):
	var game = owner.game
		var private_economy_data = game.get_civic_overview()
		owner._add_label("🏙️ اقتصاد خصوصی و مشارکت مردمی", 22)
		owner._add_label("این بخش با تصمیم شهروندان اداره می‌شود؛ مردم می‌توانند سرمایه‌گذاری کنند، شغل بسازند و برای توسعه خدمات عمومی پیشنهاد بدهند.", 15)
		owner._add_label("کسب‌وکار خصوصی: %d | فروش روزانه: %d سکه" % [int(private_economy_data.get("business_count",0)),int(private_economy_data.get("daily_revenue",0))], 18)
		owner._add_label("سرمایه در گردش: %d | مالیات امروز: %d سکه | نرخ مالیات: %d٪" % [int(private_economy_data.get("private_balance",0)),int(private_economy_data.get("daily_tax",0)),int(private_economy_data.get("tax_rate",8))], 16)
		owner._add_label("زمین خصوصی آزاد: %d قطعه | قیمت هر قطعه: %d | هزینه مجوز: %d" % [int(private_economy_data.get("private_land_available",0)),int(private_economy_data.get("private_land_price",0)),int(private_economy_data.get("permit_fee",0))], 15)
		owner._add_label("درخواست‌های منتظر تصمیم شهرداری: %d" % int(private_economy_data.get("request_count",0)), 18)
		for request in private_economy_data.get("requests", []):
			var request_type = str(request.get("type",""))
			var citizen_id = int(request.get("citizen_id",0))
			owner._add_label("📨 %s | متقاضی: شهروند %d | روز %d" % [str(request.get("title","درخواست شهروند")),citizen_id,int(request.get("day",s.day))], 16)
			if request_type == "community_project":
				owner._add_label("هزینه پروژه: %d | سهم مردم: %d | سهم شهرداری: %d" % [int(request.get("amount",0)),int(request.get("contribution",0)),int(request.get("municipal_amount",0))], 15)
			elif request_type == "permit":
				owner._add_label("هزینه کسب‌وکار و مجوز: %d | زمین موردنیاز: %d قطعه" % [int(request.get("amount",0)),int(request.get("footprint",1))], 15)
			elif request_type == "land":
				owner._add_label("تعداد زمین: %d | مبلغ معامله: %d" % [int(request.get("plots",1)),int(request.get("amount",0))], 15)
			elif request_type == "rent":
				owner._add_label("اجاره روزانه: %d | مبلغ ۷ روز: %d" % [int(request.get("daily_rent",0)),int(request.get("amount",0))], 15)
			elif request_type == "public_project":
				owner._add_label("هزینه پروژه با سرمایه کسب‌وکار: %d" % int(request.get("amount",0)), 15)
			var request_row = HBoxContainer.new()
			request_row.add_theme_constant_override("separation", 8)
			owner.content.add_child(request_row)
			var approve_button = Button.new()
			approve_button.text = "تأیید"
			owner._style_button(approve_button,false)
			owner._apply_font(approve_button,16)
			approve_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			approve_button.connect("pressed", Callable(owner, "resolve_private_request").bind(int(request.get("id",0)),true))
			request_row.add_child(approve_button)
			var reject_button = Button.new()
			reject_button.text = "رد درخواست"
			owner._style_button(reject_button,false)
			owner._apply_font(reject_button,16)
			reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			reject_button.connect("pressed", Callable(owner, "resolve_private_request").bind(int(request.get("id",0)),false))
			request_row.add_child(reject_button)
		if private_economy_data.get("requests", []).is_empty():
			owner._add_label("درخواستی در انتظار نیست. شهروندان با توجه به نیازهای شهر و سرمایه‌شان پیشنهادهای تازه می‌سازند.", 15)
		owner._add_label("🏗️ پروژه‌های مشارکتی در حال اجرا: %d" % int(private_economy_data.get("project_count",0)), 18)
		for project in private_economy_data.get("projects", []):
			var project_data = game.get_building_definitions().get(str(project.get("building_id","")),{"name":"پروژه شهری"})
			owner._add_label("%s | پیشنهاددهنده: شهروند %d | تحویل روز %d" % [str(project_data.get("name","پروژه شهری")),int(project.get("citizen_id",0)),int(project.get("finish_day",0))], 15)
			owner._add_label("سهم مردم: %d | سهم شهرداری: %d" % [int(project.get("citizen_contribution",0)),int(project.get("municipal_contribution",0))], 14)
		owner._add_label("🏪 کسب‌وکارهای مردم", 19)
		if private_economy_data.get("private_businesses", []).is_empty():
			owner._add_label("هنوز کسب‌وکار خصوصی تأسیس نشده؛ مردم پس از پس‌انداز، برای زمین، اجاره ملک یا مجوز کسب‌وکار درخواست می‌دهند.", 15)
		for business in private_economy_data.get("private_businesses", []):
			owner._add_label("%s | مالک: شهروند %d | کارمند: %d | فروش روزانه: %d سکه" % [str(business.get("name","کسب‌وکار")),int(business.get("owner_citizen_id",0)),business.get("employees",[]).size(),int(business.get("last_revenue",0))], 16)
			owner._add_label("سرمایه: %d | مالیات: %d | اعتبار مالیاتی پروژه‌ها: %d" % [int(business.get("balance",0)),int(business.get("last_tax",0)),int(business.get("tax_credit",0))], 14)
			if bool(business.get("rented_municipal",false)):
				owner._add_label("ملک شهرداری؛ پایان اجاره: روز %d" % int(business.get("rent_until_day",0)), 14)
		owner._add_label("🧠 هوش و توان شهروندان", 19)
		owner._add_label("تصمیم مردم بر اساس سرمایه، کارآفرینی، ریسک‌پذیری، خلاقیت، علاقه شغلی، رضایت عمومی و کمبود خدمات شهر گرفته می‌شود.", 15)
		for citizen_index in range(min(8,s.citizens.size())):
			var resident = s.citizens[citizen_index]
			owner._add_label("شهروند %d | کیف پول: %d | کارآفرینی: %d | خلاقیت: %d | مشارکت اجتماعی: %d" % [int(resident.get("id",citizen_index+1)),int(resident.get("wallet",0)),int(resident.get("entrepreneurship",0)),int(resident.get("creativity",0)),int(resident.get("civic_mindedness",0))], 14)

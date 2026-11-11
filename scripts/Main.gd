extends Control

const EngineScript = preload("res://scripts/GameEngine.gd")
const PersianText = preload("res://scripts/PersianText.gd")
var game = null
var current_page = "home"
var message_label = null
var content = null
var header_label = null
var ui_font = null

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST and game != null:
		game.save_game()

func _ready():
	_load_ui_font()
	game = EngineScript.new()
	if not game.load_game():
		game.new_game()
		game.save_game()
	_build_ui()
	show_page("home")

func _build_ui():
	var background = ColorRect.new()
	background.color = Color("#101827")
	background.anchor_right = 1
	background.anchor_bottom = 1
	add_child(background)
	var root = VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	var screen_width = get_viewport_rect().size.x
	var compact_layout = screen_width < 900
	root.margin_left = 16 if compact_layout else 24
	root.margin_top = 16 if compact_layout else 22
	root.margin_right = -16 if compact_layout else -24
	root.margin_bottom = -16 if compact_layout else -22
	root.add_constant_override("separation", 14 if compact_layout else 12)
	add_child(root)
	header_label = Label.new()
	header_label.text = PersianText.reshaper("مینی زکا سیتی")
	header_label.align = Label.ALIGN_CENTER
	_apply_font(header_label, 28 if compact_layout else 26)
	header_label.add_color_override("font_color", Color("#ffffff"))
	root.add_child(header_label)
	var nav = GridContainer.new()
	nav.columns = 2 if compact_layout else 3
	nav.add_constant_override("hseparation", 8)
	nav.add_constant_override("vseparation", 8)
	root.add_child(nav)
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"بازار","p":"market"},{"t":"تجارت شهرها","p":"trade"},{"t":"واردات و قراردادها","p":"imports"},{"t":"جاده و ناوگان","p":"transport"},{"t":"انبار","p":"storage"},{"t":"گزارش روز","p":"report"},{"t":"ماموریت‌ها","p":"missions"}]:
		var b = Button.new()
		b.text = PersianText.reshaper(item.t)
		b.rect_min_size = Vector2(0, 64 if compact_layout else 58)
		b.flat = false
		_apply_font(b, 21 if compact_layout else 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, true)
		b.connect("pressed", self, "show_page", [item.p])
		nav.add_child(b)
	var line = HSeparator.new()
	root.add_child(line)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_constant_override("separation", 14 if compact_layout else 10)
	scroll.add_child(content)
	message_label = Label.new()
	message_label.autowrap = true
	message_label.add_color_override("font_color", Color("#fbbf24"))
	root.add_child(message_label)

func _load_ui_font():
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://assets/fonts/Vazirmatn.ttf"
	ui_font = DynamicFont.new()
	ui_font.font_data = font_data
	ui_font.size = 20

func _apply_font(control, size=18):
	if ui_font == null:
		return
	var font = DynamicFont.new()
	font.font_data = ui_font.font_data
	font.size = int(round(float(size) * (1.18 if get_viewport_rect().size.x < 900 else 1.0)))
	control.add_font_override("font", font)

func _button_style(bg_color, border_color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _style_button(button, navigation=false):
	button.flat = false
	var normal_color = Color("#fbbf24") if navigation else Color("#7c3aed")
	var hover_color = Color("#fde68a") if navigation else Color("#8b5cf6")
	var pressed_color = Color("#d97706") if navigation else Color("#5b21b6")
	button.add_stylebox_override("normal", _button_style(normal_color, Color("#ffffff") if navigation else Color("#c4b5fd")) )
	button.add_stylebox_override("hover", _button_style(hover_color, Color("#ffffff")))
	button.add_stylebox_override("focus", _button_style(hover_color, Color("#ffffff")))
	button.add_stylebox_override("pressed", _button_style(pressed_color, Color("#ffffff")))
	button.add_stylebox_override("disabled", _button_style(Color("#1f2937"), Color("#374151")))
	button.add_color_override("font_color", Color("#111827") if navigation else Color("#ffffff"))
	button.add_color_override("font_color_focus", Color("#ffffff"))
	button.add_color_override("font_color_hover", Color("#111827") if navigation else Color("#ffffff"))
	button.add_color_override("font_color_pressed", Color("#ffffff"))
	button.add_color_override("font_color_disabled", Color("#64748b"))

func _clear_content():
	for child in content.get_children():
		child.queue_free()

func _add_label(text, size=18):
	var label = Label.new()
	label.text = PersianText.reshaper(text)
	label.align = Label.ALIGN_RIGHT
	_apply_font(label, size)
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.rect_min_size = Vector2(0, 30)
	label.add_color_override("font_color", Color("#e2e8f0"))
	content.add_child(label)
	return label

func _add_button(text, target, callback, args=[]):
	var button = Button.new()
	button.text = PersianText.reshaper(text)
	button.rect_min_size = Vector2(0, 58 if get_viewport_rect().size.x < 900 else 50)
	_apply_font(button, 19 if get_viewport_rect().size.x < 900 else 17)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, false)
	button.connect("pressed", target, callback, args)
	content.add_child(button)
	return button

func _show_message(text):
	message_label.text = PersianText.reshaper(text)

func show_page(page):
	current_page = page
	_clear_content()
	_show_message("")
	var s = game.state
	match page:
		"home":
			_add_label("روز %d  |  سطح %d  |  امتیاز تجربه %d" % [s.day,s.level,s.xp], 20)
			_add_label(" خزانه: %d / %d سکه   |   پول قفل‌شده: %d   |    جمعیت: %d نفر" % [s.money,game.get_treasury_capacity(),game.get_locked_money(),s.population], 22)
			_add_label("شاغلان: %d  |  بیکاران: %d  |  اعتبار شهر: %d  |  رضایت: %d/۱۰۰" % [game.get_employed_count(),game.get_unemployed_count(),s.reputation,int(s.get("satisfaction",50))])
			var service_lines = []
			for service_id in game.SERVICE_GROUPS.keys():
				var service_name = game.SERVICE_GROUPS[service_id].name
				service_lines.append(service_name + ": " + ("فعال" if bool(s.get("services",{}).get(service_id,false)) else "ندارد"))
			_add_label("پوشش خدمات: " + _service_summary(), 15)
			_add_label("نیازهای شهروندان: " + _needs_summary(), 15)
			_add_label(" ساختمان‌ها: %d  |  ظرفیت انبار: %d  |  بانک مرکزی: %s  |  بانک شهری: %d" % [s.buildings.size(),game.get_storage_capacity(),("فعال" if game.has_central_bank() else ("بازسازی تا %d روز دیگر" % int(s.get("central_bank_rebuild_days_left",0)) if int(s.get("central_bank_rebuild_days_left",0)) > 0 else "ندارد")),game.get_building_count("municipal_bank")])
			_add_label(" درختان جنگل: %d از ۱۰۰ | رشد روزانه: ۲ درخت" % game.get_forest_tree_count())
			_add_label(" معادن فعال: %d" % _active_mine_count())
			_add_label("منابع: "+_resource_summary())
			_add_label("ذخیره غذای شهر: %d واحد" % int(s.resources.get("food",0)),16)
			var home_economy = s.get("last_economy", {})
			_add_label("آخرین تراز روزانه: %d سکه" % int(home_economy.get("net_cashflow",0)), 17)
			_add_label("گزارش آخر:\n"+str(s.last_report), 16)
			_add_button(" پایان روز و اجرای اقتصاد", self, "advance_day")
			_add_button(" ذخیره شهر", self, "save_now")
		"buildings":
			_add_label("ساخت‌وساز شهر", 22)
			var categories = ["خانه‌ها","کشاورزی","کارخانه‌ها","معادن","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها","زیرساخت"]
			for category in categories:
				_add_label("【"+category+"】", 18)
				for id in game.get_building_definitions().keys():
					var data = game.get_building_definitions()[id]
					if data.category != category:
						continue
					var population_unlocked = s.population >= int(data.unlock)
					var required_level = int(data.get("level_unlock", 1))
					var level_unlocked = int(s.level) >= required_level
					var unlocked = population_unlocked and level_unlocked
					var label = "%s | هزینه: %d | جمعیت: %d | سطح: %d" % [data.name,data.cost,data.unlock,required_level]
					if not population_unlocked or not level_unlocked:
						label += " | 🔒 قفل"
					var b = _add_button(label, self, "build_building", [id])
					b.disabled = not unlocked or game.get_available_money() < int(data.cost) or (id == "central_bank" and int(s.get("central_bank_rebuild_days_left",0)) > 0)
			_add_label("مدیریت معادن:", 18)
			for mine_index in range(game.get_mines().size()):
				var mine = game.get_mines()[mine_index]
				var mine_status = ("فعال" if bool(mine.get("active",false)) else "متوقف")
				if str(mine.get("resource","")) == "iron_ore":
					mine_status += " | ذخیره: %d" % int(mine.get("remaining",0))
					if int(mine.get("remaining",0)) <= 0:
						_add_button(" شارژ معدن آهن — ۱۰۰۰ سکه", self, "refill_mine", [mine_index])
				_add_label("%s — %s" % [game.get_resource_definitions()[str(mine.get("resource","stone"))].name,mine_status])
			_add_label("ساختمان‌های فعلی:", 18)
			for i in range(s.buildings.size()):
				var id = s.buildings[i].id
				if int(s.buildings[i].get("balance",0)) > 0:
					_add_label("حساب %s: %d سکه" % [str(game.get_building_definitions()[id].name),int(s.buildings[i].get("balance",0))])
					_add_button(" برداشت سود %s: %d سکه" % [str(game.get_building_definitions()[id].name),int(s.buildings[i].get("balance",0))], self, "collect_profit", [i])
				_add_button("تخریب: "+str(game.get_building_definitions()[id].name), self, "demolish_building", [i])
		"citizens":
			_add_label(" جمعیت: %d | شاغل: %d | بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 20)
			_add_label("ظرفیت شغلی: %d" % game.get_job_capacity())
			_add_label("رضایت شهروندان: %d/۱۰۰" % int(s.get("satisfaction",50)))
			_add_label("نیازهای روزانه: " + _needs_summary(), 15)
			for citizen in s.citizens:
				_add_label("شهروند %s — %s | کیف پول: %d سکه" % [str(citizen.id),("بیکار" if citizen.job == "" else citizen.job),int(citizen.get("wallet",0))])
			_add_button(" تخصیص دوباره شغل‌ها", self, "reassign_jobs")
		"market":
			_add_label("بازار شهر — قیمت‌ها بر اساس عرضه و تقاضا", 22)
			_add_label("موجودی بازار کمتر باشد، قیمت بالاتر می‌رود؛ با افزایش موجودی، قیمت کاهش می‌یابد.", 15)
			for id in game.get_resource_definitions().keys():
				var d = game.get_resource_definitions()[id]
				var stock = int(s.resources.get(id,0))
				var market_stock = int(s.market_stock.get(id,0))
				var buy_price = game.get_market_price(id,"buy")
				var sell_price = game.get_market_price(id,"sell")
				_add_label("%s | انبار: %d | موجودی بازار: %d/۱۰۰ | خرید: %d | فروش: %d" % [d.name,stock,market_stock,buy_price,sell_price])
				var buy_button = _add_button("خرید ۵ واحد "+d.name, self, "buy_item", [id,5])
				buy_button.disabled = int(s.market_stock.get(id,0)) < 5 or game.get_free_storage() < 5 or game.get_available_money() < buy_price * 5
				var sell_button = _add_button("فروش ۵ واحد "+d.name, self, "sell_item", [id,5])
				sell_button.disabled = stock < 5 or int(s.market_stock.get(id,0)) > 95 or game.get_available_money() >= game.get_treasury_capacity()
		"trade":
			_add_label(" تجارت با شهرهای همسایه", 22)
			_add_label("هر شهر تقاضا و ظرفیت خرید روزانه دارد. صادرات با قیمت توافقی انجام می‌شود و درآمد مستقیم به خزانه می‌رود.", 15)
			_add_label("ظرفیت باقی‌مانده امروز:", 18)
			for city_id in game.get_trade_cities().keys():
				var city = game.get_trade_cities()[city_id]
				_add_label("%s: %d / %d واحد" % [city.name,int(s.trade_remaining.get(city_id,city.daily_capacity)),int(city.daily_capacity)])
				for resource_id in game.get_resource_definitions().keys():
					var export_price = game.get_trade_export_price(city_id,resource_id)
					if export_price <= 0:
						continue
					var city_demand_left = int(s.trade_demand_remaining.get(city_id,city.demand).get(resource_id,0))
					_add_label("%s — %s | تقاضای باقی‌مانده: %d | قیمت صادرات: %d سکه" % [city.name,game.get_resource_definitions()[resource_id].name,city_demand_left,export_price],15)
					var export_button = _add_button("صادرات ۵ واحد "+game.get_resource_definitions()[resource_id].name+" به "+city.name,self,"export_to_city",[city_id,resource_id,5])
					export_button.disabled = int(s.resources.get(resource_id,0)) <= 0 or int(s.trade_remaining.get(city_id,city.daily_capacity)) <= 0 or game.get_transport_capacity_remaining() <= 0
			_add_label("آخرین معامله: "+str(s.get("last_trade_report","هنوز معامله‌ای انجام نشده است.")),16)
		"transport":
			_add_label("🛣️ شبکه جاده‌ای و ناوگان کامیون‌ها",22)
			_add_label("سطح جاده: %d از ۳ | کامیون فعال: %d | ظرفیت روزانه: %d واحد" % [int(s.get("road_level",1)),game.get_transport_truck_count(),game.get_transport_daily_capacity()],18)
			_add_label("ظرفیت مصرف‌شده امروز: %d | ظرفیت باقی‌مانده: %d" % [int(s.get("transport_used_today",0)),game.get_transport_capacity_remaining()],16)
			_add_label("هر پایانه با ۲ کارمند، یک کامیون را فعال می‌کند؛ هر پایانه حداکثر ۲ کامیون پشتیبانی می‌کند.",15)
			_add_label("نگهداری روزانه ناوگان: %d سکه | نگهداری جاده: %d سکه" % [game.get_fleet_maintenance(),game.get_road_maintenance()],16)
			var road_level = int(s.get("road_level",1))
			if road_level < 3:
				var next_road_cost = 1500 if road_level == 1 else 3500
				var road_button = _add_button("ارتقای جاده به سطح %d — %d سکه" % [road_level+1,next_road_cost],self,"upgrade_road")
				road_button.disabled = int(s.level) < road_level+1 or game.get_available_money() < next_road_cost
			else:
				_add_label("شبکه جاده‌ای در بالاترین سطح قرار دارد.")
			if game.get_building_count("transport_depot") == 0:
				_add_label("برای آغاز تجارت زمینی، از صفحه ساختمان‌ها یک پایانه حمل‌ونقل بساز و نیروی کار آن را تأمین کن.")
			_add_label("ظرفیت کامیون‌ها بین واردات، قراردادهای تأمین و صادرات مشترک است.",15)
		"imports":
			_add_label(" واردات و حمل‌ونقل بین‌شهری", 22)
			_add_label("ظرفیت کامیون آزاد امروز: %d از %d واحد" % [game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
			_add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود. محموله پس از ۱ یا ۲ روز می‌رسد.",15)
			for city_id in game.get_import_cities().keys():
				var city = game.get_import_cities()[city_id]
				_add_label("%s | زمان حمل: %d روز" % [city.name,int(city.travel_days)],18)
				for resource_id in game.get_resource_definitions().keys():
					var stock = int(s.city_export_stock.get(city_id,city.supply).get(resource_id,0))
					var price = game.get_import_price(city_id,resource_id)
					if stock <= 0:
						continue
					_add_label("%s | موجودی: %d | قیمت: %d سکه/واحد" % [game.get_resource_definitions()[resource_id].name,stock,price],15)
					var import_button = _add_button("سفارش ۵ واحد "+game.get_resource_definitions()[resource_id].name+" از "+city.name,self,"import_from_city",[city_id,resource_id,5])
					import_button.disabled = game.get_free_storage() < 5 or game.get_transport_capacity_remaining() < 5 or game.get_available_money() < (5 * price + int(ceil(float(5 * price) * 0.10)))
			_add_label(" محموله‌های در راه:",18)
			if s.trade_shipments.empty():
				_add_label("محموله‌ای در راه نیست.")
			for shipment in s.trade_shipments:
				var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")),{"name":"نامشخص"})
				var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")),{"name":"کالای نامشخص"})
				_add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
			_add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
			_add_label(" قراردادهای واردات:",18)
			if s.import_contracts.empty():
				_add_label("قرارداد فعالی ثبت نشده است.")
			for contract_index in range(s.import_contracts.size()):
				var contract = s.import_contracts[contract_index]
				var contract_city = game.get_import_cities().get(str(contract.get("city_id","")),{"name":"نامشخص"})
				var contract_resource = game.get_resource_definitions().get(str(contract.get("resource_id","")),{"name":"نامشخص"})
				var active_label = "فعال" if bool(contract.get("active",false)) else "پایان‌یافته/لغوشده"
				_add_label("%s | %s | روزانه %d واحد | %d روز باقی‌مانده | %s" % [contract_city.name,contract_resource.name,int(contract.get("daily_amount",0)),int(contract.get("days_left",0)),active_label],15)
				if bool(contract.get("active",false)):
					_add_button("لغو قرارداد "+contract_resource.name,self,"cancel_import",[contract_index])
			for city_id in game.get_import_cities().keys():
				var city = game.get_import_cities()[city_id]
				_add_button("قرارداد ۷ روزه: ۲ واحد چوب از "+city.name,self,"make_import_contract",[city_id,"wood",2,7])
		"storage":
			_add_label(" مدیریت انبار", 22)
			_add_label("ظرفیت: %d | مصرف‌شده: %d | فضای خالی: %d" % [game.get_storage_capacity(),game.get_storage_used(),game.get_free_storage()])
			_add_label(" ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())
			for id in game.get_resource_definitions().keys():
				_add_label("%s: %d" % [game.get_resource_definitions()[id].name,s.resources.get(id,0)])
		"report":
			_add_label(" گزارش روزانه", 22)
			var report_economy = s.get("last_economy", {})
			_add_label("درآمد مالیات: %d سکه" % int(report_economy.get("tax_income",0)))
			_add_label("خرید شهروندان: %d سکه از %d خریدار" % [int(report_economy.get("consumer_spending",0)),int(report_economy.get("consumer_buyers",0))])
			_add_label("غذای مصرف‌شده شهروندان: %d واحد | ذخیره پایان روز: %d" % [int(report_economy.get("food_units_consumed",0)),int(report_economy.get("food_stock",0))])
			_add_label("واریزی حساب فروشگاه‌ها: %d سکه" % int(report_economy.get("consumer_business_revenue",0)))
			_add_label("مالیات خرید شهروندان: %d سکه" % int(report_economy.get("consumer_tax_income",0)))
			_add_label("درآمد کسب‌وکارها: %d سکه" % int(report_economy.get("business_income",0)))
			_add_label("درآمد فروش منابع: %d سکه" % int(report_economy.get("resource_income",0)))
			_add_label("کل درآمد دریافت‌شده: %d سکه" % int(report_economy.get("accepted_income",0)))
			_add_label("حقوق پرداختی: %d از %d سکه" % [int(report_economy.get("wages_paid",0)),int(report_economy.get("wages_due",0))])
			_add_label("نگهداری ناوگان و جاده: %d سکه" % int(report_economy.get("maintenance_paid",0)))
			_add_label("تغییر خالص خزانه: %d سکه" % int(report_economy.get("net_cashflow",0)), 20)
			_add_label(str(s.last_report), 18)
			_add_button("رفتن به روز بعد", self, "advance_day")
		"missions":
			_add_label(" ماموریت‌های شهر", 22)
			_add_label("با تکمیل ماموریت‌ها پاداش سکه دریافت کن.")
			for mission_index in range(game.get_missions().size()):
				var mission = game.get_missions()[mission_index]
				var definition = {}
				for item in game.MISSION_DEFINITIONS:
					if str(item.id) == str(mission.get("id","")):
						definition = item
						break
				if definition.empty():
					continue
				var status = ("دریافت شده" if bool(mission.get("claimed",false)) else ("آماده دریافت" if bool(mission.get("completed",false)) else "در حال انجام"))
				_add_label("%s — %s" % [definition.title,status],18)
				_add_label("%s | پیشرفت: %d/%d | جایزه: %d سکه" % [definition.description,int(mission.get("progress",0)),int(definition.goal),int(definition.reward)],15)
				if bool(mission.get("completed",false)) and not bool(mission.get("claimed",false)):
					_add_button(" دریافت پاداش: "+str(definition.reward), self, "claim_mission", [mission_index])
		_:
			_add_label("بخش پیدا نشد.")
	header_label.text = PersianText.reshaper("مینی زکا سیتی  |  خزانه: %d  |  جمعیت: %d" % [s.money,s.population])

func _service_summary():
	var parts = []
	for id in game.SERVICE_GROUPS.keys():
		var label = str(game.SERVICE_GROUPS[id].name)
		parts.append("%s %d%%" % [label, int(game.state.get("services",{}).get(id,0))])
	return " | ".join(parts)

func _needs_summary():
	var labels = {"food":"خوراک","water":"آب","power":"برق","health":"سلامت","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت"}
	var parts = []
	for id in labels.keys():
		parts.append("%s %d%%" % [labels[id], int(game.state.get("needs",{}).get(id,60))])
	return " | ".join(parts)

func _active_mine_count():
	var count = 0
	for mine in game.get_mines():
		if bool(mine.get("active", false)):
			count += 1
	return count

func refill_mine(index):
	var result = game.refill_iron_mine(index)
	show_page("buildings")
	_show_message(result.message)

func _resource_summary():
	var parts = []
	for id in game.get_resource_definitions().keys():
		parts.append("%s: %d" % [game.get_resource_definitions()[id].name,game.state.resources.get(id,0)])
	return " | ".join(parts)

func build_building(id):
	var result = game.build(id)
	show_page("buildings")
	_show_message(result.message)

func collect_profit(index):
	var result = game.collect_business_profit(index)
	show_page("buildings")
	_show_message(result.message)

func demolish_building(index):
	var result = game.demolish(index)
	show_page("buildings")
	_show_message(result.message)

func reassign_jobs():
	game.assign_jobs()
	game.save_game()
	show_page("citizens")
	_show_message("تخصیص شغل‌ها به‌روزرسانی شد.")

func upgrade_road():
	var result = game.upgrade_roads()
	show_page("transport")
	_show_message(result.message)

func advance_day():
	var report = game.end_day()
	show_page("home")
	_show_message(report)

func import_from_city(city_id, resource_id, amount):
	var result = game.order_import(city_id, resource_id, amount)
	show_page("imports")
	_show_message(result.message)

func make_import_contract(city_id, resource_id, amount, days):
	var result = game.create_import_contract(city_id, resource_id, amount, days)
	show_page("imports")
	_show_message(result.message)

func cancel_import(index):
	var result = game.cancel_import_contract(index)
	show_page("imports")
	_show_message(result.message)

func export_to_city(city_id, resource_id, amount):
	var result = game.trade_with_city(city_id, resource_id, amount)
	show_page("trade")
	_show_message(result.message)

func buy_item(id, amount):
	var result = game.buy_resource(id, amount)
	show_page("market")
	_show_message(result.message)

func sell_item(id, amount):
	var result = game.sell_resource(id, amount)
	show_page("market")
	_show_message(result.message)

func claim_mission(index):
	var result = game.claim_mission(index)
	show_page("missions")
	_show_message(result.message)

func save_now():
	var ok = game.save_game()
	_show_message("شهر ذخیره شد." if ok else "ذخیره‌سازی ناموفق بود.")

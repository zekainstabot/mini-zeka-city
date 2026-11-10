extends Control

const EngineScript = preload("res://scripts/GameEngine.gd")
var game = null
var current_page = "home"
var message_label = null
var content = null
var header_label = null

func _ready():
	game = EngineScript.new()
	if not game.load_game():
		game.new_game()
		game.save_game()
	_build_ui()
	show_page("home")

func _build_ui():
	var background = ColorRect.new()
	background.color = Color("#111827")
	background.anchor_right = 1
	background.anchor_bottom = 1
	add_child(background)
	var root = VBoxContainer.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.margin_left = 22
	root.margin_top = 18
	root.margin_right = -22
	root.margin_bottom = -18
	root.add_constant_override("separation", 12)
	add_child(root)
	header_label = Label.new()
	header_label.text = "🏙️ مینی زکا سیتی"
	header_label.align = Label.ALIGN_CENTER
	header_label.add_color_override("font_color", Color("#f8fafc"))
	header_label.add_font_size_override("font_size", 28)
	root.add_child(header_label)
	var nav = HBoxContainer.new()
	nav.add_constant_override("separation", 8)
	root.add_child(nav)
	for item in [{"t":"شهر من","p":"home"},{"t":"ساختمان‌ها","p":"buildings"},{"t":"شهروندان","p":"citizens"},{"t":"بازار","p":"market"},{"t":"انبار","p":"storage"},{"t":"گزارش روز","p":"report"}]:
		var b = Button.new()
		b.text = item.t
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	content.add_constant_override("separation", 10)
	scroll.add_child(content)
	message_label = Label.new()
	message_label.autowrap = true
	message_label.add_color_override("font_color", Color("#fbbf24"))
	root.add_child(message_label)

func _clear_content():
	for child in content.get_children():
		child.queue_free()

func _add_label(text, size=18):
	var label = Label.new()
	label.text = text
	label.autowrap = true
	label.add_color_override("font_color", Color("#e5e7eb"))
	label.add_font_size_override("font_size", size)
	content.add_child(label)
	return label

func _add_button(text, callback, args=[]):
	var button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.connect("pressed", self, callback, args)
	content.add_child(button)
	return button

func _show_message(text):
	message_label.text = text

func show_page(page):
	current_page = page
	_clear_content()
	_show_message("")
	var s = game.state
	match page:
		"home":
			_add_label("روز %d  |  سطح %d  |  امتیاز تجربه %d" % [s.day,s.level,s.xp], 20)
			_add_label("💰 خزانه: %d / %d سکه   |   پول قفل‌شده: %d   |   👥 جمعیت: %d نفر" % [s.money,game.get_treasury_capacity(),game.get_locked_money(),s.population], 22)
			_add_label("شاغلان: %d  |  بیکاران: %d  |  اعتبار شهر: %d" % [game.get_employed_count(),game.get_unemployed_count(),s.reputation])
			_add_label("🏘️ ساختمان‌ها: %d  |  ظرفیت انبار: %d  |  بانک مرکزی: %s  |  بانک شهری: %d" % [s.buildings.size(),game.get_storage_capacity(),("فعال" if game.has_central_bank() else ("بازسازی تا %d روز دیگر" % int(s.get("central_bank_rebuild_days_left",0)) if int(s.get("central_bank_rebuild_days_left",0)) > 0 else "ندارد")),game.get_building_count("municipal_bank")])
			_add_label("🌳 درختان جنگل: %d از ۱۰۰ | رشد روزانه: ۲ درخت" % game.get_forest_tree_count())
			_add_label("⛏️ معادن فعال: %d" % _active_mine_count())
			_add_label("منابع: "+_resource_summary())
			_add_label("گزارش آخر:\n"+str(s.last_report), 16)
			_add_button("🌅 پایان روز و اجرای اقتصاد", self, "advance_day")
			_add_button("💾 ذخیره شهر", self, "save_now")
		"buildings":
			_add_label("ساخت‌وساز شهر", 22)
			var categories = ["خانه‌ها","کارخانه‌ها","معادن","کسب‌وکارها","خدمات شهری","تفریح و فرهنگ","انبارها"]
			for category in categories:
				_add_label("【"+category+"】", 18)
				for id in game.get_building_definitions().keys():
					var data = game.get_building_definitions()[id]
					if data.category != category:
						continue
					var unlocked = s.population >= int(data.unlock)
					var label = "%s | هزینه: %d | جمعیت لازم: %d" % [data.name,data.cost,data.unlock]
					if not unlocked:
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
						_add_button("🔋 شارژ معدن آهن — ۱۰۰۰ سکه", self, "refill_mine", [mine_index])
				_add_label("%s — %s" % [game.get_resource_definitions()[str(mine.get("resource","stone"))].name,mine_status])
			_add_label("ساختمان‌های فعلی:", 18)
			for i in range(s.buildings.size()):
				var id = s.buildings[i].id
				_add_button("تخریب: "+str(game.get_building_definitions()[id].name), self, "demolish_building", [i])
		"citizens":
			_add_label("👥 جمعیت: %d | شاغل: %d | بیکار: %d" % [s.population,game.get_employed_count(),game.get_unemployed_count()], 20)
			_add_label("ظرفیت شغلی: %d" % game.get_job_capacity())
			for citizen in s.citizens:
				_add_label("شهروند %s — %s" % [str(citizen.id),("بیکار" if citizen.job == "" else citizen.job)])
			_add_button("🔄 تخصیص دوباره شغل‌ها", self, "reassign_jobs")
		"market":
			_add_label("بازار شهر — قیمت خرید و فروش", 22)
			for id in game.get_resource_definitions().keys():
				var d = game.get_resource_definitions()[id]
				var stock = int(s.resources.get(id,0))
				var market_stock = int(s.market_stock.get(id,0))
				_add_label("%s | انبار: %d | بازار: %d | خرید: %d | فروش: %d" % [d.name,stock,market_stock,d.buy,d.sell])
				_add_button("خرید ۵ واحد "+d.name, self, "buy_item", [id,5])
				_add_button("فروش ۵ واحد "+d.name, self, "sell_item", [id,5])
		"storage":
			_add_label("📦 مدیریت انبار", 22)
			_add_label("ظرفیت: %d | مصرف‌شده: %d | فضای خالی: %d" % [game.get_storage_capacity(),game.get_storage_used(),game.get_free_storage()])
			_add_label("🌳 ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())
			for id in game.get_resource_definitions().keys():
				_add_label("%s: %d" % [game.get_resource_definitions()[id].name,s.resources.get(id,0)])
		"report":
			_add_label("📜 گزارش روزانه", 22)
			_add_label(str(s.last_report), 18)
			_add_button("رفتن به روز بعد", self, "advance_day")
		_:
			_add_label("بخش پیدا نشد.")
	header_label.text = "🏙️ مینی زکا سیتی  |  خزانه: %d  |  جمعیت: %d" % [s.money,s.population]

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

func demolish_building(index):
	var result = game.demolish(index)
	show_page("buildings")
	_show_message(result.message)

func reassign_jobs():
	game.assign_jobs()
	show_page("citizens")
	_show_message("تخصیص شغل‌ها به‌روزرسانی شد.")

func advance_day():
	var report = game.end_day()
	show_page("home")
	_show_message(report)

func buy_item(id, amount):
	var result = game.buy_resource(id, amount)
	show_page("market")
	_show_message(result.message)

func sell_item(id, amount):
	var result = game.sell_resource(id, amount)
	show_page("market")
	_show_message(result.message)

func save_now():
	var ok = game.save_game()
	_show_message("شهر ذخیره شد." if ok else "ذخیره‌سازی ناموفق بود.")

extends Reference
class_name MiniZekaCityEngine

const SAVE_PATH = "user://mini_zeka_city_save.json"
const STORAGE_RESERVE = 50
const FORESTRY_RESERVES = {"wood": 20, "lumber": 10, "furniture": 0}

const RESOURCES = {
	"stone": {"name": "سنگ", "buy": 10, "sell": 15},
	"iron_ore": {"name": "سنگ‌آهن", "buy": 25, "sell": 35},
	"wood": {"name": "چوب", "buy": 12, "sell": 18},
	"lumber": {"name": "الوار", "buy": 30, "sell": 42},
	"furniture": {"name": "مبلمان", "buy": 80, "sell": 112}
}

const BUILDINGS = {
	"small_house": {"name":"خانه کوچک","category":"خانه‌ها","cost":100,"unlock":0,"capacity":2,"jobs":0,"wage":0},
	"normal_house": {"name":"خانه معمولی","category":"خانه‌ها","cost":250,"unlock":5,"capacity":4,"jobs":0,"wage":0},
	"low_apartment": {"name":"آپارتمان کم‌ارتفاع","category":"خانه‌ها","cost":800,"unlock":20,"capacity":8,"jobs":0,"wage":0},
	"high_apartment": {"name":"آپارتمان بلند","category":"خانه‌ها","cost":3000,"unlock":100,"capacity":14,"jobs":0,"wage":0},
	"residential_tower": {"name":"برج مسکونی","category":"خانه‌ها","cost":10000,"unlock":500,"capacity":22,"jobs":0,"wage":0},
	"shopping_mall": {"name":"مرکز خرید","category":"کسب‌وکارها","cost":8000,"unlock":150,"jobs":30,"wage":65,"daily_revenue":420},
	"small_warehouse": {"name":"انبار کوچک","category":"انبارها","cost":500,"unlock":0,"storage":100,"jobs":0,"wage":0},
	"central_bank": {"name":"بانک مرکزی","category":"خدمات شهری","cost":5000,"unlock":100,"jobs":8,"wage":55},
	"municipal_bank": {"name":"بانک شهری","category":"خدمات شهری","cost":1500,"unlock":40,"jobs":3,"wage":42},
	"medium_warehouse": {"name":"انبار متوسط","category":"انبارها","cost":2000,"unlock":0,"storage":500,"jobs":0,"wage":0},
	"large_warehouse": {"name":"انبار بزرگ","category":"انبارها","cost":6000,"unlock":0,"storage":2000,"jobs":0,"wage":0},
	"huge_warehouse": {"name":"انبار عظیم","category":"انبارها","cost":20000,"unlock":0,"storage":10000,"jobs":0,"wage":0},
	"woodcutter": {"name":"چوب‌بری","category":"کارخانه‌ها","cost":900,"unlock":8,"jobs":4,"wage":32,"output":"wood","amount":2},
	"sawmill": {"name":"کارخانه الوارسازی","category":"کارخانه‌ها","cost":1800,"unlock":20,"jobs":3,"wage":42,"input":"wood","input_amount":2,"output":"lumber","amount":1},
	"carpenter": {"name":"کارگاه مبلمان","category":"کارخانه‌ها","cost":2600,"unlock":35,"jobs":3,"wage":48,"input":"lumber","input_amount":2,"output":"furniture","amount":1},
	"stone_mine": {"name":"معدن سنگ","category":"معادن","cost":1200,"unlock":10,"jobs":4,"wage":38,"output":"stone","amount":2},
	"iron_mine": {"name":"معدن آهن","category":"معادن","cost":2200,"unlock":30,"jobs":5,"wage":45,"output":"iron_ore","amount":1},
	"grocery_store": {"name":"فروشگاه مواد غذایی","category":"کسب‌وکارها","cost":300,"unlock":5,"jobs":3,"wage":30,"daily_revenue":24},
	"bakery": {"name":"نانوایی","category":"کسب‌وکارها","cost":400,"unlock":10,"jobs":4,"wage":35,"daily_revenue":36},
	"restaurant": {"name":"رستوران","category":"کسب‌وکارها","cost":1000,"unlock":25,"jobs":6,"wage":45,"daily_revenue":75},
	"office": {"name":"ساختمان اداری","category":"کسب‌وکارها","cost":1800,"unlock":40,"jobs":20,"wage":60,"daily_revenue":180},
	"factory": {"name":"کارخانه","category":"کسب‌وکارها","cost":6000,"unlock":100,"jobs":25,"wage":55,"daily_revenue":220},
	"mineral_market": {"name":"بازار مواد معدنی","category":"کسب‌وکارها","cost":500,"unlock":0,"jobs":1,"wage":35},
	"water_tower": {"name":"برج آب","category":"خدمات شهری","cost":500,"unlock":5,"jobs":2,"wage":30},
	"power_station": {"name":"نیروگاه","category":"خدمات شهری","cost":1000,"unlock":10,"jobs":4,"wage":40},
	"sewage_plant": {"name":"تصفیه‌خانه فاضلاب","category":"خدمات شهری","cost":1800,"unlock":25,"jobs":3,"wage":42},
	"waste_facility": {"name":"مرکز پسماند","category":"خدمات شهری","cost":1500,"unlock":30,"jobs":3,"wage":38},
	"school": {"name":"مدرسه","category":"خدمات شهری","cost":1200,"unlock":20,"jobs":5,"wage":40},
	"clinic": {"name":"درمانگاه","category":"خدمات شهری","cost":1400,"unlock":25,"jobs":4,"wage":45},
	"hospital": {"name":"بیمارستان","category":"خدمات شهری","cost":5000,"unlock":100,"jobs":12,"wage":55},
	"police_station": {"name":"کلانتری","category":"خدمات شهری","cost":2500,"unlock":80,"jobs":6,"wage":48},
	"fire_station": {"name":"آتش‌نشانی","category":"خدمات شهری","cost":2500,"unlock":80,"jobs":6,"wage":48},
	"small_park": {"name":"پارک کوچک","category":"تفریح و فرهنگ","cost":250,"unlock":10,"jobs":1,"wage":20},
	"playground": {"name":"زمین بازی","category":"تفریح و فرهنگ","cost":350,"unlock":15,"jobs":1,"wage":20},
	"sports_center": {"name":"مجموعه ورزشی","category":"تفریح و فرهنگ","cost":2500,"unlock":100,"jobs":5,"wage":40},
	"university": {"name":"دانشگاه","category":"خدمات شهری","cost":6000,"unlock":150,"jobs":15,"wage":60},
	"cultural_center": {"name":"مرکز فرهنگی","category":"تفریح و فرهنگ","cost":4500,"unlock":300,"jobs":8,"wage":50}
}

var state = {}

func new_game():
	state = {
		"version": 1,
		"day": 1,
		"money": 10000,
		"population": 4,
		"level": 1,
		"xp": 0,
		"reputation": 50,
		"central_bank_rebuild_days_left": 0,
		"forest_trees": 100,
		"mines": [],
		"buildings": [
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_warehouse","workers":0,"balance":0}
		],
		"resources": {"stone":0,"iron_ore":0,"wood":0,"lumber":0,"furniture":0},
		"market_stock": {"stone":100,"iron_ore":100,"wood":100,"lumber":100,"furniture":100},
		"citizens": [],
		"last_report": "شهر جدید ساخته شد. به مینی زکا سیتی خوش آمدی."
	}
	_sync_population()
	return state

func load_game():
	var file = File.new()
	if not file.file_exists(SAVE_PATH):
		return false
	if file.open(SAVE_PATH, File.READ) != OK:
		return false
	var parsed = parse_json(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != 1:
		return false
	state = parsed
	_normalize_state()
	_sync_population()
	return true

func save_game():
	var file = File.new()
	if file.open(SAVE_PATH, File.WRITE) != OK:
		return false
	file.store_string(to_json(state))
	file.close()
	return true

func _normalize_state():
	if typeof(state.get("buildings", null)) != TYPE_ARRAY:
		state.buildings = []
	if typeof(state.get("citizens", null)) != TYPE_ARRAY:
		state.citizens = []
	if typeof(state.get("resources", null)) != TYPE_DICTIONARY:
		state.resources = {}
	if typeof(state.get("market_stock", null)) != TYPE_DICTIONARY:
		state.market_stock = {}
	if not state.has("central_bank_rebuild_days_left"):
		state["central_bank_rebuild_days_left"] = 0
	if not state.has("forest_trees"):
		state["forest_trees"] = 100
	if typeof(state.get("mines", null)) != TYPE_ARRAY:
		state["mines"] = []
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

func get_forest_tree_count():
	return int(state.get("forest_trees", 0))

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
		if str(citizen.get("job", "")) != "":
			count += 1
	return count

func get_unemployed_count():
	return max(0, state.population - get_employed_count())

func get_job_capacity():
	var total = 0
	for building in state.buildings:
		total += int(BUILDINGS.get(building.id, {}).get("jobs", 0))
	return total

func build(id):
	if not BUILDINGS.has(id):
		return {"ok":false,"message":"این ساختمان تعریف نشده است."}
	var data = BUILDINGS[id]
	if int(state.population) < int(data.get("unlock", 0)):
		return {"ok":false,"message":"برای ساخت این ساختمان جمعیت کافی نیست."}
	if id == "central_bank" and int(state.get("central_bank_rebuild_days_left", 0)) > 0:
		return {"ok":false,"message":"برای ساخت دوباره بانک مرکزی باید %d روز صبر کنی." % int(state.central_bank_rebuild_days_left)}
	if not _spend_money(int(data.cost)):
		return {"ok":false,"message":"پول آزاد خزانه کافی نیست؛ ممکن است بخشی از پول به‌دلیل ظرفیت خزانه قفل شده باشد."}
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 0
	state.buildings.append({"id":id,"workers":0,"balance":0})
	var new_index = state.buildings.size() - 1
	if id in ["stone_mine", "iron_mine"]:
		_register_mine(new_index, id)
	_sync_population()
	assign_jobs()
	return {"ok":true,"message":data.name+" با موفقیت ساخته شد."}

func demolish(index):
	if index < 0 or index >= state.buildings.size():
		return {"ok":false,"message":"ساختمان پیدا نشد."}
	var id = state.buildings[index].id
	if id == "small_house" and get_building_count(id) <= 1:
		return {"ok":false,"message":"آخرین خانه شهر را نمی‌توان تخریب کرد."}
	state.buildings.remove(index)
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
	return {"ok":true,"message":"ساختمان تخریب شد. بازپرداختی انجام نشد."}

func assign_jobs():
	for citizen in state.citizens:
		citizen.job = ""
		citizen.job_building_index = -1
	var workplaces = []
	for i in range(state.buildings.size()):
		var data = BUILDINGS.get(state.buildings[i].id, {})
		for slot in range(int(data.get("jobs", 0))):
			workplaces.append(i)
	for citizen in state.citizens:
		if workplaces.empty():
			break
		var selected = 0
		var selected_distance = 999999
		for slot_index in range(workplaces.size()):
			var building_index = workplaces[slot_index]
			var distance = abs(building_index - int(citizen.id) % max(1, state.buildings.size()))
			if distance < selected_distance:
				selected_distance = distance
				selected = slot_index
		var building_index = workplaces[selected]
		citizen.job_building_index = building_index
		citizen.job = str(state.buildings[building_index].id)
		workplaces.remove(selected)

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
		var production = (5 if resource_id == "stone" else 3)
		production = min(production, get_free_storage())
		if resource_id == "iron_ore":
			production = min(production, int(mine.get("remaining", 0)))
		if production <= 0:
			mine.active = false
			state.mines[i] = mine
			continue
		if production <= 0:
			report.append("استخراج معدن متوقف شد؛ فضای انبار کافی نیست.")
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

func end_day():
	var report = []
	assign_jobs()
	var total_wages = 0
	for citizen in state.citizens:
		if citizen.job == "":
			continue
		total_wages += int(BUILDINGS.get(citizen.job, {}).get("wage", 0))
	var paid_wages = min(get_available_money(), total_wages)
	state.money = int(state.money) - paid_wages
	if paid_wages < total_wages:
		state.reputation = max(0, state.reputation - 3)
		report.append("کسری بودجه؛ بخشی از حقوق پرداخت نشد.")
	else:
		report.append("حقوق روزانه پرداخت شد: "+str(total_wages)+" سکه.")

	_advance_mines(report)
	# Forest regrowth is gradual and capped; logging consumes actual trees.
	state.forest_trees = min(100, int(state.forest_trees) + 2)
	var income = state.population * 2
	if income > 0:
		report.append("مالیات شهری دریافت شد: "+str(income)+" سکه.")
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		var data = BUILDINGS.get(building.id, {})
		var workers = _workers_for_building(building_index)
		if int(data.get("jobs", 0)) > 0 and workers == 0:
			continue
		var business_income = int(data.get("daily_revenue", 0))
		if business_income > 0:
			income += business_income
			report.append(data.name+" درآمد داشت: "+str(business_income)+" سکه.")

		var output = str(data.get("output", ""))
		if output == "" or workers == 0:
			continue
		var input = str(data.get("input", ""))
		var amount = int(data.get("amount", 0))
		if str(building.id) == "woodcutter" and int(state.forest_trees) <= 0:
			report.append("چوب‌بری متوقف شد؛ جنگل برای رشد دوباره درخت‌ها به زمان نیاز دارد.")
			continue
		if input != "":
			var input_amount = int(data.get("input_amount", 0))
			if int(state.resources.get(input, 0)) < input_amount:
				continue
		if get_free_storage() < amount:
			continue
		# Consume inputs only after confirming output can fit in storage.
		if input != "":
			state.resources[input] = int(state.resources.get(input, 0)) - int(data.get("input_amount", 0))
		if str(building.id) == "woodcutter":
			var felled = min(int(state.forest_trees), amount)
			state.forest_trees -= felled
			amount = felled
			if amount <= 0:
				continue
		state.resources[output] = int(state.resources.get(output, 0)) + amount
		report.append(data.name+" تولید کرد: "+str(amount)+" "+RESOURCES[output].name+".")

	var has_market = get_building_count("mineral_market") > 0
	if has_market:
		for id in RESOURCES.keys():
			var reserve = _get_reserve(id)
			var surplus = max(0, int(state.resources.get(id, 0)) - reserve)
			var market_room = max(0, 100 - int(state.market_stock.get(id, 0)))
			var sell_amount = min(surplus, market_room, 10)
			if sell_amount > 0:
				state.resources[id] -= sell_amount
				state.market_stock[id] = int(state.market_stock.get(id, 0)) + sell_amount
				var revenue = sell_amount * int(RESOURCES[id].sell)
				income += revenue
				report.append(str(sell_amount)+" واحد "+RESOURCES[id].name+" فروخته شد.")
	var accepted_income = _add_money(income)
	if accepted_income < income:
		report.append("ظرفیت خزانه پر است؛ %d سکه از درآمد امروز دریافت نشد." % (income - accepted_income))
	for restock_id in ["stone", "iron_ore"]:
		state.market_stock[restock_id] = min(100, int(state.market_stock.get(restock_id, 0)) + 5)

	var housing = get_housing_capacity()
	if state.population < housing and state.reputation >= 25:
		state.population += 1
		state.citizens.append({"id":_next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
		report.append("یک شهروند جدید به شهر مهاجرت کرد.")
		assign_jobs()

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
	state.day += 1
	state.xp += 5 + state.population
	if state.xp >= state.level * 100:
		state.xp -= state.level * 100
		state.level += 1
		report.append("سطح شهر به "+str(state.level)+" ارتقا یافت!")
	state.last_report = "\n".join(report)
	save_game()
	return state.last_report

func _workers_for(id):
	var count = 0
	for citizen in state.citizens:
		if citizen.job == id:
			count += 1
	return count

func _get_reserve(id):
	if id in ["stone","iron_ore"]:
		return STORAGE_RESERVE
	return int(FORESTRY_RESERVES.get(id, 0))

func buy_resource(id, amount):
	if not RESOURCES.has(id) or amount <= 0:
		return {"ok":false,"message":"درخواست خرید نامعتبر است."}
	var cost = int(RESOURCES[id].buy) * amount
	if get_available_money() < cost:
		return {"ok":false,"message":"پول آزاد کافی نیست."}
	if int(state.market_stock.get(id, 0)) < amount:
		return {"ok":false,"message":"موجودی بازار کافی نیست."}
	if get_free_storage() < amount:
		return {"ok":false,"message":"فضای خالی انبار کافی نیست."}
	_spend_money(cost)
	state.market_stock[id] -= amount
	state.resources[id] = int(state.resources.get(id, 0)) + amount
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
	state.resources[id] -= amount
	state.market_stock[id] += amount
	var revenue = amount * int(RESOURCES[id].sell)
	var accepted = _add_money(revenue)
	return {"ok":true,"message":"فروش انجام شد؛ درآمد دریافتی: "+str(accepted)+" سکه."}

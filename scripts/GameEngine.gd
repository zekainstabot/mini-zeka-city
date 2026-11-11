extends Reference
class_name MiniZekaCityEngine

const SAVE_PATH = "user://mini_zeka_city_save.json"
const STORAGE_RESERVE = 50
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
	{"id":"build_5","title":"گسترش شهر","description":"تعداد ساختمان‌های شهر را به ۵ برسان.","goal":5,"reward":500},
	{"id":"population_8","title":"جذب شهروند","description":"جمعیت شهر را به ۸ نفر برسان.","goal":8,"reward":700},
	{"id":"build_market","title":"تجارت شهری","description":"یک بازار مواد معدنی بساز.","goal":1,"reward":800},
	{"id":"level_3","title":"شهردار باتجربه","description":"به سطح ۳ شهر برس.","goal":3,"reward":1200}
]

const RESOURCES = {
	"stone": {"name": "سنگ", "buy": 18, "sell": 12},
	"iron_ore": {"name": "سنگ‌آهن", "buy": 42, "sell": 30},
	"wood": {"name": "چوب", "buy": 22, "sell": 15},
	"lumber": {"name": "الوار", "buy": 50, "sell": 36},
	"furniture": {"name": "مبلمان", "buy": 130, "sell": 95},
	"food": {"name": "مواد غذایی", "buy": 10, "sell": 6}
}

const TRADE_CITIES = {
	"mehrabad": {"name":"مهرآباد","price_factor":1.20,"daily_capacity":25,"travel_days":1,"demand":{"stone":20,"iron_ore":10,"wood":25,"lumber":15,"furniture":8},"supply":{"stone":35,"iron_ore":12,"wood":8,"lumber":10,"furniture":5}},
	"navid": {"name":"نویدشهر","price_factor":1.35,"daily_capacity":18,"travel_days":2,"demand":{"stone":8,"iron_ore":25,"wood":10,"lumber":20,"furniture":18},"supply":{"stone":8,"iron_ore":40,"wood":10,"lumber":25,"furniture":22}},
	"golestan": {"name":"گلستان","price_factor":1.12,"daily_capacity":30,"travel_days":1,"demand":{"stone":15,"iron_ore":8,"wood":18,"lumber":12,"furniture":25},"supply":{"stone":18,"iron_ore":8,"wood":30,"lumber":18,"furniture":35}}
}

const BUILDINGS = {
	"small_house": {"name":"خانه کوچک","category":"خانه‌ها","cost":100,"unlock":0,"capacity":2,"jobs":0,"wage":0},
	"normal_house": {"name":"خانه معمولی","category":"خانه‌ها","cost":250,"unlock":5,"capacity":4,"jobs":0,"wage":0,"level_unlock":2},
	"low_apartment": {"name":"آپارتمان کم‌ارتفاع","category":"خانه‌ها","cost":800,"unlock":20,"capacity":8,"jobs":0,"wage":0,"level_unlock":3},
	"high_apartment": {"name":"آپارتمان بلند","category":"خانه‌ها","cost":3000,"unlock":100,"capacity":14,"jobs":0,"wage":0,"level_unlock":5},
	"residential_tower": {"name":"برج مسکونی","category":"خانه‌ها","cost":10000,"unlock":500,"capacity":22,"jobs":0,"wage":0,"level_unlock":8},
	"transport_depot": {"name":"پایانه حمل‌ونقل","category":"زیرساخت","cost":1800,"unlock":15,"jobs":4,"wage":40,"level_unlock":2},
	"farm": {"name":"مزرعه","category":"کشاورزی","cost":1200,"unlock":8,"jobs":4,"wage":35,"output":"food","amount":8,"level_unlock":2},
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
		"version": 10,
		"day": 1,
		"clock_last_unix": OS.get_unix_time(),
		"clock_cycle_seconds": 0,
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
		"road_level": 1,
		"transport_used_today": 0,
		"needs": {"food":65,"water":70,"power":70,"health":70,"education":50,"safety":70,"leisure":50,"sanitation":70},
		"services": {},
		"missions": [],
		"central_bank_rebuild_days_left": 0,
		"forest_trees": 100,
		"mines": [],
		"buildings": [
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_house","workers":0,"balance":0},
			{"id":"small_warehouse","workers":0,"balance":0}
		],
		"resources": {"stone":0,"iron_ore":0,"wood":0,"lumber":0,"furniture":0,"food":0},
		"market_stock": {"stone":60,"iron_ore":60,"wood":60,"lumber":60,"furniture":60,"food":60},
		"trade_remaining": {"mehrabad":25,"navid":18,"golestan":30},
		"trade_demand_remaining": {"mehrabad":{"stone":20,"iron_ore":10,"wood":25,"lumber":15,"furniture":8},"navid":{"stone":8,"iron_ore":25,"wood":10,"lumber":20,"furniture":18},"golestan":{"stone":15,"iron_ore":8,"wood":18,"lumber":12,"furniture":25}},
		"last_trade_report": "هنوز معامله بین‌شهری انجام نشده است.",
		"city_export_stock": {"mehrabad":{"stone":35,"iron_ore":12,"wood":8,"lumber":10,"furniture":5},"navid":{"stone":8,"iron_ore":40,"wood":10,"lumber":25,"furniture":22},"golestan":{"stone":18,"iron_ore":8,"wood":30,"lumber":18,"furniture":35}},
		"trade_shipments": [],
		"import_contracts": [],
		"last_import_report": "هنوز محموله‌ای سفارش داده نشده است.",
		"citizens": [],
		"last_economy": {"tax_income":0,"business_income":0,"resource_income":0,"gross_income":0,"accepted_income":0,"wages_due":0,"wages_paid":0,"fleet_maintenance":0,"road_maintenance":0,"maintenance_paid":0,"net_cashflow":0},
		"last_report": "شهر جدید ساخته شد. به مینی زکا سیتی خوش آمدی."
	}
	_sync_population()
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
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) < 1 or int(parsed.get("version", 0)) > 10:
		return false
	state = parsed
	_normalize_state()
	_sync_population()
	_sync_missions()
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
		citizen["wallet"] = int(clamp(int(citizen.get("wallet", 100)), 0, 500))
	for building in state.buildings:
		building["balance"] = max(0, int(building.get("balance", 0)))
	if typeof(state.get("missions", null)) != TYPE_ARRAY:
		state["missions"] = []
	if typeof(state.get("mines", null)) != TYPE_ARRAY:
		state["mines"] = []
	# Save schema migration: add dynamic market, trade and shipping state.
	state["version"] = 10
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

func get_land_size(id):
	var sizes = {
		"small_house":1,"normal_house":2,"low_apartment":3,"high_apartment":4,"residential_tower":5,
		"small_warehouse":1,"medium_warehouse":2,"large_warehouse":3,"huge_warehouse":5,
		"mineral_market":1,"small_park":1,"playground":1,"grocery_store":1,"bakery":1,"water_tower":1,
		"farm":2,"woodcutter":2,"stone_mine":2,"transport_depot":2,"restaurant":2,"office":2,
		"municipal_bank":2,"power_station":2,"sawmill":2,"sewage_plant":2,"waste_facility":2,
		"school":3,"clinic":3,"iron_mine":3,"carpenter":3,"sports_center":3,"fire_station":3,"police_station":3,
		"central_bank":4,"factory":4,"hospital":4,"university":5,"shopping_mall":5,"cultural_center":4
	}
	return int(sizes.get(str(id), 1))

func get_land_used():
	var used = 0
	for building in state.get("buildings", []):
		used += get_land_size(str(building.get("id", "")))
	for project in state.get("constructions", []):
		used += get_land_size(str(project.get("id", "")))
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
	var required_land = get_land_size(id)
	if get_land_free() < required_land:
		return {"ok":false,"message":"زمین کافی نداری؛ این ساختمان %d قطعه زمین می‌خواهد و فقط %d قطعه آزاد داری. ابتدا زمین بخر." % [required_land,get_land_free()]}
	if not _spend_money(int(data.cost)):
		return {"ok":false,"message":"پول آزاد خزانه کافی نیست؛ ممکن است بخشی از پول به‌دلیل ظرفیت خزانه قفل شده باشد."}
	var construction_times = {
		"small_house":60,"normal_house":120,"low_apartment":180,"high_apartment":240,"residential_tower":300,
		"small_warehouse":60,"mineral_market":60,"small_park":60,"playground":60,
		"grocery_store":60,"bakery":60,"water_tower":60,
		"farm":120,"woodcutter":120,"stone_mine":120,"transport_depot":120,
		"restaurant":120,"office":120,"municipal_bank":120,"power_station":120,
		"medium_warehouse":120,"sawmill":120,"sewage_plant":120,"waste_facility":120,
		"school":180,"clinic":180,"iron_mine":180,"carpenter":180,"sports_center":180,
		"large_warehouse":180,"fire_station":180,"police_station":180,
		"central_bank":240,"factory":240,"hospital":240,"university":300,
		"huge_warehouse":300,"shopping_mall":300,"cultural_center":300
	}
	if construction_times.has(id):
		var seconds = int(construction_times[id])
		state.constructions.append({"id":id,"finish_at":OS.get_unix_time()+seconds})
		save_game()
		return {"ok":true,"message":data.name+" شروع شد؛ زمان ساخت: %d دقیقه. هزینه پرداخت شد." % int(ceil(float(seconds)/60.0))}
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 0
	state.buildings.append({"id":id,"workers":0,"balance":0})
	var new_index = state.buildings.size() - 1
	if id in ["stone_mine", "iron_mine"]:
		_register_mine(new_index, id)
	_sync_population()
	assign_jobs()
	_update_missions()
	save_game()
	return {"ok":true,"message":data.name+" با موفقیت ساخته شد."}

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
			state.buildings.append({"id":id,"workers":0,"balance":0})
			var new_index = state.buildings.size() - 1
			if id in ["stone_mine", "iron_mine"]:
				_register_mine(new_index, id)
			if id == "central_bank":
				state.central_bank_rebuild_days_left = 0
			completed.append(str(BUILDINGS[id].name))
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
	save_game()
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
	# The menu-based game has no road coordinates. Assign open job
	# slots in a stable, fair order instead of inventing fake distances.
	for citizen_index in range(state.citizens.size()):
		if workplaces.empty():
			break
		var building_index = workplaces[0]
		var citizen = state.citizens[citizen_index]
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
		var production = (5 if resource_id == "stone" else 3)
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
		var data = BUILDINGS.get(building_id, {})
		if str(data.get("service_need", "")) != need_id:
			continue
		var jobs = int(data.get("jobs", 0))
		if jobs > 0 and _workers_for_building(i) <= 0:
			continue
		capacity += int(data.get("service_capacity", 0))
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
		total_need += int(needs[need_id])
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
	for definition in MISSION_DEFINITIONS:
		var found = false
		for mission in state.missions:
			if str(mission.get("id", "")) == str(definition.id):
				found = true
				break
		if not found:
			state.missions.append({"id":definition.id,"progress":0,"completed":false,"claimed":false})
	_update_missions()

func _get_mission_progress(mission_id):
	match mission_id:
		"build_5":
			return state.buildings.size()
		"population_8":
			return int(state.population)
		"build_market":
			return get_building_count("mineral_market")
		"level_3":
			return int(state.level)
	return 0

func _update_missions():
	for i in range(state.missions.size()):
		var mission = state.missions[i]
		var mission_id = str(mission.get("id", ""))
		for definition in MISSION_DEFINITIONS:
			if str(definition.id) != mission_id:
				continue
			var progress = min(int(definition.goal), _get_mission_progress(mission_id))
			mission.progress = progress
			mission.completed = progress >= int(definition.goal)
			state.missions[i] = mission
			break

func get_missions():
	_update_missions()
	return state.get("missions", [])

func claim_mission(mission_index):
	if mission_index < 0 or mission_index >= state.missions.size():
		return {"ok":false,"message":"ماموریت پیدا نشد."}
	var mission = state.missions[mission_index]
	if not bool(mission.get("completed", false)):
		return {"ok":false,"message":"این ماموریت هنوز کامل نشده است."}
	if bool(mission.get("claimed", false)):
		return {"ok":false,"message":"پاداش این ماموریت قبلاً دریافت شده است."}
	var reward = 0
	for definition in MISSION_DEFINITIONS:
		if str(definition.id) == str(mission.get("id", "")):
			reward = int(definition.reward)
			break
	var accepted = _add_money(reward)
	if accepted < reward:
		return {"ok":false,"message":"ظرفیت خزانه برای دریافت کامل پاداش کافی نیست."}
	mission.claimed = true
	state.missions[mission_index] = mission
	save_game()
	return {"ok":true,"message":"پاداش ماموریت دریافت شد: %d سکه." % reward}

func get_xp_required_for_next_level():
	return max(100, int(state.get("level", 1)) * 100)

func get_daily_xp_gain():
	# XP grows with city size, but is deliberately capped so a large city
	# cannot skip many levels in a single day.
	var population_bonus = int(sqrt(float(max(0, int(state.get("population", 0))))) * 2.0)
	var building_bonus = min(10, state.get("buildings", []).size())
	return int(clamp(5 + population_bonus + building_bonus, 5, 60))

func end_day():
	var report = []
	assign_jobs()
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
	var tax_income = int(state.population) * 2
	var business_income_total = 0
	var resource_income_total = 0
	var citizen_market = _process_citizen_purchases(report)
	var consumer_tax_income = int(citizen_market.tax)
	var income = tax_income + consumer_tax_income
	if tax_income > 0:
		report.append("مالیات شهری دریافت شد: "+str(tax_income)+" سکه.")
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
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
		if business_income > 0:
			income += business_income
			business_income_total += business_income
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
	var accepted_income = _add_money(income)
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
		"resource_income": resource_income_total,
		"gross_income": income,
		"accepted_income": accepted_income,
		"wages_due": total_wages,
		"wages_paid": paid_wages,
		"fleet_maintenance": fleet_maintenance,
		"road_maintenance": road_maintenance,
		"maintenance_paid": maintenance_paid,
		"net_cashflow": accepted_income - paid_wages - maintenance_paid
	}
	report.append("خلاصه مالی: درآمد %d | حقوق %d | تغییر خالص خزانه %d سکه." % [accepted_income, paid_wages, accepted_income - paid_wages - maintenance_paid])
	for restock_id in RESOURCES.keys():
		state.market_stock[restock_id] = min(100, int(state.market_stock.get(restock_id, 0)) + 5)
	_refresh_trade_capacity()

	_process_citizen_recruitment(report)

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

func get_trade_export_price(city_id, resource_id):
	if not TRADE_CITIES.has(city_id) or not RESOURCES.has(resource_id):
		return 0
	var city = TRADE_CITIES[city_id]
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

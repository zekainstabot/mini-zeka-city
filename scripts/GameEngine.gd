extends RefCounted
class_name MiniZekaCityEngine

const CitizenSociety = preload("res://scripts/CitizenSociety.gd")
const GameData = preload("res://scripts/GameData.gd")
const GameRanking = preload("res://scripts/GameRanking.gd")
const BankingSystem = preload("res://scripts/BankingSystem.gd")
const TradeSystem = preload("res://scripts/TradeSystem.gd")
const StorageSystem = preload("res://scripts/StorageSystem.gd")
const CityServicesSystem = preload("res://scripts/CityServicesSystem.gd")
const MissionSystem = preload("res://scripts/MissionSystem.gd")
const CityPopulationSystem = preload("res://scripts/CityPopulationSystem.gd")
const CityConstructionSystem = preload("res://scripts/CityConstructionSystem.gd")

const SAVE_PATH = "user://mini_zeka_city_save.json"
const STORAGE_RESERVE = 50
const MAX_CONCURRENT_CONSTRUCTIONS = 2
const DISTRICT_HOUSE_LIMIT = 20
const DISTRICT_OTHER_LIMIT = 20
const DISTRICT_EMERGENCY_LIMIT = 10
const DISTRICT_BUILDING_TYPE_LIMIT = 2
const DISTRICT_EMERGENCY_BUILDINGS = ["clinic","hospital","police_station","fire_station"]
const OUTSIDE_CITY_BUILDINGS = ["woodcutter","sawmill","carpenter","stone_mine","iron_mine","fishing_dock","factory","fish_processing_plant","power_station","sewage_plant","waste_facility"]
const FORESTRY_RESERVES = {"wood": 20, "lumber": 10, "furniture": 0}

const SERVICE_GROUPS = GameData.SERVICE_GROUPS
const MISSION_DEFINITIONS = GameData.MISSION_DEFINITIONS
const RESOURCES = GameData.RESOURCES
var TRADE_CITIES = {
	"mehrabad": {"name":"مهرآباد","price_factor":1.20,"daily_capacity":25,"travel_days":1,"demand":{"stone":20,"iron_ore":10,"wood":25,"lumber":15,"furniture":8},"supply":{"stone":35,"iron_ore":12,"wood":8,"lumber":10,"furniture":5}},
	"navid": {"name":"نویدشهر","price_factor":1.35,"daily_capacity":18,"travel_days":2,"demand":{"stone":8,"iron_ore":25,"wood":10,"lumber":20,"furniture":18},"supply":{"stone":8,"iron_ore":40,"wood":10,"lumber":25,"furniture":22}},
	"golestan": {"name":"گلستان","price_factor":1.12,"daily_capacity":30,"travel_days":1,"demand":{"stone":15,"iron_ore":8,"wood":18,"lumber":12,"furniture":25},"supply":{"stone":18,"iron_ore":8,"wood":30,"lumber":18,"furniture":35}}
}

func _init():
	randomize()
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

const BUILDINGS = GameData.BUILDINGS
var state = {}

const CITY_NAME_POOL = GameData.CITY_NAME_POOL
func get_random_city_name():
	var choices = CITY_NAME_POOL.duplicate(true)
	choices.shuffle()
	return str(choices[0].name)

func _sync_rival_cities():
	var player_name = str(state.get("city_name", "")).strip_edges()
	var previous_player_name = str(state.get("rival_roster_player_name", ""))
	var excluded_id = str(state.get("rival_roster_excluded_id", ""))
	if previous_player_name != player_name or excluded_id.is_empty():
		excluded_id = ""
		for city in CITY_NAME_POOL:
			if str(city.name) == player_name:
				excluded_id = str(city.id)
				break
		if excluded_id.is_empty():
			excluded_id = str(CITY_NAME_POOL[randi() % CITY_NAME_POOL.size()].id)
		state["rival_roster_player_name"] = player_name
		state["rival_roster_excluded_id"] = excluded_id
	var existing = {}
	for rival in state.get("rival_cities", []):
		existing[str(rival.get("name", ""))] = rival.duplicate(true)
	var rivals = []
	for city in CITY_NAME_POOL:
		var rival_id = str(city.id)
		if rival_id == excluded_id:
			continue
		var rival_name = str(city.name)
		var rival_data = existing.get(rival_name, {})
		if rival_data.is_empty():
			var index = rivals.size()
			rival_data = {
				"id": rival_id + "_rival",
				"name": rival_name,
				"population": 16 + index * 3,
				"level": 2 + (index % 3),
				"buildings": 6 + index,
				"wealth": 5000 + index * 1250,
				"satisfaction": 58 + (index % 5) * 5,
				"score": 280 + index * 115,
				"district_count": max(1, int(ceil(float(6 + index) / 3.0))),
				"xp": int(randi() % 100),
				"ai_style_index": int(randi() % 4),
				"ai_actions": 0
			}
		else:
			# Give older saves independent AI and XP profiles exactly once.
			if not rival_data.has("ai_style_index"):
				rival_data["ai_style_index"] = int(randi() % 4)
			if not rival_data.has("xp"):
				rival_data["xp"] = int(randi() % 100)
			if not rival_data.has("district_count"):
				rival_data["district_count"] = max(1, int(ceil(float(int(rival_data.get("buildings", 1))) / 3.0)))
			rival_data["ai_actions"] = int(rival_data.get("ai_actions", 0))
		rival_data["id"] = rival_id + "_rival"
		rival_data["name"] = rival_name
		rivals.append(rival_data)
	state["rival_cities"] = rivals

func new_game():
	state = {
		"version": 18,
		"city_name": "",
		"districts": [],
		"day": 1,
		"clock_last_unix": Time.get_unix_time_from_system(),
		"clock_cycle_seconds": 0,
		"pending_offline_income": 0,
		"pending_offline_days": 0,
		"daily_trade_city_ids": [],
		"daily_trade_city_day": 0,
		"daily_trade_city_level": 0,
		"money": 10000,
		"population": 4,
		"citizen_recruitment_mode": "auto",
		"citizen_recruitment_timer": 0.0,
		"citizen_requests": [],
		"constructions": [],
		"land_owned": 10,
		"level": 1,
		"xp": 0,
		"reputation": 50,
		"satisfaction": 50,
		"last_login_day_serial": -1,
		"next_resident_request_day": 4,
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
		"daily_missions": {},
		"login_reward_claimed_day_serial": -1,
		"city_event_history": [],
		"city_event_next_day": 3,
		"resident_requests": [],
		"next_resident_request_id": 1,
		"achievements": {},
		"city_records": {},
		"long_term_project_claimed": [],
		"weekly_challenge": {},
		"rival_cities": [],
		"mystery_active": {},
		"mystery_completed": [],
		"mystery_next_day": 4,
		"landmark_project": {},
		"landmark_projects_completed": [],
		"pending_city_decision": {},
		"next_city_decision_day": 6,
		"weekly_city_event": {},
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
		"active_service_report_keys": [],
		"district_service_coverage": {},
		"report_events": [{"timestamp":Time.get_unix_time_from_system(),"day":1,"message":"شهر جدید ساخته شد. به مینی زکا سیتی خوش آمدی."}]
	}
	_sync_rival_cities()
	_sync_population()
	CitizenSociety.new().ensure_state(self)
	_ensure_building_locations()
	_sync_missions()
	return state

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var parsed = test_json_conv.get_data()
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) < 1 or int(parsed.get("version", 0)) > 18:
		return false
	state = parsed
	state["city_name"] = str(state.get("city_name", "")).strip_edges()
	_normalize_state()
	_sync_rival_cities()
	_sync_population()
	CitizenSociety.new().ensure_state(self)
	_ensure_building_locations()
	_sync_missions()
	return true


# Convert the local calendar date to a monotonic day number without relying on UTC.
func _get_local_calendar_day_serial():
	var date = Time.get_date_dict_from_system()
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

func _ensure_daily_missions():
	return MissionSystem._ensure_daily_missions(self)


func get_daily_missions():
	return MissionSystem.get_daily_missions(self)


func claim_daily_mission(mission_id):
	return MissionSystem.claim_daily_mission(self, mission_id)


func get_login_reward_status():
	var today = _get_local_calendar_day_serial()
	var streak = max(1, int(state.get("login_streak", 1)))
	var reward = min(400, 100 + (streak - 1) * 25)
	return {
		"streak":streak,
		"reward":reward,
		"claimed":int(state.get("login_reward_claimed_day_serial", -1)) == today,
		"logged_in":int(state.get("last_login_day_serial", -1)) == today
	}

func claim_login_reward():
	var status = get_login_reward_status()
	if not bool(status.logged_in):
		return {"ok":false,"message":"برای دریافت هدیه، ابتدا امروز وارد شهر شو."}
	if bool(status.claimed):
		return {"ok":false,"message":"هدیه ورود امروز را قبلاً دریافت کرده‌ای."}
	var reward = int(status.reward)
	if get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت هدیه کافی نیست؛ ابتدا کمی از موجودی خرج کن."}
	_add_money(reward)
	state["login_reward_claimed_day_serial"] = _get_local_calendar_day_serial()
	var xp_message = _award_xp(5)
	save_game()
	return {"ok":true,"message":"هدیه ورود امروز: %d سکه + ۵ تجربه. %s" % [reward, xp_message]}

func _process_city_event(report):
	var current_day = int(state.get("day", 1))
	if current_day < int(state.get("city_event_next_day", current_day + 1)):
		return
	state["city_event_next_day"] = current_day + 2 + int(randi() % 3)
	if int(randi() % 100) >= 38:
		return
	var events = [
		{"id":"market_fair","title":"بازار پررونق","description":"بازار شهر شلوغ شد و فروش کسب‌وکارها رونق گرفت."},
		{"id":"city_festival","title":"جشن محلی","description":"جشن محلی حال‌وهوای شهر را بهتر کرد."},
		{"id":"volunteer_day","title":"روز همیاری شهروندان","description":"گروهی از شهروندان برای پاکیزگی و زیباسازی شهر داوطلب شدند."},
		{"id":"water_warning","title":"هشدار کم‌آبی","description":"مصرف آب بالا رفت؛ مدیریت منابع آب اهمیت بیشتری پیدا کرد."},
		{"id":"investor_visit","title":"بازدید سرمایه‌گذار","description":"یک سرمایه‌گذار از ظرفیت رشد شهر استقبال کرد."},
		{"id":"small_fire","title":"حادثه آتش‌سوزی","description":"در یکی از محله‌ها آتش‌سوزی کوچکی گزارش شد."}
	]
	var event = events[int(randi() % events.size())]
	var message = str(event.description)
	match str(event.id):
		"market_fair":
			var bonus = min(450, int(state.get("population", 0)) * 12)
			var accepted = _add_money(bonus)
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 2, 0, 100))
			message += " درآمد ویژه بازار: %d سکه." % accepted
		"city_festival":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 5, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
			state["needs"]["leisure"] = int(clamp(int(state.needs.get("leisure", 50)) + 6, 0, 100))
		"volunteer_day":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 3, 0, 100))
			state["needs"]["sanitation"] = int(clamp(int(state.needs.get("sanitation", 50)) + 7, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
		"water_warning":
			var impact = 3 if get_building_count("water_tower") > 0 else 6
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) - impact, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 2, 0, 100))
		"investor_visit":
			var investment = min(500, 100 + int(state.get("level", 1)) * 35)
			var accepted_investment = _add_money(investment)
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
			message += " کمک سرمایه‌گذار: %d سکه." % accepted_investment
		"small_fire":
			if get_building_count("fire_station") > 0:
				state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
				message += " ایستگاه آتش‌نشانی حادثه را سریع مهار کرد."
			else:
				state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 4, 0, 100))
				state["reputation"] = int(clamp(int(state.get("reputation", 50)) - 2, 0, 100))
				message += " نبود ایستگاه آتش‌نشانی خسارت اجتماعی را بیشتر کرد؛ ساختمانی تخریب نشد."
	var history = state.get("city_event_history", [])
	history.append({"day":current_day,"id":str(event.id),"title":str(event.title),"message":message})
	while history.size() > 20:
		history.pop_front()
	state["city_event_history"] = history
	report.append("🎲 رویداد شهر | %s: %s" % [str(event.title), message])

func _process_resident_requests(report):
	var requests = state.get("resident_requests", [])
	for index in range(requests.size() - 1, -1, -1):
		var request = requests[index]
		if bool(request.get("accepted", false)):
			if get_building_count(str(request.get("building_id", ""))) > 0:
				var reward = int(request.get("reward", 80))
				if get_treasury_capacity() - int(state.get("money", 0)) >= reward:
					_add_money(reward)
					state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 3, 0, 100))
					report.append("درخواست شهروندان انجام شد؛ %d سکه پاداش و رضایت بیشتر دریافت کردی." % reward)
					requests.remove_at(index)
					continue
				else:
					report.append("ساختمان درخواستی شهروندان ساخته شد؛ برای دریافت پاداش %d سکه‌ای باید ظرفیت خزانه را خالی کنی." % reward)
					continue
		if int(state.get("day", 1)) - int(request.get("day", 1)) >= 7:
			if bool(request.get("accepted", false)):
				state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
			requests.remove_at(index)
	state["resident_requests"] = requests
	var next_day = int(state.get("next_resident_request_day", 1))
	if int(state.get("day", 1)) < next_day or requests.size() >= 2:
		return
	var candidates = [
		{"need":"water","building":"water_tower","name":"برج آب","threshold":65},
		{"need":"power","building":"power_station","name":"نیروگاه","threshold":65},
		{"need":"health","building":"clinic","name":"درمانگاه","threshold":65},
		{"need":"education","building":"school","name":"مدرسه","threshold":60},
		{"need":"safety","building":"police_station","name":"کلانتری","threshold":65},
		{"need":"leisure","building":"small_park","name":"پارک کوچک","threshold":65},
		{"need":"sanitation","building":"waste_facility","name":"مرکز پسماند","threshold":65}
	]
	var selected = {}
	var lowest = 101
	for candidate in candidates:
		var need_value = int(state.get("needs", {}).get(str(candidate.need), 100))
		var building_data = BUILDINGS.get(str(candidate.building), {})
		if need_value >= int(candidate.threshold) or building_data.is_empty():
			continue
		if get_building_count(str(candidate.building)) > 0:
			continue
		if int(state.get("level", 1)) < int(building_data.get("level_unlock", 1)) or int(state.get("population", 0)) < int(building_data.get("unlock", 0)):
			continue
		if get_land_free() < get_land_size(str(candidate.building)):
			continue
		var duplicate_request = false
		for existing in requests:
			if str(existing.get("building_id", "")) == str(candidate.building):
				duplicate_request = true
				break
		if duplicate_request:
			continue
		if need_value < lowest:
			lowest = need_value
			selected = candidate
	if selected.is_empty():
		state["next_resident_request_day"] = int(state.get("day", 1)) + 3
		return
	var citizen_id = 0
	if not state.get("citizens", []).is_empty():
		var citizen = state.citizens[int(randi() % state.citizens.size())]
		citizen_id = int(citizen.get("id", 0))
	var request_id = int(state.get("next_resident_request_id", 1))
	state["next_resident_request_id"] = request_id + 1
	requests.append({
		"id":request_id,
		"citizen_id":citizen_id,
		"day":int(state.get("day", 1)),
		"need":str(selected.need),
		"building_id":str(selected.building),
		"title":"درخواست ساخت %s" % str(selected.name),
		"description":"پوشش خدمت «%s» پایین است. شهروندان خواستار ساخت %s هستند." % [str(selected.need), str(selected.name)],
		"reward":80,
		"accepted":false
	})
	state["resident_requests"] = requests
	state["next_resident_request_day"] = int(state.get("day", 1)) + 3 + int(randi() % 3)
	report.append("درخواست تازه شهروندان ثبت شد: ساخت %s." % str(selected.name))

func resolve_resident_request(request_id, accepted):
	var requests = state.get("resident_requests", [])
	for index in range(requests.size()):
		if int(requests[index].get("id", 0)) != int(request_id):
			continue
		if bool(requests[index].get("accepted", false)):
			return {"ok":false,"message":"این درخواست قبلاً پذیرفته شده است."}
		if bool(accepted):
			requests[index]["accepted"] = true
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 1, 0, 100))
			state["resident_requests"] = requests
			save_game()
			return {"ok":true,"message":"درخواست پذیرفته شد؛ با ساخت ساختمان پیشنهادی، پاداش و رضایت شهروندان را می‌گیری."}
		requests.remove_at(index)
		state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
		state["resident_requests"] = requests
		save_game()
		return {"ok":true,"message":"درخواست رد شد؛ رضایت شهروندان کمی کاهش یافت."}
	return {"ok":false,"message":"درخواست شهروند پیدا نشد."}

const ACHIEVEMENT_DEFINITIONS = GameData.ACHIEVEMENT_DEFINITIONS
func _update_city_records():
	var records = state.get("city_records", {})
	records["peak_population"] = max(int(records.get("peak_population", 0)), int(state.get("population", 0)))
	records["peak_money"] = max(int(records.get("peak_money", 0)), int(state.get("money", 0)))
	records["peak_level"] = max(int(records.get("peak_level", 1)), int(state.get("level", 1)))
	records["peak_satisfaction"] = max(int(records.get("peak_satisfaction", 0)), int(state.get("satisfaction", 0)))
	records["most_buildings"] = max(int(records.get("most_buildings", 0)), state.get("buildings", []).size())
	state["city_records"] = records

func _update_achievements():
	_update_city_records()
	var unlocked = state.get("achievements", {})
	for achievement in ACHIEVEMENT_DEFINITIONS:
		var id = str(achievement.id)
		if bool(unlocked.get(id, false)):
			continue
		var done = false
		match id:
			"first_expansion":
				done = state.get("buildings", []).size() >= 5
			"population_20":
				done = int(state.get("population", 0)) >= 20
			"level_5":
				done = int(state.get("level", 1)) >= 5
			"treasury_20000":
				done = int(state.get("money", 0)) >= 20000
			"happy_city":
				done = int(state.get("satisfaction", 0)) >= 85
			"login_streak_7":
				done = int(state.get("login_streak", 0)) >= 7
			"trade_50":
				done = int(state.get("trade_exported_units_total", 0)) >= 50
			"two_districts":
				done = state.get("districts", []).size() >= 2
			"production_chain":
				done = get_building_count("woodcutter") > 0 and get_building_count("sawmill") > 0 and get_building_count("carpenter") > 0
		if done:
			unlocked[id] = true
	state["achievements"] = unlocked

func get_achievements():
	_update_achievements()
	var result = []
	for definition in ACHIEVEMENT_DEFINITIONS:
		var item = definition.duplicate(true)
		item["unlocked"] = bool(state.get("achievements", {}).get(str(definition.id), false))
		result.append(item)
	return result

func get_city_records():
	_update_city_records()
	return state.get("city_records", {}).duplicate(true)

func get_geographic_rank_for_district_count(district_count):
	return GameRanking.geographic_rank_for_district_count(district_count)


func get_city_league():
	return GameRanking.city_league(state)


func get_weekly_city_event():
	var today = _get_local_calendar_day_serial()
	var week_serial = int(floor(float(today) / 7.0))
	var saved = state.get("weekly_city_event", {})
	if int(saved.get("week_serial", -1)) != week_serial:
		var rotation = int(week_serial % 4)
		var events = [
			{"id":"market_boom","title":"هفته رونق بازار","description":"کسب‌وکارهای شهر این هفته ۱۰٪ درآمد بیشتری دارند.","effect":"۱۰٪ درآمد اضافه کسب‌وکارها"},
			{"id":"festival_week","title":"هفته جشنواره شهر","description":"برنامه‌های فرهنگی حال‌وهوای شهر را بهتر می‌کنند.","effect":"هر روز ۱ امتیاز رضایت بیشتر"},
			{"id":"energy_saving","title":"هفته صرفه‌جویی انرژی","description":"مدیریت شهری هزینه نگهداری ناوگان و جاده را کاهش داده است.","effect":"۱۵٪ کاهش هزینه نگهداری"},
			{"id":"development_week","title":"هفته توسعه و آموزش","description":"فعالیت‌های عمرانی و آموزشی تجربه بیشتری تولید می‌کنند.","effect":"۲۰ تجربه اضافه در پایان هر روز"}
		]
		saved = events[rotation].duplicate(true)
		saved["week_serial"] = week_serial
		state["weekly_city_event"] = saved
		save_game()
	return saved.duplicate(true)

func get_weekly_challenge():
	var today = _get_local_calendar_day_serial()
	var week_serial = int(floor(float(today) / 7.0))
	var challenge = state.get("weekly_challenge", {})
	if int(challenge.get("week_serial", -1)) != week_serial:
		challenge = {
			"week_serial":week_serial,
			"baseline_buildings":state.get("buildings", []).size(),
			"baseline_population":int(state.get("population", 0)),
			"baseline_exports":int(state.get("trade_exported_units_total", 0)),
			"baseline_money":int(state.get("money", 0)),
			"claimed":false
		}
		state["weekly_challenge"] = challenge
		save_game()
	var rotation = int(week_serial % 4)
	var progress = 0
	var goal = 1
	var title = ""
	var description = ""
	var reward = 700
	var xp = 50
	match rotation:
		0:
			title = "هفته سازندگی"
			description = "این هفته حداقل ۲ ساختمان جدید بساز."
			progress = max(0, state.get("buildings", []).size() - int(challenge.get("baseline_buildings", 0)))
			goal = 2
			reward = 800
			xp = 55
		1:
			title = "هفته تجارت"
			description = "این هفته ۱۰ واحد کالا به شهرهای همسایه صادر کن."
			progress = max(0, int(state.get("trade_exported_units_total", 0)) - int(challenge.get("baseline_exports", 0)))
			goal = 10
			reward = 900
			xp = 60
		2:
			title = "هفته رشد جمعیت"
			description = "این هفته جمعیت شهر را ۵ نفر افزایش بده."
			progress = max(0, int(state.get("population", 0)) - int(challenge.get("baseline_population", 0)))
			goal = 5
			reward = 850
			xp = 55
		3:
			title = "هفته پس‌انداز"
			description = "این هفته موجودی خزانه را ۱٬۰۰۰ سکه افزایش بده."
			progress = max(0, int(state.get("money", 0)) - int(challenge.get("baseline_money", 0)))
			goal = 1000
			reward = 1000
			xp = 70
	return {
		"id":"weekly_" + str(rotation),
		"title":title,
		"description":description,
		"progress":min(goal,progress),
		"goal":goal,
		"reward":reward,
		"xp":xp,
		"claimed":bool(challenge.get("claimed", false)),
		"week_serial":week_serial
	}

func claim_weekly_challenge():
	var challenge = get_weekly_challenge()
	if bool(challenge.claimed):
		return {"ok":false,"message":"جایزه رقابت این هفته قبلاً دریافت شده است."}
	if int(challenge.progress) < int(challenge.goal):
		return {"ok":false,"message":"هدف هفتگی هنوز کامل نشده است."}
	var reward = int(challenge.reward)
	if get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست."}
	var saved = state.get("weekly_challenge", {})
	saved["claimed"] = true
	state["weekly_challenge"] = saved
	_add_money(reward)
	var xp_message = _award_xp(int(challenge.xp))
	save_game()
	return {"ok":true,"message":"رقابت هفتگی را بردی! %d سکه و %d تجربه دریافت کردی. %s" % [reward,int(challenge.xp),xp_message]}


func _default_rival_cities():
	var defaults = []
	for index in range(CITY_NAME_POOL.size()):
		var city = CITY_NAME_POOL[index]
		defaults.append({
			"id": str(city.id) + "_rival",
			"name": str(city.name),
			"population": 16 + index * 3,
			"level": 2 + (index % 3),
			"buildings": 6 + index,
			"district_count": max(1, int(ceil(float(6 + index) / 3.0))),
			"xp": int(randi() % 100),
			"ai_style_index": int(randi() % 4),
			"ai_actions": 0,
			"wealth": 5000 + index * 1250,
			"satisfaction": 58 + (index % 5) * 5,
			"score": 280 + index * 115
		})
	return defaults

func _advance_rival_cities(report):
	var rivals = state.get("rival_cities", _default_rival_cities())
	var styles = ["housing", "economy", "services", "innovation"]
	var style_names = ["جمعیت‌محور", "اقتصادمحور", "خدمات‌محور", "نوآور"]
	for index in range(rivals.size()):
		var rival = rivals[index].duplicate(true)
		# AI identity belongs to this saved city, never to the rival's public name or ID.
		var style_index = int(rival.get("ai_style_index", int(randi() % styles.size())))
		style_index = int(posmod(style_index, styles.size()))
		rival["ai_style_index"] = style_index
		rival["ai_style"] = styles[style_index]
		rival["ai_personality"] = style_names[style_index]
		rival["ai_actions"] = int(rival.get("ai_actions", 0))

		var wealth = int(rival.get("wealth", 0))
		var level = int(rival.get("level", 1))
		var population = int(rival.get("population", 0))
		var action = "maintain"
		var action_cost = 0
		var action_score = 0

		# Every mayor makes a budget-aware decision each simulated city day.
		if int(randi() % 100) < 72:
			match styles[style_index]:
				"housing":
					if wealth >= 350 and population < 500 and int(randi() % 100) < 78:
						action = "housing"
						action_cost = 300 + level * 35
						rival["population"] = population + (1 if int(randi() % 100) < 75 else 2)
						rival["buildings"] = int(rival.get("buildings", 0)) + 1
						rival["satisfaction"] = int(clamp(int(rival.get("satisfaction", 50)) + 1, 25, 100))
						action_score = 9 + level * 2
				"economy":
					if wealth >= 250 and int(randi() % 100) < 82:
						action = "economy"
						action_cost = 220 + level * 45
						rival["wealth"] = wealth + 650 + int(randi() % 450)
						rival["buildings"] = int(rival.get("buildings", 0)) + (1 if int(randi() % 100) < 45 else 0)
						action_score = 11 + int(randi() % 7)
				"services":
					if wealth >= 280 and int(randi() % 100) < 76:
						action = "services"
						action_cost = 260 + level * 40
						rival["satisfaction"] = int(clamp(int(rival.get("satisfaction", 50)) + 2 + int(randi() % 3), 25, 100))
						rival["population"] = population + (1 if int(randi() % 100) < 35 else 0)
						action_score = 8 + int(randi() % 6)
				"innovation":
					if wealth >= 500 and int(randi() % 100) < 68:
						action = "innovation"
						action_cost = 420 + level * 65
						if int(randi() % 100) < 24 and level < 15:
							rival["level"] = level + 1
						action_score = 13 + int(randi() % 9)

		if action_cost > 0:
			rival["wealth"] = max(0, int(rival.get("wealth", wealth)) - action_cost)
			rival["ai_actions"] = int(rival.get("ai_actions", 0)) + 1
		else:
			# A city that saves money can still grow slowly through routine activity.
			rival["wealth"] = max(0, wealth + int(randi() % 321) - 170)

		var routine_growth = 2 + int(rival.get("level", 1)) + int(randi() % 4)
		rival["score"] = int(rival.get("score", 0)) + routine_growth + action_score
		if int(randi() % 100) < 18 and int(rival.get("population", 0)) < 500:
			rival["population"] = int(rival.get("population", 0)) + 1
		if int(randi() % 100) < 12 and int(rival.get("buildings", 0)) < 250:
			rival["buildings"] = int(rival.get("buildings", 0)) + 1
		if int(randi() % 100) < 10 and int(rival.get("level", 1)) < 15:
			rival["level"] = int(rival.get("level", 1)) + 1
		rival["satisfaction"] = int(clamp(int(rival.get("satisfaction", 50)) + int(randi() % 5) - 2, 25, 100))
		# Rival XP is persistent progress within its current city level.
		var rival_level = int(clamp(int(rival.get("level", 1)), 1, 15))
		var rival_xp = max(0, int(rival.get("xp", 0))) + 8 + int(randi() % 21)
		var xp_required = max(100, rival_level * 100)
		while rival_xp >= xp_required and rival_level < 15:
			rival_xp -= xp_required
			rival_level += 1
			xp_required = max(100, rival_level * 100)
		if rival_level >= 15:
			rival_xp = min(rival_xp, xp_required - 1)
		rival["level"] = rival_level
		rival["xp"] = rival_xp
		var building_count = max(1, int(rival.get("buildings", 1)))
		rival["district_count"] = max(int(rival.get("district_count", 1)), int(ceil(float(building_count) / 3.0)))
		rivals[index] = rival

	state["rival_cities"] = rivals
	if rivals.is_empty():
		return
	var player_geo = get_geographic_rank_for_district_count(state.get("districts", []).size())
	var player_row = {"geographic_tier":int(player_geo.tier),"xp":int(state.get("xp",0)),"score":int(get_city_league().score)}
	var leader = null
	var leader_geo = {}
	var leader_row = {}
	for rival in rivals:
		var rival_geo = get_geographic_rank_for_district_count(int(rival.get("district_count", 1)))
		var rival_row = {"geographic_tier":int(rival_geo.tier),"xp":int(rival.get("xp",0)),"score":int(rival.get("score",0))}
		if leader == null or _sort_rival_standings(rival_row, leader_row):
			leader = rival
			leader_geo = rival_geo
			leader_row = rival_row
	if leader != null and _sort_rival_standings(leader_row, player_row):
		report.append("🏙️ خبر رقبا: %s با رتبه %s و مدیریت %s از شهر تو جلوتر افتاد؛ برای پس گرفتن رتبه تلاش کن." % [str(leader.get("name", "شهر رقیب")),str(leader_geo.name),str(leader.get("ai_personality", "هوشمند"))])

func get_rival_standings():
	_sync_rival_cities()
	var standings = []
	var player_geo = get_geographic_rank_for_district_count(state.get("districts", []).size())
	standings.append({"id":"player","name":str(state.get("city_name","شهر من")),"score":int(get_city_league().score),"geographic_tier":int(player_geo.tier),"geographic_rank":str(player_geo.name),"district_count":int(player_geo.district_count),"xp":int(state.get("xp",0)),"population":int(state.get("population",0)),"level":int(state.get("level",1)),"is_player":true})
	for rival in state.get("rival_cities", _default_rival_cities()):
		var rival_score = int(rival.get("score",0))
		var rival_geo = get_geographic_rank_for_district_count(int(rival.get("district_count",1)))
		standings.append({"id":str(rival.get("id","rival")),"name":str(rival.get("name","شهر رقیب")),"score":rival_score,"geographic_tier":int(rival_geo.tier),"geographic_rank":str(rival_geo.name),"district_count":int(rival_geo.district_count),"xp":int(rival.get("xp",0)),"population":int(rival.get("population",0)),"level":int(rival.get("level",1)),"is_player":false})
	standings.sort_custom(Callable(self, "_sort_rival_standings"))
	for index in range(standings.size()):
		standings[index]["rank"] = index + 1
	return standings

func _sort_rival_standings(a, b):
	return GameRanking.sort_standings(a, b)


func _process_mystery_discovery(report):
	if not state.get("mystery_active", {}).is_empty():
		return
	if int(state.get("day", 1)) < int(state.get("mystery_next_day", 4)):
		return
	if int(state.get("randi_mystery_roll", -1)) == int(state.get("day", 1)):
		return
	state["randi_mystery_roll"] = int(state.get("day", 1))
	if int(randi() % 100) >= 42:
		state["mystery_next_day"] = int(state.get("day", 1)) + 2
		return
	var completed = state.get("mystery_completed", [])
	var candidates = [
		{"id":"lost_blueprint","min_level":1,"title":"نقشه گمشده معمار","clue":"یک شهروند سالخورده نقشه‌ای قدیمی پیدا کرده؛ می‌گوید شهر باید به ۵ ساختمان برسد تا راز آن روشن شود.","objective":"تعداد ساختمان‌های شهر را به ۵ برسان.","kind":"buildings","goal":5,"reward":500,"xp":40},
		{"id":"merchant_letter","min_level":2,"title":"نامه بازرگان ناشناس","clue":"نامه‌ای از تاجری ناشناس رسیده؛ او می‌خواهد توان تجارت شهر را بسنجد.","objective":"در مجموع ۵ واحد کالا صادر کن.","kind":"exports","goal":5,"reward":650,"xp":50},
		{"id":"green_secret","min_level":2,"title":"راز باغبان پیر","clue":"باغبان قدیمی شهر از یک راز برای شاد کردن مردم حرف می‌زند.","objective":"رضایت شهر را به ۷۵ برسان.","kind":"satisfaction","goal":75,"reward":700,"xp":55},
		{"id":"founder_diary","min_level":3,"title":"دفترچه بنیان‌گذار","clue":"دفترچه‌ای مهروموم‌شده پیدا شده؛ تنها شهردار باتجربه می‌تواند نوشته‌هایش را بخواند.","objective":"شهر را به سطح ۴ برسان.","kind":"level","goal":4,"reward":900,"xp":70}
	]
	var available = []
	for candidate in candidates:
		if str(candidate.id) in completed or int(state.get("level", 1)) < int(candidate.min_level):
			continue
		available.append(candidate)
	if available.is_empty():
		return
	var selected = available[int(randi() % available.size())].duplicate(true)
	state["mystery_active"] = selected
	report.append("🔎 کشف راز مخفی: %s. سرنخی تازه در بخش پیشرفت شهر منتظر توست." % str(selected.title))

func get_mystery_status():
	var mystery = state.get("mystery_active", {}).duplicate(true)
	if mystery.is_empty():
		return {"active":false,"completed":state.get("mystery_completed", []).size(),"next_day":int(state.get("mystery_next_day", 4))}
	var progress = 0
	match str(mystery.get("kind", "")):
		"buildings":
			progress = state.get("buildings", []).size()
		"exports":
			progress = int(state.get("trade_exported_units_total", 0))
		"satisfaction":
			progress = int(state.get("satisfaction", 0))
		"level":
			progress = int(state.get("level", 1))
	mystery["progress"] = min(int(mystery.get("goal", 1)), progress)
	mystery["active"] = true
	return mystery

func claim_mystery_reward():
	var mystery = get_mystery_status()
	if not bool(mystery.get("active", false)):
		return {"ok":false,"message":"فعلاً راز مخفی تازه‌ای کشف نشده است."}
	if int(mystery.get("progress", 0)) < int(mystery.get("goal", 1)):
		return {"ok":false,"message":"هنوز سرنخ را کامل نکرده‌ای؛ شرط راز مخفی باقی مانده است."}
	var reward = int(mystery.get("reward", 0))
	if get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"برای دریافت جایزه راز مخفی، ابتدا ظرفیت خزانه را خالی کن."}
	_add_money(reward)
	var xp = int(mystery.get("xp", 0))
	var xp_message = _award_xp(xp)
	var completed = state.get("mystery_completed", [])
	completed.append(str(mystery.get("id", "")))
	state["mystery_completed"] = completed
	state["mystery_active"] = {}
	state["mystery_next_day"] = int(state.get("day", 1)) + 2
	save_game()
	return {"ok":true,"message":"راز مخفی کشف شد! %d سکه و %d تجربه گرفتی. %s" % [reward,xp,xp_message]}

func _maybe_create_city_decision(report):
	if not state.get("pending_city_decision", {}).is_empty():
		return
	if int(state.get("day", 1)) < int(state.get("next_city_decision_day", 6)):
		return
	state["next_city_decision_day"] = int(state.get("day", 1)) + 5 + int(randi() % 4)
	if int(randi() % 100) >= 32:
		return
	var choices = [
		{"id":"festival","title":"پیشنهاد برگزاری جشن شهر","description":"شورای شهر پیشنهاد داده برای افزایش روحیه مردم یک جشن محلی برگزار شود.","options":[{"id":"fund","label":"برگزاری جشن | ۳۵۰ سکه","effect":"festival_fund"},{"id":"volunteer","label":"جشن مردمی و داوطلبانه","effect":"festival_volunteer"},{"id":"decline","label":"فعلاً برگزار نکن","effect":"decline"}]},
		{"id":"water","title":"تصمیم اضطراری آب","description":"مصرف آب بالا رفته؛ باید بین سرمایه‌گذاری فوری و محدودیت مصرف انتخاب کنی.","options":[{"id":"invest","label":"سرمایه‌گذاری | ۵۰۰ سکه","effect":"water_invest"},{"id":"ration","label":"مدیریت مصرف","effect":"water_ration"}]},
		{"id":"investor","title":"پیشنهاد سرمایه‌گذار","description":"یک سرمایه‌گذار برای کمک فوری به شهر پیشنهاد مالی داده، اما انتظار امتیاز اجتماعی دارد.","options":[{"id":"accept","label":"پذیرش سرمایه | دریافت ۷۰۰ سکه","effect":"investor_accept"},{"id":"decline","label":"رد پیشنهاد","effect":"decline"}]},
		{"id":"fire_emergency","title":"🚒 آتش‌سوزی در محله مسکونی","description":"آتش‌سوزی در چند ساختمان گسترش پیدا کرده است. برای مهار آن باید سریع تصمیم بگیری.","options":[{"id":"firefighters","label":"اعزام تیم آتش‌نشانی | ۴۰۰ سکه","effect":"fire_paid","cost":400},{"id":"volunteers","label":"بسیج نیروهای داوطلب | ۱۵۰ سکه","effect":"fire_volunteer","cost":150},{"id":"ignore_fire","label":"عدم مداخله","effect":"fire_ignore"}]},
		{"id":"illness_outbreak","title":"🏥 شیوع بیماری فصلی","description":"موارد بیماری در میان شهروندان افزایش یافته است. رسیدگی درمانی می‌تواند از گسترش آن جلوگیری کند.","options":[{"id":"medical","label":"درمان و دارو | ۳۵۰ سکه","effect":"health_paid","cost":350},{"id":"public_health","label":"اطلاع‌رسانی و پیشگیری","effect":"health_public"},{"id":"ignore_illness","label":"عدم اقدام","effect":"health_ignore"}]},
		{"id":"storm_damage","title":"🌧️ خسارت طوفان","description":"طوفان به زیرساخت‌های شهر آسیب زده و خدمات شهری را مختل کرده است.","options":[{"id":"repair","label":"تعمیر فوری زیرساخت‌ها | ۵۰۰ سکه","effect":"storm_paid","cost":500},{"id":"temporary","label":"راهکار موقت | ۲۰۰ سکه","effect":"storm_temporary","cost":200},{"id":"ignore_storm","label":"تعویق تعمیرات","effect":"storm_ignore"}]}
	]
	var selected = choices[int(randi() % choices.size())].duplicate(true)
	state["pending_city_decision"] = selected
	report.append("⚖️ تصمیم مهم شهر: %s. انتخابت را در صفحه شهر من انجام بده." % str(selected.title))

func get_pending_city_decision():
	return state.get("pending_city_decision", {}).duplicate(true)

func resolve_city_decision(option_id):
	var decision = state.get("pending_city_decision", {})
	if decision.is_empty():
		return {"ok":false,"message":"تصمیم معوقی وجود ندارد."}
	var selected = {}
	for option in decision.get("options", []):
		if str(option.get("id", "")) == str(option_id):
			selected = option
			break
	if selected.is_empty():
		return {"ok":false,"message":"این گزینه معتبر نیست."}
	var effect = str(selected.get("effect", ""))
	var decision_cost = int(selected.get("cost", 350 if effect == "festival_fund" else (500 if effect == "water_invest" else 0)))
	if decision_cost > 0:
		if get_available_money() < decision_cost:
			return {"ok":false,"message":"موجودی آزاد خزانه برای این تصمیم کافی نیست."}
		_spend_money(decision_cost)
	match effect:
		"festival_fund":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 5, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
		"festival_volunteer":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 2, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
		"water_invest":
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) + 15, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 2, 0, 100))
		"water_ration":
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) + 4, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
		"investor_accept":
			_add_money(700)
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 2, 0, 100))
		"fire_paid":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + (1 if get_building_count("fire_station") > 0 else -1), 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
		"fire_volunteer":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
		"fire_ignore":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 7, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) - 4, 0, 100))
		"health_paid":
			state["needs"]["health"] = int(clamp(int(state.needs.get("health", 50)) + (12 if get_building_count("clinic") + get_building_count("hospital") > 0 else 6), 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 2, 0, 100))
		"health_public":
			state["needs"]["health"] = int(clamp(int(state.needs.get("health", 50)) + 5, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
		"health_ignore":
			state["needs"]["health"] = int(clamp(int(state.needs.get("health", 50)) - 10, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 6, 0, 100))
		"storm_paid":
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) + 5, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 2, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
		"storm_temporary":
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) + 2, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
		"storm_ignore":
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) - 8, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 5, 0, 100))
		"decline":
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) - 1, 0, 100))
	state["pending_city_decision"] = {}
	save_game()
	return {"ok":true,"message":"تصمیمت ثبت شد؛ پیامد آن در وضعیت شهر اعمال شد."}

func get_landmark_project_definitions():
	return [
		{"id":"grand_tower","title":"برج بزرگ شهر","description":"نماد شهر و مقصد تازه گردشگران.","reward":1800,"xp":130,"stages":[{"title":"پی‌ریزی برج","cost":1200,"level":2,"population":12,"buildings":4},{"title":"اسکلت و سازه اصلی","cost":1900,"level":3,"population":20,"buildings":7},{"title":"افتتاح برج","cost":3000,"level":4,"population":30,"buildings":10}]},
		{"id":"trade_center","title":"مرکز تجارت منطقه","description":"مرکز مبادله کالا و قراردادهای بین‌شهری.","reward":2200,"xp":160,"stages":[{"title":"تأمین زمین و مجوز","cost":1600,"level":3,"population":20,"buildings":6},{"title":"ساخت سالن‌های تجاری","cost":2600,"level":4,"population":35,"buildings":1,"building_id":"mineral_market"},{"title":"افتتاح مرکز تجارت","cost":3800,"level":5,"population":50,"exports":20}]},
		{"id":"regional_airport","title":"فرودگاه منطقه‌ای","description":"پروژه‌ای بزرگ برای پیوند شهر با منطقه و رشد آینده.","reward":3000,"xp":220,"stages":[{"title":"مطالعات و مجوز فرودگاه","cost":2200,"level":4,"population":35,"buildings":8},{"title":"ساخت باند و پایانه","cost":4200,"level":5,"population":55,"building_id":"transport_depot","building_count":1},{"title":"آماده‌سازی و افتتاح","cost":6000,"level":6,"population":75,"exports":35}]}
	]

func get_landmark_project_status():
	var active = state.get("landmark_project", {}).duplicate(true)
	if active.is_empty():
		return {"active":false,"completed":state.get("landmark_projects_completed", []).duplicate(true)}
	var definition = {}
	for project in get_landmark_project_definitions():
		if str(project.id) == str(active.get("id", "")):
			definition = project
			break
	if definition.is_empty():
		return {"active":false,"completed":state.get("landmark_projects_completed", []).duplicate(true)}
	var stage_index = int(active.get("stage", 0))
	if stage_index >= definition.stages.size():
		return {"active":false,"completed":state.get("landmark_projects_completed", []).duplicate(true)}
	var stage = definition.stages[stage_index].duplicate(true)
	var requirements_met = int(state.get("level", 1)) >= int(stage.get("level", 1)) and int(state.get("population", 0)) >= int(stage.get("population", 0)) and state.get("buildings", []).size() >= int(stage.get("buildings", 0))
	if str(stage.get("building_id", "")) != "":
		requirements_met = requirements_met and get_building_count(str(stage.building_id)) >= int(stage.get("building_count", 1))
	if int(stage.get("exports", 0)) > 0:
		requirements_met = requirements_met and int(state.get("trade_exported_units_total", 0)) >= int(stage.exports)
	return {"active":true,"id":str(definition.id),"title":str(definition.title),"description":str(definition.description),"stage":stage_index+1,"stage_total":definition.stages.size(),"stage_data":stage,"requirements_met":requirements_met,"reward":int(definition.reward),"xp":int(definition.xp)}

func start_landmark_project(project_id):
	if not state.get("landmark_project", {}).is_empty():
		return {"ok":false,"message":"ابتدا پروژه عظیم فعلی را به پایان برسان."}
	if str(project_id) in state.get("landmark_projects_completed", []):
		return {"ok":false,"message":"این سازه قبلاً در شهر افتتاح شده است."}
	for project in get_landmark_project_definitions():
		if str(project.id) == str(project_id):
			state["landmark_project"] = {"id":str(project_id),"stage":0}
			save_game()
			return {"ok":true,"message":"پروژه %s آغاز شد؛ برای هر مرحله باید شرایط را فراهم و هزینه را پرداخت کنی." % str(project.title)}
	return {"ok":false,"message":"پروژه پیدا نشد."}

func invest_landmark_stage():
	var status = get_landmark_project_status()
	if not bool(status.get("active", false)):
		return {"ok":false,"message":"پروژه عظیمی برای ادامه وجود ندارد."}
	if not bool(status.get("requirements_met", false)):
		return {"ok":false,"message":"شرایط جمعیت، سطح یا ساختمان‌های این مرحله هنوز فراهم نیست."}
	var stage = status.stage_data
	var cost = int(stage.get("cost", 0))
	if get_available_money() < cost:
		return {"ok":false,"message":"موجودی آزاد خزانه برای این مرحله کافی نیست."}
	_spend_money(cost)
	var active = state.get("landmark_project", {})
	active["stage"] = int(active.get("stage", 0)) + 1
	state["landmark_project"] = active
	if int(active.stage) >= int(status.stage_total):
		var project_id = str(status.id)
		var completed = state.get("landmark_projects_completed", [])
		completed.append(project_id)
		state["landmark_projects_completed"] = completed
		state["landmark_project"] = {}
		_add_money(int(status.reward))
		var xp_message = _award_xp(int(status.xp))
		save_game()
		return {"ok":true,"message":"🎉 %s افتتاح شد! پاداش %d سکه و %d تجربه دریافت کردی. %s" % [str(status.title),int(status.reward),int(status.xp),xp_message]}
	save_game()
	return {"ok":true,"message":"مرحله «%s» تکمیل شد؛ مرحله بعدی پروژه آماده پیگیری است." % str(stage.get("title", "پروژه"))}


func get_long_term_projects():
	var claimed = state.get("long_term_project_claimed", [])
	var public_count = 0
	for building_id in ["water_tower","power_station","school","clinic","police_station","fire_station","sewage_plant","waste_facility","small_park"]:
		public_count += get_building_count(building_id)
	var industry_count = int(get_building_count("woodcutter") > 0) + int(get_building_count("sawmill") > 0) + int(get_building_count("carpenter") > 0)
	return [
		{"id":"population_25","title":"شهر ۲۵ نفره","description":"جمعیت شهر را به ۲۵ نفر برسان.","progress":min(25,int(state.get("population",0))),"goal":25,"reward":1200,"xp":90,"claimed":"population_25" in claimed},
		{"id":"public_services_5","title":"زیرساخت پایدار","description":"حداقل ۵ ساختمان خدمات عمومی بساز.","progress":min(5,public_count),"goal":5,"reward":1000,"xp":75,"claimed":"public_services_5" in claimed},
		{"id":"industry_chain","title":"قطب تولیدی","description":"هر سه حلقه چوب‌بری، الوارسازی و کارگاه مبلمان را بساز.","progress":min(3,industry_count),"goal":3,"reward":1400,"xp":100,"claimed":"industry_chain" in claimed},
		{"id":"level_8","title":"پایتخت منطقه","description":"شهر را به سطح ۸ برسان.","progress":min(8,int(state.get("level",1))),"goal":8,"reward":2000,"xp":150,"claimed":"level_8" in claimed}
	]

func claim_long_term_project(project_id):
	for project in get_long_term_projects():
		if str(project.id) != str(project_id):
			continue
		if bool(project.claimed):
			return {"ok":false,"message":"جایزه این پروژه قبلاً دریافت شده است."}
		if int(project.progress) < int(project.goal):
			return {"ok":false,"message":"این پروژه هنوز تکمیل نشده است."}
		var reward = int(project.reward)
		if get_treasury_capacity() - int(state.get("money", 0)) < reward:
			return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست."}
		var claimed = state.get("long_term_project_claimed", [])
		claimed.append(str(project_id))
		state["long_term_project_claimed"] = claimed
		_add_money(reward)
		var xp_message = _award_xp(int(project.xp))
		save_game()
		return {"ok":true,"message":"پروژه بلندمدت تکمیل شد: %d سکه و %d تجربه. %s" % [reward,int(project.xp),xp_message]}
	return {"ok":false,"message":"پروژه پیدا نشد."}

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
	_update_achievements()
	save_game()
	return true

func record_active_play_seconds(seconds):
	if seconds <= 0.0:
		return
	state["active_play_seconds_today"] = float(state.get("active_play_seconds_today", 0.0)) + min(float(seconds), 1.0)

func add_report_event(message, persist=true, metadata={}):
	var clean_message = str(message).strip_edges()
	if clean_message == "":
		return
	if typeof(state.get("report_events", null)) != TYPE_ARRAY:
		state["report_events"] = []
	if typeof(state.get("active_service_report_keys", null)) != TYPE_ARRAY:
		state["active_service_report_keys"] = []
	if typeof(state.get("district_service_coverage", null)) != TYPE_DICTIONARY:
		state["district_service_coverage"] = {}
	var event_id = int(state.get("next_report_event_id", 1))
	state["next_report_event_id"] = event_id + 1
	var event = {"id":event_id,"timestamp":Time.get_unix_time_from_system(),"day":int(state.get("day", 1)),"message":clean_message,"resolved":false}
	if typeof(metadata) == TYPE_DICTIONARY:
		for key in metadata.keys():
			event[key] = metadata[key]
	state.report_events.append(event)
	if persist:
		save_game()

func review_report_event(event_id):
	if typeof(state.get("report_events", null)) != TYPE_ARRAY:
		return false
	for index in range(state.report_events.size() - 1, -1, -1):
		if int(state.report_events[index].get("id", -1)) == int(event_id):
			state.report_events.remove_at(index)
			save_game()
			return true
	return false

func check_citizen_reports():
	if typeof(state.get("citizens", null)) != TYPE_ARRAY:
		return false
	_ensure_building_locations()
	var changed = false
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		var citizen_id = int(citizen.get("id", citizen_index + 1))
		var concerns = {}
		if str(citizen.get("job", "")).strip_edges() == "" and int(state.get("day", 1)) > 1:
			concerns["unemployed"] = "شهروند شماره %d: هنوز شغلی پیدا نکرده‌ام و درآمد ثابتی ندارم." % citizen_id
		if int(citizen.get("wallet", 0)) < 20:
			concerns["low_wallet"] = "شهروند شماره %d: پول کافی برای خریدهای ضروری ندارم؛ فرصت کار یا درآمدم را بررسی کن." % citizen_id
		var previous_keys = citizen.get("active_report_keys", [])
		if typeof(previous_keys) != TYPE_ARRAY:
			previous_keys = []
		for issue_key in concerns.keys():
			if not previous_keys.has(issue_key):
				add_report_event(concerns[issue_key], false, {"citizen_id":citizen_id,"issue_key":issue_key,"resolved":false})
				changed = true
		for previous_key in previous_keys:
			if concerns.has(str(previous_key)):
				continue
			for event_index in range(state.report_events.size() - 1, -1, -1):
				var event = state.report_events[event_index]
				if int(event.get("citizen_id", 0)) == citizen_id and str(event.get("issue_key", "")) == str(previous_key) and not bool(event.get("resolved", false)):
					event["resolved"] = true
					state.report_events[event_index] = event
					changed = true
		citizen["active_report_keys"] = concerns.keys()
		state.citizens[citizen_index] = citizen

	# Service complaints are district-based: one active report per district and need,
	# not one duplicate report from every resident.
	var need_names = {"food":"خوراک","water":"آب‌رسانی","power":"برق","health":"درمان","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت محیط"}
	var need_advice = {"food":"فروشگاه‌ها و ذخیره خوراک را تقویت کن","water":"ظرفیت آب‌رسانی را افزایش بده","power":"ظرفیت برق‌رسانی را افزایش بده","health":"درمانگاه یا بیمارستان بیشتری فراهم کن","education":"ظرفیت مدرسه و دانشگاه را افزایش بده","safety":"کلانتری یا آتش‌نشانی بیشتری فراهم کن","leisure":"فضای تفریحی بیشتری ایجاد کن","sanitation":"ظرفیت جمع‌آوری پسماند و فاضلاب را افزایش بده"}
	var active_keys = state.get("active_service_report_keys", [])
	if typeof(active_keys) != TYPE_ARRAY:
		active_keys = []
	var current_keys = []
	var district_population = _get_district_population()
	var service_snapshot = {}
	for need_id in need_names.keys():
		service_snapshot[need_id] = _calculate_district_service_coverage(need_id)
	for district in state.get("districts", []):
		var district_id = str(district.get("id", ""))
		var residents = int(district_population.get(district_id, 0))
		if residents <= 0:
			continue
		# Keep at most one active service request per district so the report
		# inbox stays useful instead of flooding the player with eight items.
		var selected_need = ""
		for need_id in need_names.keys():
			var existing_key = "service_%s_%s" % [need_id, district_id]
			var existing_coverage = int(service_snapshot[need_id].get("coverage", {}).get(district_id, 0))
			if active_keys.has(existing_key) and existing_coverage < 65:
				selected_need = need_id
				break
		if selected_need == "":
			var best_priority = 999
			for need_id in need_names.keys():
				var coverage = int(service_snapshot[need_id].get("coverage", {}).get(district_id, 0))
				var need_level = int(state.get("needs", {}).get(need_id, 60))
				if coverage >= 65 or need_level > 75:
					continue
				var priority = need_level + int(coverage / 4)
				if priority < best_priority:
					best_priority = priority
					selected_need = need_id
		if selected_need != "":
			var issue_key = "service_%s_%s" % [selected_need, district_id]
			current_keys.append(issue_key)
			if not active_keys.has(issue_key):
				var coverage = int(service_snapshot[selected_need].get("coverage", {}).get(district_id, 0))
				var message = "شهروندان %s گزارش داده‌اند: پوشش خدمات %s برای جمعیت این محله کافی نیست (%d%%). پیشنهاد: %s." % [str(district.get("name", "این محله")), need_names[selected_need], coverage, need_advice[selected_need]]
				add_report_event(message, false, {"citizen_id":0,"district_id":district_id,"service_need":selected_need,"issue_key":issue_key,"resolved":false})
				changed = true
		for previous_key in active_keys:
			if not str(previous_key).ends_with("_" + district_id) or current_keys.has(str(previous_key)):
				continue
			for event_index in range(state.report_events.size() - 1, -1, -1):
				var event = state.report_events[event_index]
				if str(event.get("issue_key", "")) == str(previous_key) and str(event.get("district_id", "")) == district_id and not bool(event.get("resolved", false)):
					event["resolved"] = true
					state.report_events[event_index] = event
					changed = true
	state["active_service_report_keys"] = current_keys
	if changed:
		save_game()
	return changed

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.new().stringify(state))
	file.close()
	return true

func _normalize_state():
	if typeof(state.get("report_events", null)) != TYPE_ARRAY:
		state["report_events"] = []
	var next_report_id = max(1, int(state.get("next_report_event_id", 1)))
	for report_index in range(state.report_events.size()):
		var report_event = state.report_events[report_index]
		if not report_event.has("id"):
			report_event["id"] = next_report_id
			next_report_id += 1
		if not report_event.has("resolved"):
			report_event["resolved"] = false
		state.report_events[report_index] = report_event
		next_report_id = max(next_report_id, int(report_event.get("id", 0)) + 1)
	state["next_report_event_id"] = next_report_id
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
	state["citizen_recruitment_timer"] = max(0.0, float(state.get("citizen_recruitment_timer", 0.0)))
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
		state["clock_last_unix"] = Time.get_unix_time_from_system()
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
	if typeof(state.get("daily_missions", null)) != TYPE_DICTIONARY:
		state["daily_missions"] = {}
	state["login_reward_claimed_day_serial"] = int(state.get("login_reward_claimed_day_serial", -1))
	if typeof(state.get("city_event_history", null)) != TYPE_ARRAY:
		state["city_event_history"] = []
	while state.city_event_history.size() > 20:
		state.city_event_history.pop_front()
	state["city_event_next_day"] = max(int(state.get("day", 1)) + 1, int(state.get("city_event_next_day", int(state.get("day", 1)) + 2)))
	if typeof(state.get("resident_requests", null)) != TYPE_ARRAY:
		state["resident_requests"] = []
	if typeof(state.get("achievements", null)) != TYPE_DICTIONARY:
		state["achievements"] = {}
	if typeof(state.get("city_records", null)) != TYPE_DICTIONARY:
		state["city_records"] = {}
	if typeof(state.get("long_term_project_claimed", null)) != TYPE_ARRAY:
		state["long_term_project_claimed"] = []
	if typeof(state.get("weekly_challenge", null)) != TYPE_DICTIONARY:
		state["weekly_challenge"] = {}
	if typeof(state.get("rival_cities", null)) != TYPE_ARRAY or state.get("rival_cities", []).is_empty():
		state["rival_cities"] = _default_rival_cities()
	if typeof(state.get("mystery_active", null)) != TYPE_DICTIONARY:
		state["mystery_active"] = {}
	if typeof(state.get("mystery_completed", null)) != TYPE_ARRAY:
		state["mystery_completed"] = []
	state["mystery_next_day"] = max(int(state.get("day", 1)) + 1, int(state.get("mystery_next_day", 4)))
	if typeof(state.get("landmark_project", null)) != TYPE_DICTIONARY:
		state["landmark_project"] = {}
	if typeof(state.get("landmark_projects_completed", null)) != TYPE_ARRAY:
		state["landmark_projects_completed"] = []
	if typeof(state.get("pending_city_decision", null)) != TYPE_DICTIONARY:
		state["pending_city_decision"] = {}
	if typeof(state.get("weekly_city_event", null)) != TYPE_DICTIONARY:
		state["weekly_city_event"] = {}
	state["next_city_decision_day"] = max(int(state.get("day", 1)) + 1, int(state.get("next_city_decision_day", 6)))
	state["next_resident_request_id"] = max(1, int(state.get("next_resident_request_id", 1)))
	state["next_resident_request_day"] = max(int(state.get("day", 1)) + 1, int(state.get("next_resident_request_day", int(state.get("day", 1)) + 3)))
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
	state["version"] = 18
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
	return CityPopulationSystem._sync_population(self)


func _next_citizen_request_id():
	return CityPopulationSystem._next_citizen_request_id(self)


func _create_house_citizen_requests(building_id):
	return CityPopulationSystem._create_house_citizen_requests(self, building_id)


func _accept_pending_citizen_requests_automatically():
	return CityPopulationSystem._accept_pending_citizen_requests_automatically(self)


func set_citizen_recruitment_mode(mode):
	return CityPopulationSystem.set_citizen_recruitment_mode(self, mode)


func accept_citizen_request(request_index):
	return CityPopulationSystem.accept_citizen_request(self, request_index)


func reject_citizen_request(request_index):
	return CityPopulationSystem.reject_citizen_request(self, request_index)


func _process_citizen_recruitment(report):
	return CityPopulationSystem._process_citizen_recruitment(self, report)


func process_citizen_recruitment_interval(delta):
	return CityPopulationSystem.process_citizen_recruitment_interval(self, delta)


func _next_citizen_id():
	return CityPopulationSystem._next_citizen_id(self)


func get_housing_capacity():
	return CityPopulationSystem.get_housing_capacity(self)


func _district_letter(index):
	return CityPopulationSystem._district_letter(self, index)


func _find_district_index(district_id):
	return CityPopulationSystem._find_district_index(self, district_id)


func _is_house_building(building_id):
	return CityPopulationSystem._is_house_building(self, building_id)


func _district_can_accept(district, building_id):
	return CityPopulationSystem._district_can_accept(self, district, building_id)


func _assign_building_location(building_id):
	return CityPopulationSystem._assign_building_location(self, building_id)


func _ensure_building_locations():
	return CityPopulationSystem._ensure_building_locations(self)


func get_districts_overview():
	return CityPopulationSystem.get_districts_overview(self)


func get_district_capacity_summary(district_id):
	return CityPopulationSystem.get_district_capacity_summary(self, district_id)


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
	return StorageSystem.get_storage_rule(self, resource_id)


func set_storage_rule(resource_id, field, value):
	return StorageSystem.set_storage_rule(self, resource_id, field, value)


func toggle_storage_action(resource_id, level):
	return StorageSystem.toggle_storage_action(self, resource_id, level)


func apply_storage_rule(resource_id, manual=false):
	return StorageSystem.apply_storage_rule(self, resource_id, manual)


func get_storage_capacity():
	return StorageSystem.get_storage_capacity(self)


func get_storage_used():
	return StorageSystem.get_storage_used(self)


func get_free_storage():
	return StorageSystem.get_free_storage(self)


func has_municipal_hall():
	return get_building_count("municipal_hall") > 0

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
	return CityConstructionSystem.get_land_size(self, id)


func get_land_used():
	return CityConstructionSystem.get_land_used(self)


func get_land_free():
	return CityConstructionSystem.get_land_free(self)


func get_land_unit_price():
	return CityConstructionSystem.get_land_unit_price(self)


func buy_land(plots=1):
	return CityConstructionSystem.buy_land(self, plots)


func build(id):
	return CityConstructionSystem.build(self, id)


func process_constructions():
	return CityConstructionSystem.process_constructions(self)


func get_active_construction_count():
	return CityConstructionSystem.get_active_construction_count(self)


func get_construction_status():
	return CityConstructionSystem.get_construction_status(self)


func demolish(index):
	return CityConstructionSystem.demolish(self, index)


func assign_jobs():
	return CityConstructionSystem.assign_jobs(self)


func _workers_for_building(building_index):
	return CityConstructionSystem._workers_for_building(self, building_index)


func _has_mine(building_index):
	return CityConstructionSystem._has_mine(self, building_index)


func _register_mine(building_index, building_id):
	return CityConstructionSystem._register_mine(self, building_index, building_id)


func get_mines():
	return CityConstructionSystem.get_mines(self)


func refill_iron_mine(mine_index):
	return CityConstructionSystem.refill_iron_mine(self, mine_index)


func _advance_mines(report):
	return CityConstructionSystem._advance_mines(self, report)


func _get_service_radius(building_id):
	return CityServicesSystem._get_service_radius(self, building_id)


func _get_district_population():
	return CityServicesSystem._get_district_population(self)


func _calculate_district_service_coverage(need_id):
	return CityServicesSystem._calculate_district_service_coverage(self, need_id)


func _get_service_capacity(need_id):
	return CityServicesSystem._get_service_capacity(self, need_id)


func _update_city_services(report):
	return CityServicesSystem._update_city_services(self, report)


func _sync_missions():
	return MissionSystem._sync_missions(self)


func _get_mission_progress(mission_id):
	return MissionSystem._get_mission_progress(self, mission_id)


func _is_side_mission_available(mission_id):
	return MissionSystem._is_side_mission_available(self, mission_id)


func _update_missions():
	return MissionSystem._update_missions(self)


func get_missions():
	return MissionSystem.get_missions(self)


func claim_mission(mission_index):
	return MissionSystem.claim_mission(self, mission_index)


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
	var weekly_event = get_weekly_city_event()
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
		citizen = _apply_citizen_payday(citizen, payment)
		state.citizens[citizen_index] = citizen
		treasury_for_payroll -= payment
		paid_wages += payment
	state.money = int(state.money) - paid_wages
	var fleet_maintenance = get_fleet_maintenance()
	var road_maintenance = get_road_maintenance()
	var maintenance_due = fleet_maintenance + road_maintenance
	if str(weekly_event.get("id", "")) == "energy_saving":
		maintenance_due = int(floor(float(maintenance_due) * 0.85))
		report.append("رویداد هفتگی صرفه‌جویی انرژی: هزینه نگهداری ۱۵٪ کمتر شد.")
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

	if str(weekly_event.get("id", "")) == "market_boom" and business_income_total > 0:
		var weekly_business_bonus = int(round(float(business_income_total) * 0.10))
		income += weekly_business_bonus
		report.append("هفته رونق بازار: %d سکه درآمد اضافه از کسب‌وکارها." % weekly_business_bonus)
	if str(weekly_event.get("id", "")) == "festival_week":
		state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 1, 0, 100))
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
	_process_city_event(report)
	_process_resident_requests(report)
	_advance_rival_cities(report)
	_process_mystery_discovery(report)
	_maybe_create_city_decision(report)
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
	if str(weekly_event.get("id", "")) == "development_week":
		xp_earned += 20
		report.append("هفته توسعه و آموزش: ۲۰ تجربه اضافه دریافت شد.")
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
	_update_achievements()
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

func _apply_citizen_payday(citizen, payment):
	# Citizens choose how much of their earned wage to save based on their personal habit.
	var citizen_id = int(citizen.get("id", 1))
	var saving_habit = int(citizen.get("saving_habit", 30 + int((citizen_id * 13) % 71)))
	var saving_rate = float(clamp(0.10 + float(saving_habit) * 0.003, 0.10, 0.40))
	var wallet = max(0, int(citizen.get("wallet", 0)))
	var savings = max(0, int(citizen.get("savings", 0)))
	var desired_deposit = int(floor(float(max(0, payment)) * saving_rate))
	var wallet_room_after_pay = max(0, wallet + max(0, payment) - 40)
	var savings_room = max(0, 10000 - savings)
	var deposit = min(desired_deposit, min(wallet_room_after_pay, savings_room))
	citizen["wallet"] = wallet + max(0, payment) - deposit
	citizen["savings"] = savings + deposit
	citizen["last_savings_deposit"] = deposit
	return citizen

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
	if shops.is_empty() or total_weight <= 0:
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
		var wallet = max(0, int(citizen.get("wallet", 0)))
		var savings = max(0, int(citizen.get("savings", 0)))
		var demand_units = 1 + int(floor(float(100 - food_need) / 50.0))
		var affordable_units = int(floor(float(wallet + savings) / 10.0))
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
		var wallet_payment = min(wallet, purchase)
		var savings_payment = purchase - wallet_payment
		citizen.wallet = wallet - wallet_payment
		citizen.savings = savings - savings_payment
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
	return TradeSystem.get_import_price(self, city_id, resource_id)


func get_import_cities():
	return TradeSystem.get_import_cities(self)


func get_import_price_label(city_id, resource_id):
	return TradeSystem.get_import_price_label(self, city_id, resource_id)


func order_import(city_id, resource_id, requested_amount):
	return TradeSystem.order_import(self, city_id, resource_id, requested_amount)


func _next_shipment_id():
	return TradeSystem._next_shipment_id(self)


func create_import_contract(city_id, resource_id, daily_amount, duration_days):
	return TradeSystem.create_import_contract(self, city_id, resource_id, daily_amount, duration_days)


func _next_contract_id():
	return TradeSystem._next_contract_id(self)


func cancel_import_contract(contract_index):
	return TradeSystem.cancel_import_contract(self, contract_index)


func _process_trade_arrivals(report):
	return TradeSystem._process_trade_arrivals(self, report)


func _dispatch_import_contracts(report):
	return TradeSystem._dispatch_import_contracts(self, report)


func _record_bank_transaction(kind, amount, description):
	return BankingSystem._record_bank_transaction(self, kind, amount, description)


func get_bank_loan_limit():
	return BankingSystem.get_bank_loan_limit(self)


func take_bank_loan(amount, duration_days):
	return BankingSystem.take_bank_loan(self, amount, duration_days)


func repay_bank_loan_manual(loan_index):
	return BankingSystem.repay_bank_loan_manual(self, loan_index)


func repay_bank_loan_early(loan_index):
	return BankingSystem.repay_bank_loan_early(self, loan_index)


func create_bank_deposit(amount, duration_days):
	return BankingSystem.create_bank_deposit(self, amount, duration_days)


func withdraw_bank_deposit(deposit_index):
	return BankingSystem.withdraw_bank_deposit(self, deposit_index)


func _process_bank_day(report):
	return BankingSystem._process_bank_day(self, report)


func game_has_no_municipal_bank():
	return BankingSystem.game_has_no_municipal_bank(self)


func get_market_price(id, action):
	return TradeSystem.get_market_price(self, id, action)


func get_trade_cities():
	return TradeSystem.get_trade_cities(self)


func get_daily_trade_city_ids():
	return TradeSystem.get_daily_trade_city_ids(self)


func get_trade_export_price(city_id, resource_id):
	return TradeSystem.get_trade_export_price(self, city_id, resource_id)


func trade_with_city(city_id, resource_id, requested_amount):
	return TradeSystem.trade_with_city(self, city_id, resource_id, requested_amount)


func _refresh_trade_capacity():
	return TradeSystem._refresh_trade_capacity(self)


func buy_resource(id, amount):
	return TradeSystem.buy_resource(self, id, amount)


func sell_resource(id, amount):
	return TradeSystem.sell_resource(self, id, amount)


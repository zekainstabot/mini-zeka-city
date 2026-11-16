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
const CityEconomySystem = preload("res://scripts/CityEconomySystem.gd")
const CityProgressSystem = preload("res://scripts/CityProgressSystem.gd")

const SAVE_PATH = "user://mini_zeka_city_save.json"
const MAX_REPORT_EVENTS = 120
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
	return CityProgressSystem._sync_rival_cities(self)


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
		"login_reward_streak": 0,
		"login_reward_last_claim_unix": 0,
		"login_reward_golden_medals": 0,
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


func _get_login_reward_definitions():
	return [
		{"day":1,"coins":100,"xp":5,"title":"شروع خوش‌شانس"},
		{"day":2,"coins":150,"xp":8,"title":"هدیه روز دوم"},
		{"day":3,"coins":250,"xp":12,"title":"کیسه نقره‌ای"},
		{"day":4,"coins":400,"xp":20,"title":"گنج کوچک"},
		{"day":5,"coins":650,"xp":30,"title":"صندوق ارزشمند"},
		{"day":6,"coins":1000,"xp":50,"title":"گنجینه بزرگ"},
		{"day":7,"coins":3000,"xp":150,"title":"صندوق طلایی ویژه","item":"مدال طلایی وفاداری"}
	]

func _refresh_login_reward_cycle():
	var last_claim = int(state.get("login_reward_last_claim_unix", 0))
	if last_claim <= 0:
		return
	var now = int(Time.get_unix_time_from_system())
	# Each reward opens 24 hours after the previous claim and remains available
	# for the following 24 hours. Missing that complete window resets the cycle.
	if now >= last_claim + 172800:
		state["login_reward_streak"] = 0
		state["login_reward_last_claim_unix"] = 0
		save_game()

func get_login_reward_calendar():
	return _get_login_reward_definitions()

func get_login_reward_status():
	_refresh_login_reward_cycle()
	var now = int(Time.get_unix_time_from_system())
	var last_claim = int(state.get("login_reward_last_claim_unix", 0))
	var streak = int(clamp(int(state.get("login_reward_streak", 0)), 0, 7))
	var seconds_remaining = 0
	var can_claim = last_claim <= 0
	if last_claim > 0:
		seconds_remaining = max(0, last_claim + 86400 - now)
		can_claim = seconds_remaining <= 0
	var next_day = 1 if streak >= 7 else streak + 1
	var rewards = _get_login_reward_definitions()
	var reward = rewards[next_day - 1]
	return {
		"streak":streak,
		"next_day":next_day,
		"reward":int(reward.coins),
		"xp":int(reward.xp),
		"title":str(reward.title),
		"claimed":not can_claim,
		"can_claim":can_claim,
		"seconds_remaining":seconds_remaining,
		"last_claim_unix":last_claim
	}

func claim_login_reward():
	var status = get_login_reward_status()
	if not bool(status.can_claim):
		var remaining = int(status.seconds_remaining)
		var hours = int(remaining / 3600)
		var minutes = int((remaining % 3600) / 60)
		return {"ok":false,"message":"جایزه بعدی %d ساعت و %d دقیقه دیگر آماده می‌شود." % [hours, minutes]}
	var day = int(status.next_day)
	var rewards = _get_login_reward_definitions()
	var reward_data = rewards[day - 1]
	var reward = int(reward_data.coins)
	var xp = int(reward_data.xp)
	if get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست؛ ابتدا کمی از موجودی خرج کن."}
	_add_money(reward)
	var xp_message = _award_xp(xp)
	state["login_reward_streak"] = day
	state["login_reward_last_claim_unix"] = int(Time.get_unix_time_from_system())
	var special_text = ""
	if day == 7:
		state["login_reward_golden_medals"] = int(state.get("login_reward_golden_medals", 0)) + 1
		special_text = " 🎉 صندوق طلایی و مدال طلایی وفاداری هم گرفتی!"
	save_game()
	return {"ok":true,"message":"جایزه روز %d دریافت شد: %d سکه + %d تجربه.%s %s" % [day, reward, xp, special_text, xp_message]}

func _process_city_event(report):
	return CityProgressSystem._process_city_event(self, report)


func _process_resident_requests(report):
	return CityProgressSystem._process_resident_requests(self, report)


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
	return CityProgressSystem._update_city_records(self)


func _update_achievements():
	return CityProgressSystem._update_achievements(self)


func get_achievements():
	return CityProgressSystem.get_achievements(self)


func get_city_records():
	return CityProgressSystem.get_city_records(self)


func get_geographic_rank_for_district_count(district_count):
	return GameRanking.geographic_rank_for_district_count(district_count)


func get_city_league():
	return GameRanking.city_league(state)


func get_weekly_city_event():
	return CityProgressSystem.get_weekly_city_event(self)


func get_weekly_challenge():
	return CityProgressSystem.get_weekly_challenge(self)


func claim_weekly_challenge():
	return CityProgressSystem.claim_weekly_challenge(self)


func _default_rival_cities():
	return CityProgressSystem._default_rival_cities(self)


func _advance_rival_cities(report):
	return CityProgressSystem._advance_rival_cities(self, report)


func get_rival_standings():
	return CityProgressSystem.get_rival_standings(self)


func _sort_rival_standings(a, b):
	return CityProgressSystem._sort_rival_standings(self, a, b)


func _process_mystery_discovery(report):
	return CityProgressSystem._process_mystery_discovery(self, report)


func get_mystery_status():
	return CityProgressSystem.get_mystery_status(self)


func claim_mystery_reward():
	return CityProgressSystem.claim_mystery_reward(self)


func _maybe_create_city_decision(report):
	return CityProgressSystem._maybe_create_city_decision(self, report)


func get_pending_city_decision():
	return CityProgressSystem.get_pending_city_decision(self)


func resolve_city_decision(option_id):
	return CityProgressSystem.resolve_city_decision(self, option_id)


func get_landmark_project_definitions():
	return CityProgressSystem.get_landmark_project_definitions(self)


func get_landmark_project_status():
	return CityProgressSystem.get_landmark_project_status(self)


func start_landmark_project(project_id):
	return CityProgressSystem.start_landmark_project(self, project_id)


func invest_landmark_stage():
	return CityProgressSystem.invest_landmark_stage(self)


func get_long_term_projects():
	return CityProgressSystem.get_long_term_projects(self)


func claim_long_term_project(project_id):
	return CityProgressSystem.claim_long_term_project(self, project_id)


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
	while state.report_events.size() > MAX_REPORT_EVENTS:
		state.report_events.pop_front()
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

func check_citizen_reports(persist=true):
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
		service_snapshot[need_id] = _calculate_district_service_coverage(need_id, district_population)
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
	if changed and bool(persist):
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
	while state.report_events.size() > MAX_REPORT_EVENTS:
		state.report_events.pop_front()
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
		state.storage_rules[resource_id] = {"target":max(0,int(saved_rule.get("target",saved_rule.get("maximum",40)))),"low_action":str(saved_rule.get("low_action","market")),"high_action":"market"}
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
	state["login_reward_streak"] = int(clamp(int(state.get("login_reward_streak", 0)), 0, 7))
	state["login_reward_last_claim_unix"] = max(0, int(state.get("login_reward_last_claim_unix", 0)))
	state["login_reward_golden_medals"] = max(0, int(state.get("login_reward_golden_medals", 0)))
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

func set_storage_target(resource_id, value):
	return StorageSystem.set_storage_target(self, resource_id, value)


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


func _calculate_district_service_coverage(need_id, cached_population=null):
	return CityServicesSystem._calculate_district_service_coverage(self, need_id, cached_population)


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
	return CityEconomySystem.collect_offline_income(self)


func _calculate_transport_income(report):
	return CityEconomySystem._calculate_transport_income(self, report)


func get_daily_development_support():
	return CityEconomySystem.get_daily_development_support(self)


func end_day(is_offline=false, persist=true):
	return CityEconomySystem.end_day(self, is_offline, persist)


func _apply_citizen_payday(citizen, payment):
	return CityEconomySystem._apply_citizen_payday(self, citizen, payment)


func _process_citizen_purchases(report):
	return CityEconomySystem._process_citizen_purchases(self, report)


func collect_business_profit(building_index):
	return CityEconomySystem.collect_business_profit(self, building_index)


func _workers_for(id):
	return CityEconomySystem._workers_for(self, id)


func _get_reserve(id):
	return CityEconomySystem._get_reserve(self, id)


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


func buy_resource(id, amount, persist=true):
	return TradeSystem.buy_resource(self, id, amount, persist)


func sell_resource(id, amount, persist=true):
	return TradeSystem.sell_resource(self, id, amount, persist)


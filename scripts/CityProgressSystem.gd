extends RefCounted

# City events, rival AI, achievements, weekly challenges, decisions, and long-term projects.

static func _process_city_event(engine, report):
	var state = engine.state
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
			var accepted = engine._add_money(bonus)
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
			var impact = 3 if engine.get_building_count("water_tower") > 0 else 6
			state["needs"]["water"] = int(clamp(int(state.needs.get("water", 50)) - impact, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 2, 0, 100))
		"investor_visit":
			var investment = min(500, 100 + int(state.get("level", 1)) * 35)
			var accepted_investment = engine._add_money(investment)
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
			message += " کمک سرمایه‌گذار: %d سکه." % accepted_investment
		"small_fire":
			if engine.get_building_count("fire_station") > 0:
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

static func _process_resident_requests(engine, report):
	var state = engine.state
	var requests = state.get("resident_requests", [])
	for index in range(requests.size() - 1, -1, -1):
		var request = requests[index]
		if bool(request.get("accepted", false)):
			if engine.get_building_count(str(request.get("building_id", ""))) > 0:
				var reward = int(request.get("reward", 80))
				if engine.get_treasury_capacity() - int(state.get("money", 0)) >= reward:
					engine._add_money(reward)
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
		var building_data = engine.BUILDINGS.get(str(candidate.building), {})
		if need_value >= int(candidate.threshold) or building_data.is_empty():
			continue
		if engine.get_building_count(str(candidate.building)) > 0:
			continue
		if int(state.get("level", 1)) < int(building_data.get("level_unlock", 1)) or int(state.get("population", 0)) < int(building_data.get("unlock", 0)):
			continue
		if engine.get_land_free() < engine.get_land_size(str(candidate.building)):
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

static func _update_city_records(engine):
	var state = engine.state
	var records = state.get("city_records", {})
	records["peak_population"] = max(int(records.get("peak_population", 0)), int(state.get("population", 0)))
	records["peak_money"] = max(int(records.get("peak_money", 0)), int(state.get("money", 0)))
	records["peak_level"] = max(int(records.get("peak_level", 1)), int(state.get("level", 1)))
	records["peak_satisfaction"] = max(int(records.get("peak_satisfaction", 0)), int(state.get("satisfaction", 0)))
	records["most_buildings"] = max(int(records.get("most_buildings", 0)), state.get("buildings", []).size())
	state["city_records"] = records

static func _update_achievements(engine):
	var state = engine.state
	engine._update_city_records()
	var unlocked = state.get("achievements", {})
	for achievement in engine.ACHIEVEMENT_DEFINITIONS:
		var id = str(achievement.id)
		if bool(unlocked.get(id, false)):
			_grant_achievement_gems(engine, achievement, id)
			continue
		var done = false
		match id:
			"first_expansion":
				done = state.get("buildings", []).size() >= 5
			"buildings_10":
				done = state.get("buildings", []).size() >= 10
			"buildings_25":
				done = state.get("buildings", []).size() >= 25
			"buildings_50":
				done = state.get("buildings", []).size() >= 50
			"population_20":
				done = int(state.get("population", 0)) >= 20
			"population_50":
				done = int(state.get("population", 0)) >= 50
			"population_100":
				done = int(state.get("population", 0)) >= 100
			"level_5":
				done = int(state.get("level", 1)) >= 5
			"level_10":
				done = int(state.get("level", 1)) >= 10
			"level_20":
				done = int(state.get("level", 1)) >= 20
			"treasury_20000":
				done = int(state.get("money", 0)) >= 20000
			"treasury_50000":
				done = int(state.get("money", 0)) >= 50000
			"treasury_100000":
				done = int(state.get("money", 0)) >= 100000
			"happy_city":
				done = int(state.get("satisfaction", 0)) >= 85
			"happiness_95":
				done = int(state.get("satisfaction", 0)) >= 95
			"login_streak_7":
				done = int(state.get("login_streak", 0)) >= 7
			"login_streak_30":
				done = int(state.get("login_streak", 0)) >= 30
			"trade_50":
				done = int(state.get("trade_exported_units_total", 0)) >= 50
			"trade_100":
				done = int(state.get("trade_exported_units_total", 0)) >= 100
			"trade_500":
				done = int(state.get("trade_exported_units_total", 0)) >= 500
			"two_districts":
				done = state.get("districts", []).size() >= 2
			"five_districts":
				done = state.get("districts", []).size() >= 5
			"production_chain":
				done = engine.get_building_count("woodcutter") > 0 and engine.get_building_count("sawmill") > 0 and engine.get_building_count("carpenter") > 0
		if done:
			unlocked[id] = true
			_grant_achievement_gems(engine, achievement, id)
	state["achievements"] = unlocked

static func _grant_achievement_gems(engine, achievement, achievement_id):
	var state = engine.state
	var claimed = state.get("achievement_gem_rewards_claimed", {})
	if typeof(claimed) != TYPE_DICTIONARY:
		claimed = {}
	if bool(claimed.get(achievement_id, false)):
		return
	var reward = max(0, int(achievement.get("gem_reward", 0)))
	if reward > 0:
		state["gems"] = max(0, int(state.get("gems", 0))) + reward
		claimed[achievement_id] = true
	state["achievement_gem_rewards_claimed"] = claimed

static func get_achievements(engine):
	var state = engine.state
	var before = state.get("achievements", {}).duplicate(true)
	engine._update_achievements()
	# Persist newly earned achievements immediately, including achievements earned
	# between login sessions (for example after building or exporting goods).
	if before != state.get("achievements", {}):
		engine.save_game()
	var result = []
	for definition in engine.ACHIEVEMENT_DEFINITIONS:
		var item = definition.duplicate(true)
		item["unlocked"] = bool(state.get("achievements", {}).get(str(definition.id), false))
		result.append(item)
	return result

static func get_city_records(engine):
	var state = engine.state
	engine._update_city_records()
	return state.get("city_records", {}).duplicate(true)

static func get_weekly_city_event(engine):
	var state = engine.state
	var today = engine._get_local_calendar_day_serial()
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
		engine.save_game()
	return saved.duplicate(true)

static func get_weekly_challenge(engine):
	var state = engine.state
	var today = engine._get_local_calendar_day_serial()
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
		engine.save_game()
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

static func claim_weekly_challenge(engine):
	var state = engine.state
	var challenge = engine.get_weekly_challenge()
	if bool(challenge.claimed):
		return {"ok":false,"message":"جایزه رقابت این هفته قبلاً دریافت شده است."}
	if int(challenge.progress) < int(challenge.goal):
		return {"ok":false,"message":"هدف هفتگی هنوز کامل نشده است."}
	var reward = int(challenge.reward)
	if engine.get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست."}
	var saved = state.get("weekly_challenge", {})
	saved["claimed"] = true
	state["weekly_challenge"] = saved
	engine._add_money(reward)
	var xp_message = engine._award_xp(int(challenge.xp))
	engine.save_game()
	return {"ok":true,"message":"رقابت هفتگی را بردی! %d سکه و %d تجربه دریافت کردی. %s" % [reward,int(challenge.xp),xp_message]}

static func _default_rival_cities(engine):
	var state = engine.state
	var defaults = []
	for index in range(engine.CITY_NAME_POOL.size()):
		var city = engine.CITY_NAME_POOL[index]
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

static func _advance_rival_cities(engine, report):
	var state = engine.state
	var rivals = state.get("rival_cities", engine._default_rival_cities())
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
	var player_geo = engine.get_geographic_rank_for_district_count(state.get("districts", []).size())
	var player_row = {"geographic_tier":int(player_geo.tier),"xp":int(state.get("xp",0)),"score":int(engine.get_city_league().score)}
	var leader = null
	var leader_geo = {}
	var leader_row = {}
	for rival in rivals:
		var rival_geo = engine.get_geographic_rank_for_district_count(int(rival.get("district_count", 1)))
		var rival_row = {"geographic_tier":int(rival_geo.tier),"xp":int(rival.get("xp",0)),"score":int(rival.get("score",0))}
		if leader == null or engine._sort_rival_standings(rival_row, leader_row):
			leader = rival
			leader_geo = rival_geo
			leader_row = rival_row
	if leader != null and engine._sort_rival_standings(leader_row, player_row):
		report.append("🏙️ خبر رقبا: %s با رتبه %s و مدیریت %s از شهر تو جلوتر افتاد؛ برای پس گرفتن رتبه تلاش کن." % [str(leader.get("name", "شهر رقیب")),str(leader_geo.name),str(leader.get("ai_personality", "هوشمند"))])

static func _sync_rival_cities(engine):
	var state = engine.state
	var player_name = str(state.get("city_name", "")).strip_edges()
	var previous_player_name = str(state.get("rival_roster_player_name", ""))
	var excluded_id = str(state.get("rival_roster_excluded_id", ""))
	if previous_player_name != player_name or excluded_id.is_empty():
		excluded_id = ""
		for city in engine.CITY_NAME_POOL:
			if str(city.name) == player_name:
				excluded_id = str(city.id)
				break
		if excluded_id.is_empty():
			excluded_id = str(engine.CITY_NAME_POOL[randi() % engine.CITY_NAME_POOL.size()].id)
		state["rival_roster_player_name"] = player_name
		state["rival_roster_excluded_id"] = excluded_id
	var existing = {}
	for rival in state.get("rival_cities", []):
		existing[str(rival.get("name", ""))] = rival.duplicate(true)
	var rivals = []
	for city in engine.CITY_NAME_POOL:
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

static func get_rival_standings(engine):
	var state = engine.state
	engine._sync_rival_cities()
	var standings = []
	var player_geo = engine.get_geographic_rank_for_district_count(state.get("districts", []).size())
	standings.append({"id":"player","name":str(state.get("city_name","شهر من")),"score":int(engine.get_city_league().score),"geographic_tier":int(player_geo.tier),"geographic_rank":str(player_geo.name),"district_count":int(player_geo.district_count),"xp":int(state.get("xp",0)),"population":int(state.get("population",0)),"level":int(state.get("level",1)),"is_player":true})
	for rival in state.get("rival_cities", engine._default_rival_cities()):
		var rival_score = int(rival.get("score",0))
		var rival_geo = engine.get_geographic_rank_for_district_count(int(rival.get("district_count",1)))
		standings.append({"id":str(rival.get("id","rival")),"name":str(rival.get("name","شهر رقیب")),"score":rival_score,"geographic_tier":int(rival_geo.tier),"geographic_rank":str(rival_geo.name),"district_count":int(rival_geo.district_count),"xp":int(rival.get("xp",0)),"population":int(rival.get("population",0)),"level":int(rival.get("level",1)),"is_player":false})
	standings.sort_custom(Callable(engine, "_sort_rival_standings"))
	for index in range(standings.size()):
		standings[index]["rank"] = index + 1
	return standings

static func _sort_rival_standings(engine, a, b):
	var state = engine.state
	return engine.GameRanking.sort_standings(a, b)

static func _process_mystery_discovery(engine, report):
	var state = engine.state
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

static func get_mystery_status(engine):
	var state = engine.state
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

static func claim_mystery_reward(engine):
	var state = engine.state
	var mystery = engine.get_mystery_status()
	if not bool(mystery.get("active", false)):
		return {"ok":false,"message":"فعلاً راز مخفی تازه‌ای کشف نشده است."}
	if int(mystery.get("progress", 0)) < int(mystery.get("goal", 1)):
		return {"ok":false,"message":"هنوز سرنخ را کامل نکرده‌ای؛ شرط راز مخفی باقی مانده است."}
	var reward = int(mystery.get("reward", 0))
	if engine.get_treasury_capacity() - int(state.get("money", 0)) < reward:
		return {"ok":false,"message":"برای دریافت جایزه راز مخفی، ابتدا ظرفیت خزانه را خالی کن."}
	engine._add_money(reward)
	var xp = int(mystery.get("xp", 0))
	var xp_message = engine._award_xp(xp)
	var completed = state.get("mystery_completed", [])
	completed.append(str(mystery.get("id", "")))
	state["mystery_completed"] = completed
	state["mystery_active"] = {}
	state["mystery_next_day"] = int(state.get("day", 1)) + 2
	engine.save_game()
	return {"ok":true,"message":"راز مخفی کشف شد! %d سکه و %d تجربه گرفتی. %s" % [reward,xp,xp_message]}

static func _maybe_create_city_decision(engine, report):
	var state = engine.state
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

static func get_pending_city_decision(engine):
	var state = engine.state
	return state.get("pending_city_decision", {}).duplicate(true)

static func resolve_city_decision(engine, option_id):
	var state = engine.state
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
		if engine.get_available_money() < decision_cost:
			return {"ok":false,"message":"موجودی آزاد خزانه برای این تصمیم کافی نیست."}
		engine._spend_money(decision_cost)
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
			engine._add_money(700)
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 2, 0, 100))
		"fire_paid":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + (1 if engine.get_building_count("fire_station") > 0 else -1), 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 2, 0, 100))
		"fire_volunteer":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 1, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) + 1, 0, 100))
		"fire_ignore":
			state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) - 7, 0, 100))
			state["reputation"] = int(clamp(int(state.get("reputation", 50)) - 4, 0, 100))
		"health_paid":
			state["needs"]["health"] = int(clamp(int(state.needs.get("health", 50)) + (12 if engine.get_building_count("clinic") + engine.get_building_count("hospital") > 0 else 6), 0, 100))
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
	engine.save_game()
	return {"ok":true,"message":"تصمیمت ثبت شد؛ پیامد آن در وضعیت شهر اعمال شد."}

static func get_landmark_project_definitions(engine):
	var state = engine.state
	return [
		{"id":"grand_tower","title":"برج بزرگ شهر","description":"نماد شهر و مقصد تازه گردشگران.","reward":1800,"xp":130,"stages":[{"title":"پی‌ریزی برج","cost":1200,"level":2,"population":12,"buildings":4},{"title":"اسکلت و سازه اصلی","cost":1900,"level":3,"population":20,"buildings":7},{"title":"افتتاح برج","cost":3000,"level":4,"population":30,"buildings":10}]},
		{"id":"trade_center","title":"مرکز تجارت منطقه","description":"مرکز مبادله کالا و قراردادهای بین‌شهری.","reward":2200,"xp":160,"stages":[{"title":"تأمین زمین و مجوز","cost":1600,"level":3,"population":20,"buildings":6},{"title":"ساخت سالن‌های تجاری","cost":2600,"level":4,"population":35,"buildings":1,"building_id":"mineral_market"},{"title":"افتتاح مرکز تجارت","cost":3800,"level":5,"population":50,"exports":20}]},
		{"id":"regional_airport","title":"فرودگاه منطقه‌ای","description":"پروژه‌ای بزرگ برای پیوند شهر با منطقه و رشد آینده.","reward":3000,"xp":220,"stages":[{"title":"مطالعات و مجوز فرودگاه","cost":2200,"level":4,"population":35,"buildings":8},{"title":"ساخت باند و پایانه","cost":4200,"level":5,"population":55,"building_id":"transport_depot","building_count":1},{"title":"آماده‌سازی و افتتاح","cost":6000,"level":6,"population":75,"exports":35}]}
	]

static func get_landmark_project_status(engine):
	var state = engine.state
	var active = state.get("landmark_project", {}).duplicate(true)
	if active.is_empty():
		return {"active":false,"completed":state.get("landmark_projects_completed", []).duplicate(true)}
	var definition = {}
	for project in engine.get_landmark_project_definitions():
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
		requirements_met = requirements_met and engine.get_building_count(str(stage.building_id)) >= int(stage.get("building_count", 1))
	if int(stage.get("exports", 0)) > 0:
		requirements_met = requirements_met and int(state.get("trade_exported_units_total", 0)) >= int(stage.exports)
	return {"active":true,"id":str(definition.id),"title":str(definition.title),"description":str(definition.description),"stage":stage_index+1,"stage_total":definition.stages.size(),"stage_data":stage,"requirements_met":requirements_met,"reward":int(definition.reward),"xp":int(definition.xp)}

static func start_landmark_project(engine, project_id):
	var state = engine.state
	if not state.get("landmark_project", {}).is_empty():
		return {"ok":false,"message":"ابتدا پروژه عظیم فعلی را به پایان برسان."}
	if str(project_id) in state.get("landmark_projects_completed", []):
		return {"ok":false,"message":"این سازه قبلاً در شهر افتتاح شده است."}
	for project in engine.get_landmark_project_definitions():
		if str(project.id) == str(project_id):
			state["landmark_project"] = {"id":str(project_id),"stage":0}
			engine.save_game()
			return {"ok":true,"message":"پروژه %s آغاز شد؛ برای هر مرحله باید شرایط را فراهم و هزینه را پرداخت کنی." % str(project.title)}
	return {"ok":false,"message":"پروژه پیدا نشد."}

static func invest_landmark_stage(engine):
	var state = engine.state
	var status = engine.get_landmark_project_status()
	if not bool(status.get("active", false)):
		return {"ok":false,"message":"پروژه عظیمی برای ادامه وجود ندارد."}
	if not bool(status.get("requirements_met", false)):
		return {"ok":false,"message":"شرایط جمعیت، سطح یا ساختمان‌های این مرحله هنوز فراهم نیست."}
	var stage = status.stage_data
	var cost = int(stage.get("cost", 0))
	if engine.get_available_money() < cost:
		return {"ok":false,"message":"موجودی آزاد خزانه برای این مرحله کافی نیست."}
	engine._spend_money(cost)
	var active = state.get("landmark_project", {})
	active["stage"] = int(active.get("stage", 0)) + 1
	state["landmark_project"] = active
	if int(active.stage) >= int(status.stage_total):
		var project_id = str(status.id)
		var completed = state.get("landmark_projects_completed", [])
		completed.append(project_id)
		state["landmark_projects_completed"] = completed
		state["landmark_project"] = {}
		engine._add_money(int(status.reward))
		var xp_message = engine._award_xp(int(status.xp))
		engine.save_game()
		return {"ok":true,"message":"🎉 %s افتتاح شد! پاداش %d سکه و %d تجربه دریافت کردی. %s" % [str(status.title),int(status.reward),int(status.xp),xp_message]}
	engine.save_game()
	return {"ok":true,"message":"مرحله «%s» تکمیل شد؛ مرحله بعدی پروژه آماده پیگیری است." % str(stage.get("title", "پروژه"))}

static func get_long_term_projects(engine):
	var state = engine.state
	var claimed = state.get("long_term_project_claimed", [])
	var public_count = 0
	for building_id in ["water_tower","power_station","school","clinic","police_station","fire_station","sewage_plant","waste_facility","small_park"]:
		public_count += engine.get_building_count(building_id)
	var industry_count = int(engine.get_building_count("woodcutter") > 0) + int(engine.get_building_count("sawmill") > 0) + int(engine.get_building_count("carpenter") > 0)
	return [
		{"id":"population_25","title":"شهر ۲۵ نفره","description":"جمعیت شهر را به ۲۵ نفر برسان.","progress":min(25,int(state.get("population",0))),"goal":25,"reward":1200,"xp":90,"claimed":"population_25" in claimed},
		{"id":"public_services_5","title":"زیرساخت پایدار","description":"حداقل ۵ ساختمان خدمات عمومی بساز.","progress":min(5,public_count),"goal":5,"reward":1000,"xp":75,"claimed":"public_services_5" in claimed},
		{"id":"industry_chain","title":"قطب تولیدی","description":"هر سه حلقه چوب‌بری، الوارسازی و کارگاه مبلمان را بساز.","progress":min(3,industry_count),"goal":3,"reward":1400,"xp":100,"claimed":"industry_chain" in claimed},
		{"id":"level_8","title":"پایتخت منطقه","description":"شهر را به سطح ۸ برسان.","progress":min(8,int(state.get("level",1))),"goal":8,"reward":2000,"xp":150,"claimed":"level_8" in claimed}
	]

static func claim_long_term_project(engine, project_id):
	var state = engine.state
	for project in engine.get_long_term_projects():
		if str(project.id) != str(project_id):
			continue
		if bool(project.claimed):
			return {"ok":false,"message":"جایزه این پروژه قبلاً دریافت شده است."}
		if int(project.progress) < int(project.goal):
			return {"ok":false,"message":"این پروژه هنوز تکمیل نشده است."}
		var reward = int(project.reward)
		if engine.get_treasury_capacity() - int(state.get("money", 0)) < reward:
			return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست."}
		var claimed = state.get("long_term_project_claimed", [])
		claimed.append(str(project_id))
		state["long_term_project_claimed"] = claimed
		engine._add_money(reward)
		var xp_message = engine._award_xp(int(project.xp))
		engine.save_game()
		return {"ok":true,"message":"پروژه بلندمدت تکمیل شد: %d سکه و %d تجربه. %s" % [reward,int(project.xp),xp_message]}
	return {"ok":false,"message":"پروژه پیدا نشد."}

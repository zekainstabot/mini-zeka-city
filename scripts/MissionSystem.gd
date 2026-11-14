extends RefCounted

# Daily tasks, guided progression, side missions, and reward claims.

static func _ensure_daily_missions(engine):
	var state = engine.state
	var today = engine._get_local_calendar_day_serial()
	var daily = state.get("daily_missions", {})
	if int(daily.get("day_serial", -1)) != today:
		daily = {
			"day_serial": today,
			"baseline_buildings": state.get("buildings", []).size(),
			"baseline_employed": engine.get_employed_count(),
			"baseline_city_day": int(state.get("day", 1)),
			"baseline_land": int(state.get("land_owned", 10)),
			"baseline_population": int(state.get("population", 0)),
			"baseline_exports": int(state.get("trade_exported_units_total", 0)),
			"baseline_profit_collections": int(state.get("business_profit_collections_total", 0)),
			"claimed": []
		}
		state["daily_missions"] = daily
		engine.save_game()
	return daily

static func get_daily_missions(engine):
	var state = engine.state
	var daily = _ensure_daily_missions()
	var building_progress = max(0, state.get("buildings", []).size() - int(daily.get("baseline_buildings", 0)))
	var employed_progress = max(0, engine.get_employed_count() - int(daily.get("baseline_employed", 0)))
	var day_progress = max(0, int(state.get("day", 1)) - int(daily.get("baseline_city_day", 1)))
	var land_progress = max(0, int(state.get("land_owned", 10)) - int(daily.get("baseline_land", 10)))
	var population_progress = max(0, int(state.get("population", 0)) - int(daily.get("baseline_population", 0)))
	var export_progress = max(0, int(state.get("trade_exported_units_total", 0)) - int(daily.get("baseline_exports", 0)))
	var profit_progress = max(0, int(state.get("business_profit_collections_total", 0)) - int(daily.get("baseline_profit_collections", 0)))
	var claimed = daily.get("claimed", [])
	var rotation = int(daily.get("day_serial", 0)) % 3
	if rotation == 0:
		return [
			{"id":"daily_build","title":"یک قدم برای توسعه","description":"امروز یک ساختمان جدید بساز.","progress":min(1, building_progress),"goal":1,"reward":180,"xp":12,"claimed":"daily_build" in claimed},
			{"id":"daily_hire","title":"فرصت شغلی تازه","description":"امروز حداقل یک شهروند را شاغل کن.","progress":min(1, employed_progress),"goal":1,"reward":140,"xp":10,"claimed":"daily_hire" in claimed},
			{"id":"daily_day","title":"یک روز مدیریت موفق","description":"امروز یک روز بازی را با موفقیت به پایان برسان.","progress":min(1, day_progress),"goal":1,"reward":120,"xp":8,"claimed":"daily_day" in claimed}
		]
	elif rotation == 1:
		return [
			{"id":"daily_land","title":"گسترش محدوده","description":"امروز یک قطعه زمین به شهر اضافه کن.","progress":min(1, land_progress),"goal":1,"reward":160,"xp":11,"claimed":"daily_land" in claimed},
			{"id":"daily_population","title":"شهر رو به رشد","description":"امروز جمعیت شهر را حداقل یک نفر افزایش بده.","progress":min(1, population_progress),"goal":1,"reward":170,"xp":12,"claimed":"daily_population" in claimed},
			{"id":"daily_export","title":"تاجر یک‌روزه","description":"امروز حداقل ۳ واحد کالا صادر کن.","progress":min(3, export_progress),"goal":3,"reward":200,"xp":15,"claimed":"daily_export" in claimed}
		]
	return [
		{"id":"daily_profit","title":"سودآوری کسب‌وکار","description":"امروز درآمد یک کسب‌وکار به خزانه شهر واریز شود.","progress":min(1, profit_progress),"goal":1,"reward":160,"xp":12,"claimed":"daily_profit" in claimed},
		{"id":"daily_satisfaction","title":"شهردار محبوب","description":"رضایت شهر را به ۷۰ یا بیشتر برسان.","progress":1 if int(state.get("satisfaction", 0)) >= 70 else 0,"goal":1,"reward":170,"xp":12,"claimed":"daily_satisfaction" in claimed},
		{"id":"daily_day","title":"یک روز مدیریت موفق","description":"امروز یک روز بازی را با موفقیت به پایان برسان.","progress":min(1, day_progress),"goal":1,"reward":120,"xp":8,"claimed":"daily_day" in claimed}
	]

static func claim_daily_mission(engine, mission_id):
	var state = engine.state
	var missions = engine.get_daily_missions()
	for mission in missions:
		if str(mission.id) != str(mission_id):
			continue
		if bool(mission.claimed):
			return {"ok":false,"message":"جایزه این مأموریت روزانه قبلاً دریافت شده است."}
		if int(mission.progress) < int(mission.goal):
			return {"ok":false,"message":"این مأموریت روزانه هنوز کامل نشده است."}
		var reward = int(mission.reward)
		if engine.get_treasury_capacity() - int(state.get("money", 0)) < reward:
			return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت جایزه کافی نیست."}
		var daily = state.get("daily_missions", {})
		var claimed = daily.get("claimed", [])
		claimed.append(str(mission_id))
		daily["claimed"] = claimed
		state["daily_missions"] = daily
		engine._add_money(reward)
		var xp_message = engine._award_xp(int(mission.xp))
		engine.save_game()
		return {"ok":true,"message":"جایزه روزانه دریافت شد: %d سکه و %d تجربه. %s" % [reward, int(mission.xp), xp_message]}
	return {"ok":false,"message":"مأموریت روزانه پیدا نشد."}

static func _sync_missions(engine):
	var state = engine.state
	if typeof(state.get("missions", null)) != TYPE_ARRAY:
		state["missions"] = []
	# Remove obsolete missions from older tutorial versions.
	var valid_ids = []
	for definition in engine.MISSION_DEFINITIONS:
		valid_ids.append(str(definition.id))
	var saved_by_id = {}
	for saved_mission in state.missions:
		var saved_id = str(saved_mission.get("id", ""))
		if saved_id in valid_ids:
			saved_by_id[saved_id] = saved_mission
	# Keep old progress but always restore the canonical main-then-side order.
	state.missions = []
	for definition in engine.MISSION_DEFINITIONS:
		var mission_id = str(definition.id)
		if saved_by_id.has(mission_id):
			var saved = saved_by_id[mission_id]
			saved["type"] = str(definition.get("type", "main"))
			state.missions.append(saved)
		else:
			state.missions.append({"id":mission_id,"type":definition.get("type","main"),"progress":0,"completed":false,"claimed":false,"unlocked":str(definition.get("type","main")) == "side"})
	engine._update_missions()

static func _get_mission_progress(engine, mission_id):
	var state = engine.state
	match mission_id:
		"buy_land_tutorial":
			return max(0, int(state.get("land_owned", 10)) - 10)
		"build_house_tutorial":
			return max(0, engine.get_building_count("small_house") - 2)
		"build_farm_tutorial":
			return engine.get_building_count("farm")
		"hire_worker_tutorial":
			return engine.get_employed_count()
		"population_tutorial":
			return int(state.population)
		"market_tutorial":
			return engine.get_building_count("mineral_market")
		"transport_tutorial":
			return engine.get_building_count("transport_depot")
		"level_tutorial":
			return int(state.level)
		"side_population":
			return int(state.population)
		"side_reserve":
			return int(state.get("money", 0))
		"main_water", "side_water":
			return engine.get_building_count("water_tower")
		"main_power", "side_power":
			return engine.get_building_count("power_station")
		"main_storage":
			return engine.get_building_count("medium_warehouse")
		"main_school", "side_school":
			return engine.get_building_count("school")
		"main_clinic", "side_clinic":
			return engine.get_building_count("clinic")
		"main_wood", "side_wood":
			return engine.get_building_count("woodcutter")
		"main_stone", "side_stone_mine":
			return engine.get_building_count("stone_mine")
		"main_sawmill", "side_sawmill":
			return engine.get_building_count("sawmill")
		"main_carpenter", "side_carpenter":
			return engine.get_building_count("carpenter")
		"main_city_bank", "side_bank":
			return engine.get_building_count("municipal_bank")
		"main_central_bank":
			return engine.get_building_count("central_bank")
		"main_level_five":
			return int(state.level)
		"side_sewage":
			return engine.get_building_count("sewage_plant")
		"side_waste":
			return engine.get_building_count("waste_facility")
		"side_park":
			return engine.get_building_count("small_park")
		"side_playground":
			return engine.get_building_count("playground")
		"side_sports":
			return engine.get_building_count("sports_center")
		"side_hospital":
			return engine.get_building_count("hospital")
		"side_police":
			return engine.get_building_count("police_station")
		"side_fire":
			return engine.get_building_count("fire_station")
		"side_university":
			return engine.get_building_count("university")
		"side_cultural":
			return engine.get_building_count("cultural_center")
		"side_iron_mine":
			return engine.get_building_count("iron_mine")
		"side_fish_lake", "side_fishing_dock":
			return engine.get_building_count("fishing_dock")
		"side_fish_market":
			return engine.get_building_count("fish_market")
		"side_fish_processing":
			return engine.get_building_count("fish_processing_plant")
		"side_grocery":
			return engine.get_building_count("grocery_store")
		"side_bakery":
			return engine.get_building_count("bakery")
		"side_restaurant":
			return engine.get_building_count("restaurant")
		"side_office":
			return engine.get_building_count("office")
		"time_login_five", "time_login_seven":
			return int(state.get("login_streak", 0))
		"time_play_three", "time_play_five":
			return int(state.get("consecutive_active_game_days", 0))
		"side_loan_paid":
			var paid_loans = 0
			for loan in state.get("bank_loans", []):
				if str(loan.get("status", "")) == "paid":
					paid_loans += 1
			return paid_loans
		"side_export_eight":
			return int(state.get("trade_exported_units_total", 0))
		"side_collect_profit":
			return int(state.get("business_profit_collections_total", 0))
		"side_positive_cashflow":
			return int(state.get("profitable_day_streak", 0))
		"side_high_satisfaction":
			return int(state.get("high_satisfaction_day_streak", 0))
		"side_expand_districts":
			return int(state.get("districts", []).size())
		"side_private_tax":
			var private_tax_total = 0
			for business in state.get("private_businesses", []):
				private_tax_total += int(business.get("tax_paid_total", 0))
			return private_tax_total
	return 0

static func _is_side_mission_available(engine, mission_id):
	var state = engine.state
	# Side missions are independent from the tutorial chain. Only missions
	# tied to explicitly level-gated buildings wait for the required city level.
	var required_level = 1
	match mission_id:
		"side_iron_mine":
			required_level = 3
		"side_sports", "side_police":
			required_level = 5
		"side_hospital":
			required_level = 6
		"side_university":
			required_level = 7
		"side_cultural":
			required_level = 8
	return int(state.get("level", 1)) >= required_level

static func _update_missions(engine):
	var state = engine.state
	# Main missions remain a guided sequence; side missions unlock independently.
	var previous_main_claimed = true
	for i in range(state.missions.size()):
		var mission = state.missions[i]
		var mission_id = str(mission.get("id", ""))
		var definition = {}
		for candidate in engine.MISSION_DEFINITIONS:
			if str(candidate.id) == mission_id:
				definition = candidate
				break
		if definition.is_empty():
			continue
		if bool(definition.get("legacy", false)):
			# Preserve unclaimed rewards from older versions without adding
			# archived missions back into the new progression.
			mission["unlocked"] = bool(mission.get("completed", false)) and not bool(mission.get("claimed", false))
			state.missions[i] = mission
			continue
		var mission_type = str(definition.get("type", "main"))
		if mission_type == "side":
			mission["unlocked"] = engine._is_side_mission_available(mission_id)
		else:
			mission["unlocked"] = previous_main_claimed
			previous_main_claimed = bool(mission.get("claimed", false))
		var progress = min(int(definition.goal), engine._get_mission_progress(mission_id))
		mission["progress"] = progress
		mission["completed"] = progress >= int(definition.goal)
		state.missions[i] = mission

static func get_missions(engine):
	var state = engine.state
	engine._update_missions()
	return state.get("missions", [])

static func claim_mission(engine, mission_index):
	var state = engine.state
	if mission_index < 0 or mission_index >= state.missions.size():
		return {"ok":false,"message":"ماموریت پیدا نشد."}
	var mission = state.missions[mission_index]
	if not bool(mission.get("unlocked", false)):
		return {"ok":false,"message":"ابتدا مرحله قبلی آموزش را کامل کن."}
	if not bool(mission.get("completed", false)):
		return {"ok":false,"message":"این ماموریت هنوز کامل نشده است."}
	if bool(mission.get("claimed", false)):
		return {"ok":false,"message":"پاداش این ماموریت قبلاً دریافت شده است."}
	var reward = 0
	var xp_reward = 0
	for definition in engine.MISSION_DEFINITIONS:
		if str(definition.id) == str(mission.get("id", "")):
			reward = int(definition.reward)
			xp_reward = int(definition.get("xp", 0))
			break
	var treasury_room = max(0, engine.get_treasury_capacity() - int(state.get("money", 0)))
	if treasury_room < reward:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای دریافت کامل جایزه کافی نیست؛ ابتدا مقداری پول خرج کن یا ظرفیت خزانه را افزایش بده."}
	var accepted = engine._add_money(reward)
	if accepted < reward:
		return {"ok":false,"message":"جایزه کامل به خزانه واریز نشد؛ مأموریت همچنان آماده دریافت می‌ماند."}
	mission.claimed = true
	state.missions[mission_index] = mission
	var xp_message = engine._award_xp(xp_reward)
	engine._update_missions()
	engine.save_game()
	return {"ok":true,"message":"پاداش دریافت شد: %d از %d سکه و %d تجربه. %s" % [accepted, reward, xp_reward, xp_message]}

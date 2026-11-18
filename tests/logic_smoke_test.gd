extends SceneTree

const EngineScript = preload("res://scripts/GameEngine.gd")
const CitizenSocietyScript = preload("res://scripts/CitizenSociety.gd")
const PersianTextScript = preload("res://scripts/PersianText.gd")

func _init():
	var game = EngineScript.new()
	game.new_game()
	assert(int(game.state.version) == 18)
	assert(game.state.resources.has("food"))
	assert(game.get_resource_definitions().has("food"))
	assert(PersianTextScript.reshaper("بازی Godot").find("Godot") >= 0)
	assert(PersianTextScript.reshaper("دانلود YouTube").find("YouTube") >= 0)

	# No more than two construction projects may run at the same time.
	var construction_limit_game = EngineScript.new()
	construction_limit_game.new_game()
	construction_limit_game.state.constructions = [
		{"id":"small_park","finish_at":Time.get_unix_time_from_system()+120},
		{"id":"bakery","finish_at":Time.get_unix_time_from_system()+180}
	]
	assert(construction_limit_game.get_active_construction_count() == 2)
	var construction_money_before = int(construction_limit_game.state.money)
	var blocked_construction = construction_limit_game.build("farm")
	assert(not bool(blocked_construction.ok))
	assert(construction_limit_game.state.constructions.size() == 2)
	assert(int(construction_limit_game.state.money) == construction_money_before)
	construction_limit_game.state.constructions.pop_back()
	assert(construction_limit_game.get_active_construction_count() == 1)

	# Main missions are ordered; side missions unlock independently.
	var mission_game = EngineScript.new()
	mission_game.new_game()
	assert(mission_game.state.missions.size() == 60)
	assert(bool(mission_game.state.missions[0].unlocked))
	assert(not bool(mission_game.state.missions[1].unlocked))
	assert(bool(mission_game.state.missions[20].unlocked))
	mission_game.state.land_owned = 11
	mission_game.state.money = 9000
	mission_game._update_missions()
	assert(bool(mission_game.state.missions[0].completed))
	var mission_money_before = int(mission_game.state.money)
	var blocked_reward_game = EngineScript.new()
	blocked_reward_game.new_game()
	blocked_reward_game.state.land_owned = 11
	blocked_reward_game._update_missions()
	var blocked_reward = blocked_reward_game.claim_mission(0)
	assert(not bool(blocked_reward.ok))
	assert(not bool(blocked_reward_game.state.missions[0].claimed))
	blocked_reward_game.state.money -= 300
	assert(bool(blocked_reward_game.claim_mission(0).ok))
	var main_claim = mission_game.claim_mission(0)
	assert(bool(main_claim.ok))
	assert(int(mission_game.state.xp) == 25)
	assert(int(mission_game.state.money) == mission_money_before + 300)
	assert(bool(mission_game.state.missions[1].unlocked))
	assert(not bool(mission_game.state.missions[1].completed))
	assert(bool(mission_game.state.missions[0].claimed))
	assert(int(mission_game._get_mission_progress("build_house_tutorial")) == 0)
	mission_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	assert(int(mission_game._get_mission_progress("build_house_tutorial")) == 1)
	assert(not bool(mission_game.state.missions[2].unlocked))
	assert(bool(mission_game.state.missions[20].unlocked))
	# Side missions are available independently while main missions keep their sequence.
	mission_game._update_missions()
	assert(bool(mission_game.state.missions[20].unlocked))
	assert(bool(mission_game.state.missions[21].unlocked))
	assert(not bool(mission_game.state.missions[2].unlocked))
	mission_game.state.population = 12
	mission_game.state.buildings.append({"id":"water_tower","workers":0,"balance":0})
	mission_game._update_missions()
	assert(bool(mission_game.state.missions[20].completed))
	var side_claim = mission_game.claim_mission(20)
	assert(bool(side_claim.ok))
	assert(int(mission_game.state.xp) == 70)
	assert(int(mission_game.state.money) == mission_money_before + 900)
	assert(not bool(mission_game.claim_mission(20).ok))
	assert(bool(mission_game.state.missions[21].unlocked))
	var mission_ids = []
	for mission_definition in mission_game.MISSION_DEFINITIONS:
		mission_ids.append(str(mission_definition.id))
	assert(mission_ids.size() == 60)
	var active_mission_count = 0
	for mission_definition in mission_game.MISSION_DEFINITIONS:
		if not bool(mission_definition.get("legacy", false)):
			active_mission_count += 1
	assert(active_mission_count == 51)
	for required_id in ["main_water","main_power","main_storage","main_school","main_clinic","main_wood","main_stone","main_sawmill","main_carpenter","main_city_bank","main_central_bank","main_level_five","side_sewage","side_waste","side_hospital","side_police","side_fire","side_university","side_cultural","side_iron_mine","side_fishing_dock","side_fish_market","side_fish_processing","side_grocery","side_bakery","side_restaurant","side_office","side_loan_paid","side_export_eight","side_collect_profit","side_positive_cashflow","side_high_satisfaction","side_expand_districts","side_private_tax"]:
		assert(required_id in mission_ids)
	var legacy_mission_game = EngineScript.new()
	legacy_mission_game.state = {"version":16,"money":9700,"missions":[{"id":"side_population","claimed":true,"completed":true},{"id":"side_water","claimed":false,"completed":true,"progress":1},{"id":"buy_land_tutorial","claimed":true,"completed":true}],"buildings":[],"citizens":[],"resources":{},"market_stock":{}}
	legacy_mission_game._normalize_state()
	legacy_mission_game._sync_missions()
	assert(str(legacy_mission_game.state.missions[0].id) == "buy_land_tutorial")
	assert(bool(legacy_mission_game.state.missions[0].claimed))
	assert(str(legacy_mission_game.state.missions[20].id) == "side_population")
	assert(bool(legacy_mission_game.state.missions[20].claimed))
	var legacy_water_index = -1
	for legacy_index in range(legacy_mission_game.state.missions.size()):
		if str(legacy_mission_game.state.missions[legacy_index].id) == "side_water":
			legacy_water_index = legacy_index
			break
	assert(legacy_water_index >= 0)
	assert(bool(legacy_mission_game.state.missions[legacy_water_index].unlocked))
	var legacy_reward = legacy_mission_game.claim_mission(legacy_water_index)
	assert(bool(legacy_reward.ok))
	assert(int(legacy_mission_game.state.money) == 9920)
	# Login streaks count unique consecutive local calendar days only.
	var time_game = EngineScript.new()
	time_game.new_game()
	assert(time_game.register_login_day_serial(20000))
	assert(not time_game.register_login_day_serial(20000))
	assert(int(time_game.state.login_streak) == 1)
	assert(time_game.register_login_day_serial(20001))
	assert(int(time_game.state.login_streak) == 2)
	assert(time_game.register_login_day_serial(20003))
	assert(int(time_game.state.login_streak) == 1)
	assert(int(time_game._get_mission_progress("time_login_five")) == 1)
	# Active play streak requires five active minutes in each game day.
	for second in range(299):
		time_game.record_active_play_seconds(1.0)
	time_game.end_day()
	assert(int(time_game.state.consecutive_active_game_days) == 0)
	for active_day in range(3):
		for second in range(300):
			time_game.record_active_play_seconds(1.0)
		time_game.end_day()
	assert(int(time_game._get_mission_progress("time_play_three")) == 3)
	assert(int(time_game._get_mission_progress("time_play_five")) == 3)
	# Offline simulation must not count as active play or break a valid streak.
	for second in range(300):
		time_game.record_active_play_seconds(1.0)
	time_game.end_day(true)
	assert(int(time_game.state.consecutive_active_game_days) == 0)
	assert(int(time_game.state.active_play_seconds_today) == 0)

	# New economic and civic side-mission counters are tied to real game actions.
	time_game.state.bank_loans = [{"status":"paid"}]
	assert(int(time_game._get_mission_progress("side_loan_paid")) == 1)
	time_game.state.trade_exported_units_total = 8
	assert(int(time_game._get_mission_progress("side_export_eight")) == 8)
	time_game.state.business_profit_collections_total = 1
	assert(int(time_game._get_mission_progress("side_collect_profit")) == 1)
	time_game.state.profitable_day_streak = 3
	assert(int(time_game._get_mission_progress("side_positive_cashflow")) == 3)
	time_game.state.high_satisfaction_day_streak = 3
	assert(int(time_game._get_mission_progress("side_high_satisfaction")) == 3)
	time_game.state.private_businesses = [{"tax_paid_total":100}]
	assert(int(time_game._get_mission_progress("side_private_tax")) == 100)
	var district_game = EngineScript.new()
	district_game.new_game()
	for district_building in range(21):
		district_game.state.buildings.append({"id":"small_park","workers":0,"balance":0})
	district_game._ensure_building_locations()
	var district_overview = district_game.get_districts_overview()
	print("District smoke count: ", district_overview.get("district_count", 0))
	assert(int(district_overview.get("district_count", 0)) >= 2)
	assert(int(district_game._get_mission_progress("side_expand_districts")) >= 2)

	var patrol_game = EngineScript.new()
	patrol_game.new_game()
	patrol_game.state.population = 1
	patrol_game.state.citizens = [patrol_game.state.citizens[0]]
	patrol_game.state.needs = {"food":60,"water":60,"power":60,"health":60,"education":63,"safety":60,"leisure":60,"sanitation":60}
	patrol_game.state.buildings.append({"id":"police_station","workers":0,"balance":0})
	patrol_game.assign_jobs()
	patrol_game._update_city_services([])
	assert(int(patrol_game.state.needs.safety) == 72)
	assert(int(patrol_game.state.satisfaction) == 58)

	var profit_game = EngineScript.new()
	profit_game.new_game()
	profit_game.state.buildings.append({"id":"grocery_store","workers":0,"balance":0})
	profit_game.state.resources.food = 10
	profit_game.assign_jobs()
	profit_game.end_day()
	assert(int(profit_game._get_mission_progress("side_collect_profit")) == 1)


	# Private business revenue responds to population, satisfaction and same-sector competition.
	var market_test_society = CitizenSocietyScript.new()
	var market_state = {"population":20,"satisfaction":80,"private_businesses":[
		{"id":1,"building_id":"grocery_store"},
		{"id":2,"building_id":"bakery"},
		{"id":3,"building_id":"restaurant"}
	]}
	var grocery_market = market_test_society._get_business_market_multiplier(market_state, market_state.private_businesses[0])
	market_state.private_businesses = [{"id":1,"building_id":"grocery_store"}]
	var monopoly_market = market_test_society._get_business_market_multiplier(market_state, market_state.private_businesses[0])
	assert(grocery_market < monopoly_market)
	market_state.population = 4
	var small_city_market = market_test_society._get_business_market_multiplier(market_state, market_state.private_businesses[0])
	market_state.population = 20
	assert(monopoly_market > small_city_market)
	market_state.satisfaction = 20
	var low_satisfaction_market = market_test_society._get_business_market_multiplier(market_state, market_state.private_businesses[0])
	market_state.satisfaction = 80
	assert(monopoly_market > low_satisfaction_market)

	# Engagement systems: rival cities, weekly city events, secrets, civic choices and landmarks.
	var engagement_game = EngineScript.new()
	engagement_game.new_game()
	var standings = engagement_game.get_rival_standings()
	assert(standings.size() == 10)
	var player_found = false
	for standing in standings:
		if bool(standing.get("is_player", false)):
			player_found = true
			assert(int(standing.get("rank", 0)) >= 1 and int(standing.get("rank", 0)) <= 10)
	assert(player_found)
	assert(engagement_game.state.get("rival_cities", []).size() == 9)
	for standing in standings:
		assert(not str(standing.get("geographic_rank", "")).is_empty())
		assert(int(standing.get("district_count", 0)) >= 1)
	# Geographic city rank always wins first; XP breaks ties within the same rank.
	var settlement_rank = engagement_game.get_geographic_rank_for_district_count(6)
	var village_rank = engagement_game.get_geographic_rank_for_district_count(13)
	assert(str(settlement_rank.name) == "آبادی")
	assert(str(village_rank.name) == "روستا")
	assert(int(village_rank.tier) > int(settlement_rank.tier))
	var ranking_tiebreakers = [
		{"id":"lower_geo_rank","geographic_tier":1,"xp":99,"score":999},
		{"id":"same_rank_low_xp","geographic_tier":2,"xp":10,"score":800},
		{"id":"same_rank_high_xp","geographic_tier":2,"xp":90,"score":700}
	]
	ranking_tiebreakers.sort_custom(Callable(engagement_game, "_sort_rival_standings"))
	assert(str(ranking_tiebreakers[0].id) == "same_rank_high_xp")
	assert(str(ranking_tiebreakers[1].id) == "same_rank_low_xp")
	assert(str(ranking_tiebreakers[2].id) == "lower_geo_rank")

	# The rival news leader must follow the same geographic/XP/score priority as the ranking.
	var leader_priority_game = EngineScript.new()
	leader_priority_game.new_game()
	leader_priority_game.state["districts"] = [{"id":"A1"}]
	leader_priority_game.state["rival_cities"] = [
		{"id":"high_score_low_rank","name":"رقیب با امتیاز زیاد","district_count":4,"buildings":12,"level":1,"xp":99,"score":99999,"wealth":0,"ai_style_index":0},
		{"id":"high_rank_low_score","name":"رقیب با رتبه بالاتر","district_count":10,"buildings":30,"level":1,"xp":1,"score":1,"wealth":0,"ai_style_index":0}
	]
	var leader_priority_report = []
	leader_priority_game._advance_rival_cities(leader_priority_report)
	assert(leader_priority_report.size() == 1)
	assert(str(leader_priority_report[0]).find("رقیب با رتبه بالاتر") >= 0)

	var rival_ai_report = []
	engagement_game._advance_rival_cities(rival_ai_report)
	var saved_ai_profiles = {}
	for rival_city in engagement_game.state.get("rival_cities", []):
		assert(str(rival_city.get("ai_style", "")) in ["housing", "economy", "services", "innovation"])
		assert(int(rival_city.get("ai_style_index", -1)) >= 0 and int(rival_city.get("ai_style_index", -1)) <= 3)
		assert(int(rival_city.get("ai_actions", -1)) >= 0)
		saved_ai_profiles[str(rival_city.get("id", ""))] = int(rival_city.get("ai_style_index", -1))
	engagement_game._sync_rival_cities()
	for rival_city in engagement_game.state.get("rival_cities", []):
		assert(int(rival_city.get("ai_style_index", -1)) == int(saved_ai_profiles.get(str(rival_city.get("id", "")), -2)))
	# Rival progression must never exceed the configured level cap.
	var capped_rival = engagement_game.state.rival_cities[0]
	capped_rival["level"] = 15
	capped_rival["xp"] = 1490
	engagement_game.state.rival_cities[0] = capped_rival
	engagement_game._advance_rival_cities(rival_ai_report)
	capped_rival = engagement_game.state.rival_cities[0]
	assert(int(capped_rival.get("level", 0)) == 15)
	assert(int(capped_rival.get("xp", 99999)) < 1500)
	assert(int(capped_rival.get("district_count", 0)) >= 1)
	var weekly_city_event = engagement_game.get_weekly_city_event()
	assert(str(weekly_city_event.get("id", "")) in ["market_boom","festival_week","energy_saving","development_week"])

	engagement_game.state["mystery_active"] = {"id":"test_secret","title":"راز آزمایشی","kind":"buildings","goal":1,"reward":500,"xp":20}
	# Keep enough treasury capacity available so this reward test checks the mystery flow, not a full treasury.
	engagement_game.state["money"] = 1000
	engagement_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	var mystery_reward = engagement_game.claim_mystery_reward()
	assert(bool(mystery_reward.get("ok", false)))
	assert("test_secret" in engagement_game.state.mystery_completed)

	var decision_satisfaction_before = int(engagement_game.state.satisfaction)
	engagement_game.state["pending_city_decision"] = {"id":"test_decision","options":[{"id":"volunteer","effect":"festival_volunteer"}]}
	var decision_result = engagement_game.resolve_city_decision("volunteer")
	assert(bool(decision_result.get("ok", false)))
	assert(int(engagement_game.state.satisfaction) == decision_satisfaction_before + 2)
	# Emergency decisions must charge the selected cost and apply consequences.
	engagement_game.state["money"] = 1800
	engagement_game.state["pending_city_decision"] = {"id":"test_fire","options":[{"id":"respond","effect":"fire_paid","cost":400}]}
	var fire_money_before = int(engagement_game.state.money)
	var fire_result = engagement_game.resolve_city_decision("respond")
	assert(bool(fire_result.get("ok", false)))
	assert(int(engagement_game.state.money) == fire_money_before - 400)
	assert(int(engagement_game.state.reputation) >= 52)
	engagement_game.state["pending_city_decision"] = {"id":"test_illness","options":[{"id":"treat","effect":"health_paid","cost":350}]}
	var health_before = int(engagement_game.state.needs.health)
	assert(bool(engagement_game.resolve_city_decision("treat").get("ok", false)))
	assert(int(engagement_game.state.needs.health) > health_before)

	engagement_game.state.level = 2
	engagement_game.state.population = 12
	engagement_game.state.buildings.append({"id":"small_park","workers":0,"balance":0})
	assert(bool(engagement_game.start_landmark_project("grand_tower").get("ok", false)))
	var first_landmark_stage = engagement_game.get_landmark_project_status()
	assert(bool(first_landmark_stage.get("requirements_met", false)))
	# Earlier mystery and emergency-decision checks spend from this same test city's treasury.
	# Refill it here so the landmark test isolates stage progression rather than prior test costs.
	engagement_game.state["money"] = 10000
	assert(bool(engagement_game.invest_landmark_stage().get("ok", false)))
	assert(int(engagement_game.get_landmark_project_status().get("stage", 0)) == 2)

	# Automatic recruitment must turn new housing into residents, not stranded requests.
	var auto_recruitment_game = EngineScript.new()
	auto_recruitment_game.new_game()
	auto_recruitment_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	var automatic_arrivals = auto_recruitment_game._create_house_citizen_requests("small_house")
	assert(automatic_arrivals == 2)
	assert(int(auto_recruitment_game.state.population) == 6)
	assert(auto_recruitment_game.state.citizen_requests.is_empty())
	assert(auto_recruitment_game.state.citizens.size() == 6)

	# Manual mode keeps requests, and switching back to auto accepts them.
	var manual_recruitment_game = EngineScript.new()
	manual_recruitment_game.new_game()
	manual_recruitment_game.set_citizen_recruitment_mode("manual")
	manual_recruitment_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	var manual_requests = manual_recruitment_game._create_house_citizen_requests("small_house")
	assert(manual_requests == 2)
	assert(int(manual_recruitment_game.state.population) == 4)
	assert(manual_recruitment_game.state.citizen_requests.size() == 2)
	manual_recruitment_game.set_citizen_recruitment_mode("auto")
	assert(int(manual_recruitment_game.state.population) == 6)
	assert(manual_recruitment_game.state.citizen_requests.is_empty())
	assert(manual_recruitment_game.state.citizens.size() == 6)

	# Citizen growth follows city satisfaction, reputation and available housing.
	var timed_auto_game = EngineScript.new()
	timed_auto_game.new_game()
	timed_auto_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	timed_auto_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	assert(timed_auto_game.process_citizen_recruitment_interval(59.0) == 0)
	assert(timed_auto_game.process_citizen_recruitment_interval(1.0) == 2)
	assert(int(timed_auto_game.state.population) == 6)
	assert(timed_auto_game.state.citizen_requests.is_empty())
	timed_auto_game.state.satisfaction = 75
	assert(timed_auto_game.process_citizen_recruitment_interval(60.0) == 2)
	assert(int(timed_auto_game.state.population) == 8)

	var low_satisfaction_game = EngineScript.new()
	low_satisfaction_game.new_game()
	low_satisfaction_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	low_satisfaction_game.state.satisfaction = 20
	assert(low_satisfaction_game.process_citizen_recruitment_interval(60.0) == 0)
	low_satisfaction_game.state.satisfaction = 35
	assert(low_satisfaction_game.process_citizen_recruitment_interval(60.0) == 1)

	var timed_manual_game = EngineScript.new()
	timed_manual_game.new_game()
	timed_manual_game.set_citizen_recruitment_mode("manual")
	timed_manual_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	timed_manual_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	assert(timed_manual_game.process_citizen_recruitment_interval(60.0) == 2)
	assert(int(timed_manual_game.state.population) == 4)
	assert(timed_manual_game.state.citizen_requests.size() == 2)
	timed_manual_game.state.satisfaction = 75
	assert(timed_manual_game.process_citizen_recruitment_interval(60.0) == 2)
	assert(timed_manual_game.state.citizen_requests.size() == 4)

	var market_money_before = int(game.state.money)
	var market_stock_before = int(game.state.market_stock.food)
	var market_result = game.buy_resource("food", 5)
	assert(bool(market_result.ok))
	assert(int(game.state.resources.food) == 5)
	assert(int(game.state.market_stock.food) == market_stock_before - 5)
	assert(int(game.state.money) < market_money_before)
	var sale_money_before = int(game.state.money)
	var sale_result = game.sell_resource("food", 2)
	assert(bool(sale_result.ok))
	assert(int(game.state.resources.food) == 3)
	assert(int(game.state.market_stock.food) == market_stock_before - 3)
	assert(int(game.state.money) > sale_money_before)

	var food_game = EngineScript.new()
	food_game.new_game()
	food_game.state.buildings.append({"id":"grocery_store","workers":0,"balance":0})
	food_game.assign_jobs()
	food_game.state.resources.food = 10
	var purchase_report = []
	var purchases = food_game._process_citizen_purchases(purchase_report)
	assert(int(purchases.food_units) == 4)
	assert(int(food_game.state.resources.food) == 6)
	assert(int(purchases.spending) == 40)
	assert(int(purchases.tax) == 4)
	assert(int(food_game.state.buildings[3].balance) == 36)

	var no_shop_game = EngineScript.new()
	no_shop_game.new_game()
	no_shop_game.state.resources.food = 10
	var no_shop_result = no_shop_game._process_citizen_purchases([])
	assert(int(no_shop_result.food_units) == 0)
	assert(int(no_shop_game.state.resources.food) == 10)

	var farm_game = EngineScript.new()
	farm_game.new_game()
	farm_game.state["storage_rules"] = {"food":{"minimum":0,"maximum":40,"low_action":"market","high_action":"market"}}
	farm_game.state.buildings.append({"id":"farm","workers":0,"balance":0})
	farm_game.assign_jobs()
	var farm_report = farm_game.end_day()
	assert(int(farm_game.state.resources.food) == 8)
	assert(int(farm_game.state.day) == 2)
	assert(int(farm_game.state.last_economy.net_cashflow) == int(farm_game.state.last_economy.treasury_closing) - int(farm_game.state.last_economy.treasury_opening))

	var partial_farm_game = EngineScript.new()
	partial_farm_game.new_game()
	partial_farm_game.state["storage_rules"] = {"food":{"minimum":0,"maximum":40,"low_action":"market","high_action":"market"}}
	partial_farm_game.state.population = 1
	partial_farm_game.state.citizens = [partial_farm_game.state.citizens[0]]
	partial_farm_game.state.buildings.append({"id":"farm","workers":0,"balance":0})
	partial_farm_game.assign_jobs()
	partial_farm_game.end_day()
	assert(int(partial_farm_game.state.resources.food) == 2)

	var citizen_loan_game = EngineScript.new()
	citizen_loan_game.new_game()
	citizen_loan_game.state.buildings.append({"id":"central_bank","workers":0,"balance":0})
	citizen_loan_game.state.population = 1
	citizen_loan_game.state.citizens = [{"id":1,"job":"","job_building_index":-1,"wallet":100,"bank_loans":[{"id":1,"principal":500,"interest":50,"remaining":100,"daily_installment":50,"status":"active","missed_days":0}],"civic_profile_initialized":true}]
	citizen_loan_game.assign_jobs()
	var citizen_treasury_before = int(citizen_loan_game.state.money)
	var citizen_day_summary = CitizenSocietyScript.new().process_day(citizen_loan_game, [])
	assert(int(citizen_loan_game.state.citizens[0].wallet) == 50)
	assert(int(citizen_loan_game.state.citizens[0].bank_loans[0].remaining) == 50)
	assert(int(citizen_loan_game.state.money) == citizen_treasury_before + 50)
	assert(int(citizen_day_summary.citizen_loan_repayments) == 50)

	var fleet_game = EngineScript.new()
	fleet_game.new_game()
	fleet_game.state.population = 4
	fleet_game.state.buildings.append({"id":"transport_depot","workers":0,"balance":0})
	fleet_game.assign_jobs()
	assert(int(fleet_game.get_transport_truck_count()) == 2)
	assert(int(fleet_game.get_transport_daily_capacity()) == 20)

	var migration_game = EngineScript.new()
	migration_game.state = {"version":9,"buildings":[],"citizens":[],"resources":{},"market_stock":{}}
	migration_game._normalize_state()
	assert(int(migration_game.state.version) == 18)
	assert(migration_game.state.resources.has("food"))
	assert(int(migration_game.state.road_level) == 1)

	# The municipal hall unlocks municipal controls and starts the private economy.
	var civic_gate_game = EngineScript.new()
	civic_gate_game.new_game()
	assert(not civic_gate_game.has_municipal_hall())
	var gated_business = {"id":1,"owner_citizen_id":1,"building_id":"grocery_store","balance":200,"jobs":2,"wage":20,"revenue_per_worker":100,"tax_paid_total":0,"tax_credit":0}
	civic_gate_game.state.private_businesses.append(gated_business)
	var gated_report = []
	var gated_summary = CitizenSocietyScript.new().process_day(civic_gate_game, gated_report)
	assert(int(gated_summary.private_business_tax) == 0)
	assert(int(civic_gate_game.state.private_businesses[0].balance) == 200)
	assert(civic_gate_game.state.business_requests.is_empty())
	assert(not civic_gate_game.resolve_civic_request(999, true).ok)
	assert(not civic_gate_game.adjust_business_tax(1).ok)
	var hall_build_result = civic_gate_game.build("municipal_hall")
	assert(bool(hall_build_result.ok))
	assert(not civic_gate_game.has_municipal_hall())
	civic_gate_game.state.constructions[0]["finish_at"] = 0
	civic_gate_game.process_constructions()
	assert(civic_gate_game.has_municipal_hall())
	assert(bool(civic_gate_game.adjust_business_tax(1).ok))
	var unlocked_business_balance = int(civic_gate_game.state.private_businesses[0].balance)
	var unlocked_summary = CitizenSocietyScript.new().process_day(civic_gate_game, [])
	assert(int(unlocked_summary.private_business_tax) > 0)
	assert(int(civic_gate_game.state.private_businesses[0].balance) < unlocked_business_balance + 200)

	# District service capacity reaches neighboring districts, but never exceeds its resident capacity.
	var district_service_game = EngineScript.new()
	district_service_game.new_game()
	for house_index in range(19):
		district_service_game.state.buildings.append({"id":"small_house","workers":0,"balance":0})
	district_service_game.state.buildings.append({"id":"hospital","workers":0,"balance":0})
	district_service_game.state.population = 42
	district_service_game._sync_population()
	district_service_game._ensure_building_locations()
	district_service_game.assign_jobs()
	var district_population = district_service_game._get_district_population()
	assert(district_service_game.state.districts.size() == 2)
	assert(int(district_population.get("A1", 0)) == 40)
	assert(int(district_population.get("A2", 0)) == 2)
	var hospital_coverage = district_service_game._calculate_district_service_coverage("health")
	assert(int(hospital_coverage.coverage.get("A1", 0)) == 100)
	assert(int(hospital_coverage.coverage.get("A2", 0)) == 100)

	# Citizen service requests are district-based, persistent, and do not flood the inbox.
	var district_report_game = EngineScript.new()
	district_report_game.new_game()
	assert(district_report_game.check_citizen_reports())
	assert(district_report_game.state.active_service_report_keys.size() == 1)
	var first_service_report_key = str(district_report_game.state.active_service_report_keys[0])
	assert(first_service_report_key.begins_with("service_"))
	assert(not district_report_game.check_citizen_reports())
	assert(district_report_game.state.active_service_report_keys.size() == 1)
	var first_service_report_index = -1
	for report_index in range(district_report_game.state.report_events.size()):
		if str(district_report_game.state.report_events[report_index].get("issue_key", "")) == first_service_report_key:
			first_service_report_index = report_index
			break
	assert(first_service_report_index >= 0)
	district_report_game.state.buildings.append({"id":"school","workers":0,"balance":0})
	district_report_game._ensure_building_locations()
	district_report_game.assign_jobs()
	assert(district_report_game.check_citizen_reports())
	assert(bool(district_report_game.state.report_events[first_service_report_index].get("resolved", false)))
	assert(district_report_game.state.active_service_report_keys.size() == 1)
	assert(str(district_report_game.state.active_service_report_keys[0]) != first_service_report_key)

	# The existing per-district type limit remains intact.
	# Private businesses must be rebuilt using their building type, not numeric business id.
	var private_district_game = EngineScript.new()
	private_district_game.new_game()
	private_district_game.state["private_businesses"] = [
		{"id":101,"building_id":"grocery_store","name":"فروشگاه خصوصی"},
		{"id":102,"building_id":"grocery_store","name":"فروشگاه دوم"},
		{"id":103,"building_id":"grocery_store","name":"فروشگاه سوم"}
	]
	private_district_game._ensure_building_locations()
	var private_district = private_district_game.state.districts[0]
	assert(int(private_district.building_type_counts.get("grocery_store", 0)) == 2)
	assert(not private_district.building_type_counts.has("101"))
	assert(not private_district.building_type_counts.has("102"))
	assert(not private_district_game._district_can_accept(private_district, "grocery_store"))
	assert(private_district_game.state.districts.size() == 2)
	assert(str(private_district_game.state.private_businesses[2].district_id) == "A2")

	var district_type_limit_game = EngineScript.new()
	district_type_limit_game.new_game()
	district_type_limit_game._ensure_building_locations()
	var first_district = district_type_limit_game.state.districts[0].duplicate(true)
	first_district["building_type_counts"]["small_park"] = 2
	assert(not district_type_limit_game._district_can_accept(first_district, "small_park"))
	assert(district_type_limit_game._district_can_accept(first_district, "playground"))

	# Citizens independently select roles that fit their personal career interests.
	var independent_jobs_game = EngineScript.new()
	independent_jobs_game.new_game()
	independent_jobs_game.state.population = 2
	independent_jobs_game.state.citizens = [
		{"id":1,"job":"","job_building_index":-1,"business_interest":"industry","career_sector":"industry","education":35,"creativity":30,"initiative":75},
		{"id":2,"job":"","job_building_index":-1,"business_interest":"food","career_sector":"food","education":35,"creativity":75,"initiative":45}
	]
	independent_jobs_game.state.buildings.append({"id":"farm","workers":0,"balance":0})
	independent_jobs_game.state.buildings.append({"id":"factory","workers":0,"balance":0})
	independent_jobs_game.assign_jobs()
	assert(str(independent_jobs_game.state.citizens[0].get("job","")) == "factory")
	assert(str(independent_jobs_game.state.citizens[1].get("job","")) == "farm")

	# Personal savings follow each citizen's saving habit and remain available for essential food.
	var savings_game = EngineScript.new()
	savings_game.new_game()
	var saver = {"id":7,"wallet":100,"saving_habit":100,"savings":0}
	saver = savings_game._apply_citizen_payday(saver, 100)
	assert(int(saver.wallet) == 160)
	assert(int(saver.savings) == 40)
	assert(int(saver.last_savings_deposit) == 40)
	var savings_food_game = EngineScript.new()
	savings_food_game.new_game()
	savings_food_game.state.citizens = [{"id":1,"wallet":0,"savings":40}]
	savings_food_game.state.population = 1
	savings_food_game.state.resources.food = 4
	savings_food_game.state.needs.food = 0
	savings_food_game.state.buildings.append({"id":"grocery_store","workers":0,"balance":0})
	savings_food_game.assign_jobs()
	var savings_purchase = savings_food_game._process_citizen_purchases([])
	assert(int(savings_purchase.food_units) == 3)
	assert(int(savings_food_game.state.citizens[0].wallet) == 0)
	assert(int(savings_food_game.state.citizens[0].savings) == 10)

	print("Mini ZekaCity logic smoke tests passed.")
	quit()

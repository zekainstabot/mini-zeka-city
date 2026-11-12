extends SceneTree

const EngineScript = preload("res://scripts/GameEngine.gd")
const CitizenSocietyScript = preload("res://scripts/CitizenSociety.gd")

func _init():
	var game = EngineScript.new()
	game.new_game()
	assert(int(game.state.version) == 17)
	assert(game.state.resources.has("food"))
	assert(game.get_resource_definitions().has("food"))

	# Main missions are sequential; side missions stay independently available.
	var mission_game = EngineScript.new()
	mission_game.new_game()
	assert(mission_game.state.missions.size() == 52)
	assert(bool(mission_game.state.missions[0].unlocked))
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
	assert(not bool(mission_game.state.missions[2].unlocked))
	mission_game.state.buildings.append({"id":"water_tower","workers":0,"balance":0})
	mission_game._update_missions()
	assert(bool(mission_game.state.missions[20].completed))
	var side_claim = mission_game.claim_mission(20)
	assert(bool(side_claim.ok))
	assert(int(mission_game.state.xp) == 70)
	assert(int(mission_game.state.money) == mission_money_before + 900)
	assert(not bool(mission_game.claim_mission(20).ok))
	var mission_ids = []
	for mission_definition in mission_game.MISSION_DEFINITIONS:
		mission_ids.append(str(mission_definition.id))
	assert(mission_ids.size() == 52)
	for required_id in ["main_water","main_power","main_storage","main_school","main_clinic","main_wood","main_stone","main_sawmill","main_carpenter","main_city_bank","main_central_bank","main_level_five","side_sewage","side_waste","side_hospital","side_police","side_fire","side_university","side_cultural","side_iron_mine","side_fish_lake","side_fishing_dock","side_fish_market","side_fish_processing","side_grocery","side_bakery","side_restaurant","side_office","side_loan_paid","side_export_eight","side_collect_profit","side_positive_cashflow","side_high_satisfaction","side_expand_districts","side_private_tax"]:
		assert(required_id in mission_ids)
	var legacy_mission_game = EngineScript.new()
	legacy_mission_game.state = {"version":16,"missions":[{"id":"side_population","claimed":true,"completed":true},{"id":"buy_land_tutorial","claimed":true,"completed":true}],"buildings":[],"citizens":[],"resources":{},"market_stock":{}}
	legacy_mission_game._normalize_state()
	assert(str(legacy_mission_game.state.missions[0].id) == "buy_land_tutorial")
	assert(bool(legacy_mission_game.state.missions[0].claimed))
	assert(str(legacy_mission_game.state.missions[20].id) == "side_population")
	assert(bool(legacy_mission_game.state.missions[20].claimed))
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
	time_game.state.active_play_seconds_today = 299
	time_game.end_day()
	assert(int(time_game.state.consecutive_active_game_days) == 0)
	for active_day in range(3):
		time_game.record_active_play_seconds(300.0)
		time_game.end_day()
	assert(int(time_game._get_mission_progress("time_play_three")) == 3)
	assert(int(time_game._get_mission_progress("time_play_five")) == 3)
	# Offline simulation must not count as active play or break a valid streak.
	time_game.record_active_play_seconds(300.0)
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
	assert(int(district_game._get_mission_progress("side_expand_districts")) == 2)

	var market_result = game.buy_resource("food", 5)
	assert(bool(market_result.ok))
	assert(int(game.state.resources.food) == 5)

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
	farm_game.state.buildings.append({"id":"farm","workers":0,"balance":0})
	farm_game.assign_jobs()
	var farm_report = farm_game.end_day()
	assert(int(farm_game.state.resources.food) == 8)
	assert(int(farm_game.state.day) == 2)
	assert(int(farm_game.state.last_economy.net_cashflow) == int(farm_game.state.last_economy.treasury_closing) - int(farm_game.state.last_economy.treasury_opening))

	var partial_farm_game = EngineScript.new()
	partial_farm_game.new_game()
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
	assert(int(migration_game.state.version) == 17)
	assert(migration_game.state.resources.has("food"))
	assert(int(migration_game.state.road_level) == 1)

	print("Mini ZekaCity logic smoke tests passed.")
	quit()

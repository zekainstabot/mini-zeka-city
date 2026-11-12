extends SceneTree

const EngineScript = preload("res://scripts/GameEngine.gd")

func _init():
	var game = EngineScript.new()
	game.new_game()
	assert(int(game.state.version) == 14)
	assert(game.state.resources.has("food"))
	assert(game.get_resource_definitions().has("food"))

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
	var citizen_day_summary = CitizenSociety.new().process_day(citizen_loan_game, [])
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
	assert(int(migration_game.state.version) == 14)
	assert(migration_game.state.resources.has("food"))
	assert(int(migration_game.state.road_level) == 1)

	print("Mini ZekaCity logic smoke tests passed.")
	quit()

extends RefCounted

# Daily economy cycle, wages, private business purchases, transport revenue, and offline income.

static func collect_offline_income(engine):
	var state = engine.state
	var pending = max(0, int(state.get("pending_offline_income", 0)))
	if pending <= 0:
		return {"ok":false,"amount":0,"message":"درآمد آفلاین قابل دریافتی وجود ندارد."}
	var accepted = engine._add_money(pending)
	state["pending_offline_income"] = pending - accepted
	if int(state.pending_offline_income) <= 0:
		state["pending_offline_days"] = 0
	engine.save_game()
	if accepted <= 0:
		return {"ok":false,"amount":0,"message":"ظرفیت خزانه پر است؛ ابتدا ظرفیت خزانه را افزایش بده."}
	return {"ok":true,"amount":accepted,"message":"درآمد آفلاین دریافت شد: %d سکه." % accepted}

static func _calculate_transport_income(engine, report):
	var state = engine.state
	var station_income = 0
	var road_income = 0
	# Daily passenger demand includes the 3-minute night period, when fewer residents travel.
	var passenger_pool = max(0, int(floor(float(state.get("population", 0)) * 0.6)))
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var building_id = str(building.get("id", ""))
		var workers = engine._workers_for_building(building_index)
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
				var station_name = str(engine.BUILDINGS[building_id].name)
				report.append("%s: جابه‌جایی %d مسافر و درآمد %d سکه." % [station_name, passengers, revenue])
	if engine.get_building_count("transport_depot") > 0:
		var active_trucks = engine.get_transport_truck_count()
		var depot_income = active_trucks * 25
		station_income += depot_income
		if depot_income > 0:
			report.append("پایانه حمل‌ونقل: خدمات %d کامیون فعال، درآمد %d سکه." % [active_trucks, depot_income])
	var freight_units = int(state.get("transport_used_today", 0))
	if freight_units > 0:
		road_income = freight_units * max(1, int(state.get("road_level", 1)))
		report.append("عوارض جاده‌ای برای عبور %d واحد بار: %d سکه." % [freight_units, road_income])
	return {"station_income":station_income, "road_income":road_income}

static func get_daily_development_support(engine):
	var state = engine.state
	# Temporary development support prevents a young city from becoming insolvent.
	# It tapers off with level and only tops the treasury up toward 3,000 coins.
	var support_by_level = {1:250, 2:180, 3:100}
	var level = int(state.get("level", 1))
	var level_support = int(support_by_level.get(level, 0))
	var treasury_gap = max(0, 3000 - int(state.get("money", 0)))
	return min(level_support, treasury_gap)

static func _apply_citizen_economy_to_last_report(state, citizen_economy):
	var private_tax_accepted = int(citizen_economy.get("private_business_tax", 0))
	var citizen_loan_repayments = int(citizen_economy.get("citizen_loan_repayments", 0))
	var citizen_loan_disbursements = int(citizen_economy.get("citizen_loan_disbursements", 0))
	var incoming = private_tax_accepted + citizen_loan_repayments
	state.last_economy["private_business_tax"] = private_tax_accepted
	state.last_economy["citizen_loan_repayments"] = citizen_loan_repayments
	state.last_economy["citizen_loan_disbursements"] = citizen_loan_disbursements
	state.last_economy["gross_income"] = int(state.last_economy.get("gross_income", 0)) + incoming
	state.last_economy["accepted_income"] = int(state.last_economy.get("accepted_income", 0)) + incoming
	# Loan disbursements leave the treasury; repayments and taxes enter it.
	state.last_economy["net_cashflow"] = int(state.last_economy.get("net_cashflow", 0)) + incoming - citizen_loan_disbursements


static func end_day(engine, is_offline=false, persist=true):
	var state = engine.state
	var report = []
	var weekly_event = engine.get_weekly_city_event()
	var treasury_opening = int(state.get("money", 0))
	engine.assign_jobs()
	var development_support_due = engine.get_daily_development_support()
	var development_support_paid = engine._add_money(development_support_due)
	if development_support_paid > 0:
		report.append("کمک‌هزینه توسعه شهر: %d سکه." % development_support_paid)
	var total_wages = 0
	var paid_wages = 0
	var treasury_for_payroll = engine.get_available_money()
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		if str(citizen.get("job", "")) == "":
			continue
		var wage = int(engine.BUILDINGS.get(citizen.job, {}).get("wage", 0))
		var wallet_room = max(0, 500 - int(citizen.get("wallet", 0)))
		var payable_wage = min(wage, wallet_room)
		total_wages += payable_wage
		var payment = min(payable_wage, treasury_for_payroll)
		citizen = engine._apply_citizen_payday(citizen, payment)
		state.citizens[citizen_index] = citizen
		treasury_for_payroll -= payment
		paid_wages += payment
	state.money = int(state.money) - paid_wages
	var fleet_maintenance = engine.get_fleet_maintenance()
	var road_maintenance = engine.get_road_maintenance()
	var maintenance_due = fleet_maintenance + road_maintenance
	if str(weekly_event.get("id", "")) == "energy_saving":
		maintenance_due = int(floor(float(maintenance_due) * 0.85))
		report.append("رویداد هفتگی صرفه‌جویی انرژی: هزینه نگهداری ۱۵٪ کمتر شد.")
	var maintenance_paid = min(maintenance_due, engine.get_available_money())
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

	engine._advance_mines(report)
	# Forest regrowth is gradual and capped; logging consumes actual trees.
	state.forest_trees = min(100, int(state.forest_trees) + 2)
	var tax_income = int(state.population) * 5
	var business_income_total = 0
	var resource_income_total = 0
	var citizen_market = engine._process_citizen_purchases(report)
	var consumer_tax_income = int(citizen_market.tax)
	var income = tax_income + consumer_tax_income
	var transport_income = engine._calculate_transport_income(report)
	var station_income = int(transport_income.station_income)
	var road_income = int(transport_income.road_income)
	income += station_income + road_income
	if tax_income > 0:
		report.append("مالیات شهری دریافت شد: "+str(tax_income)+" سکه.")
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var data = engine.BUILDINGS.get(building.id, {})
		var workers = engine._workers_for_building(building_index)
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
		var output_rule = engine.get_storage_rule(output)
		if int(state.resources.get(output,0)) < int(output_rule.get("minimum",10)) and str(output_rule.get("low_action","market")) == "factory":
			amount = int(ceil(float(amount) * 1.5))
		if str(building.id) == "woodcutter" and int(state.forest_trees) <= 0:
			report.append("چوب‌بری متوقف شد؛ جنگل برای رشد دوباره درخت‌ها به زمان نیاز دارد.")
			continue
		var scaled_input_amount = int(data.get("input_amount", 0))
		if input != "" and required_workers > 0:
			scaled_input_amount = max(1, int(ceil(float(scaled_input_amount) * float(workers) / float(required_workers))))
		if input != "":
			var available_input = int(state.resources.get(input, 0))
			if available_input < scaled_input_amount:
				report.append("%s متوقف شد؛ %s کافی نیست (نیاز: %d، موجودی: %d)." % [str(data.get("name", building.id)), str(engine.RESOURCES.get(input, {}).get("name", input)), scaled_input_amount, available_input])
				continue
		if engine.get_free_storage() < amount:
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
		report.append(data.name+" تولید کرد: "+str(amount)+" "+engine.RESOURCES[output].name+".")

	if str(weekly_event.get("id", "")) == "market_boom" and business_income_total > 0:
		var weekly_business_bonus = int(round(float(business_income_total) * 0.10))
		income += weekly_business_bonus
		report.append("هفته رونق بازار: %d سکه درآمد اضافه از کسب‌وکارها." % weekly_business_bonus)
	if str(weekly_event.get("id", "")) == "festival_week":
		state["satisfaction"] = int(clamp(int(state.get("satisfaction", 50)) + 1, 0, 100))
	# Apply each warehouse threshold after today's production.
	var treasury_before_storage_rules = int(state.get("money", 0))
	for storage_resource_id in engine.RESOURCES.keys():
		var storage_result = engine.apply_storage_rule(str(storage_resource_id), false)
		if bool(storage_result.get("ok",false)) and str(storage_result.get("message","")).find("خریداری شد") >= 0:
			report.append(str(storage_result.message))
	var storage_rule_cashflow = int(state.get("money", 0)) - treasury_before_storage_rules

	var has_market = engine.get_building_count("mineral_market") > 0
	if has_market:
		for id in engine.RESOURCES.keys():
			var reserve = engine._get_reserve(id)
			var surplus = max(0, int(state.resources.get(id, 0)) - reserve)
			var market_room = max(0, 100 - int(state.market_stock.get(id, 0)))
			var unit_price = engine.get_market_price(id, "sell")
			var treasury_room_for_sales = max(0, engine.get_treasury_capacity() - int(state.money) - income)
			var affordable_sale = int(floor(float(treasury_room_for_sales) / float(unit_price)))
			var sell_amount = min(min(surplus, market_room), min(10, affordable_sale))
			if sell_amount > 0:
				state.resources[id] -= sell_amount
				state.market_stock[id] = int(state.market_stock.get(id, 0)) + sell_amount
				var revenue = sell_amount * unit_price
				income += revenue
				resource_income_total += revenue
				report.append(str(sell_amount)+" واحد "+engine.RESOURCES[id].name+" فروخته شد؛ درآمد: "+str(revenue)+" سکه.")
	# Transfer business profits automatically, but preserve any amount the treasury cannot accept.
	var automatic_business_profit = 0
	for profit_index in range(state.buildings.size()):
		var profit_building = state.buildings[profit_index]
		automatic_business_profit += max(0, int(profit_building.get("balance", 0)))
	if automatic_business_profit > 0:
		income += automatic_business_profit
	var accepted_income = engine._add_money(income)
	var bank_repayment_paid = engine._process_bank_day(report)
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
	for restock_id in engine.RESOURCES.keys():
		state.market_stock[restock_id] = min(100, int(state.market_stock.get(restock_id, 0)) + 5)
	engine._refresh_trade_capacity()

	var citizen_economy = engine.CitizenSociety.new().process_day(engine, report)
	_apply_citizen_economy_to_last_report(state, citizen_economy)
	if not engine.has_central_bank() and int(state.central_bank_rebuild_days_left) > 0:
		state.central_bank_rebuild_days_left -= 1
		if int(state.central_bank_rebuild_days_left) == 0:
			var before = int(state.money)
			state.money = min(int(state.money), engine.get_treasury_capacity())
			var destroyed = before - int(state.money)
			if destroyed > 0:
				report.append("مهلت بازسازی بانک مرکزی تمام شد؛ %d سکه مازاد از خزانه حذف شد." % destroyed)
			else:
				report.append("مهلت بازسازی بانک مرکزی تمام شد؛ ظرفیت عادی خزانه فعال شد.")
	engine._update_city_services(report)
	engine._process_city_event(report)
	engine._process_resident_requests(report)
	engine._advance_rival_cities(report)
	engine._process_mystery_discovery(report)
	engine._maybe_create_city_decision(report)
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
	engine._process_trade_arrivals(report)
	engine._dispatch_import_contracts(report)
	# Neighboring provinces restore part of their exportable production each day.
	engine._restock_provincial_trade_supply()
	var xp_earned = engine.get_daily_xp_gain()
	if str(weekly_event.get("id", "")) == "development_week":
		xp_earned += 20
		report.append("هفته توسعه و آموزش: ۲۰ تجربه اضافه دریافت شد.")
	var previous_level = int(state.level)
	state.xp += xp_earned
	var levels_gained = 0
	while state.xp >= engine.get_xp_required_for_next_level():
		state.xp -= engine.get_xp_required_for_next_level()
		state.level += 1
		levels_gained += 1
	report.append("امتیاز تجربه امروز: %d | پیشرفت سطح: %d از %d." % [xp_earned, int(state.xp), engine.get_xp_required_for_next_level()])
	if levels_gained > 0:
		report.append("تبریک! شهر %d سطح ارتقا یافت؛ سطح فعلی: %d." % [levels_gained, state.level])
		var newly_unlocked = []
		for building_id in engine.BUILDINGS.keys():
			var definition = engine.BUILDINGS[building_id]
			var required_level = int(definition.get("level_unlock", 1))
			if required_level > previous_level and required_level <= int(state.level) and int(state.population) >= int(definition.get("unlock", 0)):
				newly_unlocked.append(str(definition.name))
		if newly_unlocked.size() > 0:
			report.append("ساختمان‌های تازه در دسترس: " + "، ".join(newly_unlocked))
	engine._update_missions()
	engine._update_achievements()
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
	engine._update_missions()
	report.append("خلاصه مالی: درآمد ثبت‌شده %d | حقوق %d | نگهداری %d | اقساط شهرداری %d | اقساط شهروندان %d | وام پرداختی به شهروندان %d | تغییر خالص خزانه %d سکه." % [int(state.last_economy.accepted_income), paid_wages, maintenance_paid, bank_repayment_paid, citizen_loan_repayments, citizen_loan_disbursements, int(state.last_economy.net_cashflow)])
	for report_message in report:
		engine.add_report_event(str(report_message), false)
	state.last_report = "\n".join(report)
	if bool(persist):
		engine.save_game()
	return state.last_report

static func _apply_citizen_payday(engine, citizen, payment):
	var state = engine.state
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

static func _process_citizen_purchases(engine, report):
	var state = engine.state
	var shops = []
	var total_weight = 0
	for i in range(state.buildings.size()):
		var building = state.buildings[i]
		var data = engine.BUILDINGS.get(str(building.get("id", "")), {})
		if str(data.get("service_need", "")) != "food":
			continue
		var required = int(data.get("jobs", 0))
		var workers = engine._workers_for_building(i)
		if required <= 0 or workers <= 0:
			continue
		var weight = int(max(1, int(data.get("service_capacity", 1)) * workers / required))
		shops.append({"index":i,"weight":weight})
		total_weight += weight

	var spending = 0
	var sales_tax = 0
	var buyers = 0
	var business_revenue_total = 0
	var food_units = 0
	var food_need = int(state.get("needs", {}).get("food", 60))
	var food_stock = max(0, int(state.resources.get("food",0)))
	var citizen_count = state.citizens.size()
	var rotation_count = max(1, citizen_count)
	var start_index = int(state.day) % rotation_count
	var unmet_food_units = 0
	var requested_food_units = 0

	for step in range(citizen_count):
		var citizen_index = int((start_index + step) % rotation_count)
		var citizen = state.citizens[citizen_index]
		var demand_units = 1 + int(floor(float(100 - food_need) / 50.0))
		requested_food_units += demand_units
		if shops.is_empty() or total_weight <= 0:
			unmet_food_units += demand_units
			continue
		var wallet = max(0, int(citizen.get("wallet", 0)))
		var savings = max(0, int(citizen.get("savings", 0)))
		var affordable_units = int(floor(float(wallet + savings) / 10.0))
		var purchase_units = min(min(demand_units, affordable_units), food_stock)
		if purchase_units <= 0:
			unmet_food_units += demand_units
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
		unmet_food_units += max(0, demand_units - purchase_units)

	state.resources.food = food_stock
	var shortage_ratio = float(unmet_food_units) / float(max(1, requested_food_units))
	if requested_food_units > 0 and shortage_ratio > 0.0:
		var food_penalty = max(1, int(ceil(shortage_ratio * 6.0)))
		state.needs.food = int(clamp(food_need - food_penalty, 0, 100))
		var satisfaction_penalty = max(1, int(ceil(shortage_ratio * 2.0)))
		state.satisfaction = int(clamp(int(state.get("satisfaction", 50)) - satisfaction_penalty, 0, 100))
		report.append("کمبود خوراک: %d از %d واحد تقاضای روزانه تأمین نشد؛ رضایت و شاخص خوراک کاهش یافت." % [unmet_food_units, requested_food_units])
	elif requested_food_units > 0 and food_units >= requested_food_units:
		state.needs.food = int(clamp(food_need + 1, 0, 100))
	if buyers > 0:
		report.append("شهروندان %d خرید خوراک انجام دادند؛ %d واحد غذا مصرف شد و %d سکه گردش مالی ایجاد کرد." % [buyers,food_units,spending])
	elif food_stock <= 0 or shops.is_empty():
		report.append("ذخیره غذا یا دسترسی به فروشگاه کافی نیست؛ شهروندان خرید خوراکی انجام ندادند.")
	return {"spending":spending,"tax":sales_tax,"buyers":buyers,"business_revenue":business_revenue_total,"food_units":food_units,"food_demand":requested_food_units,"food_shortage":unmet_food_units}

static func collect_business_profit(engine, building_index):
	var state = engine.state
	if building_index < 0 or building_index >= state.buildings.size():
		return {"ok":false,"message":"ساختمان پیدا نشد."}
	var building = state.buildings[building_index]
	var balance = max(0, int(building.get("balance", 0)))
	if balance <= 0:
		return {"ok":false,"message":"این کسب‌وکار هنوز سود قابل برداشت ندارد."}
	var accepted = engine._add_money(balance)
	if accepted <= 0:
		return {"ok":false,"message":"ظرفیت خزانه پر است؛ فعلاً امکان برداشت سود وجود ندارد."}
	building.balance = balance - accepted
	state.buildings[building_index] = building
	state["business_profit_collections_total"] = int(state.get("business_profit_collections_total", 0)) + 1
	engine._update_missions()
	engine.save_game()
	return {"ok":true,"message":"%d سکه سود به خزانه منتقل شد." % accepted}

static func _workers_for(engine, id):
	var state = engine.state
	var count = 0
	for citizen in state.citizens:
		if citizen.job == id:
			count += 1
	return count

static func _get_reserve(engine, id):
	var state = engine.state
	if id in ["stone","iron_ore"]:
		return engine.STORAGE_RESERVE
	if id == "food":
		return max(0, int(state.get("population",0)) * 2)
	return int(engine.FORESTRY_RESERVES.get(id, 0))

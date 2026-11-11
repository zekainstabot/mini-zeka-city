extends Reference

# Independent citizen economy and municipal request system.
# Private businesses use their own cash balances and never merge with the player's treasury.

func ensure_state(engine):
	var state = engine.state
	var defaults = {
		"private_land_available": 30,
		"private_land_price": 300,
		"business_tax_rate": 8,
		"business_permit_fee": 50,
		"business_requests": [],
		"private_businesses": [],
		"civic_projects": [],
		"next_private_business_id": 1,
		"next_business_request_id": 1,
		"municipal_rent_income_total": 0
	}
	for key in defaults.keys():
		if not state.has(key):
			state[key] = defaults[key].duplicate(true) if typeof(defaults[key]) == TYPE_ARRAY or typeof(defaults[key]) == TYPE_DICTIONARY else defaults[key]
	if typeof(state.get("business_requests", null)) != TYPE_ARRAY:
		state["business_requests"] = []
	if typeof(state.get("private_businesses", null)) != TYPE_ARRAY:
		state["private_businesses"] = []
	if typeof(state.get("civic_projects", null)) != TYPE_ARRAY:
		state["civic_projects"] = []
	state["private_land_available"] = max(0, int(state.get("private_land_available", 30)))
	state["private_land_price"] = max(100, int(state.get("private_land_price", 300)))
	state["business_tax_rate"] = int(clamp(int(state.get("business_tax_rate", 8)), 0, 30))
	state["business_permit_fee"] = max(0, int(state.get("business_permit_fee", 50)))
	for building_index in range(state.buildings.size()):
		var building = state.buildings[building_index]
		var building_data = engine.BUILDINGS.get(str(building.get("id", "")), {})
		if not building.has("municipal_owned"):
			building["municipal_owned"] = str(building_data.get("category", "")) != "خانه‌ها"
		if not building.has("rented_to"):
			building["rented_to"] = 0
		state.buildings[building_index] = building
	for i in range(state.citizens.size()):
		var citizen = state.citizens[i]
		var profile_id = int(citizen.get("id", i + 1))
		var interests = ["food", "industry", "services"]
		if not bool(citizen.get("civic_profile_initialized", false)):
			citizen["wallet"] = max(250, int(citizen.get("wallet", 100)))
			citizen["private_land"] = 0
			citizen["private_business_id"] = 0
			citizen["private_job_id"] = 0
			citizen["next_civic_request_day"] = int(state.day)
			citizen["civic_request_pending"] = false
			citizen["last_project_request_day"] = 0
			citizen["civic_profile_initialized"] = true
		else:
			citizen["wallet"] = int(clamp(int(citizen.get("wallet", 0)), 0, 2000))
			citizen["private_land"] = max(0, int(citizen.get("private_land", 0)))
			citizen["private_business_id"] = int(citizen.get("private_business_id", 0))
			citizen["private_job_id"] = int(citizen.get("private_job_id", 0))
		if not citizen.has("entrepreneurship"):
			citizen["entrepreneurship"] = 35 + int((profile_id * 17) % 66)
		if not citizen.has("risk_tolerance"):
			citizen["risk_tolerance"] = 20 + int((profile_id * 29) % 81)
		if not citizen.has("business_interest"):
			citizen["business_interest"] = interests[int(profile_id) % interests.size()]
		if not citizen.has("saving_habit"):
			citizen["saving_habit"] = 30 + int((profile_id * 13) % 71)
		state.citizens[i] = citizen
	engine.state = state

func _next_request_id(state):
	var value = int(state.get("next_business_request_id", 1))
	state["next_business_request_id"] = value + 1
	return value

func _find_citizen_index(state, citizen_id):
	for i in range(state.citizens.size()):
		if int(state.citizens[i].get("id", 0)) == int(citizen_id):
			return i
	return -1

func _find_business_index(state, business_id):
	for i in range(state.private_businesses.size()):
		if int(state.private_businesses[i].get("id", 0)) == int(business_id):
			return i
	return -1

func _has_pending_request(state, citizen_id, request_type=""):
	for request in state.business_requests:
		if int(request.get("citizen_id", 0)) == int(citizen_id):
			if request_type == "" or str(request.get("type", "")) == request_type:
				return true
	return false

func _find_rentable_building(engine):
	var state = engine.state
	for i in range(state.buildings.size()):
		var building = state.buildings[i]
		var data = engine.BUILDINGS.get(str(building.get("id", "")), {})
		var category = str(data.get("category", ""))
		if data.empty() or int(data.get("jobs", 0)) <= 0:
			continue
		if category != "کسب‌وکارها" and category != "کارخانه‌ها":
			continue
		if not bool(building.get("municipal_owned", false)) or int(building.get("rented_to", 0)) > 0:
			continue
		var already_requested = false
		for request in state.business_requests:
			if str(request.get("type", "")) == "rent" and int(request.get("building_index", -1)) == i:
				already_requested = true
				break
		if not already_requested:
			return i
	return -1

func _expire_rentals(engine, report):
	var state = engine.state
	for business_index in range(state.private_businesses.size() - 1, -1, -1):
		var business = state.private_businesses[business_index]
		if not bool(business.get("rented_municipal", false)) or int(state.day) <= int(business.get("rent_until_day", 0)):
			continue
		var business_id = int(business.get("id", 0))
		var owner_id = int(business.get("owner_citizen_id", 0))
		for request_index in range(state.business_requests.size() - 1, -1, -1):
			var pending_request = state.business_requests[request_index]
			if int(pending_request.get("citizen_id", 0)) == owner_id:
				state.business_requests.remove(request_index)
		for citizen_index in range(state.citizens.size()):
			var citizen = state.citizens[citizen_index]
			if int(citizen.get("private_job_id", 0)) == business_id:
				citizen["private_job_id"] = 0
			if int(citizen.get("private_business_id", 0)) == business_id:
				citizen["private_business_id"] = 0
				citizen["civic_request_pending"] = false
				citizen["next_civic_request_day"] = int(state.day) + 1
			state.citizens[citizen_index] = citizen
		var building_index = int(business.get("building_index", -1))
		if building_index >= 0 and building_index < state.buildings.size():
			state.buildings[building_index]["rented_to"] = 0
			state.buildings[building_index]["rent_until_day"] = 0
		state.private_businesses.remove(business_index)
		report.append("قرارداد اجاره ملک شهرداری پایان یافت؛ ملک برای درخواست‌های جدید آزاد شد.")

func _choose_business(engine, citizen):
	var state = engine.state
	var interest = str(citizen.get("business_interest", "food"))
	var candidates = ["grocery_store", "bakery", "woodcutter", "restaurant", "sawmill", "carpenter", "office", "factory", "shopping_mall"]
	if interest == "industry":
		candidates = ["woodcutter", "sawmill", "carpenter", "factory", "grocery_store", "bakery", "restaurant", "office", "shopping_mall"]
	elif interest == "services":
		candidates = ["office", "shopping_mall", "grocery_store", "bakery", "restaurant", "woodcutter", "sawmill", "carpenter", "factory"]
	var selected = ""
	for building_id in candidates:
		if not engine.BUILDINGS.has(building_id):
			continue
		var data = engine.BUILDINGS[building_id]
		if int(state.population) < int(data.get("unlock", 0)):
			continue
		if int(state.level) < int(data.get("level_unlock", 1)):
			continue
		if int(data.get("jobs", 0)) <= 0:
			continue
		var total_cost = int(data.get("cost", 0)) + int(state.get("business_permit_fee", 50))
		if int(citizen.get("wallet", 0)) < total_cost:
			continue
		selected = building_id
		break
	return selected

func _queue_land_or_permit_requests(engine):
	var state = engine.state
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		var citizen_id = int(citizen.get("id", 0))
		if bool(citizen.get("civic_request_pending", false)):
			continue
		if int(citizen.get("private_business_id", 0)) > 0:
			continue
		if int(state.day) < int(citizen.get("next_civic_request_day", 1)):
			continue
		var wallet = int(citizen.get("wallet", 0))
		if int(citizen.get("private_land", 0)) <= 0:
			var rentable_index = _find_rentable_building(engine)
			if rentable_index >= 0:
				var rentable = state.buildings[rentable_index]
				var rentable_data = engine.BUILDINGS.get(str(rentable.get("id", "")), {})
				var daily_rent = max(15, int(int(rentable_data.get("cost", 500)) * 0.02))
				var lease_cost = daily_rent * 7
				if wallet >= lease_cost:
					state.business_requests.append({
						"id":_next_request_id(state),
						"type":"rent",
						"citizen_id":citizen_id,
						"day":int(state.day),
						"building_index":rentable_index,
						"building_id":str(rentable.get("id", "")),
						"daily_rent":daily_rent,
						"amount":lease_cost,
						"title":"درخواست اجاره %s برای ۷ روز" % str(rentable_data.get("name", "ملک شهرداری"))
					})
					citizen["civic_request_pending"] = true
					state.citizens[citizen_index] = citizen
					continue
			var land_price = int(state.get("private_land_price", 300))
			var entrepreneurship = int(citizen.get("entrepreneurship", 50))
			var investment_threshold = land_price + max(0, 60 - entrepreneurship) * 3
			if entrepreneurship < 45 or int(state.get("private_land_available", 0)) <= 0 or wallet < investment_threshold:
				continue
			var plots = 1
			state.business_requests.append({
				"id":_next_request_id(state),
				"type":"land",
				"citizen_id":citizen_id,
				"day":int(state.day),
				"plots":plots,
				"amount":land_price * plots,
				"title":"درخواست خرید %d قطعه زمین خصوصی" % plots
			})
			citizen["civic_request_pending"] = true
			state.citizens[citizen_index] = citizen
			continue
		var building_id = _choose_business(engine, citizen)
		if building_id == "":
			continue
		var required_plots = int(engine.get_land_size(building_id))
		var owned_private_plots = int(citizen.get("private_land", 0))
		if owned_private_plots < required_plots:
			var extra_plots = required_plots - owned_private_plots
			var extra_land_cost = int(state.get("private_land_price", 300)) * extra_plots
			var required_business_cost = int(engine.BUILDINGS[building_id].get("cost", 0)) + int(state.get("business_permit_fee", 50))
			if int(state.get("private_land_available", 0)) < extra_plots or wallet < extra_land_cost + required_business_cost:
				continue
			state.business_requests.append({
				"id":_next_request_id(state),
				"type":"land",
				"citizen_id":citizen_id,
				"day":int(state.day),
				"plots":extra_plots,
				"amount":extra_land_cost,
				"title":"درخواست خرید %d قطعه زمین تکمیلی برای کسب‌وکار" % extra_plots
			})
			citizen["civic_request_pending"] = true
			state.citizens[citizen_index] = citizen
			continue
		var data = engine.BUILDINGS[building_id]
		var fee = int(state.get("business_permit_fee", 50))
		state.business_requests.append({
			"id":_next_request_id(state),
			"type":"permit",
			"citizen_id":citizen_id,
			"day":int(state.day),
			"building_id":building_id,
			"building_name":str(data.name),
			"amount":int(data.cost) + fee,
			"footprint":int(engine.get_land_size(building_id)),
			"title":"درخواست مجوز تأسیس %s" % str(data.name)
		})
		citizen["civic_request_pending"] = true
		state.citizens[citizen_index] = citizen

func _choose_public_project(engine):
	var state = engine.state
	var candidates = [
		{"need":"leisure","id":"small_park"},
		{"need":"water","id":"water_tower"},
		{"need":"education","id":"school"},
		{"need":"health","id":"clinic"},
		{"need":"safety","id":"fire_station"},
		{"need":"sanitation","id":"waste_facility"}
	]
	for candidate in candidates:
		if int(state.get("needs", {}).get(candidate.need, 100)) >= 65:
			continue
		var building_id = str(candidate.id)
		var data = engine.BUILDINGS.get(building_id, {})
		if data.empty():
			continue
		if int(state.population) < int(data.get("unlock", 0)) or int(state.level) < int(data.get("level_unlock", 1)):
			continue
		if engine.get_land_free() < int(engine.get_land_size(building_id)):
			continue
		return building_id
	return ""

func _queue_public_project_requests(engine):
	var state = engine.state
	if not state.civic_projects.empty():
		return
	for business_index in range(state.private_businesses.size()):
		var business = state.private_businesses[business_index]
		var owner_id = int(business.get("owner_citizen_id", 0))
		var citizen_index = _find_citizen_index(state, owner_id)
		if citizen_index < 0:
			continue
		var citizen = state.citizens[citizen_index]
		if int(state.day) - int(citizen.get("last_project_request_day", 0)) < 12:
			continue
		if int(citizen.get("risk_tolerance", 50)) < 35:
			continue
		if _has_pending_request(state, owner_id, "public_project"):
			continue
		var building_id = _choose_public_project(engine)
		if building_id == "":
			continue
		var cost = int(engine.BUILDINGS[building_id].get("cost", 0))
		if int(business.get("balance", 0)) < cost or int(business.get("tax_paid_total", 0)) <= 0:
			continue
		state.business_requests.append({
			"id":_next_request_id(state),
			"type":"public_project",
			"citizen_id":owner_id,
			"business_id":int(business.get("id", 0)),
			"day":int(state.day),
			"building_id":building_id,
			"building_name":str(engine.BUILDINGS[building_id].name),
			"amount":cost,
			"title":"پیشنهاد ساخت %s به‌جای بخشی از مالیات" % str(engine.BUILDINGS[building_id].name)
		})
		citizen["last_project_request_day"] = int(state.day)
		citizen["civic_request_pending"] = true
		state.citizens[citizen_index] = citizen
		break

func _process_private_businesses(engine, report):
	var state = engine.state
	var tax_total = 0
	for business_index in range(state.private_businesses.size()):
		var business = state.private_businesses[business_index]
		var data = engine.BUILDINGS.get(str(business.get("building_id", "")), {})
		if data.empty():
			continue
		var employee_ids = []
		for citizen_index in range(state.citizens.size()):
			var citizen = state.citizens[citizen_index]
			if int(citizen.get("private_job_id", 0)) == int(business.get("id", 0)):
				employee_ids.append(int(citizen.get("id", 0)))
		var required = max(1, int(data.get("jobs", 1)))
		for citizen_index in range(state.citizens.size()):
			if employee_ids.size() >= required:
				break
			var citizen = state.citizens[citizen_index]
			if int(citizen.get("id", 0)) == int(business.get("owner_citizen_id", 0)):
				continue
			if str(citizen.get("job", "")) != "" or int(citizen.get("private_job_id", 0)) > 0:
				continue
			citizen["private_job_id"] = int(business.get("id", 0))
			state.citizens[citizen_index] = citizen
			employee_ids.append(int(citizen.get("id", 0)))
		var workers = employee_ids.size()
		var revenue_per_worker = int(business.get("revenue_per_worker", 50))
		var revenue = revenue_per_worker * workers
		var wage = int(business.get("wage", 15)) * workers
		var cash = int(business.get("balance", 0))
		var wage_paid = min(wage, cash + revenue)
		var tax_due = int(floor(float(revenue) * float(state.get("business_tax_rate", 8)) / 100.0))
		var credit = min(tax_due, int(business.get("tax_credit", 0)))
		var tax_paid = tax_due - credit
		business["tax_credit"] = max(0, int(business.get("tax_credit", 0)) - credit)
		business["tax_paid_total"] = int(business.get("tax_paid_total", 0)) + tax_paid
		business["balance"] = max(0, cash + revenue - wage_paid - tax_paid)
		business["last_revenue"] = revenue
		business["last_tax"] = tax_paid
		business["employees"] = employee_ids
		tax_total += tax_paid
		for citizen_index in range(state.citizens.size()):
			var citizen = state.citizens[citizen_index]
			if int(citizen.get("id", 0)) in employee_ids:
				var payment = int(business.get("wage", 15))
				citizen["wallet"] = int(clamp(int(citizen.get("wallet", 0)) + payment, 0, 2000))
				state.citizens[citizen_index] = citizen
		var owner_index = _find_citizen_index(state, int(business.get("owner_citizen_id", 0)))
		if owner_index >= 0 and int(business.get("balance", 0)) > 0:
			var dividend = min(10, int(business.balance))
			var owner = state.citizens[owner_index]
			var accepted_dividend = min(dividend, max(0, 2000 - int(owner.get("wallet", 0))))
			owner["wallet"] = int(owner.get("wallet", 0)) + accepted_dividend
			business["balance"] = int(business.balance) - accepted_dividend
			state.citizens[owner_index] = owner
		state.private_businesses[business_index] = business
		if workers > 0:
			report.append("%s خصوصی: فروش %d، حقوق %d، مالیات %d سکه؛ %d کارمند." % [str(data.name), revenue, wage_paid, tax_paid, workers])
	if tax_total > 0:
		var accepted = engine._add_money(tax_total)
		report.append("مالیات کسب‌وکارهای خصوصی: %d سکه به خزانه شهرداری واریز شد." % accepted)

func _complete_civic_projects(engine, report):
	var state = engine.state
	var remaining = []
	var completed_any = false
	for project in state.civic_projects:
		if int(project.get("finish_day", 0)) > int(state.day):
			remaining.append(project)
			continue
		var building_id = str(project.get("building_id", ""))
		if not engine.BUILDINGS.has(building_id):
			continue
		# Project land is already reserved by get_land_used().
		state.buildings.append({"id":building_id,"workers":0,"balance":0,"municipal_owned":true,"civic_project":true})
		var business_index = _find_business_index(state, int(project.get("business_id", 0)))
		if business_index >= 0:
			var business = state.private_businesses[business_index]
			business["tax_credit"] = int(business.get("tax_credit", 0)) + int(project.get("tax_credit", 0))
			state.private_businesses[business_index] = business
		report.append("شهروند شماره %d پروژه عمومی %s را تحویل داد؛ اعتبار مالیاتی %d سکه ثبت شد." % [int(project.get("citizen_id", 0)), str(engine.BUILDINGS[building_id].name), int(project.get("tax_credit", 0))])
		completed_any = true
	state.civic_projects = remaining
	if completed_any:
		engine._sync_population()
		engine.assign_jobs()

func process_day(engine, report):
	ensure_state(engine)
	var state = engine.state
	_expire_rentals(engine, report)
	_complete_civic_projects(engine, report)
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		if str(citizen.get("job", "")) == "" and int(citizen.get("private_job_id", 0)) <= 0:
			var saving_income = 10 + int(int(citizen.get("saving_habit", 50)) / 5)
			citizen["wallet"] = int(clamp(int(citizen.get("wallet", 0)) + saving_income, 0, 2000))
			state.citizens[citizen_index] = citizen
	_process_private_businesses(engine, report)
	_queue_land_or_permit_requests(engine)
	_queue_public_project_requests(engine)
	if not state.business_requests.empty():
		report.append("%d درخواست شهروندان برای زمین، مجوز یا پروژه عمرانی در شهرداری منتظر بررسی است." % state.business_requests.size())
	engine.state = state

func resolve_request(engine, request_id, approved):
	ensure_state(engine)
	var state = engine.state
	var request_index = -1
	for i in range(state.business_requests.size()):
		if int(state.business_requests[i].get("id", 0)) == int(request_id):
			request_index = i
			break
	if request_index < 0:
		return {"ok":false,"message":"درخواست شهرداری پیدا نشد."}
	var request = state.business_requests[request_index]
	var citizen_index = _find_citizen_index(state, int(request.get("citizen_id", 0)))
	if citizen_index < 0:
		state.business_requests.remove(request_index)
		return {"ok":false,"message":"شهروند متقاضی دیگر در شهر حضور ندارد."}
	var citizen = state.citizens[citizen_index]
	if not approved:
		state.business_requests.remove(request_index)
		citizen["civic_request_pending"] = false
		citizen["next_civic_request_day"] = int(state.day) + 3
		state.citizens[citizen_index] = citizen
		engine.state = state
		engine.save_game()
		return {"ok":true,"message":"درخواست شهروند شماره %d رد شد." % int(citizen.get("id", 0))}
	var request_type = str(request.get("type", ""))
	if request_type == "land":
		var plots = int(request.get("plots", 1))
		var cost = int(request.get("amount", 0))
		var land_treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
		if int(state.get("private_land_available", 0)) < plots or int(citizen.get("wallet", 0)) < cost or land_treasury_room < cost:
			return {"ok":false,"message":"زمین، سرمایه شهروند یا ظرفیت خزانه برای این معامله کافی نیست."}
		state["private_land_available"] = int(state.private_land_available) - plots
		citizen["private_land"] = int(citizen.get("private_land", 0)) + plots
		citizen["wallet"] = int(citizen.get("wallet", 0)) - cost
		engine._add_money(cost)
		citizen["civic_request_pending"] = false
		citizen["next_civic_request_day"] = int(state.day) + 1
		state.citizens[citizen_index] = citizen
		state.business_requests.remove(request_index)
		engine.state = state
		engine.save_game()
		return {"ok":true,"message":"فروش %d قطعه زمین به شهروند شماره %d تأیید شد؛ درآمد فروش زمین جدا از مالیات ثبت شد." % [plots, int(citizen.id)]}
	if request_type == "rent":
		var building_index = int(request.get("building_index", -1))
		var daily_rent = int(request.get("daily_rent", 0))
		var lease_cost = int(request.get("amount", 0))
		var rent_treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
		if building_index < 0 or building_index >= state.buildings.size() or int(citizen.get("wallet", 0)) < lease_cost or rent_treasury_room < lease_cost:
			return {"ok":false,"message":"ملک، سرمایه مستأجر یا ظرفیت خزانه برای دریافت کامل اجاره کافی نیست."}
		var municipal_property = state.buildings[building_index]
		if int(municipal_property.get("rented_to", 0)) > 0 or not bool(municipal_property.get("municipal_owned", false)):
			return {"ok":false,"message":"این ملک دیگر برای اجاره آزاد نیست."}
		var rented_id = int(state.get("next_private_business_id", 1))
		state["next_private_business_id"] = rented_id + 1
		citizen["wallet"] = int(citizen.get("wallet", 0)) - lease_cost
		citizen["private_business_id"] = rented_id
		citizen["civic_request_pending"] = false
		state.citizens[citizen_index] = citizen
		municipal_property["rented_to"] = int(citizen.id)
		municipal_property["rent_until_day"] = int(state.day) + 7
		municipal_property["rent_per_day"] = daily_rent
		state.buildings[building_index] = municipal_property
		var rented_id_name = str(request.get("building_id", ""))
		var rented_data = engine.BUILDINGS.get(rented_id_name, {})
		var rent_revenue = max(30, int(int(rented_data.get("daily_revenue", 0)) / max(1, int(rented_data.get("jobs", 1)))))
		state.private_businesses.append({
			"id":rented_id,
			"owner_citizen_id":int(citizen.id),
			"building_id":rented_id_name,
			"name":str(rented_data.get("name", "کسب‌وکار"))+" (اجاره‌ای)",
			"balance":0,
			"employees":[],
			"jobs":int(rented_data.get("jobs", 1)),
			"wage":max(12,int(int(rented_data.get("wage", 30)) / 2)),
			"revenue_per_worker":rent_revenue,
			"last_revenue":0,
			"last_tax":0,
			"tax_paid_total":0,
			"tax_credit":0,
			"rented_municipal":true,
			"building_index":building_index,
			"rent_until_day":int(state.day) + 7,
			"created_day":int(state.day)
		})
		state["municipal_rent_income_total"] = int(state.get("municipal_rent_income_total", 0)) + lease_cost
		engine._add_money(lease_cost)
		state.business_requests.remove(request_index)
		engine.state = state
		engine.assign_jobs()
		engine.save_game()
		return {"ok":true,"message":"اجاره ملک شهرداری برای ۷ روز تأیید شد؛ مبلغ %d سکه جدا از مالیات دریافت شد." % lease_cost}
	if request_type == "permit":
		var building_id = str(request.get("building_id", ""))
		var data = engine.BUILDINGS.get(building_id, {})
		var cost = int(request.get("amount", 0))
		var footprint = int(request.get("footprint", 1))
		var permit_fee = int(state.get("business_permit_fee", 50))
		var permit_treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
		if data.empty() or int(citizen.get("private_land", 0)) < footprint or int(citizen.get("wallet", 0)) < cost or permit_treasury_room < permit_fee:
			return {"ok":false,"message":"شرایط زمین یا سرمایه برای صدور مجوز دیگر برقرار نیست."}
		var business_id = int(state.get("next_private_business_id", 1))
		state["next_private_business_id"] = business_id + 1
		citizen["wallet"] = int(citizen.get("wallet", 0)) - cost
		citizen["private_land"] = int(citizen.get("private_land", 0)) - footprint
		citizen["private_business_id"] = business_id
		citizen["civic_request_pending"] = false
		state.citizens[citizen_index] = citizen
		var revenue_map = {"grocery_store":65,"bakery":85,"woodcutter":70,"restaurant":110,"sawmill":100,"carpenter":125,"office":115,"factory":150,"shopping_mall":220}
		state.private_businesses.append({
			"id":business_id,
			"owner_citizen_id":int(citizen.id),
			"building_id":building_id,
			"name":str(data.name),
			"balance":0,
			"employees":[],
			"jobs":int(data.get("jobs", 1)),
			"wage":max(12,int(data.get("wage", 30) / 2)),
			"revenue_per_worker":int(revenue_map.get(building_id, 60)),
			"last_revenue":0,
			"last_tax":0,
			"tax_paid_total":0,
			"tax_credit":0,
			"created_day":int(state.day)
		})
		engine._add_money(int(state.get("business_permit_fee", 50)))
		state.business_requests.remove(request_index)
		engine.state = state
		engine.save_game()
		return {"ok":true,"message":"مجوز %s صادر شد؛ کسب‌وکار خصوصی شهروند شماره %d آغاز به کار کرد." % [str(data.name), int(citizen.id)]}
	if request_type == "public_project":
		var business_index = _find_business_index(state, int(request.get("business_id", 0)))
		if business_index < 0:
			return {"ok":false,"message":"کسب‌وکار تأمین‌کننده پروژه پیدا نشد."}
		var business = state.private_businesses[business_index]
		var building_id = str(request.get("building_id", ""))
		var cost = int(request.get("amount", 0))
		if not engine.BUILDINGS.has(building_id) or int(business.get("balance", 0)) < cost:
			return {"ok":false,"message":"سرمایه کسب‌وکار برای اجرای پروژه کافی نیست."}
		business["balance"] = int(business.balance) - cost
		state.private_businesses[business_index] = business
		state.civic_projects.append({
			"business_id":int(business.id),
			"citizen_id":int(citizen.id),
			"building_id":building_id,
			"finish_day":int(state.day) + 2,
			"tax_credit":cost
		})
		citizen["civic_request_pending"] = false
		state.citizens[citizen_index] = citizen
		state.business_requests.remove(request_index)
		engine.state = state
		engine.save_game()
		return {"ok":true,"message":"پروژه %s تأیید شد؛ پس از تحویل، %d سکه اعتبار مالیاتی به کسب‌وکار تعلق می‌گیرد." % [str(engine.BUILDINGS[building_id].name), cost]}
	return {"ok":false,"message":"نوع درخواست پشتیبانی نمی‌شود."}

func adjust_tax_rate(engine, delta):
	ensure_state(engine)
	var state = engine.state
	state["business_tax_rate"] = int(clamp(int(state.get("business_tax_rate", 8)) + int(delta), 0, 30))
	engine.state = state
	engine.save_game()
	return {"ok":true,"message":"نرخ مالیات کسب‌وکارهای خصوصی به %d درصد تغییر کرد." % int(state.business_tax_rate)}

func get_overview(engine):
	ensure_state(engine)
	var state = engine.state
	var total_balance = 0
	var total_revenue = 0
	var total_tax = 0
	for business in state.private_businesses:
		total_balance += int(business.get("balance", 0))
		total_revenue += int(business.get("last_revenue", 0))
		total_tax += int(business.get("last_tax", 0))
	return {
		"requests":state.business_requests,
		"request_count":state.business_requests.size(),
		"private_land_available":int(state.private_land_available),
		"private_land_price":int(state.private_land_price),
		"tax_rate":int(state.business_tax_rate),
		"permit_fee":int(state.business_permit_fee),
		"private_businesses":state.private_businesses,
		"business_count":state.private_businesses.size(),
		"private_balance":total_balance,
		"daily_revenue":total_revenue,
		"daily_tax":total_tax,
		"projects":state.civic_projects,
		"project_count":state.civic_projects.size(),
		"rent_income":int(state.get("municipal_rent_income_total", 0))
	}

extends RefCounted

# Land purchasing, building construction, demolition, staffing, and mines.

static func get_land_size(engine, id):
	var state = engine.state
	var sizes = {
		"small_house":1,"normal_house":2,"low_apartment":3,"high_apartment":4,"residential_tower":5,
		"small_warehouse":1,"medium_warehouse":2,"large_warehouse":3,"huge_warehouse":5,
		"fish_lake":4,"fishing_dock":2,"fish_market":2,"fish_processing_plant":3,
		"mineral_market":1,"small_park":1,"playground":1,"grocery_store":1,"bakery":1,"water_tower":1,
		"farm":2,"woodcutter":2,"stone_mine":2,"transport_depot":2,"restaurant":2,"office":2,
		"municipal_bank":2,"municipal_hall":2,"power_station":2,"sawmill":2,"sewage_plant":2,"waste_facility":2,
		"school":3,"clinic":3,"iron_mine":3,"carpenter":3,"sports_center":3,"fire_station":3,"police_station":3,
		"central_bank":4,"factory":4,"hospital":4,"university":5,"shopping_mall":5,"cultural_center":4,"taxi_station":1,"bus_station":2
	}
	return int(sizes.get(str(id), 1))

static func get_land_used(engine):
	var state = engine.state
	var used = 0
	for building in state.get("buildings", []):
		used += engine.get_land_size(str(building.get("id", "")))
	for project in state.get("constructions", []):
		used += engine.get_land_size(str(project.get("id", "")))
	for project in state.get("civic_projects", []):
		used += engine.get_land_size(str(project.get("building_id", "")))
	return used

static func get_land_free(engine):
	var state = engine.state
	return max(0, int(state.get("land_owned", 10)) - engine.get_land_used())

static func get_land_unit_price(engine):
	var state = engine.state
	return 300 + max(0, int(state.get("land_owned", 10)) - 10) * 40

static func buy_land(engine, plots=1):
	var state = engine.state
	var amount = int(plots)
	if amount < 1 or amount > 10:
		return {"ok":false,"message":"هر بار می‌توانی بین ۱ تا ۱۰ قطعه زمین بخری."}
	var owned = int(state.get("land_owned", 10))
	var unit_price = engine.get_land_unit_price()
	var total = unit_price * amount
	if not engine._spend_money(total):
		return {"ok":false,"message":"پول آزاد خزانه برای خرید زمین کافی نیست؛ هزینه هر قطعه %d سکه است." % unit_price}
	state["land_owned"] = owned + amount
	engine.save_game()
	return {"ok":true,"message":"%d قطعه زمین به قیمت %d سکه خریداری شد. زمین آزاد: %d قطعه." % [amount,total,engine.get_land_free()]}

static func build(engine, id):
	var state = engine.state
	if str(id) == "fish_lake":
		return {"ok":false,"message":"دریاچه بخشی از طبیعت شهر است و نیازی به ساخت ندارد؛ برای شروع صید، اسکله صیادی بساز."}
	if not engine.BUILDINGS.has(id):
		return {"ok":false,"message":"این ساختمان تعریف نشده است."}
	if engine.get_active_construction_count() >= engine.MAX_CONCURRENT_CONSTRUCTIONS:
		return {"ok":false,"message":"ظرفیت ساخت‌وساز تکمیل است؛ حداکثر ۲ ساختمان می‌توانند هم‌زمان در حال ساخت باشند. پس از تکمیل یکی از پروژه‌ها دوباره اقدام کن."}
	var data = engine.BUILDINGS[id]
	if int(state.population) < int(data.get("unlock", 0)):
		return {"ok":false,"message":"برای ساخت این ساختمان جمعیت کافی نیست."}
	if int(state.level) < int(data.get("level_unlock", 1)):
		return {"ok":false,"message":"برای ساخت این ساختمان باید به سطح %d برسی." % int(data.get("level_unlock", 1))}
	if id == "central_bank" and int(state.get("central_bank_rebuild_days_left", 0)) > 0:
		return {"ok":false,"message":"برای ساخت دوباره بانک مرکزی باید %d روز صبر کنی." % int(state.central_bank_rebuild_days_left)}
	if id in ["fish_market","fish_processing_plant"] and engine.get_building_count("fishing_dock") <= 0:
		return {"ok":false,"message":"برای راه‌اندازی بازار یا کارخانه فرآوری ماهی، ابتدا اسکله صیادی بساز."}
	# A new neighborhood may only be opened when the road network has
	# reached the matching development level. The first neighborhood is free.
	if not id in engine.OUTSIDE_CITY_BUILDINGS:
		var districts = state.get("districts", [])
		var needs_new_district = districts.is_empty()
		if not districts.is_empty():
			needs_new_district = true
			for district in districts:
				if engine._district_can_accept(district, id):
					needs_new_district = false
					break
		if needs_new_district and not districts.is_empty():
			var required_road_level = min(3, districts.size() + 1)
			var current_road_level = int(state.get("road_level", 1))
			if current_road_level < required_road_level:
				var next_district_number = districts.size() + 1
				return {"ok":false,"message":"🔒 برای ایجاد محله %d، ابتدا شبکه جاده‌ای را به سطح %d از ۳ ارتقا بده. سطح فعلی جاده: %d از ۳. از بخش «توسعه شهر» جاده‌ها را ارتقا بده." % [next_district_number, required_road_level, current_road_level]}
	var required_land = engine.get_land_size(id)
	if engine.get_land_free() < required_land:
		return {"ok":false,"message":"زمین کافی نداری؛ این ساختمان %d قطعه زمین می‌خواهد و فقط %d قطعه آزاد داری. ابتدا زمین بخر." % [required_land,engine.get_land_free()]}
	if not engine._spend_money(int(data.cost)):
		return {"ok":false,"message":"پول آزاد خزانه کافی نیست؛ ممکن است بخشی از پول به‌دلیل ظرفیت خزانه قفل شده باشد."}
	var construction_times = {
		"small_house":60,"normal_house":120,"low_apartment":180,"high_apartment":240,"residential_tower":300,
		"small_warehouse":60,"mineral_market":60,"small_park":60,"playground":60,"taxi_station":60,"bus_station":60,
		"grocery_store":60,"bakery":60,"water_tower":60,
		"farm":120,"fish_lake":180,"fishing_dock":120,"fish_market":120,"fish_processing_plant":240,"woodcutter":120,"stone_mine":120,"transport_depot":120,
		"restaurant":120,"office":120,"municipal_bank":120,"municipal_hall":120,"power_station":120,
		"medium_warehouse":120,"sawmill":120,"sewage_plant":120,"waste_facility":120,
		"school":180,"clinic":180,"iron_mine":180,"carpenter":180,"sports_center":180,
		"large_warehouse":180,"fire_station":180,"police_station":180,
		"central_bank":240,"factory":240,"hospital":240,"university":300,
		"huge_warehouse":300,"shopping_mall":300,"cultural_center":300
	}
	var location = engine._assign_building_location(id)
	var location_label = str(location.get("district_name", "منطقه صنعتی خارج شهر"))
	var earned_xp = engine._building_xp_reward(data)
	var xp_message = engine._award_xp(earned_xp)
	if construction_times.has(id):
		var seconds = int(construction_times[id])
		state.constructions.append({"id":id,"finish_at":Time.get_unix_time_from_system()+seconds,"zone":location.zone,"district_id":location.district_id,"district_name":location.district_name})
		engine.save_game()
		return {"ok":true,"message":data.name+" شروع شد؛ زمان ساخت: %d دقیقه. محل ساخت: %s. هزینه پرداخت شد. +%d تجربه. %s" % [int(ceil(float(seconds)/60.0)),location_label,earned_xp,xp_message]}
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 0
	state.buildings.append({"id":id,"workers":0,"balance":0,"zone":location.zone,"district_id":location.district_id,"district_name":location.district_name})
	var new_index = state.buildings.size() - 1
	if id in ["stone_mine", "iron_mine"]:
		engine._register_mine(new_index, id)
	engine._sync_population()
	var new_citizen_requests = engine._create_house_citizen_requests(id)
	engine.assign_jobs()
	engine._update_missions()
	engine.save_game()
	var resident_message = ""
	if new_citizen_requests > 0:
		if str(state.get("citizen_recruitment_mode", "auto")) == "auto":
			resident_message = " %d شهروند جدید به‌صورت خودکار وارد شهر شدند." % new_citizen_requests
		else:
			resident_message = " %d درخواست مهاجرت ثبت شد؛ از بخش شهروندان بررسی‌شان کن." % new_citizen_requests
	return {"ok":true,"message":data.name+" با موفقیت در %s ساخته شد. +%d تجربه. %s%s" % [location_label,earned_xp,xp_message,resident_message]}

static func process_constructions(engine):
	var state = engine.state
	var now = Time.get_unix_time_from_system()
	var remaining = []
	var completed = []
	var completed_building_ids = []
	for construction in state.get("constructions", []):
		if int(construction.get("finish_at", 0)) > now:
			remaining.append(construction)
			continue
		var id = str(construction.get("id", ""))
		if engine.BUILDINGS.has(id):
			state.buildings.append({"id":id,"workers":0,"balance":0,"zone":str(construction.get("zone","district")),"district_id":str(construction.get("district_id","")),"district_name":str(construction.get("district_name",""))})
			var new_index = state.buildings.size() - 1
			if id in ["stone_mine", "iron_mine"]:
				engine._register_mine(new_index, id)
			if id == "central_bank":
				state.central_bank_rebuild_days_left = 0
			completed.append(str(engine.BUILDINGS[id].name)+" ("+str(construction.get("district_name","منطقه صنعتی خارج شهر"))+")")
			completed_building_ids.append(id)
	state["constructions"] = remaining
	if completed.size() > 0:
		engine._sync_population()
		var new_citizen_requests = 0
		for completed_id in completed_building_ids:
			new_citizen_requests += engine._create_house_citizen_requests(completed_id)
		engine.assign_jobs()
		engine._update_missions()
		state["last_report"] = "ساخت‌وساز تکمیل شد: " + "، ".join(completed)
		if new_citizen_requests > 0:
			if str(state.get("citizen_recruitment_mode", "auto")) == "auto":
				state["last_report"] += " | %d شهروند جدید به‌صورت خودکار وارد شهر شدند." % new_citizen_requests
			else:
				state["last_report"] += " | %d درخواست مهاجرت ثبت شد؛ از بخش شهروندان بررسی‌شان کن." % new_citizen_requests
		engine.save_game()
		return true
	return false

static func get_active_construction_count(engine):
	var state = engine.state
	return state.get("constructions", []).size()

static func get_construction_status(engine):
	var state = engine.state
	var result = []
	var now = Time.get_unix_time_from_system()
	for construction in state.get("constructions", []):
		var id = str(construction.get("id", ""))
		if not engine.BUILDINGS.has(id):
			continue
		result.append({"name":str(engine.BUILDINGS[id].name),"remaining":max(0,int(construction.get("finish_at",0))-now)})
	return result

static func demolish(engine, index):
	var state = engine.state
	if index < 0 or index >= state.buildings.size():
		return {"ok":false,"message":"ساختمان پیدا نشد."}
	if int(state.buildings[index].get("rented_to", 0)) > 0:
		return {"ok":false,"message":"این ملک شهرداری در قرارداد اجاره است و تا پایان قرارداد قابل تخریب نیست."}
	var id = state.buildings[index].id
	if id == "small_house" and engine.get_building_count(id) <= 1:
		return {"ok":false,"message":"آخرین خانه شهر را نمی‌توان تخریب کرد."}
	state.buildings.remove_at(index)
	engine._ensure_building_locations()
	for request_index in range(state.get("business_requests", []).size() - 1, -1, -1):
		var civic_request = state.business_requests[request_index]
		if str(civic_request.get("type", "")) != "rent":
			continue
		var requested_building_index = int(civic_request.get("building_index", -1))
		if requested_building_index == index:
			for citizen_index in range(state.citizens.size()):
				if int(state.citizens[citizen_index].get("id", 0)) == int(civic_request.get("citizen_id", 0)):
					state.citizens[citizen_index]["civic_request_pending"] = false
					state.citizens[citizen_index]["next_civic_request_day"] = int(state.day) + 1
			state.business_requests.remove_at(request_index)
		elif requested_building_index > index:
			civic_request["building_index"] = requested_building_index - 1
			state.business_requests[request_index] = civic_request
	for business_index in range(state.private_businesses.size()):
		var private_business = state.private_businesses[business_index]
		if bool(private_business.get("rented_municipal", false)):
			var rented_index = int(private_business.get("building_index", -1))
			if rented_index > index:
				private_business["building_index"] = rented_index - 1
				state.private_businesses[business_index] = private_business
	for mine_index in range(state.mines.size() - 1, -1, -1):
		if int(state.mines[mine_index].get("building_index", -1)) == index:
			state.mines.remove_at(mine_index)
		elif int(state.mines[mine_index].get("building_index", -1)) > index:
			state.mines[mine_index].building_index -= 1
	if id == "central_bank":
		state.central_bank_rebuild_days_left = 7
		var excess = max(0, int(state.money) - engine.get_treasury_capacity())
		if excess > 0:
			state.last_report = "با تخریب بانک مرکزی، %d سکه تا پایان مهلت بازسازی قفل شد." % excess
	engine._sync_population()
	engine.assign_jobs()
	engine.save_game()
	return {"ok":true,"message":"ساختمان تخریب شد. بازپرداختی انجام نشد."}

static func assign_jobs(engine):
	var state = engine.state
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		citizen["job"] = ""
		citizen["job_building_index"] = -1
		state.citizens[citizen_index] = citizen
	var workplaces = []
	for i in range(state.buildings.size()):
		if int(state.buildings[i].get("rented_to", 0)) > 0:
			continue
		var data = engine.BUILDINGS.get(str(state.buildings[i].get("id", "")), {})
		for slot in range(int(data.get("jobs", 0))):
			workplaces.append(i)
	# Each resident independently chooses the best available role for their
	# interests and abilities. The simulation has no road coordinates, so
	# distance is deliberately not fabricated.
	for citizen_index in range(state.citizens.size()):
		var citizen = state.citizens[citizen_index]
		if int(citizen.get("private_job_id", 0)) > 0 or workplaces.is_empty():
			continue
		var preference = str(citizen.get("career_sector", citizen.get("business_interest", "services")))
		var best_slot = -1
		var best_score = -999999.0
		for slot_index in range(workplaces.size()):
			var building_index = int(workplaces[slot_index])
			var building_id = str(state.buildings[building_index].get("id", ""))
			var data = engine.BUILDINGS.get(building_id, {})
			var sector = "services"
			if building_id in ["farm", "grocery_store", "bakery", "restaurant", "fishing_dock", "fish_market", "fish_processing"]:
				sector = "food"
			elif building_id in ["woodcutter", "sawmill", "carpenter", "factory", "iron_mine", "stone_mine"]:
				sector = "industry"
			var score = float(int(data.get("wage", 30))) * 0.2
			if sector == preference:
				score += 40.0
			else:
				score -= 8.0
			score += float(int(citizen.get("education", 30))) * (0.16 if sector == "services" else 0.04)
			score += float(int(citizen.get("creativity", 30))) * (0.08 if sector == "food" else 0.03)
			score += float(int(citizen.get("initiative", 30))) * 0.03
			# Stable tie-breaker prevents jobs from reshuffling randomly each day.
			score += float((int(citizen.get("id", citizen_index + 1)) + building_index) % 7) * 0.001
			if score > best_score:
				best_score = score
				best_slot = slot_index
		if best_slot < 0:
			continue
		var selected_building = int(workplaces[best_slot])
		citizen["job_building_index"] = selected_building
		citizen["job"] = str(state.buildings[selected_building].get("id", ""))
		state.citizens[citizen_index] = citizen
		workplaces.remove_at(best_slot)

static func _workers_for_building(engine, building_index):
	var state = engine.state
	var count = 0
	for citizen in state.citizens:
		if int(citizen.get("job_building_index", -1)) == building_index:
			count += 1
	return count

static func _has_mine(engine, building_index):
	var state = engine.state
	for mine in state.mines:
		if int(mine.get("building_index", -1)) == building_index:
			return true
	return false

static func _register_mine(engine, building_index, building_id):
	var state = engine.state
	var is_iron = building_id == "iron_mine"
	state.mines.append({
		"building_index": building_index,
		"resource": ("iron_ore" if is_iron else "stone"),
		"active": true,
		"remaining": (150 if is_iron else -1),
		"initial_reserve": (150 if is_iron else -1),
		"extracted": 0
	})

static func get_mines(engine):
	var state = engine.state
	return state.get("mines", [])

static func refill_iron_mine(engine, mine_index):
	var state = engine.state
	if mine_index < 0 or mine_index >= state.mines.size():
		return {"ok":false,"message":"معدن پیدا نشد."}
	var mine = state.mines[mine_index]
	if str(mine.get("resource", "")) != "iron_ore":
		return {"ok":false,"message":"این معدن نیاز به شارژ سنگ‌آهن ندارد."}
	if int(mine.get("remaining", 0)) > 0:
		return {"ok":false,"message":"ذخیره سنگ‌آهن معدن هنوز تمام نشده است."}
	if not engine._spend_money(1000):
		return {"ok":false,"message":"برای شارژ معدن به ۱۰۰۰ سکه پول آزاد نیاز داری."}
	mine.remaining = int(mine.get("initial_reserve", 150))
	mine.active = int(mine.remaining) > 0
	state.mines[mine_index] = mine
	engine.save_game()
	return {"ok":true,"message":"ذخیره معدن آهن دوباره شارژ شد."}

static func _advance_mines(engine, report):
	var state = engine.state
	for i in range(state.mines.size()):
		var mine = state.mines[i]
		var building_index = int(mine.get("building_index", -1))
		if building_index < 0 or building_index >= state.buildings.size() or engine._workers_for_building(building_index) <= 0:
			continue
		if not bool(mine.get("active", false)):
			continue
		var resource_id = str(mine.get("resource", ""))
		var required_workers = max(1, int(engine.BUILDINGS.get(str(state.buildings[building_index].get("id", "")), {}).get("jobs", 1)))
		var actual_workers = engine._workers_for_building(building_index)
		var base_production = (5 if resource_id == "stone" else 3)
		var production = max(1, int(floor(float(base_production) * float(actual_workers) / float(required_workers))))
		production = min(production, engine.get_free_storage())
		if resource_id == "iron_ore":
			production = min(production, int(mine.get("remaining", 0)))
		if production <= 0:
			# A full warehouse pauses extraction without disabling the mine.
			# Production resumes automatically as soon as storage is freed.
			if engine.get_free_storage() <= 0:
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
		report.append("معدن %s واحد %s استخراج کرد." % [production, engine.RESOURCES[resource_id].name])
		state.mines[i] = mine

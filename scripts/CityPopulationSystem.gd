extends RefCounted

# Citizen recruitment, housing, district placement, and neighborhood capacity.

static func _sync_population(engine):
	var state = engine.state
	var capacity = 0
	for building in state.buildings:
		var definition = engine.BUILDINGS.get(building.id, {})
		capacity += int(definition.get("capacity", 0))
	state.population = min(max(0, int(state.population)), capacity)
	while state.citizens.size() > state.population:
		state.citizens.pop_back()
	while state.citizens.size() < state.population:
		state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})

static func _next_citizen_request_id(engine):
	var state = engine.state
	var highest = 0
	for request in state.get("citizen_requests", []):
		highest = max(highest, int(request.get("id", 0)))
	return highest + 1

static func _create_house_citizen_requests(engine, building_id):
	var state = engine.state
	var definition = engine.BUILDINGS.get(str(building_id), {})
	var new_capacity = int(definition.get("capacity", 0))
	if new_capacity <= 0:
		return 0
	var free_slots = max(0, engine.get_housing_capacity() - int(state.get("population", 0)) - state.get("citizen_requests", []).size())
	var arrival_count = min(new_capacity, free_slots)
	if arrival_count <= 0:
		return 0
	if str(state.get("citizen_recruitment_mode", "auto")) == "auto":
		if int(state.get("reputation", 0)) < 25:
			return 0
		for arrival_number in range(arrival_count):
			state.population += 1
			state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
		engine.assign_jobs()
		return arrival_count
	for request_number in range(arrival_count):
		var request_id = engine._next_citizen_request_id()
		state.citizen_requests.append({
			"id": request_id,
			"day": int(state.get("day", 1)),
			"source": "new_house",
			"building_id": str(building_id),
			"building_name": str(definition.get("name", "خانه"))
		})
	return arrival_count

static func _accept_pending_citizen_requests_automatically(engine):
	var state = engine.state
	if int(state.get("reputation", 0)) < 25:
		return 0
	var requests = state.get("citizen_requests", [])
	var free_slots = max(0, engine.get_housing_capacity() - int(state.get("population", 0)))
	var arrivals = min(requests.size(), free_slots)
	if arrivals <= 0:
		return 0
	for arrival_number in range(arrivals):
		state.population += 1
		state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
	state["citizen_requests"] = requests.slice(arrivals)
	engine.assign_jobs()
	return arrivals

static func set_citizen_recruitment_mode(engine, mode):
	var state = engine.state
	if str(mode) != "auto" and str(mode) != "manual":
		return {"ok":false,"message":"حالت جذب نامعتبر است."}
	state["citizen_recruitment_mode"] = str(mode)
	var arrivals = 0
	if str(mode) == "auto":
		arrivals = engine._accept_pending_citizen_requests_automatically()
	engine.save_game()
	var message = "حالت جذب شهروندان: "+("خودکار" if str(mode) == "auto" else "دستی")
	if arrivals > 0:
		message += "؛ %d متقاضی به‌صورت خودکار پذیرفته شد." % arrivals
	return {"ok":true,"message":message}

static func accept_citizen_request(engine, request_index):
	var state = engine.state
	if request_index < 0 or request_index >= state.citizen_requests.size():
		return {"ok":false,"message":"درخواست پیدا نشد."}
	if int(state.population) >= engine.get_housing_capacity():
		return {"ok":false,"message":"ظرفیت خانه‌ها پر است؛ ابتدا خانه بیشتری بساز."}
	var request = state.citizen_requests[request_index]
	state.citizen_requests.remove_at(request_index)
	state.population += 1
	state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
	engine.assign_jobs()
	engine.save_game()
	return {"ok":true,"message":"متقاضی شماره %d پذیرفته شد و به شهر اضافه شد." % int(request.get("id",0))}

static func reject_citizen_request(engine, request_index):
	var state = engine.state
	if request_index < 0 or request_index >= state.citizen_requests.size():
		return {"ok":false,"message":"درخواست پیدا نشد."}
	var request = state.citizen_requests[request_index]
	state.citizen_requests.remove_at(request_index)
	engine.save_game()
	return {"ok":true,"message":"درخواست متقاضی شماره %d رد شد." % int(request.get("id",0))}

static func _process_citizen_recruitment(engine, report):
	var state = engine.state
	if str(state.get("citizen_recruitment_mode", "auto")) == "auto":
		var accepted_pending = engine._accept_pending_citizen_requests_automatically()
		if accepted_pending > 0:
			report.append("%d متقاضی قبلی به‌صورت خودکار پذیرفته شدند." % accepted_pending)
	var housing = engine.get_housing_capacity()
	var pending_requests = state.citizen_requests.size()
	var available_slots = max(0, housing - int(state.population) - pending_requests)
	# A city receives 5 to 10 potential residents per game day, limited by free housing.
	if available_slots <= 0 or int(state.reputation) < 25:
		return
	var daily_target = 5 + int(randi() % 6)
	var arrivals = min(daily_target, available_slots)
	if str(state.get("citizen_recruitment_mode", "auto")) == "manual":
		for request_number in range(arrivals):
			var request_id = engine._next_citizen_request_id()
			state.citizen_requests.append({"id":request_id,"day":int(state.day)})
		report.append("%d درخواست جذب شهروند ثبت شد؛ از بخش شهروندان بررسی‌شان کن." % arrivals)
		return
	for arrival_number in range(arrivals):
		state.population += 1
		state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
	report.append("%d شهروند جدید به‌صورت خودکار به شهر مهاجرت کردند." % arrivals)
	engine.assign_jobs()

static func process_citizen_recruitment_interval(engine, delta):
	var state = engine.state
	if delta <= 0.0:
		return 0
	var timer = float(state.get("citizen_recruitment_timer", 0.0)) + float(delta)
	var completed_intervals = int(floor(timer / 60.0))
	state["citizen_recruitment_timer"] = fmod(timer, 60.0)
	if completed_intervals <= 0:
		return 0
	var total_added = 0
	var changed = false
	for interval_index in range(completed_intervals):
		if int(state.get("reputation", 0)) < 25:
			continue
		var satisfaction = int(state.get("satisfaction", 50))
		# A welcoming city attracts more applicants; poor living conditions slow migration.
		var growth_limit = 3 if satisfaction >= 70 else (2 if satisfaction >= 45 else (1 if satisfaction >= 30 else 0))
		if growth_limit <= 0:
			continue
		var pending = state.get("citizen_requests", [])
		var free_slots = max(0, engine.get_housing_capacity() - int(state.get("population", 0)) - pending.size())
		var batch_size = min(growth_limit, free_slots)
		if batch_size <= 0:
			continue
		if str(state.get("citizen_recruitment_mode", "auto")) == "manual":
			for request_number in range(batch_size):
				state.citizen_requests.append({
					"id": engine._next_citizen_request_id(),
					"day": int(state.get("day", 1)),
					"source": "periodic_recruitment"
				})
		else:
			for arrival_number in range(batch_size):
				state.population += 1
				state.citizens.append({"id":engine._next_citizen_id(),"job":"","job_building_index":-1,"wallet":100})
			total_added += batch_size
			changed = true
			continue
		total_added += batch_size
		changed = true
	if changed:
		if str(state.get("citizen_recruitment_mode", "auto")) == "auto":
			engine.assign_jobs()
		engine.save_game()
	return total_added

static func _next_citizen_id(engine):
	var state = engine.state
	var highest = 0
	for citizen in state.citizens:
		highest = max(highest, int(citizen.get("id", 0)))
	return highest + 1

static func get_housing_capacity(engine):
	var state = engine.state
	var total = 0
	for building in state.buildings:
		total += int(engine.BUILDINGS.get(building.id, {}).get("capacity", 0))
	return total

static func _district_letter(engine, index):
	var state = engine.state
	var value = int(index) + 1
	var result = ""
	while value > 0:
		var remainder = (value - 1) % 26
		result = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substr(remainder, 1) + result
		value = int((value - 1) / 26)
	return result

static func _find_district_index(engine, district_id):
	var state = engine.state
	for i in range(state.get("districts", []).size()):
		if str(state.districts[i].get("id", "")) == str(district_id):
			return i
	return -1

static func _is_house_building(engine, building_id):
	var state = engine.state
	return int(engine.BUILDINGS.get(str(building_id), {}).get("capacity", 0)) > 0

static func _district_can_accept(engine, district, building_id):
	var state = engine.state
	var id = str(building_id)
	var is_house = engine._is_house_building(id)
	var house_count = int(district.get("house_count", 0))
	var other_count = int(district.get("other_count", 0))
	var emergency_count = int(district.get("emergency_count", 0))
	var type_counts = district.get("building_type_counts", {})
	if is_house:
		return house_count < engine.DISTRICT_HOUSE_LIMIT
	var type_count = int(type_counts.get(id, 0))
	if type_count >= engine.DISTRICT_BUILDING_TYPE_LIMIT:
		return false
	if id in engine.DISTRICT_EMERGENCY_BUILDINGS:
		return emergency_count < engine.DISTRICT_EMERGENCY_LIMIT
	return other_count < engine.DISTRICT_OTHER_LIMIT

static func _assign_building_location(engine, building_id):
	var state = engine.state
	var id = str(building_id)
	if id in engine.OUTSIDE_CITY_BUILDINGS:
		return {"zone":"industrial","district_id":"","district_name":"منطقه صنعتی خارج شهر"}
	if typeof(state.get("districts", null)) != TYPE_ARRAY:
		state["districts"] = []
	var chosen_index = -1
	for i in range(state.districts.size()):
		if engine._district_can_accept(state.districts[i], id):
			chosen_index = i
			break
	if chosen_index < 0:
		var district_number = state.districts.size()
		var district_id = engine._district_letter(int(district_number / 50)) + str((district_number % 50) + 1)
		state.districts.append({"id":district_id,"name":"محله "+district_id,"building_count":0,"house_count":0,"other_count":0,"emergency_count":0,"building_type_counts":{}})
		chosen_index = state.districts.size() - 1
	var district = state.districts[chosen_index]
	if engine._is_house_building(id):
		district["house_count"] = int(district.get("house_count", 0)) + 1
	elif id in engine.DISTRICT_EMERGENCY_BUILDINGS:
		district["emergency_count"] = int(district.get("emergency_count", 0)) + 1
	else:
		district["other_count"] = int(district.get("other_count", 0)) + 1
	if not engine._is_house_building(id):
		var type_counts = district.get("building_type_counts", {})
		type_counts[id] = int(type_counts.get(id, 0)) + 1
		district["building_type_counts"] = type_counts
	district["building_count"] = int(district.get("house_count", 0)) + int(district.get("other_count", 0)) + int(district.get("emergency_count", 0))
	state.districts[chosen_index] = district
	return {"zone":"district","district_id":str(district.id),"district_name":str(district.name)}

static func _ensure_building_locations(engine):
	var state = engine.state
	# Rebuild neighborhood assignments from actual saved buildings so older
	# saves also adopt the new 20-house / 20-other-building rules.
	state["districts"] = []
	for collection_name in ["buildings", "constructions", "private_businesses"]:
		var collection = state.get(collection_name, [])
		for i in range(collection.size()):
			var item = collection[i]
			if collection_name == "private_businesses" and bool(item.get("rented_municipal", false)):
				continue
			# Private business records use a numeric business id in `id`; their building type lives in `building_id`.
			var building_id = str(item.get("building_id", item.get("id", "")))
			var location = engine._assign_building_location(building_id)
			for key in location.keys():
				item[key] = location[key]
			collection[i] = item
		state[collection_name] = collection

static func get_districts_overview(engine):
	var state = engine.state
	engine._ensure_building_locations()
	var result = []
	for district in state.get("districts", []):
		var names = []
		for building in state.get("buildings", []):
			if str(building.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(engine.BUILDINGS.get(str(building.get("id", "")), {}).get("name", "ساختمان")))
		for construction in state.get("constructions", []):
			if str(construction.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(engine.BUILDINGS.get(str(construction.get("id", "")), {}).get("name", "پروژه در حال ساخت"))+" (در حال ساخت)")
		for business in state.get("private_businesses", []):
			if bool(business.get("rented_municipal", false)):
				continue
			if str(business.get("district_id", "")) == str(district.get("id", "")):
				names.append(str(business.get("name", engine.BUILDINGS.get(str(business.get("building_id", "")), {}).get("name", "کسب‌وکار"))))
		var row = district.duplicate(true)
		row["building_names"] = names
		row["building_count"] = names.size()
		result.append(row)
	var industrial_names = []
	for building in state.get("buildings", []):
		if str(building.get("zone", "")) == "industrial":
			industrial_names.append(str(engine.BUILDINGS.get(str(building.get("id", "")), {}).get("name", "ساختمان")))
	for construction in state.get("constructions", []):
		if str(construction.get("zone", "")) == "industrial":
			industrial_names.append(str(engine.BUILDINGS.get(str(construction.get("id", "")), {}).get("name", "ساختمان"))+" (در حال ساخت)")
	for business in state.get("private_businesses", []):
		if bool(business.get("rented_municipal", false)):
			continue
		if str(business.get("zone", "")) == "industrial":
			industrial_names.append(str(business.get("name", "کسب‌وکار خصوصی")))
	return {"districts":result,"industrial_buildings":industrial_names,"district_count":result.size()}

static func get_district_capacity_summary(engine, district_id):
	var state = engine.state
	engine._ensure_building_locations()
	for district in state.get("districts", []):
		if str(district.get("id", "")) == str(district_id):
			return {
				"house_count": int(district.get("house_count", 0)),
				"other_count": int(district.get("other_count", 0)),
				"emergency_count": int(district.get("emergency_count", 0)),
				"building_type_counts": district.get("building_type_counts", {}).duplicate(true)
			}
	return {"house_count":0,"other_count":0,"emergency_count":0,"building_type_counts":{}}

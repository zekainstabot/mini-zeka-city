extends RefCounted

# District population allocation and city service coverage/recovery.

static func _get_service_radius(engine, building_id):
	var state = engine.state
	var radii = {
		"hospital":2,"university":2,"school":2,"power_station":2,
		"sports_center":2,"cultural_center":2
	}
	return int(radii.get(str(building_id), 1))

static func _get_district_population(engine):
	var state = engine.state
	var populations = {}
	for district in state.get("districts", []):
		populations[str(district.get("id", ""))] = 0
	var remaining = min(max(0, int(state.get("population", 0))), state.get("citizens", []).size())
	for building in state.get("buildings", []):
		var building_id = str(building.get("id", ""))
		var housing_capacity = int(engine.BUILDINGS.get(building_id, {}).get("capacity", 0))
		if housing_capacity <= 0 or remaining <= 0:
			continue
		var district_id = str(building.get("district_id", ""))
		if district_id == "":
			continue
		var residents = min(remaining, housing_capacity)
		populations[district_id] = int(populations.get(district_id, 0)) + residents
		remaining -= residents
	if remaining > 0 and not state.get("districts", []).is_empty():
		var fallback_id = str(state.districts[0].get("id", ""))
		populations[fallback_id] = int(populations.get(fallback_id, 0)) + remaining
	return populations

static func _calculate_district_service_coverage(engine, need_id, cached_population=null):
	var state = engine.state
	var district_population = cached_population if typeof(cached_population) == TYPE_DICTIONARY else engine._get_district_population()
	var served = {}
	var coverage = {}
	var total_population = 0
	for district in state.get("districts", []):
		var district_id = str(district.get("id", ""))
		served[district_id] = 0
		total_population += int(district_population.get(district_id, 0))
	var providers = []
	for building_index in range(state.get("buildings", []).size()):
		var building = state.buildings[building_index]
		if int(building.get("rented_to", 0)) > 0:
			continue
		var building_id = str(building.get("id", ""))
		var data = engine.BUILDINGS.get(building_id, {})
		if str(data.get("service_need", "")) != str(need_id):
			continue
		var required_workers = int(data.get("jobs", 0))
		var workers = engine._workers_for_building(building_index)
		if required_workers > 0 and workers <= 0:
			continue
		var capacity = int(data.get("service_capacity", 0))
		var origin_index = engine._find_district_index(str(building.get("district_id", "")))
		var radius = engine._get_service_radius(building_id)
		var global_service = false
		# Infrastructure outside the city serves all districts proportionally.
		if origin_index < 0 and str(building.get("zone", "")) == "industrial" and not state.get("districts", []).is_empty():
			origin_index = 0
			radius = state.districts.size() - 1
			global_service = true
		if capacity > 0 and origin_index >= 0:
			providers.append({"origin":origin_index,"capacity":capacity,"radius":radius,"global":global_service})
	for business in state.get("private_businesses", []):
		if bool(business.get("rented_municipal", false)):
			continue
		var building_id = str(business.get("building_id", ""))
		var data = engine.BUILDINGS.get(building_id, {})
		if str(data.get("service_need", "")) != str(need_id):
			continue
		var required_workers = max(1, int(data.get("jobs", 1)))
		var workers = business.get("employees", []).size()
		var capacity = int(round(float(data.get("service_capacity", 0)) * min(1.0, float(workers) / float(required_workers))))
		var origin_index = engine._find_district_index(str(business.get("district_id", "")))
		if capacity > 0 and origin_index >= 0:
			providers.append({"origin":origin_index,"capacity":capacity,"radius":engine._get_service_radius(building_id)})
	for provider in providers:
		var remaining_capacity = int(provider.capacity)
		if bool(provider.get("global", false)):
			var total_unserved = 0
			for district_id in served.keys():
				total_unserved += max(0, int(district_population.get(district_id, 0)) - int(served.get(district_id, 0)))
			if total_unserved > 0:
				for district in state.get("districts", []):
					var district_id = str(district.get("id", ""))
					var demand = max(0, int(district_population.get(district_id, 0)) - int(served.get(district_id, 0)))
					var share = min(demand, int(floor(float(provider.capacity) * float(demand) / float(total_unserved))))
					served[district_id] = int(served.get(district_id, 0)) + share
					remaining_capacity -= share
				while remaining_capacity > 0:
					var allocated_any = false
					for district in state.get("districts", []):
						if remaining_capacity <= 0:
							break
						var district_id = str(district.get("id", ""))
						if int(served.get(district_id, 0)) >= int(district_population.get(district_id, 0)):
							continue
						served[district_id] = int(served.get(district_id, 0)) + 1
						remaining_capacity -= 1
						allocated_any = true
					if not allocated_any:
						break
			continue
		var origin = int(provider.origin)
		var radius = int(provider.radius)
		for distance in range(radius + 1):
			var candidate_indices = []
			if distance == 0:
				candidate_indices.append(origin)
			else:
				candidate_indices.append(origin - distance)
				candidate_indices.append(origin + distance)
			for district_index in candidate_indices:
				if remaining_capacity <= 0:
					break
				if district_index < 0 or district_index >= state.districts.size():
					continue
				var district_id = str(state.districts[district_index].get("id", ""))
				var district_need = int(district_population.get(district_id, 0))
				var available_need = max(0, district_need - int(served.get(district_id, 0)))
				if available_need <= 0:
					continue
				var allocated = min(remaining_capacity, available_need)
				served[district_id] = int(served.get(district_id, 0)) + allocated
				remaining_capacity -= allocated
	for district in state.get("districts", []):
		var district_id = str(district.get("id", ""))
		var residents = int(district_population.get(district_id, 0))
		coverage[district_id] = int(round(float(served.get(district_id, 0)) * 100.0 / float(max(1, residents)))) if residents > 0 else 100
	var total_served = 0
	for district_id in served.keys():
		total_served += int(served[district_id])
	return {"served":served,"population":district_population,"coverage":coverage,"total_served":total_served,"total_population":total_population}

static func _get_service_capacity(engine, need_id):
	var state = engine.state
	return int(engine._calculate_district_service_coverage(str(need_id)).get("total_served", 0))

static func _update_city_services(engine, report):
	var state = engine.state
	engine._ensure_building_locations()
	var population = max(1, int(state.population))
	var service_state = {}
	var district_status = {}
	var district_population = engine._get_district_population()
	var needs = state.get("needs", {})
	var need_ids = ["food","water","power","health","education","safety","leisure","sanitation"]
	var daily_decay = {"food":8,"water":10,"power":4,"health":3,"education":2,"safety":2,"leisure":4,"sanitation":3}
	var total_need = 0
	for district in state.get("districts", []):
		var district_id = str(district.get("id", ""))
		district_status[district_id] = {"population":int(district_population.get(district_id, 0)),"services":{}}
	for need_id in need_ids:
		var service_data = engine._calculate_district_service_coverage(need_id, district_population)
		var served = service_data.get("served", {})
		var total_served = int(service_data.get("total_served", 0))
		if need_id == "food":
			var food_limit = int(floor(float(state.resources.get("food",0)) * 100.0 / float(population)))
			if total_served > food_limit and total_served > 0:
				var food_factor = float(food_limit) / float(total_served)
				total_served = 0
				for district in state.get("districts", []):
					var district_id = str(district.get("id", ""))
					var district_served = int(floor(float(served.get(district_id, 0)) * food_factor))
					served[district_id] = district_served
					total_served += district_served
		var coverage = int(clamp(round(float(total_served) * 100.0 / float(population)), 0, 100))
		service_state[need_id] = coverage
		for district in state.get("districts", []):
			var district_id = str(district.get("id", ""))
			var residents = int(district_population.get(district_id, 0))
			var district_served = int(served.get(district_id, 0))
			var district_coverage = int(round(float(district_served) * 100.0 / float(max(1, residents)))) if residents > 0 else 100
			district_status[district_id]["services"][need_id] = {"served":district_served,"capacity":residents,"coverage":district_coverage}
		var current = int(needs.get(need_id, 60))
		var decay = int(daily_decay.get(need_id, 2))
		var recovery = int(round(float(coverage) * 0.12))
		needs[need_id] = int(clamp(current - decay + recovery, 0, 100))
	# A staffed police station provides a modest night-patrol safety benefit.
	var night_patrol_active = false
	for building_index in range(state.buildings.size()):
		if str(state.buildings[building_index].get("id", "")) == "police_station" and engine._workers_for_building(building_index) > 0:
			night_patrol_active = true
			break
	if night_patrol_active:
		needs["safety"] = int(min(100, int(needs.get("safety", 0)) + 2))
		report.append("گشت شبانه کلانتری فعال بود؛ امنیت شهر ۲ واحد بهبود یافت.")
	total_need = 0
	for need_id in need_ids:
		total_need += int(needs.get(need_id, 0))
	state.needs = needs
	state.services = service_state
	state["district_service_coverage"] = district_status
	var average = int(round(float(total_need) / float(need_ids.size())))
	state.satisfaction = average
	if average < 30:
		state.reputation = max(0, int(state.reputation) - 2)
	elif average < 45:
		state.reputation = max(0, int(state.reputation) - 1)
	elif average >= 80:
		state.reputation = min(100, int(state.reputation) + 1)
	var names = {"food":"خوراک","water":"آب","power":"برق","health":"سلامت","education":"آموزش","safety":"امنیت","leisure":"تفریح","sanitation":"بهداشت"}
	var summaries = []
	var citizen_problems = []
	var recommendations = {"food":"ذخیره مواد غذایی و ظرفیت فروشگاه‌های خوراک را افزایش بده","water":"برج آب و ظرفیت آبرسانی را بررسی کن","power":"ظرفیت نیروگاه و تأمین برق را افزایش بده","health":"درمانگاه یا بیمارستان و نیروی درمانی را تقویت کن","education":"مدرسه و پوشش آموزشی شهر را توسعه بده","safety":"کلانتری و پوشش امنیت محله‌ها را بررسی کن","leisure":"پارک و مراکز تفریحی بیشتری بساز","sanitation":"خدمات پسماند و بهداشت محیط را تقویت کن"}
	for need_id in need_ids:
		var need_value = int(needs.get(need_id, 0))
		summaries.append("%s %d%%" % [names[need_id], need_value])
		if need_value < 55:
			var urgency = "بحرانی" if need_value < 30 else "ضعیف" if need_value < 45 else "نیازمند رسیدگی"
			citizen_problems.append("%s: %s (%d%%)؛ پیشنهاد: %s" % [urgency, names[need_id], need_value, recommendations[need_id]])
	report.append("نیاز شهروندان: " + " | ".join(summaries))
	if not citizen_problems.is_empty():
		report.append("📨 گزارش شورای شهروندان: مردم از این مشکلات خبر داده‌اند: " + "؛ ".join(citizen_problems) + ".")
	else:
		report.append("📨 گزارش شورای شهروندان: نیازهای اصلی شهر در وضعیت قابل‌قبول است؛ شکایت فوری ثبت نشده است.")
	report.append("رضایت میانگین: %d از ۱۰۰" % average)

extends RefCounted

# Storage capacity, stock rules, and automated market/factory balancing.

static func get_storage_rule(engine, resource_id):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)):
		return {}
	if typeof(state.get("storage_rules", null)) != TYPE_DICTIONARY:
		state["storage_rules"] = {}
	if not state.storage_rules.has(str(resource_id)):
		state.storage_rules[str(resource_id)] = {"minimum":10,"maximum":40,"low_action":"market","high_action":"market"}
	return state.storage_rules[str(resource_id)]

static func set_storage_rule(engine, resource_id, field, value):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)) or not str(field) in ["minimum","maximum"]:
		return {"ok":false,"message":"تنظیم انبار نامعتبر است."}
	var rule = engine.get_storage_rule(str(resource_id))
	var amount = max(0,int(value))
	if str(field) == "minimum":
		rule.minimum = min(amount,max(0,int(rule.maximum)-5))
	else:
		rule.maximum = max(amount,int(rule.minimum)+5)
	state.storage_rules[str(resource_id)] = rule
	engine.save_game()
	return {"ok":true,"message":"حد موجودی "+engine.RESOURCES[str(resource_id)].name+" ذخیره شد."}

static func toggle_storage_action(engine, resource_id, level):
	var state = engine.state
	var rule = engine.get_storage_rule(str(resource_id))
	if str(level) == "low":
		rule.low_action = "factory" if str(rule.get("low_action","market")) == "market" else "market"
	else:
		rule.high_action = "shop" if str(rule.get("high_action","market")) == "market" else "market"
	state.storage_rules[str(resource_id)] = rule
	engine.save_game()
	return {"ok":true,"message":"روش مدیریت موجودی "+engine.RESOURCES[str(resource_id)].name+" تغییر کرد."}

static func apply_storage_rule(engine, resource_id, manual=false):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)):
		return {"ok":false,"message":"ماده پیدا نشد."}
	var id = str(resource_id)
	var rule = engine.get_storage_rule(id)
	var current = int(state.resources.get(id,0))
	var minimum = int(rule.get("minimum",10))
	var maximum = int(rule.get("maximum",40))
	if current < minimum:
		if str(rule.get("low_action","market")) == "market":
			var amount = min(minimum-current,min(int(state.market_stock.get(id,0)),engine.get_free_storage()))
			var price = engine.get_market_price(id,"buy")
			amount = min(amount,int(floor(float(engine.get_available_money())/float(max(1,price)))))
			if amount > 0:
				engine._spend_money(amount*price)
				state.market_stock[id] = int(state.market_stock.get(id,0))-amount
				state.resources[id] = current+amount
				return {"ok":true,"message":"برای انبار %d واحد %s از بازار خریداری شد." % [amount,engine.RESOURCES[id].name]}
			return {"ok":false,"message":"برای تأمین "+engine.RESOURCES[id].name+" موجودی بازار، فضای انبار یا پول کافی نیست."}
		return {"ok":true,"message":"تولید "+engine.RESOURCES[id].name+" در کارخانه‌ها در اولویت قرار گرفت؛ تولید اضافه فقط با مواد اولیه و نیروی کار ممکن است."}
	if current > maximum:
		var surplus = current-maximum
		if str(rule.get("high_action","market")) == "shop":
			if id != "food" or engine.get_building_count("grocery_store") <= 0:
				return {"ok":false,"message":"برای فروش این ماده از فروشگاه، فروشگاه مواد غذایی لازم است؛ فعلاً از بازار استفاده کن."}
			# Keep surplus food for the normal citizen-purchase process at staffed grocery stores.
			return {"ok":true,"message":"مازاد خوراک در انبار ماند تا فروشگاه‌ها آن را به شهروندان بفروشند."}
		# Market route uses the same stock and treasury limits as manual market sales.
		var sell_mode = "sell"
		var unit_sell_price = max(1, engine.get_market_price(id, sell_mode))
		var market_room = max(0, 100 - int(state.market_stock.get(id, 0)))
		var treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
		var sold = min(surplus, min(market_room, int(floor(float(treasury_room) / float(unit_sell_price)))))
		if sold > 0:
			var revenue = sold*engine.get_market_price(id,"sell")
			state.resources[id] = current-sold
			state.market_stock[id] = int(state.market_stock.get(id,0))+sold
			engine._add_money(revenue)
			return {"ok":true,"message":"%d واحد %s به فروش رسید و %d سکه درآمد ایجاد کرد." % [sold,engine.RESOURCES[id].name,revenue]}
		return {"ok":false,"message":"بازار یا خزانه ظرفیت فروش "+engine.RESOURCES[id].name+" را ندارد."}
	return {"ok":true,"message":"موجودی "+engine.RESOURCES[id].name+" در محدوده تنظیم‌شده است."}

static func get_storage_capacity(engine, ):
	var state = engine.state
	var total = 0
	for building in state.buildings:
		total += int(engine.BUILDINGS.get(building.id, {}).get("storage", 0))
	return total

static func get_storage_used(engine, ):
	var state = engine.state
	var total = 0
	for value in state.resources.values():
		total += int(value)
	return total

static func get_free_storage(engine, ):
	var state = engine.state
	return max(0, engine.get_storage_capacity() - engine.get_storage_used())

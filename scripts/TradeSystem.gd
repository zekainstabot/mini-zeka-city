extends RefCounted

# Intercity trade, imports, contracts, shipments, and domestic market operations.

# Shared settlement for every trade channel: domestic market, imports and exports.
# Callers validate route-specific limits first; this function applies the common
# money and inventory changes; the caller persists after route-specific state is updated.
static func _settle_trade(engine, resource_id, amount, money_delta, inventory_delta=0, market_delta=0):
	var state = engine.state
	if not engine.RESOURCES.has(resource_id) or int(amount) <= 0:
		return {"ok":false,"message":"تسویه معامله نامعتبر است."}
	var money_change = int(money_delta)
	var next_inventory = int(state.resources.get(resource_id, 0)) + int(inventory_delta)
	var next_market = int(state.market_stock.get(resource_id, 0)) + int(market_delta)
	if next_inventory < 0 or next_market < 0 or next_market > 100:
		return {"ok":false,"message":"موجودی کالا برای تسویه معامله کافی نیست."}
	if money_change < 0:
		if not engine._spend_money(-money_change):
			return {"ok":false,"message":"پول آزاد کافی نیست."}
	elif money_change > 0:
		var accepted = engine._add_money(money_change)
		if accepted < money_change:
			return {"ok":false,"message":"ظرفیت خزانه برای دریافت درآمد کافی نیست."}
	state.resources[resource_id] = next_inventory
	state.market_stock[resource_id] = next_market
	return {"ok":true}


static func get_import_price(engine, city_id, resource_id):
	var state = engine.state
	if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id):
		return 0
	var city = engine.TRADE_CITIES[city_id]
	var stock = int(state.get("city_export_stock", {}).get(city_id, city.supply).get(resource_id, 0))
	if stock <= 0:
		return 0
	var base = int(engine.RESOURCES[resource_id].buy)
	var scarcity = 1.0 + max(0.0, 1.0 - float(stock) / max(1.0, float(city.supply.get(resource_id, 1)))) * 0.35
	return max(1, int(round(float(base) * float(city.price_factor) * scarcity)))

static func get_import_cities(engine):
	var state = engine.state
	return engine.TRADE_CITIES

static func get_import_price_label(engine, city_id, resource_id):
	var state = engine.state
	var price = engine.get_import_price(city_id, resource_id)
	if price <= 0:
		return "ناموجود"
	return str(price)+" سکه/واحد"

static func order_import(engine, city_id, resource_id, requested_amount):
	var state = engine.state
	if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id) or requested_amount <= 0:
		return {"ok":false,"message":"سفارش واردات نامعتبر است."}
	var city = engine.TRADE_CITIES[city_id]
	var city_stock = state.city_export_stock.get(city_id, city.supply)
	var available = int(city_stock.get(resource_id, 0))
	var amount = min(min(int(requested_amount), available), engine.get_transport_capacity_remaining())
	if amount <= 0:
		return {"ok":false,"message":"کالا یا ظرفیت کامیون‌های آزاد برای واردات کافی نیست؛ پایانه حمل‌ونقل و نیروی کار آن را بررسی کن."}
	if engine.get_free_storage() < amount:
		return {"ok":false,"message":"برای محموله فضای کافی در انبار نداری."}
	var unit_price = engine.get_import_price(city_id, resource_id)
	var shipping_fee = max(1, int(ceil(float(amount * unit_price) * 0.10)))
	var total_cost = amount * unit_price + shipping_fee
	if engine.get_available_money() < total_cost:
		return {"ok":false,"message":"پول آزاد خزانه برای خرید و کرایه حمل کافی نیست."}
	var shipment = {"id":engine._next_shipment_id(),"city_id":city_id,"resource_id":resource_id,"amount":amount,"arrival_day":int(state.day)+int(city.travel_days),"paid":total_cost}
	city_stock[resource_id] = available - amount
	state.city_export_stock[city_id] = city_stock
	state.trade_shipments.append(shipment)
	var settlement = _settle_trade(engine, resource_id, amount, -total_cost)
	if not settlement.ok:
		state.trade_shipments.pop_back()
		city_stock[resource_id] = available
		state.city_export_stock[city_id] = city_stock
		return settlement
	state.transport_used_today = int(state.get("transport_used_today",0)) + amount
	state.last_import_report = "%d واحد %s از %s سفارش داده شد؛ تحویل روز %d؛ هزینه با حمل: %d سکه." % [amount,engine.RESOURCES[resource_id].name,city.name,int(shipment.arrival_day),total_cost]
	engine.save_game()
	return {"ok":true,"message":state.last_import_report}

static func _next_shipment_id(engine):
	var state = engine.state
	var highest = 0
	for shipment in state.trade_shipments:
		highest = max(highest, int(shipment.get("id",0)))
	return highest + 1

static func create_import_contract(engine, city_id, resource_id, daily_amount, duration_days):
	var state = engine.state
	if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id):
		return {"ok":false,"message":"شهر یا کالای قرارداد معتبر نیست."}
	if engine.get_transport_truck_count() <= 0:
		return {"ok":false,"message":"برای قرارداد واردات ابتدا پایانه حمل‌ونقل بساز و حداقل ۲ کارمند به ناوگان اختصاص بده."}
	if daily_amount > engine.get_transport_daily_capacity():
		return {"ok":false,"message":"مقدار روزانه قرارداد از ظرفیت ناوگان بیشتر است؛ کامیون یا سطح جاده را افزایش بده."}
	if daily_amount < 1 or daily_amount > 10 or duration_days < 3 or duration_days > 30:
		return {"ok":false,"message":"قرارداد باید روزانه ۱ تا ۱۰ واحد و بین ۳ تا ۳۰ روز باشد."}
	for contract in state.import_contracts:
		if bool(contract.get("active",true)) and str(contract.get("city_id","")) == city_id and str(contract.get("resource_id","")) == resource_id:
			return {"ok":false,"message":"برای این کالا از این شهر قرارداد فعالی داری."}
	var contract = {"id":engine._next_contract_id(),"city_id":city_id,"resource_id":resource_id,"daily_amount":int(daily_amount),"days_left":int(duration_days),"active":true,"created_day":int(state.day)}
	state.import_contracts.append(contract)
	engine.save_game()
	return {"ok":true,"message":"قرارداد %d روزه ثبت شد؛ سفارش‌ها روزانه با بررسی پول و فضای انبار ارسال می‌شوند." % int(duration_days)}

static func _next_contract_id(engine):
	var state = engine.state
	var highest = 0
	for contract in state.import_contracts:
		highest = max(highest, int(contract.get("id",0)))
	return highest + 1

static func cancel_import_contract(engine, contract_index):
	var state = engine.state
	if contract_index < 0 or contract_index >= state.import_contracts.size():
		return {"ok":false,"message":"قرارداد پیدا نشد."}
	state.import_contracts[contract_index]["active"] = false
	engine.save_game()
	return {"ok":true,"message":"قرارداد لغو شد؛ محموله‌های در راه طبق سفارش قبلی تحویل می‌شوند."}

static func _process_trade_arrivals(engine, report):
	var state = engine.state
	var remaining_shipments = []
	for shipment in state.trade_shipments:
		if int(shipment.get("arrival_day",0)) > int(state.day):
			remaining_shipments.append(shipment)
			continue
		var amount = int(shipment.get("amount",0))
		if engine.get_free_storage() < amount:
			shipment["arrival_day"] = int(state.day) + 1
			remaining_shipments.append(shipment)
			report.append("محموله %d به‌دلیل پر بودن انبار یک روز در گمرک متوقف شد." % int(shipment.get("id",0)))
			continue
		var resource_id = str(shipment.get("resource_id",""))
		if engine.RESOURCES.has(resource_id):
			state.resources[resource_id] = int(state.resources.get(resource_id,0)) + amount
			report.append("محموله %d رسید: %d واحد %s." % [int(shipment.get("id",0)),amount,engine.RESOURCES[resource_id].name])
	state.trade_shipments = remaining_shipments

static func _dispatch_import_contracts(engine, report):
	var state = engine.state
	for contract_index in range(state.import_contracts.size()):
		var contract = state.import_contracts[contract_index]
		if not bool(contract.get("active",false)) or int(contract.get("days_left",0)) <= 0:
			continue
		var city_id = str(contract.get("city_id",""))
		var resource_id = str(contract.get("resource_id",""))
		if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id):
			contract["active"] = false
			state.import_contracts[contract_index] = contract
			continue
		var amount = int(contract.get("daily_amount",1))
		var stock = state.city_export_stock.get(city_id,engine.TRADE_CITIES[city_id].supply)
		amount = min(min(amount,int(stock.get(resource_id,0))),min(engine.get_free_storage(),engine.get_transport_capacity_remaining()))
		var price = engine.get_import_price(city_id,resource_id)
		var total = amount * price + max(1,int(ceil(float(amount * price)*0.10)))
		if amount <= 0 or price <= 0 or engine.get_available_money() < total:
			report.append("قرارداد واردات %s امروز به‌دلیل کمبود کالا، پول یا فضای انبار اجرا نشد." % engine.RESOURCES[resource_id].name)
		else:
			stock[resource_id] = int(stock.get(resource_id,0)) - amount
			state.city_export_stock[city_id] = stock
			state.trade_shipments.append({"id":engine._next_shipment_id(),"city_id":city_id,"resource_id":resource_id,"amount":amount,"arrival_day":int(state.day)+int(engine.TRADE_CITIES[city_id].travel_days),"paid":total})
			var settlement = _settle_trade(engine, resource_id, amount, -total)
			if not settlement.ok:
				state.trade_shipments.pop_back()
				stock[resource_id] = int(stock.get(resource_id,0)) + amount
				state.city_export_stock[city_id] = stock
				report.append("قرارداد واردات %s اجرا نشد: %s" % [engine.RESOURCES[resource_id].name, settlement.message])
			else:
				state.transport_used_today = int(state.get("transport_used_today",0)) + amount
				report.append("قرارداد واردات %s: محموله %d واحدی ارسال شد." % [engine.RESOURCES[resource_id].name,amount])
		contract["days_left"] = int(contract.get("days_left",0)) - 1
		if int(contract.days_left) <= 0:
			contract["active"] = false
		state.import_contracts[contract_index] = contract

static func get_market_price(engine, id, action):
	var state = engine.state
	if not engine.RESOURCES.has(id):
		return 0
	var stock = int(state.get("market_stock", {}).get(id, 60))
	var target_stock = 60
	var scarcity = float(target_stock - stock) / float(target_stock)
	var multiplier = clamp(1.0 + scarcity * 0.55, 0.65, 1.55)
	var base_price = int(engine.RESOURCES[id].get("buy" if action == "buy" else "sell", 0))
	return max(1, int(round(float(base_price) * multiplier)))

static func get_trade_cities(engine):
	var state = engine.state
	return engine.TRADE_CITIES

static func get_daily_trade_city_ids(engine):
	var state = engine.state
	var current_day = int(state.get("day", 1))
	var current_level = int(state.get("level", 1))
	var saved_ids = state.get("daily_trade_city_ids", [])
	if int(state.get("daily_trade_city_day", 0)) == current_day and int(state.get("daily_trade_city_level", 0)) == current_level and saved_ids.size() > 0:
		var valid_saved = true
		for saved_id in saved_ids:
			if not engine.TRADE_CITIES.has(str(saved_id)) or str(saved_id) in ["mehrabad","navid","golestan"]:
				valid_saved = false
				break
		if valid_saved:
			return saved_ids.duplicate()
	var available_ids = engine.TRADE_CITIES.keys()
	# Provincial trade screens must list real provinces, not the three old demo cities.
	for legacy_city_id in ["mehrabad","navid","golestan"]:
		available_ids.erase(legacy_city_id)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(current_day * 7919 + current_level * 104729)
	for index in range(available_ids.size() - 1, 0, -1):
		var swap_index = rng.randi_range(0, index)
		var temp = available_ids[index]
		available_ids[index] = available_ids[swap_index]
		available_ids[swap_index] = temp
	var visible_count = 3
	if current_level >= 30:
		visible_count = 22
	elif current_level >= 20:
		visible_count = 16
	elif current_level >= 15:
		visible_count = 12
	elif current_level >= 10:
		visible_count = 8
	elif current_level >= 6:
		visible_count = 5
	var selected = available_ids.slice(0, min(visible_count, available_ids.size()) - 1)
	state["daily_trade_city_ids"] = selected
	state["daily_trade_city_day"] = current_day
	state["daily_trade_city_level"] = current_level
	engine.save_game()
	return selected.duplicate()

static func get_trade_export_price(engine, city_id, resource_id):
	var state = engine.state
	if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id):
		return 0
	var city = engine.TRADE_CITIES[city_id]
	if int(city.demand.get(resource_id, 0)) <= 0:
		return 0
	var demand = int(state.get("trade_demand_remaining", {}).get(city_id, city.demand).get(resource_id, 0))
	if demand <= 0:
		return 0
	var local_price = engine.get_market_price(resource_id, "sell")
	var demand_factor = 1.0 + min(0.25, float(demand) / 100.0)
	return max(1, int(round(float(local_price) * float(city.price_factor) * demand_factor)))

static func trade_with_city(engine, city_id, resource_id, requested_amount):
	var state = engine.state
	if not engine.TRADE_CITIES.has(city_id) or not engine.RESOURCES.has(resource_id) or requested_amount <= 0:
		return {"ok":false,"message":"درخواست تجارت نامعتبر است."}
	var city = engine.TRADE_CITIES[city_id]
	if int(city.demand.get(resource_id, 0)) <= 0:
		return {"ok":false,"message":city.name+" به این کالا نیازی ندارد و آن را نمی‌پذیرد."}
	var demand_by_resource = state.trade_demand_remaining.get(city_id, city.demand)
	var demand = int(demand_by_resource.get(resource_id, 0))
	if demand <= 0:
		return {"ok":false,"message":city.name+" سهمیه خرید این کالا را امروز تکمیل کرده است."}
	var remaining = int(state.trade_remaining.get(city_id, city.daily_capacity))
	var available = int(state.resources.get(resource_id, 0))
	var unit_price = engine.get_trade_export_price(city_id, resource_id)
	var treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
	var affordable_amount = int(floor(float(treasury_room) / float(unit_price)))
	var amount = min(min(min(int(requested_amount),remaining),min(available,demand)),min(affordable_amount,engine.get_transport_capacity_remaining()))
	if amount <= 0:
		return {"ok":false,"message":"موجودی کالا، تقاضای شهر یا ظرفیت خزانه کافی نیست."}
	var final_revenue = amount * unit_price
	var settlement = _settle_trade(engine, resource_id, amount, final_revenue, -amount)
	if not settlement.ok:
		return settlement
	state["trade_exported_units_total"] = int(state.get("trade_exported_units_total", 0)) + amount
	state.trade_remaining[city_id] = remaining - amount
	demand_by_resource[resource_id] = demand - amount
	state.trade_demand_remaining[city_id] = demand_by_resource
	state.transport_used_today = int(state.get("transport_used_today",0)) + amount
	state.last_trade_report = "%d واحد %s به %s صادر شد؛ درآمد: %d سکه." % [amount,engine.RESOURCES[resource_id].name,city.name,final_revenue]
	engine.save_game()
	return {"ok":true,"message":state.last_trade_report,"amount":amount,"revenue":final_revenue}

static func _refresh_trade_capacity(engine):
	var state = engine.state
	for city_id in engine.TRADE_CITIES.keys():
		var city = engine.TRADE_CITIES[city_id]
		state.trade_remaining[city_id] = int(city.daily_capacity)
		state.trade_demand_remaining[city_id] = city.demand.duplicate(true)
		# Provincial suppliers replenish a portion of their base output every day.
		# Stock is capped at the province's normal supply, so imports can recover
		# after heavy orders without creating an unlimited source of resources.
		var province_stock = state.city_export_stock.get(city_id, city.supply.duplicate(true))
		for resource_id in engine.RESOURCES.keys():
			var base_supply = max(0, int(city.supply.get(resource_id, 0)))
			var current_stock = max(0, int(province_stock.get(resource_id, base_supply)))
			var daily_output = int(ceil(float(base_supply) * 0.25))
			province_stock[resource_id] = min(base_supply, current_stock + daily_output)
		state.city_export_stock[city_id] = province_stock

static func buy_resource(engine, id, amount, persist=true):
	var state = engine.state
	if not engine.RESOURCES.has(id) or amount <= 0:
		return {"ok":false,"message":"درخواست خرید نامعتبر است."}
	var unit_price = engine.get_market_price(id, "buy")
	var cost = unit_price * amount
	if engine.get_available_money() < cost:
		return {"ok":false,"message":"پول آزاد کافی نیست."}
	if int(state.market_stock.get(id, 0)) < amount:
		return {"ok":false,"message":"موجودی بازار کافی نیست."}
	if engine.get_free_storage() < amount:
		return {"ok":false,"message":"فضای خالی انبار کافی نیست."}
	var settlement = _settle_trade(engine, id, amount, -cost, amount, -amount)
	if not settlement.ok:
		return settlement
	if persist:
		engine.save_game()
	return {"ok":true,"message":"خرید انجام شد: "+str(amount)+" واحد "+engine.RESOURCES[id].name}

static func sell_resource(engine, id, amount, persist=true):
	var state = engine.state
	if not engine.RESOURCES.has(id) or amount <= 0:
		return {"ok":false,"message":"درخواست فروش نامعتبر است."}
	if int(state.resources.get(id, 0)) < amount:
		return {"ok":false,"message":"موجودی انبار کافی نیست."}
	if int(state.market_stock.get(id, 0)) + amount > 100:
		amount = max(0, 100 - int(state.market_stock.get(id, 0)))
	if amount <= 0:
		return {"ok":false,"message":"بازار ظرفیت خرید ندارد."}
	var unit_price = engine.get_market_price(id, "sell")
	var treasury_room = max(0, engine.get_treasury_capacity() - int(state.money))
	var affordable_amount = int(floor(float(treasury_room) / float(unit_price)))
	amount = min(amount, affordable_amount)
	if amount <= 0:
		return {"ok":false,"message":"ظرفیت خزانه پر است؛ فعلاً امکان دریافت درآمد فروش وجود ندارد."}
	var revenue = amount * unit_price
	var settlement = _settle_trade(engine, id, amount, revenue, -amount, amount)
	if not settlement.ok:
		return settlement
	if persist:
		engine.save_game()
	return {"ok":true,"message":"فروش %d واحد انجام شد؛ درآمد دریافتی: %d سکه." % [amount, revenue]}

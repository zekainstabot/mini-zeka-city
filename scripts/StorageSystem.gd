extends RefCounted

# Storage capacity, stock rules, and automated market/factory balancing.

static func get_storage_rule(engine, resource_id):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)):
		return {}
	if typeof(state.get("storage_rules", null)) != TYPE_DICTIONARY:
		state["storage_rules"] = {}
	if not state.storage_rules.has(str(resource_id)):
		state.storage_rules[str(resource_id)] = {"target":40,"low_action":"market","high_action":"market"}
	var rule = state.storage_rules[str(resource_id)]
	# Migrate older minimum/maximum rules without losing the user's chosen upper stock limit.
	if not rule.has("target"):
		rule["target"] = int(rule.get("maximum", 40))
		rule.erase("minimum")
		rule.erase("maximum")
	if not rule.has("low_action"):
		rule["low_action"] = "market"
	rule["high_action"] = "market"
	state.storage_rules[str(resource_id)] = rule
	return rule

static func set_storage_rule(engine, resource_id, field, value):
	if str(field) not in ["minimum", "maximum"]:
		return {"ok":false,"message":"تنظیم انبار نامعتبر است."}
	return set_storage_target(engine, resource_id, value)

static func set_storage_target(engine, resource_id, value):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)):
		return {"ok":false,"message":"تنظیم انبار نامعتبر است."}
	var rule = engine.get_storage_rule(str(resource_id))
	var capacity = engine.get_storage_capacity()
	var amount = int(clamp(int(value), 0, max(0, capacity)))
	rule["target"] = amount
	state.storage_rules[str(resource_id)] = rule
	engine.save_game()
	return {"ok":true,"message":"موجودی هدف "+engine.RESOURCES[str(resource_id)].name+" روی %d تنظیم شد." % amount}

static func toggle_storage_action(engine, resource_id, level):
	var state = engine.state
	var rule = engine.get_storage_rule(str(resource_id))
	if str(level) == "low":
		rule["low_action"] = "factory" if str(rule.get("low_action","market")) == "market" else "market"
	state.storage_rules[str(resource_id)] = rule
	engine.save_game()
	return {"ok":true,"message":"روش تأمین "+engine.RESOURCES[str(resource_id)].name+" تغییر کرد."}

static func apply_storage_rule(engine, resource_id, manual=false):
	var state = engine.state
	if not engine.RESOURCES.has(str(resource_id)):
		return {"ok":false,"message":"ماده پیدا نشد."}
	var id = str(resource_id)
	var rule = engine.get_storage_rule(id)
	var current = int(state.resources.get(id,0))
	var target = int(rule.get("target",40))
	if current < target:
		if str(rule.get("low_action","market")) == "factory":
			return {"ok":true,"message":"تأمین %s به تولید کارخانه‌ها سپرده شده است؛ تولید طبق چرخه عادی شهر انجام می‌شود." % engine.RESOURCES[id].name}
		var amount_to_buy = min(target-current, min(int(state.market_stock.get(id,0)), engine.get_free_storage()))
		if amount_to_buy <= 0:
			return {"ok":false,"message":"برای تأمین %s موجودی بازار یا فضای خالی انبار کافی نیست." % engine.RESOURCES[id].name}
		var buy_result = engine.buy_resource(id, amount_to_buy)
		return {"ok":bool(buy_result.get("ok",false)),"message":str(buy_result.get("message","خرید خودکار انجام نشد."))}
	if current > target:
		var amount_to_sell = current-target
		var sell_result = engine.sell_resource(id, amount_to_sell)
		return {"ok":bool(sell_result.get("ok",false)),"message":str(sell_result.get("message","فروش خودکار انجام نشد."))}
	return {"ok":true,"message":"موجودی "+engine.RESOURCES[id].name+" روی مقدار هدف قرار دارد."}

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

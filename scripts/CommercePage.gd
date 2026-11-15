extends RefCounted

# Builds the domestic market, exports, imports, shipments and trade contracts.
static func build(owner, s):
	var game = owner.game
	owner._add_label("🛒 بازار، تجارت و واردات", 22)
	owner._add_label("فهرست استان‌های تجاری هر روز تغییر می‌کند و با ارتقای سطح شهر، گزینه‌های بیشتری آزاد می‌شود.", 15)
	owner._add_button(("▼ " if owner.commerce_section_expanded.domestic else "▶ ") + "بازار داخلی و خریدوفروش", owner, "_toggle_commerce_section", ["domestic"])
	if owner.commerce_section_expanded.domestic:
		owner._add_label("قیمت‌ها بر اساس عرضه و تقاضا تغییر می‌کنند.", 15)
		for id in game.get_resource_definitions().keys():
			var d = game.get_resource_definitions()[id]
			var stock = int(s.resources.get(id,0))
			var market_stock = int(s.market_stock.get(id,0))
			var buy_price = game.get_market_price(id,"buy")
			var sell_price = game.get_market_price(id,"sell")
			owner._add_label("%s | انبار: %d | بازار: %d/۱۰۰ | خرید: %d | فروش: %d" % [d.name,stock,market_stock,buy_price,sell_price])
			var buy_max = min(int(s.market_stock.get(id,0)), min(game.get_free_storage(), int(floor(float(game.get_available_money()) / max(1,buy_price)))))
			var buy_slider = _add_quantity_slider(owner, "مقدار خرید "+d.name, buy_max)
			var buy_button = owner._add_button("خرید "+d.name, owner, "buy_item_from_slider", [id,buy_slider])
			buy_button.disabled = buy_max <= 0
			var treasury_room = max(0, game.get_treasury_capacity() - int(s.money))
			var sell_max = min(stock, min(max(0,100-int(s.market_stock.get(id,0))), int(floor(float(treasury_room) / max(1,sell_price)))))
			var sell_slider = _add_quantity_slider(owner, "مقدار فروش "+d.name, sell_max)
			var sell_button = owner._add_button("فروش "+d.name, owner, "sell_item_from_slider", [id,sell_slider])
			sell_button.disabled = sell_max <= 0
	owner._add_button(("▼ " if owner.commerce_section_expanded.export else "▶ ") + "صادرات به استان‌ها", owner, "_toggle_commerce_section", ["export"])
	if owner.commerce_section_expanded.export:
		var trade_ids = game.get_daily_trade_city_ids()
		owner._add_label("استان‌های فعال امروز: %d | ظرفیت حمل آزاد: %d واحد" % [trade_ids.size(),game.get_transport_capacity_remaining()],16)
		owner._add_label("هر استان فقط کالاهای موردنیاز خودش را می‌خرد؛ کالاهای دیگر برای صادرات به آن استان پذیرفته نمی‌شوند. فهرست فردا تغییر می‌کند.",14)
		for city_id in trade_ids:
			var city = game.get_trade_cities()[city_id]
			owner._add_label("%s | ظرفیت باقی‌مانده: %d از %d واحد" % [city.name,int(s.trade_remaining.get(city_id,city.daily_capacity)),int(city.daily_capacity)],18)
			for resource_id in game.get_resource_definitions().keys():
				var export_price = game.get_trade_export_price(city_id,resource_id)
				if export_price <= 0:
					continue
				var city_demand_left = int(s.trade_demand_remaining.get(city_id,city.demand).get(resource_id,0))
				owner._add_label("%s | تقاضا: %d | قیمت صادرات: %d سکه" % [game.get_resource_definitions()[resource_id].name,city_demand_left,export_price],15)
				var treasury_room = max(0, game.get_treasury_capacity() - int(s.money))
				var export_max = min(int(s.resources.get(resource_id,0)), min(city_demand_left, min(int(s.trade_remaining.get(city_id,city.daily_capacity)), min(game.get_transport_capacity_remaining(), int(floor(float(treasury_room) / max(1,export_price)))))))
				var export_slider = _add_quantity_slider(owner, "مقدار صادرات "+game.get_resource_definitions()[resource_id].name+" به "+city.name, export_max)
				var export_button = owner._add_button("صادرات به "+city.name,owner,"export_from_slider",[city_id,resource_id,export_slider])
				export_button.disabled = export_max <= 0
		owner._add_label("آخرین معامله: "+str(s.get("last_trade_report","هنوز معامله‌ای انجام نشده است.")),16)
	owner._add_button(("▼ " if owner.commerce_section_expanded.import else "▶ ") + "واردات از استان‌ها", owner, "_toggle_commerce_section", ["import"])
	if owner.commerce_section_expanded.import:
		var import_ids = game.get_daily_trade_city_ids()
		owner._add_label("استان‌های فعال امروز: %d | ظرفیت کامیون آزاد: %d از %d واحد" % [import_ids.size(),game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
		owner._add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود؛ زمان تحویل بسته به فاصله استان است.",15)
		for city_id in import_ids:
			var city = game.get_import_cities()[city_id]
			owner._add_label("%s | زمان حمل: %d روز" % [city.name,int(city.travel_days)],18)
			for resource_id in game.get_resource_definitions().keys():
				var import_stock = int(s.city_export_stock.get(city_id,city.supply).get(resource_id,0))
				var price = game.get_import_price(city_id,resource_id)
				if import_stock <= 0:
					continue
				owner._add_label("%s | موجودی: %d | قیمت: %d سکه/واحد" % [game.get_resource_definitions()[resource_id].name,import_stock,price],15)
				var import_max = min(import_stock, min(game.get_free_storage(), game.get_transport_capacity_remaining()))
				while import_max > 0:
					var import_cost = import_max * price + max(1,int(ceil(float(import_max * price) * 0.10)))
					if import_cost <= game.get_available_money():
						break
					import_max -= 1
				var import_slider = _add_quantity_slider(owner, "مقدار سفارش "+game.get_resource_definitions()[resource_id].name+" از "+city.name, import_max)
				var import_button = owner._add_button("سفارش از "+city.name,owner,"import_from_slider",[city_id,resource_id,import_slider])
				import_button.disabled = import_max <= 0
	owner._add_button(("▼ " if owner.commerce_section_expanded.shipments else "▶ ") + "محموله‌های در راه", owner, "_toggle_commerce_section", ["shipments"])
	if owner.commerce_section_expanded.shipments:
		if s.trade_shipments.is_empty():
			owner._add_label("محموله‌ای در راه نیست.")
		for shipment in s.trade_shipments:
			var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")) ,{"name":"نامشخص"})
			var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")) ,{"name":"کالای نامشخص"})
			owner._add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
		owner._add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
	owner._add_button(("▼ " if owner.commerce_section_expanded.contracts else "▶ ") + "قراردادهای واردات", owner, "_toggle_commerce_section", ["contracts"])
	if owner.commerce_section_expanded.contracts:
		if s.import_contracts.is_empty():
			owner._add_label("قرارداد فعالی ثبت نشده است.")
		for contract_index in range(s.import_contracts.size()):
			var contract = s.import_contracts[contract_index]
			var contract_city = game.get_import_cities().get(str(contract.get("city_id","")) ,{"name":"نامشخص"})
			var contract_resource = game.get_resource_definitions().get(str(contract.get("resource_id","")) ,{"name":"نامشخص"})
			var active_label = "فعال" if bool(contract.get("active",false)) else "پایان‌یافته/لغوشده"
			owner._add_label("%s | %s | روزانه %d واحد | %d روز باقی‌مانده | %s" % [contract_city.name,contract_resource.name,int(contract.get("daily_amount",0)),int(contract.get("days_left",0)),active_label],15)
			if bool(contract.get("active",false)):
				owner._add_button("لغو قرارداد "+contract_resource.name,owner,"cancel_import",[contract_index])
		for import_city_id in game.get_daily_trade_city_ids():
			var import_city = game.get_import_cities()[import_city_id]
			var contract_max = min(10, game.get_transport_daily_capacity())
			var contract_slider = _add_quantity_slider(owner, "مقدار روزانه قرارداد چوب از "+import_city.name, contract_max)
			var contract_button = owner._add_button("ثبت قرارداد ۷ روزه از "+import_city.name,owner,"make_import_contract_from_slider",[import_city_id,contract_slider,7])
			contract_button.disabled = contract_max <= 0


static func _add_quantity_slider(owner, caption, maximum):
	var safe_maximum = max(0, int(maximum))
	var label = owner._add_label(caption+" : "+str(1 if safe_maximum > 0 else 0), 14)
	var slider = HSlider.new()
	slider.min_value = 1
	slider.max_value = max(1, safe_maximum)
	slider.step = 1
	slider.value = 1
	slider.custom_minimum_size = Vector2(0, 38)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.editable = safe_maximum > 0
	var parent = owner.active_section_container if owner.active_section_container != null else owner.content
	parent.add_child(slider)
	slider.value_changed.connect(func(value):
		label.text = owner.PersianText.reshaper(caption+" : "+str(int(round(value))))
	)
	return slider

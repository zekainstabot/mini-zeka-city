extends RefCounted

# Builds intercity imports, shipments, and supply contracts.
static func build(owner, s):
	var game = owner.game
				owner._add_label(" واردات و حمل‌ونقل بین‌شهری", 22)
				owner._add_label("ظرفیت کامیون آزاد امروز: %d از %d واحد" % [game.get_transport_capacity_remaining(),game.get_transport_daily_capacity()],16)
				owner._add_label("هزینه کالا و ۱۰٪ کرایه حمل هنگام سفارش پرداخت می‌شود. محموله پس از ۱ یا ۲ روز می‌رسد.",15)
				for city_id in game.get_import_cities().keys():
					var city = game.get_import_cities()[city_id]
					owner._add_label("%s | زمان حمل: %d روز" % [city.name,int(city.travel_days)],18)
					for resource_id in game.get_resource_definitions().keys():
						var stock = int(s.city_export_stock.get(city_id,city.supply).get(resource_id,0))
						var price = game.get_import_price(city_id,resource_id)
						if stock <= 0:
							continue
						owner._add_label("%s | موجودی: %d | قیمت: %d سکه/واحد" % [game.get_resource_definitions()[resource_id].name,stock,price],15)
						var import_button = owner._add_button("سفارش ۵ واحد "+game.get_resource_definitions()[resource_id].name+" از "+city.name,owner,"import_from_city",[city_id,resource_id,5])
						import_button.disabled = game.get_free_storage() < 5 or game.get_transport_capacity_remaining() < 5 or game.get_available_money() < (5 * price + int(ceil(float(5 * price) * 0.10)))
				owner._add_label(" محموله‌های در راه:",18)
				if s.trade_shipments.is_empty():
					owner._add_label("محموله‌ای در راه نیست.")
				for shipment in s.trade_shipments:
					var shipment_city = game.get_import_cities().get(str(shipment.get("city_id","")),{"name":"نامشخص"})
					var shipment_resource = game.get_resource_definitions().get(str(shipment.get("resource_id","")),{"name":"کالای نامشخص"})
					owner._add_label("#%d | %s | %d واحد %s | تحویل روز %d" % [int(shipment.get("id",0)),shipment_city.name,int(shipment.get("amount",0)),shipment_resource.name,int(shipment.get("arrival_day",0))],15)
				owner._add_label("آخرین سفارش: "+str(s.get("last_import_report","")),15)
				owner._add_label(" قراردادهای واردات:",18)
				if s.import_contracts.is_empty():
					owner._add_label("قرارداد فعالی ثبت نشده است.")
				for contract_index in range(s.import_contracts.size()):
					var contract = s.import_contracts[contract_index]
					var contract_city = game.get_import_cities().get(str(contract.get("city_id","")),{"name":"نامشخص"})
					var contract_resource = game.get_resource_definitions().get(str(contract.get("resource_id","")),{"name":"نامشخص"})
					var active_label = "فعال" if bool(contract.get("active",false)) else "پایان‌یافته/لغوشده"
					owner._add_label("%s | %s | روزانه %d واحد | %d روز باقی‌مانده | %s" % [contract_city.name,contract_resource.name,int(contract.get("daily_amount",0)),int(contract.get("days_left",0)),active_label],15)
					if bool(contract.get("active",false)):
						owner._add_button("لغو قرارداد "+contract_resource.name,owner,"cancel_import",[contract_index])
				for city_id in game.get_import_cities().keys():
					var city = game.get_import_cities()[city_id]
					owner._add_button("قرارداد ۷ روزه: ۲ واحد چوب از "+city.name,owner,"make_import_contract",[city_id,"wood",2,7])

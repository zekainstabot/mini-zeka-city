extends RefCounted

# Builds city land expansion, roads, transport facilities, and fleet status.
static func build(owner, s):
	var game = owner.game
				owner._add_label("🚧 زیرساخت و توسعه شهر",22)
				owner._add_label("🗺️ زمین و گسترش محدوده شهر",19)
				owner._add_label("زمین شهر: %d قطعه | اشغال‌شده: %d | آزاد: %d" % [int(s.get("land_owned",10)),game.get_land_used(),game.get_land_free()],17)
				owner._add_label("برای گسترش شهر زمین بخر؛ هر ساختمان چند قطعه از زمین را اشغال می‌کند.",15)
				var land_button = owner._add_button("خرید ۱ قطعه زمین | قیمت: %d سکه" % game.get_land_unit_price(), owner, "buy_land")
				land_button.disabled = game.get_available_money() < game.get_land_unit_price()
				owner._add_label("🛣️ جاده‌ها و مسیرهای حمل‌ونقل",19)
				owner._add_label("جاده‌های اصلی شهر و مسیرهای بین‌شهری",19)
				owner._add_label("سطح جاده‌های بین‌شهری: %d از ۳" % int(s.get("road_level",1)),17)
				var road_level = int(s.get("road_level",1))
				if road_level < 3:
					var next_road_cost = 1500 if road_level == 1 else 3500
					var road_locked = int(s.level) < road_level+1
					var road_button = owner._add_button("احداث و ارتقای مسیر بین‌شهری به سطح %d%s — %d سکه" % [road_level+1, " 🔒" if road_locked else "", next_road_cost],owner,"upgrade_road")
					road_button.disabled = not road_locked and game.get_available_money() < next_road_cost
				else:
					owner._add_label("مسیرهای بین‌شهری به بالاترین سطح رسیده‌اند.")
				owner._add_label("🚏 ایستگاه‌های حمل‌ونقل شهری",19)
				owner._add_label("ایستگاه اتوبوس: %d | ایستگاه تاکسی: %d" % [game.get_building_count("bus_station"),game.get_building_count("taxi_station")],16)
				for facility_id in ["bus_station","taxi_station"]:
					var facility = game.get_building_definitions().get(facility_id,{})
					if facility.is_empty():
						continue
					var facility_population = int(facility.get("unlock",0))
					var facility_level = int(facility.get("level_unlock",1))
					var facility_locked = int(s.level) < facility_level or int(s.population) < facility_population
					var facility_name = str(facility.get("name","ایستگاه")) + (" 🔒" if facility_locked else "")
					var facility_button = owner._add_button("ساخت "+facility_name+" — %d سکه | زمین: %d قطعه | جمعیت لازم: %d نفر | سطح: %d" % [int(facility.get("cost",0)),game.get_land_size(facility_id),facility_population,facility_level],owner,"build_transport_facility",[facility_id])
					facility_button.disabled = false
				owner._add_label("🚚 پایانه و ناوگان کامیون",19)
				owner._add_label("پایانه حمل‌ونقل: %d | کامیون فعال: %d | ظرفیت روزانه: %d واحد" % [game.get_building_count("transport_depot"),game.get_transport_truck_count(),game.get_transport_daily_capacity()],17)
				owner._add_label("ظرفیت مصرف‌شده امروز: %d | ظرفیت باقی‌مانده: %d" % [int(s.get("transport_used_today",0)),game.get_transport_capacity_remaining()],16)
				owner._add_label("هر پایانه با ۲ کارمند، یک کامیون را فعال می‌کند؛ هر پایانه حداکثر ۲ کامیون پشتیبانی می‌کند.",15)
				owner._add_label("نگهداری روزانه ناوگان: %d سکه | نگهداری جاده: %d سکه" % [game.get_fleet_maintenance(),game.get_road_maintenance()],16)
				var depot = game.get_building_definitions().get("transport_depot",{})
				if not depot.is_empty():
					var depot_population = int(depot.get("unlock",0))
					var depot_level = int(depot.get("level_unlock",1))
					var depot_locked = int(s.level) < depot_level or int(s.population) < depot_population
					var depot_title = "ساخت پایانه حمل‌ونقل" + (" 🔒" if depot_locked else "")
					var depot_button = owner._add_button(depot_title+" — %d سکه | زمین: %d قطعه | جمعیت لازم: %d نفر | سطح: %d" % [int(depot.get("cost",0)),game.get_land_size("transport_depot"),depot_population,depot_level],owner,"build_transport_facility",["transport_depot"])
					depot_button.disabled = false
				owner._add_label("ظرفیت کامیون‌ها بین واردات، قراردادهای تأمین و صادرات مشترک است.",15)

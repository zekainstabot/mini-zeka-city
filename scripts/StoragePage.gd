extends RefCounted

# Builds storage controls, production totals, and automatic stock rules.
static func build(owner, s):
	var game = owner.game
	owner._add_label("مدیریت و تنظیم خودکار انبار", 22)
	var production_toggle = owner._add_button(("▼ " if owner.storage_production_expanded else "▶ ") + "تولید روزانه شهر", owner, "toggle_storage_production")
	owner._style_button(production_toggle, false)
	if owner.storage_production_expanded:
		owner._add_label("فقط کالاهایی که ساختمان‌های تولیدی شهر می‌سازند؛ مقدار بر اساس کارگران و مواد اولیه فعلی محاسبه می‌شود.", 14)
		var production_totals = owner._get_daily_production_totals()
		if production_totals.is_empty():
			owner._add_label("در حال حاضر تولید فعالی نداری. برای شروع، یک ساختمان تولیدی بساز و نیروی کار آن را تأمین کن.", 16)
		else:
			for resource_id in production_totals.keys():
				owner._add_label("%s : %d در روز" % [str(game.get_resource_definitions()[resource_id].name), int(production_totals[resource_id])], 18)
	owner._add_label("ظرفیت: %d | مصرف‌شده: %d | فضای خالی: %d" % [game.get_storage_capacity(),game.get_storage_used(),game.get_free_storage()])
	owner._add_label("برای هر ماده حداقل و حداکثر موجودی تعیین کن. تنظیمات در پایان هر روز اجرا می‌شوند.",15)
	owner._add_label("اگر موجودی از حداقل کمتر شود، می‌توانی خرید از بازار یا افزایش تولید کارخانه را انتخاب کنی؛ اگر از حداکثر بیشتر شود، فروش خودکار انجام می‌شود.",15)
	for id in game.get_resource_definitions().keys():
		var resource_name = str(game.get_resource_definitions()[id].name)
		var rule = game.get_storage_rule(id)
		var current_amount = int(s.resources.get(id,0))
		var market_amount = int(s.market_stock.get(id,0))
		var is_expanded = bool(owner.storage_section_expanded.get(str(id), false))
		var section_button = owner._add_button(("▼ " if is_expanded else "▶ ") + resource_name + " | موجودی: %d" % current_amount,owner,"toggle_storage_section",[str(id)])
		owner._style_button(section_button,false)
		if not is_expanded:
			continue
		var section_body = VBoxContainer.new()
		section_body.add_theme_constant_override("separation",5)
		section_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.content.add_child(section_body)
		owner.active_section_container = section_body
		owner._add_label("موجودی انبار: %d | موجودی بازار: %d" % [current_amount,market_amount],16)
		owner._add_label("حداقل موجودی: %d | حداکثر موجودی: %d" % [int(rule.get("minimum",10)),int(rule.get("maximum",40))],16)
		var minimum_slider_label = owner._add_label("تنظیم حداقل موجودی: %d" % int(rule.get("minimum",10)),15)
		var minimum_slider = HSlider.new()
		minimum_slider.min_value = 0
		minimum_slider.max_value = max(0, int(rule.get("maximum",40)) - 5)
		minimum_slider.step = 5
		minimum_slider.value = clampf(float(rule.get("minimum",10)), minimum_slider.min_value, minimum_slider.max_value)
		minimum_slider.custom_minimum_size = Vector2(0, 42)
		minimum_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.active_section_container.add_child(minimum_slider)
		minimum_slider.value_changed.connect(func(value):
			minimum_slider_label.text = owner.PersianText.reshaper("تنظیم حداقل موجودی: %d" % int(round(value)))
		)
		minimum_slider.drag_ended.connect(func(changed):
			if changed:
				owner.set_storage_rule_slider(str(id), "minimum", int(round(minimum_slider.value))
		)
		var maximum_slider_label = owner._add_label("تنظیم حداکثر موجودی: %d" % int(rule.get("maximum",40)),15)
		var maximum_slider = HSlider.new()
		maximum_slider.min_value = int(rule.get("minimum",10)) + 5
		maximum_slider.max_value = max(1000, int(rule.get("maximum",40)))
		maximum_slider.step = 5
		maximum_slider.value = clampf(float(rule.get("maximum",40)), maximum_slider.min_value, maximum_slider.max_value)
		maximum_slider.custom_minimum_size = Vector2(0, 42)
		maximum_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.active_section_container.add_child(maximum_slider)
		maximum_slider.value_changed.connect(func(value):
			maximum_slider_label.text = owner.PersianText.reshaper("تنظیم حداکثر موجودی: %d" % int(round(value)))
		)
		maximum_slider.drag_ended.connect(func(changed):
			if changed:
				owner.set_storage_rule_slider(str(id), "maximum", int(round(maximum_slider.value))
		)
		owner._add_label("وقتی موجودی کم شد: "+("خرید از بازار" if str(rule.get("low_action","market")) == "market" else "افزایش تولید کارخانه"),15)
		owner._add_button("تغییر روش تأمین",owner,"toggle_storage_low_action",[id])
		owner._add_label("وقتی موجودی زیاد شد: "+("فروش به بازار" if str(rule.get("high_action","market")) == "market" else "فروش از فروشگاه‌ها"),15)
		owner._add_button("تغییر روش فروش",owner,"toggle_storage_high_action",[id])
		owner._add_button("اجرای تنظیمات همین ماده",owner,"run_storage_rule",[id])
		owner.active_section_container = null
	owner._add_label("ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())

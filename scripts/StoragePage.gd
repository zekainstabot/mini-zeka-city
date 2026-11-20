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
	owner._add_label("برای هر کالا موجودی هدف تعیین کن؛ انبار هر ۶۰ ثانیه به‌صورت خودکار بررسی می‌شود.",15)
	owner._add_label("کمتر از هدف: تأمین از منبع انتخابی. بیشتر از هدف: فروش مازاد به بازار، با رعایت ظرفیت بازار و خزانه.",15)
	var resources_expanded = bool(owner.storage_section_expanded.get("all", false))
	var resources_button = owner._add_button(("▼ " if resources_expanded else "▶ ") + "تنظیم موجودی همه کالاها", owner, "toggle_storage_section", ["all"])
	owner._style_button(resources_button, false)
	if resources_expanded:
		var resources_body = VBoxContainer.new()
		resources_body.add_theme_constant_override("separation", 8)
		resources_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.content.add_child(resources_body)
		owner.active_section_container = resources_body
		var master_target_label = owner._add_label("تنظیم هم‌زمان هدف همه کالاها", 17)
		var master_slider = HSlider.new()
		master_slider.min_value = 0
		master_slider.max_value = max(1, game.get_storage_capacity())
		master_slider.step = 1
		master_slider.value = 0
		master_slider.custom_minimum_size = Vector2(0, 52)
		master_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		master_slider.focus_mode = Control.FOCUS_NONE
		resources_body.add_child(master_slider)
		master_target_label.text = owner.PersianText.reshaper("تنظیم هم‌زمان هدف همه کالاها | مقدار: %d" % int(master_slider.value))
		master_slider.value_changed.connect(func(value):
			master_target_label.text = owner.PersianText.reshaper("تنظیم هم‌زمان هدف همه کالاها | مقدار: %d" % int(round(value)))
		)
		master_slider.drag_ended.connect(func(changed):
			if changed:
				owner.set_all_storage_targets_slider(int(round(master_slider.value)))
		)
		owner._add_label("با کشیدن این نوار، مقدار هدف تمام کالاها یکسان تنظیم می‌شود؛ برای تغییر جداگانه از نوار هر کالا استفاده کن.", 13)
		for id in game.get_resource_definitions().keys():
			var resource_name = str(game.get_resource_definitions()[id].name)
			var rule = game.get_storage_rule(id)
			var current_amount = int(s.resources.get(id, 0))
			var market_amount = int(s.market_stock.get(id, 0))
			var target_value = int(rule.get("target", rule.get("maximum", 40)))
			owner._add_label("%s | انبار: %d | بازار: %d" % [resource_name, current_amount, market_amount], 17)
			var target_label = owner._add_label("موجودی هدف: %d" % target_value, 15)
			var target_slider = HSlider.new()
			target_slider.min_value = 0
			target_slider.max_value = max(1, game.get_storage_capacity())
			target_slider.step = 1
			target_slider.value = clampf(float(target_value), target_slider.min_value, target_slider.max_value)
			target_slider.custom_minimum_size = Vector2(0, 48)
			target_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			target_slider.focus_mode = Control.FOCUS_NONE
			resources_body.add_child(target_slider)
			target_slider.value_changed.connect(func(value):
				target_label.text = owner.PersianText.reshaper("موجودی هدف: %d" % int(round(value)))
			)
			target_slider.drag_ended.connect(func(changed):
				if changed:
					owner.set_storage_target_slider(str(id), int(round(target_slider.value)))
			)
			owner._add_label("تأمین هنگام کمبود: " + ("خرید از بازار" if str(rule.get("low_action", "factory")) == "market" else "تولید داخلی (بدون خرید)"), 14)
			owner._add_button("تغییر روش تأمین " + resource_name, owner, "toggle_storage_low_action", [id])
			owner._add_label("مازاد بر مقدار هدف: فروش خودکار به بازار", 13)
		owner.active_section_container = null
	owner._add_label("ذخیره درختان جنگل: %d / ۱۰۰" % game.get_forest_tree_count())

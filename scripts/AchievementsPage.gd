extends RefCounted

# Dedicated achievement gallery. Rewards are granted automatically and persisted by the game system.
static func build(owner, s):
	var game = owner.game
	owner._add_progress_missions_tabs("achievements")
	var achievements = game.get_achievements()
	var unlocked_count = 0
	# Unlocked achievements are counted above; coin rewards are shown on each badge.
	for achievement in achievements:
		if bool(achievement.get("unlocked", false)):
			unlocked_count += 1
	var summary = PanelContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var summary_style = StyleBoxFlat.new()
	summary_style.bg_color = Color("#26384b")
	summary_style.border_color = Color("#60a5fa")
	summary_style.set_border_width_all(2)
	summary_style.set_corner_radius_all(14)
	summary_style.content_margin_left = 14
	summary_style.content_margin_right = 14
	summary_style.content_margin_top = 12
	summary_style.content_margin_bottom = 12
	summary.add_theme_stylebox_override("panel", summary_style)
	owner.content.add_child(summary)
	var summary_body = VBoxContainer.new()
	summary_body.add_theme_constant_override("separation", 7)
	summary.add_child(summary_body)
	var summary_title = Label.new()
	summary_title.text = owner.PersianText.reshaper("تالار افتخارات شهر")
	summary_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner._apply_font(summary_title, 22)
	summary_title.add_theme_color_override("font_color", Color("#bfdbfe"))
	summary_body.add_child(summary_title)
	var summary_label = Label.new()
	summary_label.text = owner.PersianText.reshaper("نشان‌های کسب‌شده: %d از %d    |    موجودی Zeka Coin: %d" % [unlocked_count, achievements.size(), game.get_zeka_coins()])
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(summary_label, 16)
	summary_label.add_theme_color_override("font_color", Color("#f8fafc"))
	summary_body.add_child(summary_label)
	var completion = ProgressBar.new()
	completion.min_value = 0
	completion.max_value = max(1, achievements.size())
	completion.value = unlocked_count
	completion.show_percentage = false
	completion.custom_minimum_size = Vector2(0, 12)
	var completion_fill = StyleBoxFlat.new()
	completion_fill.bg_color = Color("#eabf54")
	completion_fill.set_corner_radius_all(6)
	completion.add_theme_stylebox_override("fg", completion_fill)
	var completion_bg = StyleBoxFlat.new()
	completion_bg.bg_color = Color("#334155")
	completion_bg.set_corner_radius_all(6)
	completion.add_theme_stylebox_override("bg", completion_bg)
	summary_body.add_child(completion)
	owner._add_label("پاداش هر نشان پس از باز شدن، خودکار به کیف Zeka Coin اضافه می‌شود؛ نیازی به دریافت دستی نیست.", 14)

	var categories = [
		{"id":"construction","title":"🏗️ ساخت‌وساز و معماری","ids":["first_expansion","buildings_10","buildings_25","buildings_50"]},
		{"id":"population","title":"👥 جمعیت و توسعه","ids":["population_20","population_50","population_100","level_5","level_10","level_20"]},
		{"id":"economy","title":"💰 اقتصاد و خزانه","ids":["treasury_20000","treasury_50000","treasury_100000"]},
		{"id":"wellbeing","title":"🌳 رفاه شهروندان","ids":["happy_city","happiness_95"]},
		{"id":"trade","title":"🚚 تجارت و بازرگانی","ids":["trade_50","trade_100","trade_500"]},
		{"id":"activity","title":"📅 استمرار و حضور","ids":["login_streak_7","login_streak_30"]},
		{"id":"districts","title":"🏘️ محله‌ها و زنجیره تولید","ids":["two_districts","five_districts","production_chain"]}
	]
	for category in categories:
		var category_items = []
		for achievement in achievements:
			if str(achievement.get("id", "")) in category.ids:
				category_items.append(achievement)
		if category_items.is_empty():
			continue
		owner._add_label(str(category.title), 20)
		for unlocked_state in [true, false]:
			for achievement in category_items:
				var is_unlocked = bool(achievement.get("unlocked", false))
				if is_unlocked != unlocked_state:
					continue
				_add_achievement_card(owner, game, achievement, is_unlocked)

static func _add_achievement_card(owner, game, achievement, is_unlocked):
	var achievement_id = str(achievement.get("id", ""))
	var progress = _get_achievement_progress(game, achievement_id)
	var reward = int(achievement.get("zeka_coin_reward", 0))
	var reward_claimed = bool(game.state.get("achievement_zeka_coin_rewards_claimed", {}).get(achievement_id, false))
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#263b32") if is_unlocked else Color("#202b3b")
	style.border_color = Color("#4ade80") if is_unlocked else Color("#475569")
	style.set_border_width_all(1 if not is_unlocked else 2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	owner.content.add_child(card)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	card.add_child(body)
	var title = Label.new()
	title.text = owner.PersianText.reshaper(("🏅 " if is_unlocked else "🔒 ") + str(achievement.get("title", "دستاورد")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.text_direction = Control.TEXT_DIRECTION_RTL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(title, 18)
	title.add_theme_color_override("font_color", Color("#86efac") if is_unlocked else Color("#f8fafc"))
	body.add_child(title)
	var description = Label.new()
	description.text = owner.PersianText.reshaper(str(achievement.get("description", "")))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	description.text_direction = Control.TEXT_DIRECTION_RTL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(description, 15)
	description.add_theme_color_override("font_color", Color("#e2e8f0"))
	body.add_child(description)
	var status = Label.new()
	var status_text = "✓ نشان باز شده" if is_unlocked else "در انتظار تکمیل"
	status_text += "   |   پاداش: %d Zeka Coin" % reward
	status_text += "   |   " + ("به کیف پول اضافه شد" if reward_claimed else ("در حال ثبت پاداش" if is_unlocked else "پس از باز شدن خودکار پرداخت می‌شود"))
	status.text = owner.PersianText.reshaper(status_text)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.text_direction = Control.TEXT_DIRECTION_RTL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(status, 14)
	status.add_theme_color_override("font_color", Color("#fcd34d") if is_unlocked else Color("#bfdbfe"))
	body.add_child(status)
	var progress_label = Label.new()
	progress_label.text = owner.PersianText.reshaper("پیشرفت: %s از %s" % [str(progress.current), str(progress.goal)])
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.text_direction = Control.TEXT_DIRECTION_RTL
	owner._apply_font(progress_label, 14)
	progress_label.add_theme_color_override("font_color", Color("#cbd5e1"))
	body.add_child(progress_label)
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max(1, int(progress.goal))
	bar.value = bar.max_value if is_unlocked else min(int(progress.current), int(progress.goal))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("#4ade80") if is_unlocked else Color("#38bdf8")
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fg", fill)
	var background = StyleBoxFlat.new()
	background.bg_color = Color("#334155")
	background.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("bg", background)
	body.add_child(bar)

static func _get_achievement_progress(game, achievement_id):
	var state = game.state
	var current = 0
	var goal = 1
	match achievement_id:
		"first_expansion", "buildings_10", "buildings_25", "buildings_50":
			current = state.get("buildings", []).size()
			goal = {"first_expansion":5, "buildings_10":10, "buildings_25":25, "buildings_50":50}[achievement_id]
		"population_20", "population_50", "population_100":
			current = int(state.get("population", 0))
			goal = {"population_20":20, "population_50":50, "population_100":100}[achievement_id]
		"level_5", "level_10", "level_20":
			current = int(state.get("level", 1))
			goal = {"level_5":5, "level_10":10, "level_20":20}[achievement_id]
		"treasury_20000", "treasury_50000", "treasury_100000":
			current = int(state.get("city_records", {}).get("peak_money", state.get("money", 0)))
			goal = {"treasury_20000":20000, "treasury_50000":50000, "treasury_100000":100000}[achievement_id]
		"happy_city", "happiness_95":
			current = int(state.get("satisfaction", 0))
			goal = 85 if achievement_id == "happy_city" else 95
		"login_streak_7", "login_streak_30":
			current = int(state.get("login_streak", 0))
			goal = 7 if achievement_id == "login_streak_7" else 30
		"trade_50", "trade_100", "trade_500":
			current = int(state.get("trade_exported_units_total", 0))
			goal = {"trade_50":50, "trade_100":100, "trade_500":500}[achievement_id]
		"two_districts", "five_districts":
			current = game.get_populated_district_count()
			goal = 2 if achievement_id == "two_districts" else 5
		"production_chain":
			current = int(game.get_building_count("woodcutter") > 0) + int(game.get_building_count("sawmill") > 0) + int(game.get_building_count("carpenter") > 0)
			goal = 3
	return {"current":min(current, goal), "goal":goal}

extends RefCounted

# A compact, mobile-first city leaderboard styled for Mini Zeka City.
static func _make_card(parent, fill_color, border_color, radius=16):
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return panel

static func _make_label(owner, parent, value, size, color, alignment=HORIZONTAL_ALIGNMENT_RIGHT):
	var label = Label.new()
	label.text = owner.PersianText.reshaper(str(value))
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(label, size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

static func build(owner, s):
	var game = owner.game
	var rows = game.get_rival_standings()
	var player_rank = 0
	var player_row = {}
	for row in rows:
		if bool(row.get("is_player", false)):
			player_rank = int(row.get("rank", 0))
			player_row = row
			break

	_make_label(owner, owner.content, "🏆  تالار افتخار شهرها", 25, Color("#ffe2a1"), HORIZONTAL_ALIGNMENT_CENTER)
	_make_label(owner, owner.content, "جایگاه شهرها را ببین و برای رسیدن به رتبه‌های بالاتر تلاش کن.", 15, Color("#cbd5e1"), HORIZONTAL_ALIGNMENT_CENTER)

	if player_rank > 0:
		var summary = _make_card(owner.content, Color("#173b3c"), Color("#55c9a7"), 18)
		var summary_box = VBoxContainer.new()
		summary_box.add_theme_constant_override("separation", 4)
		summary.add_child(summary_box)
		_make_label(owner, summary_box, "جایگاه فعلی شهر تو", 15, Color("#a7f3d0"), HORIZONTAL_ALIGNMENT_CENTER)
		_make_label(owner, summary_box, "رتبه  %d  از  %d" % [player_rank, rows.size()], 25, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
		_make_label(owner, summary_box, "%s  •  %s XP" % [str(player_row.get("name", "شهر من")), str(int(player_row.get("xp", 0)))], 15, Color("#d1fae5"), HORIZONTAL_ALIGNMENT_CENTER)

	if rows.size() > 0:
		_make_label(owner, owner.content, "سه شهر برتر", 19, Color("#f8fafc"), HORIZONTAL_ALIGNMENT_RIGHT)
		var podium = HBoxContainer.new()
		podium.add_theme_constant_override("separation", 7)
		podium.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner.content.add_child(podium)
		var podium_indices = [1, 0, 2] if rows.size() >= 3 else []
		if rows.size() == 2:
			podium_indices = [1, 0]
		elif rows.size() == 1:
			podium_indices = [0]
		for index in podium_indices:
			var row = rows[index]
			var rank = int(row.get("rank", index + 1))
			var is_player = bool(row.get("is_player", false))
			var medal = "🥇" if rank == 1 else ("🥈" if rank == 2 else "🥉")
			var card_color = Color("#3b3425") if rank == 1 else Color("#253345")
			var border_color = Color("#e7bd65") if rank == 1 else Color("#64748b")
			if is_player:
				card_color = Color("#173b3c")
				border_color = Color("#55c9a7")
			var card = _make_card(podium, card_color, border_color, 14)
			var stack = VBoxContainer.new()
			stack.add_theme_constant_override("separation", 5)
			card.add_child(stack)
			_make_label(owner, stack, medal, 25, Color("#ffe2a1"), HORIZONTAL_ALIGNMENT_CENTER)
			_make_label(owner, stack, "رتبه %d" % rank, 14, Color("#f8fafc"), HORIZONTAL_ALIGNMENT_CENTER)
			_make_label(owner, stack, str(row.get("name", "شهر")), 14, Color("#ffffff"), HORIZONTAL_ALIGNMENT_CENTER)
			_make_label(owner, stack, "%d XP" % int(row.get("xp", 0)), 13, Color("#a7f3d0"), HORIZONTAL_ALIGNMENT_CENTER)

	_make_label(owner, owner.content, "جدول رتبه‌بندی", 19, Color("#f8fafc"), HORIZONTAL_ALIGNMENT_RIGHT)
	var table_header = HBoxContainer.new()
	table_header.add_theme_constant_override("separation", 8)
	owner.content.add_child(table_header)
	_make_label(owner, table_header, "رتبه", 14, Color("#9fb4c8"), HORIZONTAL_ALIGNMENT_CENTER).custom_minimum_size.x = 48
	_make_label(owner, table_header, "نام شهر", 14, Color("#9fb4c8"), HORIZONTAL_ALIGNMENT_RIGHT)
	_make_label(owner, table_header, "تجربه", 14, Color("#9fb4c8"), HORIZONTAL_ALIGNMENT_CENTER).custom_minimum_size.x = 82

	for row in rows:
		var rank = int(row.get("rank", 0))
		var is_player = bool(row.get("is_player", false))
		var row_color = Color("#173b3c") if is_player else Color("#1c2b3b")
		var border = Color("#55c9a7") if is_player else Color("#34475b")
		var row_panel = _make_card(owner.content, row_color, border, 13)
		var row_box = VBoxContainer.new()
		row_box.add_theme_constant_override("separation", 5)
		row_panel.add_child(row_box)
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row_box.add_child(line)
		var rank_label = _make_label(owner, line, ("👑 " if rank == 1 else "") + str(rank), 17, Color("#f6d58c") if rank <= 3 else Color("#cbd5e1"), HORIZONTAL_ALIGNMENT_CENTER)
		rank_label.custom_minimum_size.x = 48
		var name_text = str(row.get("name", "شهر"))
		if is_player:
			name_text += "  •  شهر تو"
		_make_label(owner, line, name_text, 16, Color("#ffffff"), HORIZONTAL_ALIGNMENT_RIGHT)
		var xp_label = _make_label(owner, line, "%d" % int(row.get("xp", 0)), 15, Color("#a7f3d0"), HORIZONTAL_ALIGNMENT_CENTER)
		xp_label.custom_minimum_size.x = 82
		_make_label(owner, row_box, "%s  |  امتیاز توسعه: %d  |  جمعیت: %d" % [str(row.get("geographic_rank", "آبادی کوچک")), int(row.get("score", 0)), int(row.get("population", 0))], 13, Color("#b8c7d6"), HORIZONTAL_ALIGNMENT_RIGHT)

	if rows.is_empty():
		_make_label(owner, owner.content, "هنوز شهری برای رتبه‌بندی وجود ندارد. کمی در شهر پیشرفت کن و دوباره سر بزن.", 16, Color("#cbd5e1"), HORIZONTAL_ALIGNMENT_CENTER)

	_make_label(owner, owner.content, "رتبه‌بندی فعلاً میان شهرهای رقیب همین ذخیره بازی محاسبه می‌شود و آنلاین یا جهانی نیست.", 13, Color("#94a3b8"), HORIZONTAL_ALIGNMENT_CENTER)
	owner._add_button("🏙️ بازگشت به شهر", owner, "show_page", ["home"])

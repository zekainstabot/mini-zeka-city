extends RefCounted

const PersianText = preload("res://scripts/PersianText.gd")

static func add_section(owner, title, description, target_page=""):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#1e293b")
	panel_style.border_color = Color("#475569")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	owner.content.add_child(panel)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	panel.add_child(body)
	var compact = owner.get_viewport_rect().size.x < 900
	var heading = Label.new()
	heading.text = PersianText.reshaper(title)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner._apply_font(heading, 18 if compact else 17)
	heading.add_theme_color_override("font_color", Color("#fbbf24"))
	body.add_child(heading)
	var details = Label.new()
	details.text = PersianText.reshaper(description)
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owner._apply_font(details, 16 if compact else 15)
	details.add_theme_color_override("font_color", Color("#e2e8f0"))
	body.add_child(details)
	if str(target_page) != "":
		var jump = Button.new()
		jump.text = PersianText.reshaper("رفتن به بخش مربوط  ←")
		jump.custom_minimum_size = Vector2(0, 48 if compact else 42)
		jump.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owner._apply_font(jump, 16 if compact else 15)
		owner._style_button(jump, false)
		jump.connect("pressed", Callable(owner, "_open_help_target").bind(str(target_page)))
		body.add_child(jump)

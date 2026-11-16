extends RefCounted

static func button_style(bg_color, border_color):
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(15)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static var _button_style_cache: Dictionary = {}

static func _get_button_styles(navigation: bool) -> Dictionary:
	var cache_key = "navigation" if navigation else "regular"
	if _button_style_cache.has(cache_key):
		return _button_style_cache[cache_key]
	var normal_color = Color("#202124") if navigation else Color("#FFFFFF")
	var hover_color = Color("#34363A") if navigation else Color("#E8EAED")
	var pressed_color = Color("#111214") if navigation else Color("#DADCE0")
	var border_normal = Color("#050505") if navigation else Color("#73777D")
	var border_hover = Color("#000000") if navigation else Color("#4B5057")
	var border_pressed = Color("#000000") if navigation else Color("#30343A")
	var styles = {
		"normal": button_style(normal_color, border_normal),
		"hover": button_style(hover_color, border_hover),
		"pressed": button_style(pressed_color, border_pressed)
	}
	_button_style_cache[cache_key] = styles
	return styles

static func style_button(button, navigation=false):
	button.flat = false
	# One consistent text rule across every menu, card, popup, and page:
	# centered Persian text with wrapping instead of clipping on narrow screens.
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text_direction = Control.TEXT_DIRECTION_RTL
	# Activate after touch release so Android cannot leave a menu button stuck
	# in the pressed/blue state while the next screen is displayed.
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button.focus_mode = Control.FOCUS_NONE
	var styles = _get_button_styles(bool(navigation))
	var text_color = Color("#FFFFFF") if navigation else Color("#111111")
	button.add_theme_stylebox_override("normal", styles.normal)
	button.add_theme_stylebox_override("hover", styles.hover)
	button.add_theme_stylebox_override("focus", styles.hover)
	button.add_theme_stylebox_override("pressed", styles.pressed)
	# Locked navigation items keep the same visual style; only the lock icon indicates availability.
	button.add_theme_stylebox_override("disabled", styles.normal)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_color_focus", text_color)
	button.add_theme_color_override("font_color_hover", text_color)
	button.add_theme_color_override("font_color_pressed", text_color)
	button.add_theme_color_override("font_color_disabled", text_color)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_color_override("font_outline_color", Color("#FFFFFF") if not navigation else Color("#111827"))

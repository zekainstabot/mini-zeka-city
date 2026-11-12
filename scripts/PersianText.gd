extends RefCounted
class_name PersianText

# Godot 4's TextServerAdvanced performs Arabic/Persian glyph shaping and
# Unicode bidirectional layout natively. Keep the old method name so existing
# UI call sites remain compatible, but never reverse or reshape Unicode text.
static func reshaper(value: String, line_length: int = 0) -> String:
	if line_length <= 0 or value.length() <= line_length:
		return value
	var words := value.split(" ", false)
	var lines: Array[String] = []
	var current := ""
	for word in words:
		if current.is_empty():
			current = word
		elif current.length() + 1 + word.length() <= line_length:
			current += " " + word
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	return "\n".join(lines)

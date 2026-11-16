extends RefCounted
class_name PersianText

# Keep Persian UI numerals consistent. Godot handles Arabic/Persian shaping
# and bidirectional layout natively; this helper only normalizes digits and
# optionally wraps long text.
static func reshaper(value: String, line_length: int = 0) -> String:
	var normalized := value
	var latin_digits := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	var persian_digits := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
	for index in range(latin_digits.size()):
		normalized = normalized.replace(latin_digits[index], persian_digits[index])

	if line_length <= 0 or normalized.length() <= line_length:
		return normalized
	var words := normalized.split(" ", false)
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

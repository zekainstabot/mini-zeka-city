"""
Persian text shaping and right-to-left ordering for Godot 3.x.

Godot 3.x does not provide the same built-in Arabic shaping/RTL pipeline
as newer Godot versions, so this helper keeps the existing public API while
using joining capabilities instead of inspecting already-mutated characters.
"""
extends Reference

enum {
	NOT_SUPPORTED = -1,
	ISOLATED,
	INITIAL,
	MEDIAL,
	FINAL
}

# Presentation forms: isolated, initial, medial, final.
const LETTERS := {
	"آ" : ["ﺁ", "", "", "ﺂ"],
	"ا" : ["ﺍ", "", "", "ﺎ"],
	"ب" : ["ﺏ", "ﺑ", "ﺒ", "ﺐ"],
	"پ" : ["ﭖ", "ﭘ", "ﭙ", "ﭗ"],
	"ت" : ["ﺕ", "ﺗ", "ﺘ", "ﺖ"],
	"ث" : ["ﺙ", "ﺛ", "ﺜ", "ﺚ"],
	"ج" : ["ﺝ", "ﺟ", "ﺠ", "ﺞ"],
	"چ" : ["ﭺ", "ﭼ", "ﭽ", "ﭻ"],
	"ح" : ["ﺡ", "ﺣ", "ﺤ", "ﺢ"],
	"خ" : ["ﺥ", "ﺧ", "ﺨ", "ﺦ"],
	"د" : ["ﺩ", "", "", "ﺪ"],
	"ذ" : ["ﺫ", "", "", "ﺬ"],
	"ر" : ["ﺭ", "", "", "ﺮ"],
	"ز" : ["ﺯ", "", "", "ﺰ"],
	"ژ" : ["ﮊ", "", "", "ﮋ"],
	"س" : ["ﺱ", "ﺳ", "ﺴ", "ﺲ"],
	"ش" : ["ﺵ", "ﺷ", "ﺸ", "ﺶ"],
	"ص" : ["ﺹ", "ﺻ", "ﺼ", "ﺺ"],
	"ض" : ["ﺽ", "ﺿ", "ﻀ", "ﺾ"],
	"ط" : ["ﻁ", "ﻃ", "ﻄ", "ﻂ"],
	"ظ" : ["ﻅ", "ﻇ", "ﻈ", "ﻆ"],
	"ع" : ["ﻉ", "ﻋ", "ﻌ", "ﻊ"],
	"غ" : ["ﻍ", "ﻏ", "ﻐ", "ﻎ"],
	"ف" : ["ﻑ", "ﻓ", "ﻔ", "ﻒ"],
	"ق" : ["ﻕ", "ﻗ", "ﻘ", "ﻖ"],
	"ک" : ["ﮎ", "ﮐ", "ﮑ", "ﮏ"],
	"گ" : ["ﮒ", "ﮔ", "ﮕ", "ﮓ"],
	"ل" : ["ﻝ", "ﻟ", "ﻠ", "ﻞ"],
	"ﻻ" : ["ﻻ", "", "", "ﻼ"],
	"م" : ["ﻡ", "ﻣ", "ﻤ", "ﻢ"],
	"ن" : ["ﻥ", "ﻧ", "ﻨ", "ﻦ"],
	"و" : ["ﻭ", "", "", "ﻮ"],
	"ه" : ["ﻩ", "ﻫ", "ﻬ", "ﻪ"],
	"ی" : ["ﯼ", "ﯾ", "ﯿ", "ﯽ"],
	"أ" : ["ﺃ", "", "", "ﺄ"],
	"إ" : ["ﺇ", "", "", "ﺈ"],
	"ؤ" : ["ﺅ", "", "", "ﺆ"],
	"ئ" : ["ﺉ", "ﺋ", "ﺌ", "ﺊ"],
	"ء" : ["ﺀ", "", "", ""]
}

const BRACKETS := [
	["(", ")"], ["«", "»"], ["{", "}"], ["[", "]"], ["<", ">"]
]

static func reshaper(string: String, line_length: int = 0) -> String:
	if string.empty():
		return ""
	string = wrap(string, line_length)
	string = invert(string)
	string = reshape(string)
	return string

static func invert(string: String) -> String:
	string = invert_brackets(string)
	string = invert_numbers(string)
	string = invert_letters(string)
	return string

static func invert_brackets(string: String) -> String:
	for index in range(string.length()):
		for bracket in BRACKETS:
			if bracket.has(string[index]):
				string[index] = bracket[int(bracket.find(string[index]) == 0)]
	return string

static func invert_numbers(string: String) -> String:
	var regex = RegEx.new()
	regex.compile("([0-9۰-۹٠-٩])+" )
	var matches = regex.search_all(string)
	for match_result in matches:
		var number = match_result.get_string()
		var reversed_number = ""
		for index in range(number.length() - 1, -1, -1):
			reversed_number += number[index]
		string = string.replace(number, reversed_number)
	return string

# Preserve Latin words and numeric groups while reversing RTL text runs.
static func invert_letters(string: String) -> String:
	var regex = RegEx.new()
	regex.compile("[A-Za-z][A-Za-z0-9_./:+-]*(?: +[A-Za-z][A-Za-z0-9_./:+-]*)*")
	var matches = regex.search_all(string)
	if matches.empty():
		return _reverse_characters(string)
	var parts = []
	var cursor = 0
	for match_result in matches:
		var match_start = match_result.get_start()
		if match_start > cursor:
			parts.append({"text": string.substr(cursor, match_start - cursor), "fixed": false})
		parts.append({"text": match_result.get_string(), "fixed": true})
		cursor = match_result.get_end()
	if cursor < string.length():
		parts.append({"text": string.substr(cursor), "fixed": false})
	var result = ""
	for index in range(parts.size() - 1, -1, -1):
		var part = parts[index]
		result += str(part.text) if bool(part.fixed) else _reverse_characters(str(part.text))
	return result

static func _reverse_characters(value: String) -> String:
	var result = ""
	for index in range(value.length() - 1, -1, -1):
		result += value[index]
	return result

# A letter can join the preceding logical character when it has a final form.
static func _can_join_previous(letter: String) -> bool:
	if not LETTERS.has(letter):
		return false
	return str(LETTERS[letter][FINAL]) != ""

# A letter can join the following logical character when it has an initial form.
static func _can_join_next(letter: String) -> bool:
	if not LETTERS.has(letter):
		return false
	return str(LETTERS[letter][INITIAL]) != ""

static func reshape(string: String) -> String:
	string = string.replace("لا", "ﻻ")
	var source = string
	var output = ""
	for index in range(source.length()):
		var letter = source[index]
		if not LETTERS.has(letter):
			output += letter
			continue
		var forms = LETTERS[letter]
		var joins_previous = false
		var joins_next = false
		if index > 0:
			var previous_letter = source[index - 1]
			joins_previous = _can_join_previous(previous_letter) and _can_join_next(letter)
		if index + 1 < source.length():
			var next_letter = source[index + 1]
			joins_next = _can_join_previous(letter) and _can_join_next(next_letter)
		if joins_previous and joins_next:
			output += str(forms[MEDIAL])
		elif joins_previous:
			output += str(forms[INITIAL])
		elif joins_next:
			output += str(forms[FINAL])
		else:
			output += str(forms[ISOLATED])
	return output

# Kept for compatibility with any older callers.
static func previous(letter: int, string: String) -> int:
	if letter <= 0 or letter >= string.length():
		return NOT_SUPPORTED
	var current = string[letter - 1]
	if not LETTERS.has(current):
		return NOT_SUPPORTED
	return FINAL if _can_join_previous(current) else ISOLATED

static func next(letter: int, string: String) -> int:
	if letter < 0 or letter + 1 >= string.length():
		return NOT_SUPPORTED
	var current = string[letter + 1]
	if not LETTERS.has(current):
		return NOT_SUPPORTED
	return INITIAL if _can_join_next(current) else ISOLATED

static func wrap(string: String, line_length: int = 0) -> String:
	if line_length <= 0:
		return string
	var words = string.split(" ", false)
	var lines = []
	var current_line = ""
	for word in words:
		if current_line == "":
			current_line = word
		elif current_line.length() + 1 + word.length() <= line_length:
			current_line += " " + word
		else:
			lines.append(current_line)
			current_line = word
	if current_line != "":
		lines.append(current_line)
	return "\n".join(lines)

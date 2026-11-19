extends RefCounted

# Pure ranking calculations shared by the game engine and ranking UI.
static func geographic_rank_for_district_count(district_count):
	var ranks = [
		"آبادی کوچک", "آبادی", "آبادی بزرگ",
		"روستای کوچک", "روستا", "روستای بزرگ",
		"ده کوچک", "ده", "ده بزرگ",
		"دهستان کوچک", "دهستان", "دهستان بزرگ",
		"بخش کوچک", "بخش", "بخش بزرگ",
		"شهر کوچک", "شهر", "شهر بزرگ",
		"شهرستان کوچک", "شهرستان", "شهرستان بزرگ",
		"استان کوچک", "استان", "استان بزرگ",
		"ایالت کوچک", "ایالت", "ایالت بزرگ",
		"کشور کوچک", "کشور", "کشور بزرگ",
		"قاره کوچک", "قاره", "قاره بزرگ",
		"سیاره کوچک", "سیاره", "سیاره بزرگ",
		"منظومه کوچک", "منظومه", "منظومه بزرگ",
		"سامانه ستاره‌ای کوچک", "سامانه ستاره‌ای", "سامانه ستاره‌ای بزرگ",
		"کهکشان کوچک", "کهکشان", "کهکشان بزرگ",
		"گروه کهکشانی کوچک", "گروه کهکشانی", "گروه کهکشانی بزرگ",
		"خوشه کهکشانی کوچک", "خوشه کهکشانی", "خوشه کهکشانی بزرگ",
		"ابرخوشه کهکشانی کوچک", "ابرخوشه کهکشانی", "ابرخوشه کهکشانی بزرگ",
		"شبکه کیهانی کوچک", "شبکه کیهانی", "شبکه کیهانی بزرگ",
		"جهان قابل مشاهده کوچک", "جهان قابل مشاهده", "جهان قابل مشاهده بزرگ",
		"جهان کوچک", "جهان", "جهان بزرگ"
	]
	var safe_count = max(1, int(district_count))
	var tier = min(int(floor(float(safe_count - 1) / 3.0)), ranks.size() - 1)
	return {"name":str(ranks[tier]),"tier":tier,"district_count":safe_count,"next_at":(tier + 1) * 3 + 1 if tier < ranks.size() - 1 else 0}

static func city_league(city_state):
	var score = int(city_state.get("level", 1)) * 100 + int(city_state.get("population", 0)) * 5 + city_state.get("buildings", []).size() * 12 + int(city_state.get("satisfaction", 0)) * 2 + int(city_state.get("reputation", 0)) * 2
	var leagues = [
		{"name":"توسعه نوپا","min":0,"next":300},
		{"name":"توسعه در حال رشد","min":300,"next":650},
		{"name":"توسعه پویا","min":650,"next":1100},
		{"name":"توسعه پیشرفته","min":1100,"next":1700},
		{"name":"توسعه ممتاز","min":1700,"next":0}
	]
	var selected = leagues[0]
	for league in leagues:
		if score >= int(league.min):
			selected = league
	return {"score":score,"name":str(selected.name),"next":int(selected.next),"tier":leagues.find(selected)}

static func sort_standings(a, b):
	var tier_a = int(a.get("geographic_tier", 0))
	var tier_b = int(b.get("geographic_tier", 0))
	if tier_a != tier_b:
		return tier_a > tier_b
	var xp_a = int(a.get("xp", 0))
	var xp_b = int(b.get("xp", 0))
	if xp_a != xp_b:
		return xp_a > xp_b
	return int(a.get("score", 0)) > int(b.get("score", 0))

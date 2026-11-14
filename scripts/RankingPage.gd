extends RefCounted

# Builds the city ranking and rival standings page.
static func build(owner, s):
	var game = owner.game
	owner._add_label("🏆 رتبه‌بندی شهرها", 24)
	owner._add_label("اول رده جغرافیایی شهر، بعد XP و در صورت برابری هر دو، امتیاز توسعه تعیین‌کننده جایگاه است.", 16)
	var ranking_rows = game.get_rival_standings()
	var player_rank = 0
	for ranking_row in ranking_rows:
		if bool(ranking_row.get("is_player", false)):
			player_rank = int(ranking_row.get("rank", 0))
	if player_rank > 0:
		owner._add_label("👑 رتبه فعلی شهر تو: %d از %d" % [player_rank, ranking_rows.size()], 20)
	for ranking_row in ranking_rows:
		var ranking_prefix = "👑 " if bool(ranking_row.get("is_player", false)) else "🏘️ "
		var ranking_name = str(ranking_row.get("name", "شهر"))
		var ranking_card_text = "%sرتبه %d ـ %s\nرده جغرافیایی: %s  |  XP: %d\nامتیاز توسعه: %d\nجمعیت: %d نفر  |  سطح: %d" % [ranking_prefix, int(ranking_row.get("rank", 0)), ranking_name, str(ranking_row.get("geographic_rank", "آبادی کوچک")), int(ranking_row.get("xp", 0)), int(ranking_row.get("score", 0)), int(ranking_row.get("population", 0)), int(ranking_row.get("level", 1))]
		owner._add_label(ranking_card_text, 18)
	owner._add_label("نکته: این رتبه‌بندی فعلاً بین شهرهای رقیب داخل همین ذخیره بازی محاسبه می‌شود و آنلاین یا جهانی نیست.", 14)
	owner._add_button("🏙️ بازگشت به شهر", owner, "show_page", ["home"])

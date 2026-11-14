extends RefCounted

# Builds long-term city progress, achievements, and weekly challenges.
static func build(owner, s):
	var game = owner.game
	owner._add_progress_missions_tabs("progress")
	owner._add_label("🏗️ هدف‌های بلندمدت شهر",23)
	owner._add_label("این هدف‌ها با ساخت‌وساز و رشد شهر کامل می‌شوند. پیشرفت هر هدف ذخیره می‌شود و پس از تکمیل، می‌توانی جایزه‌اش را دریافت کنی.",16)
	for project in game.get_long_term_projects():
		var project_done = int(project.progress) >= int(project.goal)
		owner._add_label(str(project.title),19)
		owner._add_label(str(project.description),16)
		owner._add_label("میزان پیشرفت: %d از %d\nجایزه: %d سکه و %d تجربه" % [int(project.progress),int(project.goal),int(project.reward),int(project.xp)],16)
		var project_bar = ProgressBar.new()
		project_bar.min_value = 0
		project_bar.max_value = max(1,int(project.goal))
		project_bar.value = int(project.progress)
		project_bar.show_percentage = false
		project_bar.custom_minimum_size = Vector2(0,12)
		owner.content.add_child(project_bar)
		if bool(project.claimed):
			owner._add_label("✓ این جایزه را دریافت کرده‌ای",15)
		elif project_done:
			owner._add_button("🎁 دریافت جایزه پروژه",owner,"claim_long_term_project",[str(project.id)])
		else:
			owner._add_label("● هنوز در حال تکمیل این هدف هستی",15)

	owner._add_label("🏙️ رتبه‌بندی شهرها",23)
	owner._add_label("ابتدا رده جغرافیایی، سپس XP و در نهایت امتیاز توسعه رتبه شهرها را تعیین می‌کند.",15)
	for rival_row in game.get_rival_standings():
		var rival_prefix = "👑 " if bool(rival_row.get("is_player",false)) else "🏘️ "
		owner._add_label("%sرتبه %d ـ %s\nرده جغرافیایی: %s | XP: %d\nامتیاز توسعه: %d | جمعیت: %d نفر | سطح: %d" % [rival_prefix,int(rival_row.get("rank",0)),str(rival_row.get("name","")),str(rival_row.get("geographic_rank","آبادی کوچک")),int(rival_row.get("xp",0)),int(rival_row.get("score",0)),int(rival_row.get("population",0)),int(rival_row.get("level",1))],16)
	owner._add_label("🔎 رازها و کشفیات",23)
	var mystery = game.get_mystery_status()
	if bool(mystery.get("active",false)):
		owner._add_label("سرنخ تازه: "+str(mystery.get("title","راز مخفی")),18)
		owner._add_label(str(mystery.get("clue","")),15)
		owner._add_label(str(mystery.get("objective","")),16)
		owner._add_label("پیشرفت سرنخ: %d از %d\nپاداش کشف: %d سکه و %d تجربه" % [int(mystery.get("progress",0)),int(mystery.get("goal",1)),int(mystery.get("reward",0)),int(mystery.get("xp",0))],16)
		if int(mystery.get("progress",0)) >= int(mystery.get("goal",1)):
			owner._add_button("🗝️ باز کردن راز و دریافت جایزه",owner,"claim_mystery_reward")
	else:
		owner._add_label("فعلاً سرنخ تازه‌ای پیدا نکرده‌ای. با پیشرفت شهر و گذشت روزها، ممکن است راز تازه‌ای کشف شود.",15)
		owner._add_label("تعداد رازهای کشف‌شده: %d" % int(mystery.get("completed",0)),15)
	owner._add_label("🏛️ پروژه‌های بزرگ شهری",23)
	var landmark_status = game.get_landmark_project_status()
	if bool(landmark_status.get("active",false)):
		var stage_data = landmark_status.get("stage_data",{})
		owner._add_label("پروژه در حال اجرا: %s\nمرحله %d از %d" % [str(landmark_status.get("title","")),int(landmark_status.get("stage",1)),int(landmark_status.get("stage_total",1))],18)
		owner._add_label("کار این مرحله: %s\nهزینه تکمیل: %d سکه" % [str(stage_data.get("title","")),int(stage_data.get("cost",0))],16)
		owner._add_label("برای انجام این مرحله لازم است: سطح شهر %d، جمعیت %d نفر و دست‌کم %d ساختمان داشته باشی." % [int(stage_data.get("level",1)),int(stage_data.get("population",0)),int(stage_data.get("buildings",0))],15)
		var stage_button = owner._add_button("🏗️ سرمایه‌گذاری و تکمیل این مرحله",owner,"invest_landmark_stage")
		stage_button.disabled = not bool(landmark_status.get("requirements_met",false)) or game.get_available_money() < int(stage_data.get("cost",0))
	else:
		owner._add_label("در هر زمان فقط یک پروژه بزرگ را می‌توانی دنبال کنی. هر پروژه چند مرحله دارد و برای عبور از هر مرحله باید شرط‌های آن را فراهم کنی و هزینه‌اش را بپردازی.",15)
		for landmark in game.get_landmark_project_definitions():
			var completed_landmarks = landmark_status.get("completed",[])
			var is_completed_landmark = str(landmark.id) in completed_landmarks
			owner._add_label("%s\nجایزه پس از افتتاح: %d سکه و %d تجربه" % [str(landmark.title),int(landmark.reward),int(landmark.xp)],17)
			owner._add_label(str(landmark.description),14)
			if is_completed_landmark:
				owner._add_label("✓ این سازه در شهر افتتاح شده است",15)
			else:
				owner._add_button("آغاز پروژه "+str(landmark.title),owner,"start_landmark_project",[str(landmark.id)])

	owner._add_label("🏆 رتبه، افتخارات و رکوردهای شهر",23)
	var league = game.get_city_league()
	owner._add_label("رده امتیاز توسعه: %s\nامتیاز توسعه: %d" % [str(league.name),int(league.score)],19)
	if int(league.next) > 0:
		owner._add_label("برای رسیدن به رده امتیاز توسعه بعدی، %d امتیاز دیگر لازم داری." % max(0,int(league.next)-int(league.score)),15)
	owner._add_label("این رتبه فقط بر اساس وضعیت شهر خودت محاسبه می‌شود و جدول رتبه‌بندی جهانی نیست.",14)
	var weekly = game.get_weekly_challenge()
	owner._add_label("🏁 چالش این هفته: "+str(weekly.title),19)
	owner._add_label(str(weekly.description),15)
	owner._add_label("پیشرفت این هفته: %d از %d\nجایزه: %d سکه و %d تجربه" % [int(weekly.progress),int(weekly.goal),int(weekly.reward),int(weekly.xp)],16)
	if bool(weekly.claimed):
		owner._add_label("✓ جایزه چالش این هفته را دریافت کرده‌ای.",15)
	elif int(weekly.progress) >= int(weekly.goal):
		owner._add_button("🏆 دریافت جایزه رقابت هفتگی",owner,"claim_weekly_challenge")
	var records = game.get_city_records()
	owner._add_label("📊 رکوردهای ثبت‌شده شهر",19)
	owner._add_label("بیشترین جمعیت ثبت‌شده: %d نفر\nبیشترین موجودی خزانه: %d سکه" % [int(records.get("peak_population",0)),int(records.get("peak_money",0))],16)
	owner._add_label("بالاترین سطح شهر: %d\nبیشترین رضایت ثبت‌شده: %d از ۱۰۰\nبیشترین تعداد ساختمان: %d" % [int(records.get("peak_level",1)),int(records.get("peak_satisfaction",0)),int(records.get("most_buildings",0))],16)
	var achievement_list = game.get_achievements()
	var unlocked_achievements = 0
	for achievement in achievement_list:
		if bool(achievement.unlocked):
			unlocked_achievements += 1
	owner._add_label("افتخارات به‌دست‌آمده: %d از %d" % [unlocked_achievements,achievement_list.size()],17)
	for achievement in achievement_list:
		var achievement_status = "🏅 بازشده" if bool(achievement.unlocked) else "🔒 هنوز باز نشده"
		owner._add_label(achievement_status+" | "+str(achievement.title),18)
		owner._add_label(str(achievement.description),15)

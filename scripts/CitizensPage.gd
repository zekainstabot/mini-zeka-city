extends RefCounted

# Builds the citizens page while preserving Main.gd as the owner of state and actions.
static func build(owner, s):
	var game = owner.game
	owner._add_label(" جمعیت: %d | شاغل: %d | بیکار: %d" % [s.population,owner.game.get_employed_count(),owner.game.get_unemployed_count()], 20)
	var poor_citizens = 0
	var middle_citizens = 0
	var wealthy_citizens = 0
	for wealth_citizen in s.citizens:
		var citizen_wallet = int(wealth_citizen.get("wallet",0))
		if citizen_wallet < 500:
			poor_citizens += 1
		elif citizen_wallet < 1200:
			middle_citizens += 1
		else:
			wealthy_citizens += 1
	owner._add_label("وضعیت اقتصادی شهروندان | فقیر: %d نفر  |  متوسط: %d نفر  |  ثروتمند: %d نفر" % [poor_citizens,middle_citizens,wealthy_citizens], 17)
	owner._add_label("ظرفیت مسکن: %d | ظرفیت شغلی: %d" % [owner.game.get_housing_capacity(),owner.game.get_job_capacity()])
	owner._add_label("رضایت شهروندان: %d/۱۰۰" % int(s.get("satisfaction",50)))
	owner._add_label("نیازهای روزانه: " + owner._needs_summary(), 15)
	var resident_requests = s.get("resident_requests",[])
	owner._add_label("📣 درخواست‌های شهروندان: %d" % resident_requests.size(),18)
	for resident_request in resident_requests:
		owner._add_label(str(resident_request.get("title","درخواست شهروندان"))+" | روز "+str(int(resident_request.get("day",s.day))),17)
		owner._add_label(str(resident_request.get("description","")),15)
		owner._add_button("رفتن به بخش ساخت ساختمان پیشنهادی  ←",owner,"go_to_resident_request_building",[str(resident_request.get("building_id",""))])
		if bool(resident_request.get("accepted",false)):
			owner._add_label("✓ پذیرفته شده؛ با ساخت ساختمان پیشنهادی، درخواست تکمیل می‌شود.",15)
		else:
			owner._add_button("پذیرفتن و تعهد ساخت",owner,"resolve_resident_request",[int(resident_request.get("id",0)),true])
			owner._add_button("رد درخواست",owner,"resolve_resident_request",[int(resident_request.get("id",0)),false])
	var recruitment_mode = str(s.get("citizen_recruitment_mode","auto"))
	var is_auto_recruitment = recruitment_mode == "auto"
	var next_recruitment_mode = "manual" if is_auto_recruitment else "auto"
	var current_recruitment_label = "خودکار" if is_auto_recruitment else "دستی"
	var next_recruitment_label = "دستی" if is_auto_recruitment else "خودکار"
	owner._add_label("روش جذب شهروند", 18)
	var recruitment_toggle = owner._add_button("جذب %s ✓  |  تغییر به جذب %s" % [current_recruitment_label,next_recruitment_label], owner, "set_recruitment_mode", [next_recruitment_mode])
	owner._style_button(recruitment_toggle, true)
	owner._add_label("درخواست‌های در انتظار: %d" % s.get("citizen_requests", []).size(), 18)
	for request_index in range(s.get("citizen_requests", []).size()):
		var request = s.citizen_requests[request_index]
		owner._add_label("متقاضی شماره %d | درخواست در روز %d" % [int(request.get("id",0)),int(request.get("day",s.day))], 17)
		owner._add_button("قبول درخواست شماره %d" % int(request.get("id",0)), owner, "accept_citizen_request", [request_index])
		owner._add_button("رد درخواست شماره %d" % int(request.get("id",0)), owner, "reject_citizen_request", [request_index])
	if int(s.population) >= owner.game.get_housing_capacity():
		owner._add_label("ظرفیت خانه‌ها پر است؛ برای جذب شهروند جدید خانه بساز.", 15)
	elif int(s.reputation) < 25:
		owner._add_label("اعتبار شهر باید حداقل ۲۵ باشد تا متقاضی جدید بیاید.", 15)
	var citizen_groups = {"بیکاران":[],"کارمندان شهرداری":[],"کارمندان بخش خصوصی":[],"کارآفرینان بخش خصوصی":[]}
	for citizen in s.citizens:
		var group_name = "بیکاران"
		if str(citizen.get("job","")) != "":
			group_name = "کارمندان شهرداری"
		elif int(citizen.get("private_business_id",0)) > 0:
			group_name = "کارآفرینان بخش خصوصی"
		elif int(citizen.get("private_job_id",0)) > 0:
			group_name = "کارمندان بخش خصوصی"
		citizen_groups[group_name].append(citizen)
	for group_name in ["بیکاران","کارمندان شهرداری","کارمندان بخش خصوصی","کارآفرینان بخش خصوصی"]:
		var group_citizens = citizen_groups[group_name]
		if group_citizens.is_empty():
			continue
		var group_expanded = bool(owner.citizen_status_expanded.get(group_name,false))
		var group_button = owner._add_button(("%s " % ("▼" if group_expanded else "▶")) + "%s (%d)" % [group_name,group_citizens.size()], owner, "toggle_citizen_status_group", [group_name])
		owner._style_button(group_button,false)
		if group_expanded:
			for citizen in group_citizens:
				var citizen_role = group_name
				if str(citizen.get("job","")) != "":
					citizen_role += ": " + str(citizen.job)
				owner._add_label("شهروند %s — %s | کیف پول: %d سکه | زمین خصوصی: %d قطعه" % [str(citizen.id),citizen_role,int(citizen.get("wallet",0)),int(citizen.get("private_land",0))])
				var interest_names = {"food":"خوراک","industry":"صنعت","services":"خدمات"}
				owner._add_label("استعداد کارآفرینی: %d | ریسک‌پذیری: %d | علاقه: %s | پس‌انداز: %d" % [int(citizen.get("entrepreneurship",0)),int(citizen.get("risk_tolerance",0)),str(interest_names.get(str(citizen.get("business_interest","")),"نامشخص")),int(citizen.get("saving_habit",0))], 14)
	owner._add_button(" تخصیص دوباره شغل‌ها", owner, "reassign_jobs")

extends RefCounted

# City treasury loans, deposits, repayments, and bank ledger.

static func _record_bank_transaction(engine, kind, amount, description):
	var state = engine.state
	if typeof(state.get("bank_transactions", null)) != TYPE_ARRAY:
		state["bank_transactions"] = []
	state.bank_transactions.append({"day":int(state.get("day",1)),"kind":str(kind),"amount":int(amount),"description":str(description)})
	while state.bank_transactions.size() > 100:
		state.bank_transactions.pop_front()

static func get_bank_loan_limit(engine):
	var state = engine.state
	if not engine.has_central_bank():
		return 0
	var capacity_room = max(0, engine.get_treasury_capacity() - int(state.get("money",0)))
	var city_limit = 5000 + int(state.get("level",1)) * 2000 + int(state.get("population",0)) * 100
	return min(capacity_room, city_limit)

static func take_bank_loan(engine, amount, duration_days):
	var state = engine.state
	if not engine.has_central_bank():
		return {"ok":false,"message":"برای دریافت وام ابتدا بانک مرکزی بساز."}
	var active_loans = 0
	for loan in state.get("bank_loans", []):
		if str(loan.get("status","active")) == "active":
			active_loans += 1
	if active_loans >= 2:
		return {"ok":false,"message":"حداکثر ۲ وام فعال می‌توانی داشته باشی؛ ابتدا یکی را تسویه کن."}
	var term = int(duration_days)
	var rates = {7:8,14:14,30:25}
	if not rates.has(term):
		return {"ok":false,"message":"مدت وام باید ۷، ۱۴ یا ۳۰ روز باشد."}
	var principal = int(amount)
	if principal < 1000 or principal > BankingSystem.get_bank_loan_limit(engine):
		return {"ok":false,"message":"مبلغ وام باید حداقل ۱۰۰۰ و حداکثر %d سکه باشد." % BankingSystem.get_bank_loan_limit(engine)}
	var interest = int(ceil(float(principal * int(rates[term])) / 100.0))
	var total_due = principal + interest
	var accepted = engine._add_money(principal)
	if accepted != principal:
		return {"ok":false,"message":"ظرفیت خزانه برای پرداخت کامل وام کافی نیست."}
	var loan = {"id":state.get("bank_loans",[]).size()+1,"principal":principal,"interest":interest,"total_due":total_due,"remaining":total_due,"daily_installment":int(ceil(float(total_due)/float(term))),"duration":term,"days_left":term,"status":"active","missed_days":0}
	state.bank_loans.append(loan)
	BankingSystem._record_bank_transaction(engine, "loan",principal,"دریافت وام %d روزه با سود %d درصد" % [term,int(rates[term])])
	engine.save_game()
	return {"ok":true,"message":"وام %d سکه‌ای با سود %d سکه ثبت شد؛ بازپرداخت روزانه حدود %d سکه به مدت %d روز." % [principal,interest,loan.daily_installment,term]}

static func repay_bank_loan_manual(engine, loan_index):
	var state = engine.state
	if loan_index < 0 or loan_index >= state.get("bank_loans",[]).size():
		return {"ok":false,"message":"وام پیدا نشد."}
	var loan = state.bank_loans[loan_index]
	if str(loan.get("status","")) != "active":
		return {"ok":false,"message":"این وام فعال نیست."}
	if int(loan.get("last_manual_payment_day", 0)) == int(state.get("day", 1)):
		return {"ok":false,"message":"قسط این وام امروز یک‌بار دستی پرداخت شده است."}
	var due = min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))
	var payment = min(due,engine.get_available_money())
	if payment <= 0:
		return {"ok":false,"message":"برای پرداخت قسط، موجودی آزاد خزانه کافی نیست."}
	engine._spend_money(payment)
	loan["remaining"] = int(loan.get("remaining",0)) - payment
	loan["days_left"] = max(0,int(loan.get("days_left",0))-1)
	loan["last_manual_payment_day"] = int(state.get("day",1))
	if int(loan.get("remaining",0)) <= 0:
		loan["status"] = "paid"
	state.bank_loans[loan_index] = loan
	BankingSystem._record_bank_transaction(engine, "repayment",payment,"پرداخت دستی قسط وام شماره %d" % int(loan.get("id",loan_index+1)))
	engine.save_game()
	return {"ok":true,"message":"قسط دستی به مبلغ %d سکه پرداخت شد؛ مانده وام: %d سکه." % [payment,int(loan.get("remaining",0))]}

static func repay_bank_loan_early(engine, loan_index):
	var state = engine.state
	if loan_index < 0 or loan_index >= state.get("bank_loans",[]).size():
		return {"ok":false,"message":"وام پیدا نشد."}
	var loan = state.bank_loans[loan_index]
	if str(loan.get("status","")) != "active":
		return {"ok":false,"message":"این وام فعال نیست."}
	var due = int(loan.get("remaining",0))
	if engine.get_available_money() < due:
		return {"ok":false,"message":"برای تسویه کامل وام، %d سکه پول آزاد لازم داری." % due}
	engine._spend_money(due)
	loan["remaining"] = 0
	loan["status"] = "paid"
	state.bank_loans[loan_index] = loan
	BankingSystem._record_bank_transaction(engine, "repayment",due,"تسویه زودهنگام وام شماره %d" % int(loan.get("id",loan_index+1)))
	engine.save_game()
	return {"ok":true,"message":"وام با پرداخت %d سکه تسویه شد." % due}

static func create_bank_deposit(engine, amount, duration_days):
	var state = engine.state
	if BankingSystem.game_has_no_municipal_bank(engine):
		return {"ok":false,"message":"برای سپرده‌گذاری ابتدا بانک شهری بساز."}
	var term = int(duration_days)
	var rates = {7:3,14:7,30:15}
	var principal = int(amount)
	if not rates.has(term):
		return {"ok":false,"message":"مدت سپرده باید ۷، ۱۴ یا ۳۰ روز باشد."}
	if principal < 500 or engine.get_available_money() < principal:
		return {"ok":false,"message":"مبلغ سپرده حداقل ۵۰۰ سکه است و باید پول آزاد کافی داشته باشی."}
	if not engine._spend_money(principal):
		return {"ok":false,"message":"برداشت مبلغ سپرده از خزانه انجام نشد."}
	var interest = int(floor(float(principal * int(rates[term])) / 100.0))
	var deposit = {"id":state.get("bank_deposits",[]).size()+1,"principal":principal,"interest":interest,"duration":term,"maturity_day":int(state.day)+term,"status":"active"}
	state.bank_deposits.append(deposit)
	BankingSystem._record_bank_transaction(engine, "deposit",principal,"افتتاح سپرده %d روزه با سود %d درصد" % [term,int(rates[term])])
	engine.save_game()
	return {"ok":true,"message":"سپرده %d سکه‌ای ثبت شد؛ سود سررسید %d سکه است." % [principal,interest]}

static func withdraw_bank_deposit(engine, deposit_index):
	var state = engine.state
	if deposit_index < 0 or deposit_index >= state.get("bank_deposits",[]).size():
		return {"ok":false,"message":"سپرده پیدا نشد."}
	var deposit = state.bank_deposits[deposit_index]
	if str(deposit.get("status","")) == "withdrawn":
		return {"ok":false,"message":"این سپرده قبلاً برداشت شده است."}
	var matured = int(state.day) >= int(deposit.get("maturity_day",0))
	var payout = int(deposit.get("principal",0)) + (int(deposit.get("interest",0)) if matured else 0)
	if engine.get_treasury_capacity() - int(state.money) < payout:
		return {"ok":false,"message":"ظرفیت خالی خزانه برای پرداخت %d سکه کافی نیست." % payout}
	engine._add_money(payout)
	deposit["status"] = "withdrawn"
	deposit["withdrawn_day"] = int(state.day)
	state.bank_deposits[deposit_index] = deposit
	BankingSystem._record_bank_transaction(engine, "withdrawal",payout,"برداشت سپرده شماره %d%s" % [int(deposit.get("id",deposit_index+1))," با سود" if matured else " پیش از سررسید؛ بدون سود"])
	engine.save_game()
	return {"ok":true,"message":"%d سکه به خزانه برگشت%s." % [payout,"؛ سود هم دریافت شد" if matured else "؛ چون زودتر برداشت کردی سودی تعلق نگرفت"]}

static func _process_bank_day(engine, report):
	var state = engine.state
	var total_paid = 0
	for index in range(state.get("bank_loans",[]).size()):
		var loan = state.bank_loans[index]
		if str(loan.get("status","")) != "active":
			continue
		if int(loan.get("last_manual_payment_day", 0)) == int(state.get("day", 1)):
			report.append("قسط وام شماره %d امروز دستی پرداخت شده است؛ برداشت خودکار تکرار نشد." % int(loan.get("id",index+1)))
			continue
		var due = min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))
		var payment = min(due,engine.get_available_money())
		if payment > 0:
			engine._spend_money(payment)
			loan["remaining"] = int(loan.get("remaining",0)) - payment
			loan["days_left"] = max(0,int(loan.get("days_left",0))-1)
			loan["missed_days"] = 0
			total_paid += payment
			BankingSystem._record_bank_transaction(engine, "repayment",payment,"قسط روزانه وام شماره %d" % int(loan.get("id",index+1)))
			if int(loan.remaining) <= 0:
				loan["status"] = "paid"
				report.append("وام شماره %d به‌طور کامل تسویه شد." % int(loan.get("id",index+1)))
			else:
				report.append("قسط وام: %d سکه؛ مانده بدهی: %d سکه." % [payment,int(loan.remaining)])
		else:
			loan["missed_days"] = int(loan.get("missed_days",0)) + 1
			loan["days_left"] = int(loan.get("days_left",0)) + 1
			report.append("قسط وام پرداخت نشد؛ به‌دلیل کمبود پول، سررسید یک روز تمدید شد و جریمه‌ای نگرفت.")
		state.bank_loans[index] = loan
	for index in range(state.get("bank_deposits",[]).size()):
		var deposit = state.bank_deposits[index]
		if str(deposit.get("status","")) == "active" and int(state.day) + 1 >= int(deposit.get("maturity_day",0)):
			deposit["status"] = "matured"
			report.append("سپرده شماره %d سررسید شد؛ اصل و %d سکه سود آماده برداشت است." % [int(deposit.get("id",index+1)),int(deposit.get("interest",0))])
		state.bank_deposits[index] = deposit
	if total_paid > 0:
		state["bank_daily_repayment"] = total_paid
	return total_paid

static func game_has_no_municipal_bank(engine):
	return engine.get_building_count("municipal_bank") <= 0

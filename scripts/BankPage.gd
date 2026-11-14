extends RefCounted

# Builds city banking, loans, deposits, and transaction history.
static func build(owner, s):
	var game = owner.game
	owner._add_label("🏦 بانک و امور مالی شهر",22)
	owner._add_label("بانک مرکزی: %s | بانک شهری: %d" % ["فعال" if game.has_central_bank() else "ساخته نشده",game.get_building_count("municipal_bank")],17)
	owner._add_label("وام فقط با بانک مرکزی و سپرده‌گذاری با بانک شهری فعال می‌شود.",15)
	owner._add_label("موجودی خزانه: %d سکه | ظرفیت آزاد: %d سکه" % [int(s.money),game.get_available_money()],16)
	owner._add_label("حداکثر وام قابل دریافت: %d سکه" % game.get_bank_loan_limit(),16)
	var player_active_loans = 0
	for player_loan in s.get("bank_loans", []):
		if str(player_loan.get("status", "active")) == "active":
			player_active_loans += 1
	owner._add_label("وام‌های فعال شهرداری: %d از ۲" % player_active_loans,16)
	owner._add_label("شهروندان شاغل و کم‌پول نیز در صورت فعال‌بودن بانک مرکزی، خودکار وام می‌گیرند؛ سقف هر شهروند ۲ وام فعال است و قسط از کیف پول خودش کم می‌شود.",15)
	var citizen_active_loans = 0
	for bank_citizen in s.get("citizens", []):
		for citizen_loan in bank_citizen.get("bank_loans", []):
			if str(citizen_loan.get("status", "active")) == "active":
				citizen_active_loans += 1
	owner._add_label("وام‌های فعال شهروندان: %d" % citizen_active_loans,16)
	owner._add_label("💳 دریافت وام",19)
	for loan_option in [{"amount":1000,"days":7},{"amount":3000,"days":14},{"amount":5000,"days":30}]:
		var loan_button = owner._add_button("درخواست وام %d سکه‌ای — %d روزه" % [int(loan_option.amount),int(loan_option.days)],owner,"request_bank_loan",[int(loan_option.amount),int(loan_option.days)])
		loan_button.disabled = not game.has_central_bank() or game.get_bank_loan_limit() < int(loan_option.amount) or player_active_loans >= 2
	for loan_index in range(s.get("bank_loans",[]).size()):
		var loan = s.bank_loans[loan_index]
		owner._add_label("وام #%d | اصل: %d | سود: %d | مانده: %d | وضعیت: %s" % [int(loan.get("id",loan_index+1)),int(loan.get("principal",0)),int(loan.get("interest",0)),int(loan.get("remaining",0)),"فعال" if str(loan.get("status","")) == "active" else "تسویه‌شده"],15)
		if str(loan.get("status","")) == "active":
			var manual_button = owner._add_button("پرداخت دستی قسط وام #%d — تا %d سکه" % [int(loan.get("id",loan_index+1)),min(int(loan.get("remaining",0)),int(loan.get("daily_installment",0)))],owner,"repay_bank_loan_manual",[loan_index])
			manual_button.disabled = int(loan.get("last_manual_payment_day",0)) == int(s.get("day",1)) or game.get_available_money() <= 0
			var full_button = owner._add_button("تسویه کامل وام #%d — %d سکه" % [int(loan.get("id",loan_index+1)),int(loan.get("remaining",0))],owner,"repay_bank_loan",[loan_index])
			full_button.disabled = game.get_available_money() < int(loan.get("remaining",0))
	owner._add_label("🏧 سپرده‌گذاری",19)
	owner._add_label("سود کل سپرده: ۷ روز ۳٪ | ۱۴ روز ۷٪ | ۳۰ روز ۱۵٪؛ برداشت پیش از سررسید بدون سود است.",14)
	for deposit_option in [{"amount":500,"days":7},{"amount":1000,"days":14},{"amount":2500,"days":30}]:
		var deposit_button = owner._add_button("سپرده %d سکه‌ای — %d روزه" % [int(deposit_option.amount),int(deposit_option.days)],owner,"open_bank_deposit",[int(deposit_option.amount),int(deposit_option.days)])
		deposit_button.disabled = game.get_building_count("municipal_bank") <= 0 or game.get_available_money() < int(deposit_option.amount)
	for deposit_index in range(s.get("bank_deposits",[]).size()):
		var deposit = s.bank_deposits[deposit_index]
		var deposit_status = str(deposit.get("status","active"))
		if deposit_status == "withdrawn":
			continue
		owner._add_label("سپرده #%d | اصل: %d | سود: %d | سررسید: روز %d | %s" % [int(deposit.get("id",deposit_index+1)),int(deposit.get("principal",0)),int(deposit.get("interest",0)),int(deposit.get("maturity_day",0)),"آماده برداشت" if deposit_status == "matured" or int(s.day) >= int(deposit.get("maturity_day",0)) else "در حال سپرده"],15)
		owner._add_button("برداشت سپرده #%d" % int(deposit.get("id",deposit_index+1)),owner,"withdraw_bank_savings",[deposit_index])
	owner._add_label("📜 گردش حساب و سوابق مالی",19)
	if s.get("bank_transactions",[]).is_empty():
		owner._add_label("هنوز تراکنش بانکی ثبت نشده است.",15)
	else:
		for transaction_index in range(s.bank_transactions.size()-1,-1,-1):
			var transaction = s.bank_transactions[transaction_index]
			owner._add_label("روز %d | %s | %d سکه | %s" % [int(transaction.get("day",0)),str(transaction.get("kind","")),int(transaction.get("amount",0)),str(transaction.get("description",""))],14)

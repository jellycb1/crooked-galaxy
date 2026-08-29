extends SceneTree

const Model = preload("res://tools/rift_calendar_economy_model.gd")


func _init() -> void:
	print("Crooked Galaxy · 36-clear Rift economy calendar")
	for profile in Model.PROFILES:
		var result := Model.simulate(profile)
		print("\n%s · %d hunts · level %d · %d transports" % [str(result.id), int(result.hunts), int(result.final_level), int(result.transports)])
		print("  INCOME · Rift %d · missions %d · Daily %d · Weekly %d · Circuit %d · gross %d" % [int(result.rift_credits), int(result.mission_credits), int(result.daily_credits), int(result.weekly_credits), int(result.circuit_credits), int(result.gross_credits)])
		print("  PRESSURE · workshop %d/%d actions · transports %d · wallet %d · Rift share %.1f%%" % [int(result.workshop_credit_spend), int(result.workshop_actions), int(result.transport_credit_spend), int(result.final_credits), float(result.rift_credit_share) * 100.0])
		print("  RETENTION · %d circuits · %d Black Warrants · chips free/spent/shortfall %d/%d/%d" % [int(result.circuit_completions), int(result.black_warrants), int(result.free_warp_chips), int(result.premium_warp_chip_spend), int(result.purchased_chip_shortfall)])
	print("\nRIFT SERVICE · first calibration total %d · reward/service %.2f–%.2f" % [int(Model.simulate(Model.PROFILES[0]).rift_first_service_total), float(Model.simulate(Model.PROFILES[0]).minimum_service_ratio), float(Model.simulate(Model.PROFILES[0]).maximum_service_ratio)])
	quit(0)

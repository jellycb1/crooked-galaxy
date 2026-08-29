extends SceneTree

const Model = preload("res://tools/rift_calendar_economy_model.gd")

var failures := 0


func _init() -> void:
	var results: Array = Model.PROFILES.map(func(profile): return Model.simulate(profile))
	for result in results:
		check(int(result.days) == 36 and int(result.rift_credits) == 1059023, "%s completes the same authored 36-clear Rift calendar" % str(result.id))
		check(int(result.transports) == 4 and int(result.black_warrants) == 6, "%s can fund every transport and enter each sampled weekly operation" % str(result.id))
		check(int(result.circuit_completions) >= 4, "%s completes at least four full Network Circuits during five complete weeks" % str(result.id))
		check(int(result.workshop_actions) > 0 and int(result.workshop_credit_spend) > 0 and int(result.final_credits) > 0, "%s sustains real workshop pressure without entering a debt state" % str(result.id))
		check(float(result.minimum_service_ratio) >= 1.0 and float(result.maximum_service_ratio) <= 2.0, "%s advanced first clears fund one to two matching first services" % str(result.id))
	check(int(results[0].premium_warp_chip_spend) == 0 and int(results[1].premium_warp_chip_spend) == 0, "free profiles never consume premium currency")
	check(int(results[2].premium_warp_chip_spend) == 936 and int(results[2].purchased_chip_shortfall) == 900, "premium profile exposes the exact 36-day refill demand after earned chips")
	check(int(results[2].rift_credits) == int(results[0].rift_credits) and int(results[2].hunts) > int(results[0].hunts), "premium fuel buys more normal activity but never multiplies daily Rift rewards")
	check(float(results[0].rift_credit_share) >= 0.15 and float(results[0].rift_credit_share) <= 0.30, "Rift remains a meaningful minority of free balanced gross Credits")
	check(int(results[0].rift_first_service_total) == 624580, "all 24 advanced artifacts expose their exact first-service liability")
	finish()


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("  FAIL: %s" % description)


func finish() -> void:
	if failures == 0:
		print("PASS: the 36-clear Rift calendar is economically coherent across free and premium activity")
		quit(0)
	else:
		printerr("FAIL: %d Rift calendar economy test(s) failed" % failures)
		quit(1)

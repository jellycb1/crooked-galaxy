extends SceneTree

const Model = preload("res://tools/rift_year_one_chronology_model.gd")


func _init() -> void:
	print("Crooked Galaxy Rift year-one chronology · 55% audited baseline per attempt")
	for profile in Model.PROFILES:
		var result := Model.simulate(profile)
		print("\n%s · year-end L%d · daily clear %.1f%% · %.2f open days/clear · expected retry spend %.1f chips" % [
			str(result.id), int(result.final_level), float(result.daily_success_probability) * 100.0,
			float(result.expected_days_per_clear), float(result.expected_total_retry_chip_spend),
		])
		var level_days: Dictionary = result.level_milestone_days
		print("  late level gates · L160/%s · L170/%s · L180/%s · L190/%s · L200/%s" % [
			str(level_days.get(160, "—")), str(level_days.get(170, "—")), str(level_days.get(180, "—")),
			str(level_days.get(190, "—")), str(level_days.get(200, "—")),
		])
		for reality in result.realities:
			if not bool(reality.reachable):
				print("  %s · L%d not reached during year one" % [str(reality.id), int(reality.unlock_level)])
				continue
			if bool(reality.completed_in_year):
				print("  %s · level gate D%.0f · key D%.1f · complete D%.1f · perfect/pity bounds D%.0f/D%.0f" % [
					str(reality.id), float(reality.level_day), float(reality.expected_key_day), float(reality.expected_completion_day),
					float(reality.earliest_completion_day), float(reality.pity_first_try_completion_day),
				])
			else:
				var next_stage_index := int(reality.stages_reached)
				var next_level := int(reality.stage_calendar[next_stage_index].recommended_level) if next_stage_index < reality.stage_calendar.size() else 0
				print("  %s · level gate D%.0f · key D%.1f · %d/12 stages reachable in Y1 · next L%d" % [
					str(reality.id), float(reality.level_day), float(reality.expected_key_day), int(reality.stages_reached), next_level,
				])
	print("\nNOTE · chronology is a planning model, not a promise: it uses the live XP/fuel curve, real level gates, key pity and retry prices, with a declared 55% per-attempt combat baseline.")
	quit(0)

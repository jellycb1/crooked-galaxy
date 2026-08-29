class_name ArsenalView
extends RefCounted

const EquipmentPresentation = preload("res://scripts/equipment_presentation.gd")
const EquipmentGenerationRules = preload("res://scripts/equipment_generation_rules.gd")
const Rules = preload("res://scripts/core_rules.gd")
const Content = preload("res://scripts/content_db.gd")
const StateScript = preload("res://scripts/game_state.gd")
const ContractRules = preload("res://scripts/contract_rules.gd")
const LocaleRules = preload("res://scripts/locale_rules.gd")
const MissionRules = preload("res://scripts/mission_rules.gd")
const UIDesignSystem = preload("res://scripts/ui_design_system.gd")
const INVENTORY_PAGE_SIZE := 12


static func text(key: String, fallback: String = "", values: Array = []) -> String:
	return LocaleRules.text(key, fallback, values)


static func localized_content(prefix: String, definition: Dictionary, field: String) -> String:
	return text(LocaleRules.content_key(prefix, str(definition.get("id", "")), field), str(definition.get(field, "")))


static func localized_approach_name(approach_id: String, fallback: String = "CONTRATO BASE") -> String:
	if approach_id.is_empty() and fallback != "CONTRATO BASE":
		return fallback
	for approach in Content.contract_approaches():
		if str(approach.get("id", "")) == approach_id:
			return localized_content("approach", approach, "name")
	return text("COMMON_BASE_CONTRACT", fallback)


static func localized_field_defeat(context: Dictionary) -> String:
	if context.is_empty():
		return ""
	var tested_name := localized_approach_name(str(context.get("tested_approach_id", "")), str(context.get("tested_approach_name", "CONTRATO BASE"))).to_upper()
	var tested := "%s %d%%" % [tested_name, roundi(float(context.get("tested_odds", 0.0)) * 100.0)]
	if bool(context.get("overridden", false)):
		var chosen_name := localized_approach_name(str(context.get("chosen_approach_id", "")), str(context.get("chosen_approach_name", "CONTRATO BASE"))).to_upper()
		return text("COMBAT_OVERRIDE_DEFEAT", "OVERRIDE DERROTADO · TESTADA %s → ESCOLHIDA %s · REAVALIE A ROTA", [tested, chosen_name])
	return text("COMBAT_TESTED_ROUTE_FAILED", "ROTA TESTADA TAMBÉM FALHOU · %s · REFORCE A BUILD OU REVEJA O INCIDENTE", [tested])


static func build(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	content.add_theme_constant_override("separation", 14)
	var readiness := field_readiness(state)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(titles)
	titles.add_child(host.scene_title(text("ARSENAL_TITLE", "ARSENAL")))
	var subtitle_text := text("ARSENAL_BUILD_UPGRADES", "BUILD E MELHORIAS")
	if host.arsenal_section == "inventory":
		subtitle_text = text("ARSENAL_BACKPACK_COUNT", "MOCHILA · %d ITENS", [state.player.inventory.size()])
	elif host.arsenal_section == "workshop":
		subtitle_text = text("ARSENAL_WORKSHOP_SUBTITLE", "TESTE DE CAMPO · MELHORIAS")
	elif host.arsenal_section == "collection":
		subtitle_text = text("ARSENAL_COLLECTION_SUBTITLE", "CATÁLOGO PERMANENTE DE SÉRIES")
	var subtitle := host.readable_caption(subtitle_text)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(subtitle)
	if host.arsenal_section == "workshop" and not readiness.is_empty() and bool(readiness.target_available):
		var focused_target: Dictionary = readiness.target
		var analyze := host.secondary_action(text("ARSENAL_CHOOSE_ROUTE", "ESCOLHER ROTA"), host.LIME)
		analyze.name = "FieldReadinessAction"
		analyze.custom_minimum_size.x = 180
		var target_id := str(focused_target.id)
		analyze.pressed.connect(func():
			host.view_mode = "board"
			host.briefing_context = {
				"target_id": target_id,
				"approach_id": str(readiness.get("approach", {}).get("id", "")),
				"approach_name": str(readiness.get("approach", {}).get("name", "CONTRATO BASE")),
				"odds": float(readiness.get("current_odds", 0.0)),
			}
			state.select_bounty(focused_target)
		)
		title_row.add_child(analyze)
	var back := host.secondary_action(text("COMMON_BACK", "VOLTAR"), host.CYAN)
	back.custom_minimum_size.x = 150
	back.pressed.connect(func():
		host.view_mode = "board"
		host.board_section = "bounties"
		host.call("render")
	)
	title_row.add_child(back)
	content.add_child(section_tabs(host))
	match host.arsenal_section:
		"inventory":
			build_inventory_section(host, content, state)
		"workshop":
			build_workshop_section(host, content, state, readiness)
		"collection":
			build_collection_section(host, content, state)
		_:
			build_equipped_section(host, content, state, readiness)


static func section_tabs(host: CrookedUIFactory) -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.name = "ArsenalSectionTabs"
	tabs.add_theme_constant_override("separation", 8)
	for definition in [
		{"id": "equipped", "text": text("ARSENAL_EQUIPPED", "EQUIPADO"), "color": host.GOLD},
		{"id": "workshop", "text": text("ARSENAL_WORKSHOP_TAB", "OFICINA"), "color": host.LIME},
		{"id": "inventory", "text": text("ARSENAL_BACKPACK", "MOCHILA"), "color": host.CYAN},
		{"id": "collection", "text": text("ARSENAL_COLLECTION", "SÉRIES"), "color": host.CORAL},
	]:
		var section := str(definition.id)
		var selected := host.arsenal_section == section
		var tab := host.primary_action(str(definition.text), definition.color) if selected else host.secondary_action(str(definition.text), definition.color)
		tab.name = "ArsenalTab_%s" % section
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 76)
		tab.pressed.connect(func():
			host.arsenal_section = section
			host.call("render")
		)
		tabs.add_child(tab)
	return tabs


static func build_collection_section(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:
	var section := scrollable_section(content, "CollectionScroll")
	var progress := state.item_collection_progress()
	var overview := host.panel(VBoxContainer.new(), Color("#173356"), 16, 14)
	overview.name = "EquipmentCollectionOverview"
	var overview_box := overview.get_child(0) as VBoxContainer
	overview_box.add_child(host.label(text("ARSENAL_COLLECTION_PROGRESS", "CATÁLOGO DE SÉRIES · %d/%d", [int(progress.discovered), int(progress.total)]), UIDesignSystem.FONT_BODY, host.GOLD))
	var overview_hint := host.label(text("ARSENAL_COLLECTION_HINT", "Receber, comprar ou reciclar uma variante regista-a permanentemente."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	overview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview_box.add_child(overview_hint)
	section.add_child(overview)
	if state.last_notice_context == "collection" and not state.last_notice.is_empty():
		var receipt := host.panel(VBoxContainer.new(), Color("#173f48"), 12, 10)
		receipt.name = "CollectionClaimReceipt"
		var receipt_text := host.label(str(state.last_notice), UIDesignSystem.FONT_CAPTION, host.LIME)
		receipt_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(receipt.get_child(0) as VBoxContainer).add_child(receipt_text)
		section.add_child(receipt)
	section.add_child(collection_milestones_panel(host, state))
	var discovered: Array = state.player.get("discovered_item_variant_ids", [])
	var entries := Content.procedural_collection_entries()
	host.collection_planet_index = clampi(host.collection_planet_index, 0, Content.PLANETS.size() - 1)
	section.add_child(collection_planet_navigation(host))
	var planet: Dictionary = Content.PLANETS[host.collection_planet_index]
	var planet_id := str(planet.id)
	var planet_entries := entries.filter(func(entry): return str(entry.planet_id) == planet_id)
	var planet_discovered := 0
	for entry in planet_entries:
		for variant_id in EquipmentGenerationRules.VARIANT_IDS:
			if discovered.has("%s::%s" % [str(entry.template_id), str(variant_id)]):
				planet_discovered += 1
	var planet_panel := host.panel(VBoxContainer.new(), host.PANEL, 14, 12)
	planet_panel.name = "CollectionPlanet_%s" % planet_id
	var planet_box := planet_panel.get_child(0) as VBoxContainer
	planet_box.add_theme_constant_override("separation", 8)
	planet_box.add_child(host.label(text("ARSENAL_COLLECTION_PLANET", "%s · %d/%d", [localized_content("planet", planet, "name").to_upper(), planet_discovered, planet_entries.size() * EquipmentGenerationRules.VARIANT_IDS.size()]), UIDesignSystem.FONT_BODY, Color(str(planet.accent))))
	for entry in planet_entries:
		planet_box.add_child(collection_family_row(host, discovered, entry))
	section.add_child(planet_panel)


static func collection_planet_navigation(host: CrookedUIFactory) -> PanelContainer:
	var panel := host.panel(HBoxContainer.new(), Color("#101d38"), 12, 10)
	panel.name = "CollectionPlanetNavigation"
	var row := panel.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 8)
	var previous := host.secondary_action("‹", host.CYAN)
	previous.name = "CollectionPlanetPrevious"
	previous.custom_minimum_size = Vector2(56, 48)
	previous.disabled = host.collection_planet_index <= 0
	previous.pressed.connect(func(): change_collection_planet(host, -1))
	row.add_child(previous)
	var planet: Dictionary = Content.PLANETS[host.collection_planet_index]
	var status := host.center_label(text("COLLECTION_PLANET_PAGE", "%s · %d/%d", [localized_content("planet", planet, "name").to_upper(), host.collection_planet_index + 1, Content.PLANETS.size()]), UIDesignSystem.FONT_CAPTION, Color(str(planet.accent)))
	status.name = "CollectionPlanetPage"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(status)
	var next := host.secondary_action("›", host.CYAN)
	next.name = "CollectionPlanetNext"
	next.custom_minimum_size = Vector2(56, 48)
	next.disabled = host.collection_planet_index >= Content.PLANETS.size() - 1
	next.pressed.connect(func(): change_collection_planet(host, 1))
	row.add_child(next)
	return panel


static func change_collection_planet(host: CrookedUIFactory, direction: int) -> void:
	var next_index := clampi(host.collection_planet_index + direction, 0, Content.PLANETS.size() - 1)
	if next_index == host.collection_planet_index:
		return
	host.collection_planet_index = next_index
	host.reset_session_scroll("CollectionScroll", "collection_scroll_position")
	if host.has_method("render"):
		host.call("render")


static func collection_milestones_panel(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var panel := host.panel(VBoxContainer.new(), Color("#152a42"), 14, 12)
	panel.name = "CollectionMilestones"
	var box := panel.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	box.add_child(title_row)
	var milestones := state.collection_milestones()
	var claimed_count := milestones.filter(func(entry): return bool(entry.claimed)).size()
	var heading := host.label(text("COLLECTION_MILESTONES_SUMMARY", "MARCOS DO ARQUIVO · %d/%d", [claimed_count, milestones.size()]), UIDesignSystem.FONT_BODY, host.GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(heading)
	var ready_count := state.collection_rewards_ready()
	if ready_count > 0:
		var claim_all := host.primary_action(text("COLLECTION_CLAIM_ALL", "RESGATAR · %d", [ready_count]), host.LIME)
		claim_all.name = "ClaimAllCollectionMilestones"
		claim_all.custom_minimum_size.x = 132
		claim_all.pressed.connect(state.claim_all_collection_milestones)
		title_row.add_child(claim_all)
	var visible_milestones: Array[Dictionary] = []
	for milestone in milestones:
		if bool(milestone.complete) and not bool(milestone.claimed):
			visible_milestones.append(milestone)
			break
	if visible_milestones.is_empty():
		for milestone in milestones:
			if not bool(milestone.claimed):
				visible_milestones.append(milestone)
				break
	if visible_milestones.is_empty() and not milestones.is_empty():
		visible_milestones.append(milestones.back())
	for milestone in visible_milestones:
		var milestone_row := HBoxContainer.new()
		milestone_row.name = "CollectionMilestone_%s" % str(milestone.id)
		milestone_row.add_theme_constant_override("separation", 8)
		var status := "✓" if bool(milestone.claimed) else ("!" if bool(milestone.complete) else "·")
		var status_label := host.center_label(status, UIDesignSystem.FONT_BODY, host.LIME if bool(milestone.claimed) else (host.GOLD if bool(milestone.complete) else host.MUTED))
		status_label.custom_minimum_size = Vector2(28, 28)
		milestone_row.add_child(status_label)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_row.add_child(copy)
		copy.add_child(host.label(str(milestone.name), UIDesignSystem.FONT_CAPTION, host.INK if bool(milestone.complete) else host.MUTED))
		var progress_text := text("COLLECTION_MILESTONE_PROGRESS", "%d/%d REGISTADAS · +%d FICHAS", [mini(int(milestone.discovered), int(milestone.threshold)), int(milestone.threshold), int(milestone.warp_chips)])
		var progress_label := host.label(progress_text, UIDesignSystem.FONT_CAPTION, host.LIME if bool(milestone.claimed) else host.MUTED)
		progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(progress_label)
		if bool(milestone.complete) and not bool(milestone.claimed):
			var claim := host.secondary_action(text("ACTION_CLAIM", "RESGATAR"), host.GOLD)
			claim.name = "ClaimCollection_%s" % str(milestone.id)
			claim.custom_minimum_size.x = 110
			var milestone_id := str(milestone.id)
			claim.pressed.connect(func(): state.claim_collection_milestone(milestone_id))
			milestone_row.add_child(claim)
		box.add_child(milestone_row)
	var cadence_hint := host.label(text("COLLECTION_MILESTONE_CADENCE", "O arquivo mostra o próximo marco; recompensas concluídas podem ser resgatadas em conjunto."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	cadence_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(cadence_hint)
	return panel


static func collection_family_row(host: CrookedUIFactory, discovered: Array, entry: Dictionary) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.name = "CollectionFamily_%s" % str(entry.template_id)
	row.add_theme_constant_override("separation", 2)
	var found_variants: Array[String] = []
	var missing_variants: Array[String] = []
	for variant_id in EquipmentGenerationRules.VARIANT_IDS:
		var label_key := "ITEM_VARIANT_%s" % str(variant_id).to_upper()
		var fallback := text("ITEM_VARIANT_STANDARD", "SÉRIE PADRÃO") if str(variant_id) == "standard" else str(variant_id).to_upper()
		var variant_name := text(label_key, fallback)
		if discovered.has("%s::%s" % [str(entry.template_id), str(variant_id)]):
			found_variants.append(variant_name)
		else:
			missing_variants.append(variant_name)
	var representative := {
		"id": "collection_preview",
		"name": str(entry.name),
		"description": str(entry.description),
		"slot": str(entry.slot),
		"origin_planet_id": str(entry.planet_id),
		"variant_id": "standard",
	}
	var family_name := EquipmentPresentation.localized_item_field(representative, "name") if not found_variants.is_empty() else text("ARSENAL_COLLECTION_UNKNOWN", "SÉRIE DESCONHECIDA")
	var title := host.label(text("ARSENAL_COLLECTION_FAMILY", "%s · %s · %d/5", [family_name, EquipmentPresentation.localized_slot(str(entry.slot)).to_upper(), found_variants.size()]), UIDesignSystem.FONT_CAPTION, host.INK if not found_variants.is_empty() else host.MUTED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title)
	var status_text := text("ARSENAL_COLLECTION_FOUND", "REGISTADAS · %s", [", ".join(found_variants)]) if not found_variants.is_empty() else text("ARSENAL_COLLECTION_NONE", "NENHUMA VARIANTE REGISTADA")
	var status := host.label(status_text, UIDesignSystem.FONT_CAPTION, host.LIME if not found_variants.is_empty() else host.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(status)
	if not missing_variants.is_empty() and not found_variants.is_empty():
		var missing := host.label(text("ARSENAL_COLLECTION_MISSING", "EM FALTA · %s", [", ".join(missing_variants)]), UIDesignSystem.FONT_CAPTION, host.MUTED)
		missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(missing)
	return row


static func build_equipped_section(host: CrookedUIFactory, content: VBoxContainer, state: StateScript, readiness: Dictionary) -> void:
	var section := scrollable_section(content, "EquippedScroll")
	var notice_context := str(state.last_notice_context)
	if notice_context == "workshop" or notice_context.begins_with("reward_"):
		var notice_title := text("ARSENAL_WORKSHOP_LOG", "REGISTRO DA OFICINA") if notice_context == "workshop" else text("ARSENAL_CONTRACT_RECEIPT", "RECIBO DE CONTRATO")
		var notice := host.readable_caption("%s · %s" % [notice_title, state.last_notice], host.LIME)
		notice.name = "WorkshopNotice"
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(notice)
	section.add_child(host.readable_body(text("ARSENAL_WORKSHOP_STATUS", "OFICINA · ◈ %d · %d SUCATA · PODER TOTAL %d", [int(state.player.get("credits", 0)), int(state.player.get("scrap", 0)), Rules.player_power(state.player)]), host.GOLD))
	var set_origin := Rules.equipment_set_origin(state.player)
	var set_text := text("ARSENAL_KIT_INACTIVE", "KIT PLANETÁRIO · INATIVO · combine arma e armadura da mesma origem")
	var set_color := host.MUTED
	if not set_origin.is_empty():
		set_text = text("ARSENAL_KIT_ACTIVE", "KIT PLANETÁRIO · %s · +%d PODER · +%d VIDA", [localized_content("planet", Content.get_planet(set_origin), "name").to_upper(), Rules.PLANETARY_KIT_POWER_BONUS, Rules.PLANETARY_KIT_HEALTH_BONUS])
		set_color = host.LIME
	var set_label := host.readable_caption(set_text, set_color)
	set_label.name = "PlanetaryKitStatus"
	section.add_child(set_label)
	section.add_child(universal_equipment_grid(host, state))
	section.add_child(loadout_toolbar(host, state))


static func build_workshop_section(host: CrookedUIFactory, content: VBoxContainer, state: StateScript, readiness: Dictionary) -> void:
	var section := scrollable_section(content, "WorkshopScroll")
	var notice_context := str(state.last_notice_context)
	if notice_context == "workshop" or notice_context.begins_with("reward_"):
		var notice_title := text("ARSENAL_WORKSHOP_LOG", "REGISTRO DA OFICINA") if notice_context == "workshop" else text("ARSENAL_CONTRACT_RECEIPT", "RECIBO DE CONTRATO")
		var notice := host.readable_caption("%s · %s" % [notice_title, state.last_notice], host.LIME)
		notice.name = "WorkshopNotice"
		section.add_child(notice)
	section.add_child(host.readable_body(text("ARSENAL_WORKSHOP_STATUS", "OFICINA · ◈ %d · %d SUCATA · PODER TOTAL %d", [int(state.player.get("credits", 0)), int(state.player.get("scrap", 0)), Rules.player_power(state.player)]), host.GOLD))
	section.add_child(field_readiness_card(host, state, readiness))
	var workshop_recommendation := recommended_workshop_action(state, readiness)
	section.add_child(workshop_recommendation_card(host, state, workshop_recommendation, readiness))
	section.add_child(workshop_slot_selector(host, state))
	var equipped_row := VBoxContainer.new()
	equipped_row.name = "EquippedWorkbench"
	equipped_row.add_theme_constant_override("separation", 8)
	section.add_child(equipped_row)
	var selected_slot := resolved_workshop_slot(host, state)
	equipped_row.add_child(workshop_upgrade_card(host, state, selected_slot, workshop_recommendation))


static func resolved_workshop_slot(host: CrookedUIFactory, state: StateScript) -> String:
	var selected := str(host.workshop_slot)
	if Rules.EQUIPMENT_SLOTS.has(selected) and not state.player.get(selected, {}).is_empty():
		return selected
	for slot in Rules.EQUIPMENT_SLOTS:
		if not state.player.get(slot, {}).is_empty():
			host.workshop_slot = slot
			return slot
	return "weapon"


static func workshop_slot_selector(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var card := host.panel(VBoxContainer.new(), Color("#13233e"), 12, 10)
	card.name = "WorkshopSlotSelector"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	box.add_child(host.label(text("ARSENAL_WORKSHOP_SLOT_TITLE", "PEÇA NA BANCADA · ESCOLHA UM ESPAÇO EQUIPADO"), UIDesignSystem.FONT_CAPTION, host.CYAN))
	var grid := GridContainer.new()
	grid.name = "WorkshopSlotGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	var selected := resolved_workshop_slot(host, state)
	for slot_value in Rules.EQUIPMENT_SLOTS:
		var slot := str(slot_value)
		var item: Dictionary = state.player.get(slot, {})
		var active: bool = slot == selected
		var action := host.action_button(EquipmentPresentation.localized_slot(slot).to_upper(), host.GOLD if active else (host.CYAN if not item.is_empty() else host.MUTED), true)
		action.name = "WorkshopSlot_%s" % slot
		action.custom_minimum_size = Vector2(0, UIDesignSystem.TOUCH_TARGET_MIN)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.disabled = item.is_empty()
		action.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var slot_id: String = slot
		action.pressed.connect(func():
			host.workshop_slot = slot_id
			host.call("render")
		)
		grid.add_child(action)
	return card


static func scrollable_section(content: VBoxContainer, node_name: String) -> VBoxContainer:
	var scroller := ScrollContainer.new()
	scroller.name = node_name
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override("separation", 12)
	scroller.add_child(sheet)
	return sheet


static func build_inventory_section(host: CrookedUIFactory, content: VBoxContainer, state: StateScript) -> void:

	var page_data := paginated_inventory(host, state)
	var visible_items: Array = page_data.items
	content.add_child(inventory_header(host, page_data, state.player.inventory.size()))
	var collection := state.item_collection_progress()
	var collection_panel := host.panel(VBoxContainer.new(), Color("#173356"), 12, 10)
	collection_panel.name = "EquipmentCollectionProgress"
	var collection_box := collection_panel.get_child(0) as VBoxContainer
	collection_box.add_child(host.label(text("ARSENAL_COLLECTION_PROGRESS", "CATÁLOGO DE SÉRIES · %d/%d", [int(collection.discovered), int(collection.total)]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var collection_hint := host.label(text("ARSENAL_COLLECTION_HINT", "Receber, comprar ou reciclar uma variante regista-a permanentemente."), UIDesignSystem.FONT_CAPTION, host.MUTED)
	collection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_box.add_child(collection_hint)
	content.add_child(collection_panel)
	content.add_child(inventory_toolbar(host, state))
	var scroller := ScrollContainer.new()
	scroller.name = "InventoryScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroller.add_child(list)
	if visible_items.is_empty():
		var empty := host.panel(VBoxContainer.new(), host.PANEL, 24, 24)
		var empty_box := empty.get_child(0) as VBoxContainer
		empty_box.add_child(host.center_label(text("ARSENAL_FILTER_EMPTY", "Nenhuma peça neste filtro."), UIDesignSystem.FONT_BODY, host.MUTED))
		empty_box.add_child(host.center_label(text("ARSENAL_FILTER_EMPTY_HINT", "Outros compartimentos talvez estejam menos vazios."), UIDesignSystem.FONT_CAPTION, host.MUTED))
		list.add_child(empty)
	else:
		for item in visible_items:
			list.add_child(inventory_item_card(host, state, item))


static func filtered_inventory(host: CrookedUIFactory, state: StateScript) -> Array:
	return EquipmentPresentation.filtered_inventory(state.player.inventory, host.inventory_filter, host.inventory_sort)


static func paginated_inventory(host: CrookedUIFactory, state: StateScript) -> Dictionary:
	# Cards only read item dictionaries. Sorting references avoids deep-copying an
	# unbounded inventory before retaining the small visible page.
	var filtered := EquipmentPresentation.filtered_inventory_refs(state.player.inventory, host.inventory_filter, host.inventory_sort)
	var page_count := maxi(1, ceili(float(filtered.size()) / float(INVENTORY_PAGE_SIZE)))
	host.inventory_page = clampi(host.inventory_page, 0, page_count - 1)
	var first := host.inventory_page * INVENTORY_PAGE_SIZE
	var last := mini(filtered.size(), first + INVENTORY_PAGE_SIZE)
	return {
		"items": filtered.slice(first, last),
		"filtered_count": filtered.size(),
		"page": host.inventory_page,
		"page_count": page_count,
	}


static func inventory_header(host: CrookedUIFactory, page_data: Dictionary, inventory_count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "InventoryPager"
	row.add_theme_constant_override("separation", 8)
	var summary := host.label(text("ARSENAL_ITEM_COUNT", "ITENS · %d / %d", [int(page_data.filtered_count), inventory_count]), UIDesignSystem.FONT_CAPTION, host.MUTED)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(summary)
	if int(page_data.page_count) <= 1:
		return row
	var previous := host.action_button("‹", host.CYAN, true)
	previous.name = "InventoryPagePrevious"
	previous.custom_minimum_size = Vector2(UIDesignSystem.TOUCH_TARGET_MIN, UIDesignSystem.TOUCH_TARGET_MIN)
	previous.tooltip_text = text("ARSENAL_PREVIOUS_PAGE", "Página anterior do inventário")
	previous.disabled = int(page_data.page) <= 0
	previous.pressed.connect(func():
		host.inventory_page = maxi(0, host.inventory_page - 1)
		host.reset_session_scroll("InventoryScroll", "inventory_scroll_position")
		host.call("render")
	)
	row.add_child(previous)
	var status := host.center_label("%d / %d" % [int(page_data.page) + 1, int(page_data.page_count)], UIDesignSystem.FONT_CAPTION, host.GOLD)
	status.name = "InventoryPageStatus"
	status.custom_minimum_size = Vector2(64, UIDesignSystem.TOUCH_TARGET_MIN)
	row.add_child(status)
	var next := host.action_button("›", host.CYAN, true)
	next.name = "InventoryPageNext"
	next.custom_minimum_size = Vector2(UIDesignSystem.TOUCH_TARGET_MIN, UIDesignSystem.TOUCH_TARGET_MIN)
	next.tooltip_text = text("ARSENAL_NEXT_PAGE", "Próxima página do inventário")
	next.disabled = int(page_data.page) >= int(page_data.page_count) - 1
	next.pressed.connect(func():
		host.inventory_page = mini(int(page_data.page_count) - 1, host.inventory_page + 1)
		host.reset_session_scroll("InventoryScroll", "inventory_scroll_position")
		host.call("render")
	)
	row.add_child(next)
	return row


static func field_readiness(state: StateScript) -> Dictionary:
	var target_context := field_readiness_target_context(state)
	if target_context.is_empty():
		return {}
	var target: Dictionary = target_context.target
	var recovery_focus := bool(target_context.recovery_focus)
	var evaluations := ContractRules.evaluate_approaches(state.player, target, Content.contract_approaches())
	var recommended_id := ContractRules.recommended_approach_id(evaluations, str(state.player.get("class_id", "")))
	var contract := target
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			contract = evaluation.preview
			break
	var power_player := field_readiness_projection_player(state.player, "power")
	var health_player := field_readiness_projection_player(state.player, "health")
	var reinforced := not health_player.is_empty()
	if not reinforced:
		health_player = state.player
	return {
		"target": target,
		"contract": contract,
		"approach": contract.get("approach", {}),
		"current_odds": Rules.bounty_odds(state.player, contract),
		"power_odds": Rules.bounty_odds(power_player, contract),
		"health_odds": Rules.bounty_odds(health_player, contract),
		"can_reinforce": reinforced,
		"target_available": true,
		"recovery_focus": recovery_focus,
		"planet_tier": 0,
	}


static func field_readiness_target_context(state: StateScript) -> Dictionary:
	var offers := MissionRules.board_offers(state.player)
	if offers.is_empty():
		return {}
	var target: Dictionary = offers[mini(1, offers.size() - 1)]
	var recovery_focus := false
	if not state.combat_summary.is_empty() and not bool(state.combat_summary.get("won", true)):
		var defeated_id := str(state.combat_summary.get("target_id", state.current_bounty.get("id", "")))
		var defeated_target := Content.get_target(defeated_id)
		var recovery_offer := MissionRules.offer_for_target(state.player, defeated_target)
		if not recovery_offer.is_empty():
			target = recovery_offer
			recovery_focus = true
	return {"target": target, "recovery_focus": recovery_focus}


static func field_readiness_projection_player(player: Dictionary, kind: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score := Rules.player_build_score(player)
	if kind == "power":
		for slot in Rules.EQUIPMENT_SLOTS:
			var item: Dictionary = player.get(slot, {})
			if item.is_empty():
				continue
			var projected := player.duplicate(true)
			var powered: Dictionary = item.duplicate(true)
			powered.power = int(powered.get("power", 0)) + 1
			projected[slot] = powered
			var score := Rules.player_build_score(projected)
			if best.is_empty() or score > best_score:
				best = projected
				best_score = score
		return best if not best.is_empty() else player.duplicate(true)
	for slot in Rules.EQUIPMENT_SLOTS:
		var item: Dictionary = player.get(slot, {})
		if item.is_empty() or not Rules.can_upgrade_integrity(item):
			continue
		var projected := player.duplicate(true)
		var reinforced: Dictionary = item.duplicate(true)
		reinforced.integrity_upgrades = int(reinforced.get("integrity_upgrades", 0)) + 1
		projected[slot] = reinforced
		var score := Rules.player_build_score(projected)
		if best.is_empty() or score > best_score:
			best = projected
			best_score = score
	return best


static func warm_field_readiness_step(state: StateScript, step: int) -> bool:
	# The board has several idle frames before the player can reach the Arsenal.
	# Warm one deterministic estimate per frame so low-end phones never pay the
	# complete analysis spike on a navigation tap. Every result feeds the normal
	# bounded CoreRules cache; no parallel state or permanent resource is retained.
	var target_context := field_readiness_target_context(state)
	if target_context.is_empty():
		return true
	var target: Dictionary = target_context.target
	var approaches := Content.contract_approaches()
	if step < approaches.size():
		Rules.bounty_odds(state.player, Content.apply_approach(target, approaches[step]))
		return false
	var evaluations := ContractRules.evaluate_approaches(state.player, target, approaches)
	var recommended_id := ContractRules.recommended_approach_id(evaluations, str(state.player.get("class_id", "")))
	var contract := target
	for evaluation in evaluations:
		if str(evaluation.id) == recommended_id:
			contract = evaluation.preview
			break
	if step == approaches.size():
		Rules.bounty_odds(field_readiness_projection_player(state.player, "power"), contract)
		return false
	if step == approaches.size() + 1:
		var health_player := field_readiness_projection_player(state.player, "health")
		Rules.bounty_odds(health_player if not health_player.is_empty() else state.player, contract)
		return workshop_projection_candidates(state).is_empty()
	var projections := workshop_projection_candidates(state)
	var projection_index := step - approaches.size() - 2
	if projection_index >= projections.size():
		return true
	Rules.bounty_odds(projections[projection_index].player, contract)
	return projection_index == projections.size() - 1


static func field_readiness_card(host: CrookedUIFactory, state: StateScript, readiness: Dictionary = {}) -> PanelContainer:
	if readiness.is_empty():
		readiness = field_readiness(state)
	var card := host.panel(VBoxContainer.new(), Color("#13233e"), 16, 14)
	card.name = "FieldReadiness"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 10)
	if readiness.is_empty():
		box.add_child(host.label(text("ARSENAL_FIELD_TEST_UNAVAILABLE", "TESTE DE CAMPO INDISPONÍVEL"), UIDesignSystem.FONT_CAPTION, host.MUTED))
		return card
	var target: Dictionary = readiness.target
	var target_context := text("ARSENAL_REVENGE", "REVANCHE") if bool(readiness.get("recovery_focus", false)) else (text("ARSENAL_CURRENT_WARRANT", "MANDADO ATUAL") if bool(readiness.target_available) else text("ARSENAL_NEXT_WARRANT", "PRÓXIMO MANDADO"))
	var target_label := host.label(text("ARSENAL_FIELD_TEST_TARGET", "TESTE DE CAMPO · %s: %s", [target_context, localized_content("target", target, "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.GOLD)
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_label.name = "FieldReadinessTarget"
	box.add_child(target_label)
	if bool(readiness.get("recovery_focus", false)):
		var route_diagnosis_text := localized_field_defeat(state.combat_summary.get("field_test_context", {}))
		if not route_diagnosis_text.is_empty():
			var route_diagnosis := host.label(route_diagnosis_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
			route_diagnosis.name = "FieldReadinessRecoveryRoute"
			route_diagnosis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(route_diagnosis)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	box.add_child(metrics)
	metrics.add_child(host.metric_chip(text("ARSENAL_NOW", "AGORA"), "%d%%" % roundi(float(readiness.current_odds) * 100.0), readiness_color(host, float(readiness.current_odds))))
	metrics.add_child(host.metric_chip(text("ARSENAL_PLUS_POWER", "+1 PODER"), "%d%%" % roundi(float(readiness.power_odds) * 100.0), readiness_color(host, float(readiness.power_odds))))
	var health_title := text("ARSENAL_PLUS_HEALTH", "+8 VIDA") if bool(readiness.can_reinforce) else text("ARSENAL_MAX_REINFORCEMENT", "REF. MÁX.")
	metrics.add_child(host.metric_chip(health_title, "%d%%" % roundi(float(readiness.health_odds) * 100.0), readiness_color(host, float(readiness.health_odds))))
	var approach: Dictionary = readiness.get("approach", {})
	var approach_name := localized_content("approach", approach, "name").to_upper() if not approach.is_empty() else text("COMMON_BASE_CONTRACT", "CONTRATO BASE")
	var approach_label := host.label(text("ARSENAL_TESTED_APPROACH", "ABORDAGEM TESTADA · %s · incidentes ainda podem alterar as chances", [approach_name]), UIDesignSystem.FONT_CAPTION, host.MUTED)
	approach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	approach_label.name = "FieldReadinessApproach"
	box.add_child(approach_label)
	return card


static func readiness_color(host: CrookedUIFactory, odds: float) -> Color:
	return host.LIME if odds >= 0.72 else (host.GOLD if odds >= 0.42 else host.CORAL)


static func recommended_workshop_action(state: StateScript, readiness: Dictionary = {}) -> Dictionary:
	if readiness.is_empty():
		readiness = field_readiness(state)
	if readiness.is_empty():
		return {}
	var target: Dictionary = readiness.contract
	var current_odds := float(readiness.current_odds)
	var current_score := Rules.player_build_score(state.player)
	var best: Dictionary = {}
	var best_value := -1.0
	for candidate in workshop_projection_candidates(state):
		var slot := str(candidate.slot)
		var kind := str(candidate.kind)
		var cost := int(candidate.cost)
		var credit_cost := int(candidate.credit_cost)
		var simulated: Dictionary = candidate.player
		var item: Dictionary = state.player[slot]
		var projected_odds := Rules.bounty_odds(simulated, target)
		var odds_gain := maxf(0.0, projected_odds - current_odds)
		var score_gain := maxf(0.0, Rules.player_build_score(simulated) - current_score)
		# Scrap remains the scarce workshop resource; Credits contribute a smaller
		# normalized service weight so equal Scrap choices prefer the cheaper job.
		var normalized_cost := float(cost) + float(credit_cost) / 100.0
		var value := odds_gain / normalized_cost + score_gain / normalized_cost * 0.00001
		if value > best_value:
			best_value = value
			best = {
				"slot": slot,
				"kind": kind,
				"cost": cost,
				"credit_cost": credit_cost,
				"odds": projected_odds,
				"current_odds": current_odds,
				"odds_gain": odds_gain,
				"score_gain": score_gain,
				"item_name": EquipmentPresentation.localized_item_field(item, "name") if not item.is_empty() else host_slot_fallback(slot),
			}
	return best


static func workshop_projection_candidates(state: StateScript) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var scrap := int(state.player.get("scrap", 0))
	var credits := int(state.player.get("credits", 0))
	for slot in Rules.EQUIPMENT_SLOTS:
		var item: Dictionary = state.player[slot]
		if item.is_empty():
			continue
		var actions := [{"kind": "power", "cost": Rules.equipment_upgrade_cost(item), "credit_cost": Rules.equipment_upgrade_credit_cost(item)}]
		if Rules.can_upgrade_integrity(item):
			actions.append({"kind": "integrity", "cost": Rules.equipment_integrity_upgrade_cost(item), "credit_cost": Rules.equipment_integrity_credit_cost(item)})
		for action in actions:
			var cost := int(action.cost)
			if cost > scrap or int(action.credit_cost) > credits:
				continue
			var simulated := state.player.duplicate(true)
			var simulated_item: Dictionary = simulated[slot].duplicate(true)
			if str(action.kind) == "power":
				simulated_item.power = int(simulated_item.get("power", 0)) + 1
			else:
				simulated_item.integrity_upgrades = int(simulated_item.get("integrity_upgrades", 0)) + 1
			simulated[slot] = simulated_item
			candidates.append({"slot": slot, "kind": str(action.kind), "cost": cost, "credit_cost": int(action.credit_cost), "player": simulated})
	return candidates


static func host_slot_fallback(slot: String) -> String:
	return EquipmentPresentation.localized_slot(slot)


static func workshop_recommendation_card(host: CrookedUIFactory, state: StateScript, recommendation: Dictionary, readiness: Dictionary = {}) -> PanelContainer:
	# The 48 px action defines this strip's height; compact vertical padding preserves
	# a full inventory touch row in the 450x800 Android viewport.
	var card := host.panel(HBoxContainer.new(), Color("#19233a"), 16, 12)
	card.name = "WorkshopRecommendation"
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)
	if recommendation.is_empty():
		copy.add_child(host.label(text("ARSENAL_NEXT_INVESTMENT", "PRÓXIMO INVESTIMENTO"), UIDesignSystem.FONT_CAPTION, host.GOLD))
		var unavailable := host.label(text("ARSENAL_NO_AFFORDABLE_UPGRADE", "Nenhuma melhoria cabe nos saldos atuais de Créditos e Sucata."), UIDesignSystem.FONT_BODY, host.MUTED)
		unavailable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(unavailable)
		return card
	var slot := str(recommendation.slot)
	var kind := str(recommendation.kind)
	var action_name := text("ARSENAL_PLUS_POWER", "+1 PODER") if kind == "power" else text("ARSENAL_HEALTH_GAIN", "+%d VIDA", [Rules.INTEGRITY_HEALTH_PER_LEVEL])
	copy.add_child(host.label(text("ARSENAL_BEST_INVESTMENT", "MELHOR INVESTIMENTO · %s", [EquipmentPresentation.localized_slot(slot).to_upper()]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var item_line := host.label("%s · %s" % [str(recommendation.item_name), action_name], UIDesignSystem.FONT_BODY, host.INK)
	item_line.custom_minimum_size = Vector2.ZERO
	item_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(item_line)
	var current_percent := roundi(float(recommendation.get("current_odds", readiness.get("current_odds", 0.0))) * 100.0)
	var projected_percent := roundi(float(recommendation.odds) * 100.0)
	var impact := text("ARSENAL_TEST_IMPACT", "%d%% → %d%% no teste", [current_percent, projected_percent])
	if projected_percent == current_percent:
		impact = text("ARSENAL_ODDS_CAPPED", "chance já no limite · impacto de build +%d", [maxi(1, roundi(float(recommendation.get("score_gain", 1.0))))])
	copy.add_child(host.label(text("ARSENAL_WORKSHOP_COST_IMPACT", "◈ %d · %d sucata · %s", [int(recommendation.credit_cost), int(recommendation.cost), impact]), UIDesignSystem.FONT_CAPTION, host.LIME))
	var apply := host.action_button(text("ARSENAL_APPLY", "APLICAR"), host.LIME, true)
	apply.name = "RecommendedWorkshopAction"
	apply.custom_minimum_size = Vector2(132, UIDesignSystem.SECONDARY_ACTION_HEIGHT)
	apply.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	apply.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	apply.tooltip_text = text("ARSENAL_APPLY_TOOLTIP", "Executa a melhoria com o melhor ganho projetado pelo custo total da oficina.")
	if kind == "power":
		apply.pressed.connect(func(): state.upgrade_equipped(slot))
	else:
		apply.pressed.connect(func(): state.reinforce_equipped(slot))
	row.add_child(apply)
	return card


static func inventory_toolbar(host: CrookedUIFactory, state: StateScript) -> VBoxContainer:
	var toolbar := VBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 7)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	toolbar.add_child(filters)
	for definition in [
		{"id": "all", "text": text("ARSENAL_FILTER_ALL", "TODOS")},
		{"id": "weapon", "text": text("ARSENAL_FILTER_WEAPONS", "ARMAS")},
		{"id": "armor", "text": text("ARSENAL_FILTER_ARMOR", "TRAJES")},
		{"id": "other", "text": text("ARSENAL_FILTER_OTHER", "OUTROS")},
	]:
		var mode := str(definition.id)
		var selected := host.inventory_filter == mode
		var filter_button := host.action_button(str(definition.text), host.CYAN if selected else host.MUTED, not selected)
		filter_button.name = "InventoryFilter_%s" % mode
		filter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_button.custom_minimum_size = Vector2(0, 72)
		filter_button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		filter_button.pressed.connect(func():
			host.inventory_filter = mode
			host.inventory_page = 0
			host.reset_session_scroll("InventoryScroll", "inventory_scroll_position")
			host.call("render")
		)
		filters.add_child(filter_button)
	var utility_row := HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 6)
	toolbar.add_child(utility_row)
	var sort := host.action_button(text("ARSENAL_SORT", "ORDEM · %s", [text("ARSENAL_RARITY", "RARIDADE") if host.inventory_sort == "rarity" else text("COMMON_POWER", "PODER")]), host.GOLD, true)
	sort.name = "InventorySort"
	sort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort.custom_minimum_size = Vector2(0, 72)
	sort.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	sort.pressed.connect(func():
		host.inventory_sort = "rarity" if host.inventory_sort == "power" else "power"
		host.inventory_page = 0
		host.reset_session_scroll("InventoryScroll", "inventory_scroll_position")
		host.call("render")
	)
	utility_row.add_child(sort)
	var preview := state.inferior_recycle_preview()
	var recycle := host.action_button(text("ARSENAL_RECYCLE_BULK", "RECICLAR · %d · +%d", [int(preview.count), int(preview.scrap)]), host.CORAL if int(preview.count) > 0 else host.MUTED, true)
	recycle.name = "RecycleInferior"
	recycle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recycle.disabled = int(preview.count) <= 0
	recycle.custom_minimum_size = Vector2(0, 72)
	recycle.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	recycle.tooltip_text = text("ARSENAL_RECYCLE_BULK_TOOLTIP", "Recicla apenas peças comuns sem modificações ou investimento que não superam o efeito atual.")
	recycle.pressed.connect(state.recycle_inferior_inventory)
	utility_row.add_child(recycle)
	return toolbar


static func loadout_toolbar(host: CrookedUIFactory, state: StateScript) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.name = "LoadoutToolbar"
	row.add_theme_constant_override("separation", 10)
	for index in 2:
		var loadouts: Array = state.player.get("equipment_loadouts", [])
		var loadout: Dictionary = loadouts[index] if index < loadouts.size() else {}
		var weapon := state.inventory_item_by_id(str(loadout.get("weapon_id", "")))
		var armor := state.inventory_item_by_id(str(loadout.get("armor_id", "")))
		var ready := not weapon.is_empty() and not armor.is_empty()
		var card := host.panel(VBoxContainer.new(), Color("#0d1530"), 11, 12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2.ZERO
		row.add_child(card)
		var box := card.get_child(0) as VBoxContainer
		box.add_child(host.label(text("ARSENAL_LOADOUT", "LOADOUT · %s", [state.loadout_name(index)]), UIDesignSystem.FONT_CAPTION, host.GOLD))
		var saved_count := 0
		for slot in Rules.EQUIPMENT_SLOTS:
			if not str(loadout.get("%s_id" % slot, "")).is_empty():
				saved_count += 1
		var weapon_name := EquipmentPresentation.localized_item_field(weapon, "name") if not weapon.is_empty() else text("ARSENAL_NOT_SAVED", "não salvo")
		var armor_name := EquipmentPresentation.localized_item_field(armor, "name") if not armor.is_empty() else text("ARSENAL_NOT_SAVED", "não salvo")
		var summary := text("ARSENAL_LOADOUT_SUMMARY", "%d/%d PEÇAS · %s / %s", [saved_count, Rules.EQUIPMENT_SLOTS.size(), weapon_name, armor_name])
		var summary_label := host.label(summary, UIDesignSystem.FONT_CAPTION, host.MUTED)
		summary_label.custom_minimum_size = Vector2.ZERO
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_label.max_lines_visible = 2
		box.add_child(summary_label)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 5)
		box.add_child(actions)
		var save := host.secondary_action(text("ARSENAL_SAVE", "SALVAR"), host.CYAN)
		save.name = "SaveLoadout_%d" % index
		save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		save.custom_minimum_size.x = 0
		save.pressed.connect(func(): state.save_equipment_loadout(index))
		actions.add_child(save)
		var apply := host.secondary_action(text("ARSENAL_USE", "USAR"), host.LIME if ready else host.MUTED)
		apply.name = "ApplyLoadout_%d" % index
		apply.disabled = not ready
		apply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		apply.custom_minimum_size.x = 0
		apply.pressed.connect(func(): state.apply_equipment_loadout(index))
		actions.add_child(apply)
	return row


static func inventory_item_card(host: CrookedUIFactory, state: StateScript, item: Dictionary) -> PanelContainer:
	var card := host.panel(HBoxContainer.new(), host.PANEL, 15, 15)
	card.name = "InventoryItem_%s" % str(item.get("id", "unknown"))
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var icon := host.equipment_icon(item, 58)
	icon.name = "EquipmentIcon_%s" % str(item.get("id", "unknown"))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.custom_minimum_size = Vector2.ZERO
	row.add_child(details)
	var item_name := host.label(EquipmentPresentation.localized_item_field(item, "name"), UIDesignSystem.FONT_BODY, host.INK)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name.max_lines_visible = 2
	details.add_child(item_name)
	var stat_line := host.label(text("ARSENAL_ITEM_STATS", "%s · %s · +%d poder", [EquipmentPresentation.localized_rarity(str(item.rarity)), EquipmentPresentation.localized_slot(str(item.slot)), int(item.power)]), UIDesignSystem.FONT_CAPTION, Color(str(item.color)))
	stat_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat_line.max_lines_visible = 2
	details.add_child(stat_line)
	var procedural_identity := EquipmentPresentation.procedural_identity_text(item)
	if not procedural_identity.is_empty():
		var identity_line := host.label(procedural_identity, UIDesignSystem.FONT_CAPTION, host.CYAN)
		identity_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(identity_line)
	var origin_id := str(item.get("origin_planet_id", ""))
	if not origin_id.is_empty():
		var origin_line := host.label(text("REWARD_ORIGIN", "ORIGEM · %s", [localized_content("planet", Content.get_planet(origin_id), "name").to_upper()]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		origin_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		origin_line.max_lines_visible = 2
		details.add_child(origin_line)
	if Rules.has_workshop_investment(item):
		var workshop_parts: Array[String] = []
		if int(item.get("power_upgrades", 0)) > 0:
			workshop_parts.append(text("ARSENAL_CALIBRATIONS", "%d calib.", [int(item.power_upgrades)]))
		if int(item.get("integrity_upgrades", 0)) > 0:
			workshop_parts.append(text("ARSENAL_REINFORCEMENTS", "%d reforços · +%d vida", [int(item.integrity_upgrades), int(item.integrity_upgrades) * Rules.INTEGRITY_HEALTH_PER_LEVEL]))
		var workshop_line := host.label(text("ARSENAL_WORKSHOP_ITEM", "◇ OFICINA · %s", [" · ".join(workshop_parts)]), UIDesignSystem.FONT_CAPTION, host.CYAN)
		workshop_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		workshop_line.max_lines_visible = 2
		details.add_child(workshop_line)
	var modifier_text := EquipmentPresentation.modifier_text(item)
	if not modifier_text.is_empty():
		var trait_line := host.label("◆ %s" % modifier_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
		trait_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_line.max_lines_visible = 3
		details.add_child(trait_line)
	var current: Dictionary = state.player[str(item.slot)]
	var equipped := str(current.get("id", "")) == str(item.get("id", ""))
	var simulated := state.player.duplicate(true)
	simulated[str(item.slot)] = item
	var score_difference := Rules.player_build_score(simulated) - Rules.player_build_score(state.player)
	var comparison_text := text("ARSENAL_EQUIPPED", "EQUIPADO") if equipped else EquipmentPresentation.equipment_delta_text(state.player, item)
	var status := host.label(comparison_text, UIDesignSystem.FONT_CAPTION, host.LIME if score_difference > 0 or equipped else (host.GOLD if score_difference == 0 else host.MUTED))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(status)
	if not equipped:
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		row.add_child(buttons)
		var equip_button := host.action_button(text("ARSENAL_EQUIP", "EQUIPAR"), host.CYAN, true)
		equip_button.custom_minimum_size = Vector2(128, 72)
		equip_button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		var item_id := str(item.id)
		equip_button.pressed.connect(func(): state.equip_from_inventory(item_id))
		buttons.add_child(equip_button)
		var manually_locked: bool = state.player.get("locked_item_ids", []).has(item_id)
		var lock_button := host.action_button(text("ARSENAL_UNLOCK", "LIBERAR") if manually_locked else text("ARSENAL_PROTECT", "PROTEGER"), host.GOLD, true)
		lock_button.name = "Lock_%s" % item_id
		lock_button.custom_minimum_size = Vector2(128, 72)
		lock_button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		lock_button.pressed.connect(func(): state.toggle_item_lock(item_id))
		buttons.add_child(lock_button)
		var scrap_button := host.action_button(text("ARSENAL_RECYCLE_ITEM", "RECICLAR +%d", [Rules.salvage_value(item)]), host.CORAL, true)
		scrap_button.name = "Scrap_%s" % item_id
		scrap_button.custom_minimum_size = Vector2(128, 72)
		scrap_button.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
		scrap_button.disabled = state.is_item_protected(item_id)
		scrap_button.pressed.connect(func(): state.scrap_item(item_id))
		buttons.add_child(scrap_button)
	return card


static func workshop_upgrade_card(host: CrookedUIFactory, state: StateScript, slot: String, recommendation: Dictionary = {}) -> PanelContainer:
	var item: Dictionary = state.player[slot]
	var power_cost := Rules.equipment_upgrade_cost(item)
	var integrity_cost := Rules.equipment_integrity_upgrade_cost(item)
	var power_credit_cost := Rules.equipment_upgrade_credit_cost(item)
	var integrity_credit_cost := Rules.equipment_integrity_credit_cost(item)
	var power_affordable := int(state.player.get("scrap", 0)) >= power_cost and int(state.player.get("credits", 0)) >= power_credit_cost
	var integrity_affordable := int(state.player.get("scrap", 0)) >= integrity_cost and int(state.player.get("credits", 0)) >= integrity_credit_cost
	var integrity_level := int(item.get("integrity_upgrades", 0))
	var calibration_level := int(item.get("power_upgrades", 0))
	var integrity_available := Rules.can_upgrade_integrity(item)
	var card := host.panel(HBoxContainer.new(), Color("#0d1530"), 16, 14)
	card.name = "EquippedSlot_%s" % slot
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2.ZERO
	var row := card.get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 12)
	var icon := host.equipment_icon(item, 72)
	icon.name = "EquippedWorkbenchIcon_%s" % slot
	row.add_child(icon)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(box)
	box.add_child(host.label(EquipmentPresentation.localized_slot(slot).to_upper(), UIDesignSystem.FONT_CAPTION, host.MUTED))
	var item_label := host.label("%s · +%d" % [EquipmentPresentation.localized_item_field(item, "name"), int(item.power)], UIDesignSystem.FONT_BODY, host.INK)
	item_label.custom_minimum_size = Vector2.ZERO
	item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_label.max_lines_visible = 2
	box.add_child(item_label)
	var workshop_status := host.label(text("ARSENAL_UPGRADE_STATUS", "CAL %d · REF %d/%d · +%d VIDA", [calibration_level, integrity_level, Rules.MAX_INTEGRITY_UPGRADES, integrity_level * Rules.INTEGRITY_HEALTH_PER_LEVEL]), UIDesignSystem.FONT_CAPTION, host.CYAN if calibration_level > 0 or integrity_level > 0 else host.MUTED)
	workshop_status.custom_minimum_size = Vector2.ZERO
	workshop_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	workshop_status.max_lines_visible = 2
	box.add_child(workshop_status)
	var modifier_text := EquipmentPresentation.modifier_text(item)
	if not modifier_text.is_empty():
		var trait_label := host.label("◆ %s" % modifier_text, UIDesignSystem.FONT_CAPTION, host.GOLD)
		trait_label.custom_minimum_size = Vector2.ZERO
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_label.max_lines_visible = 2
		box.add_child(trait_label)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	row.add_child(actions)
	var improve := host.action_button(text("ARSENAL_UPGRADE_POWER_DUAL", "+1 PODER\n◈ %d · %d SUC", [power_credit_cost, power_cost]), host.LIME if power_affordable else host.MUTED, true)
	if str(recommendation.get("slot", "")) == slot and str(recommendation.get("kind", "")) == "power":
		improve.text = "★ " + improve.text
		improve.tooltip_text = text("ARSENAL_RECOMMENDED_TOOLTIP", "Melhor ganho projetado pelo custo total contra o alvo do teste de campo.")
	improve.name = "Upgrade_%s" % slot
	improve.disabled = not power_affordable
	improve.custom_minimum_size = Vector2(168, UIDesignSystem.SECONDARY_ACTION_HEIGHT)
	improve.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	improve.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	improve.pressed.connect(func(): state.upgrade_equipped(slot))
	actions.add_child(improve)
	var reinforce_text := text("ARSENAL_REINFORCE_HEALTH_DUAL", "+%d VIDA\n◈ %d · %d SUC", [Rules.INTEGRITY_HEALTH_PER_LEVEL, integrity_credit_cost, integrity_cost]) if integrity_available else text("ARSENAL_MAX_INTEGRITY", "INTEGRIDADE MÁX.")
	var reinforce := host.action_button(reinforce_text, host.CYAN if integrity_affordable and integrity_available else host.MUTED, true)
	if str(recommendation.get("slot", "")) == slot and str(recommendation.get("kind", "")) == "integrity":
		reinforce.text = "★ " + reinforce.text
		reinforce.tooltip_text = text("ARSENAL_RECOMMENDED_TOOLTIP", "Melhor ganho projetado pelo custo total contra o alvo do teste de campo.")
	reinforce.name = "Reinforce_%s" % slot
	reinforce.disabled = not integrity_affordable or not integrity_available
	reinforce.custom_minimum_size = Vector2(168, UIDesignSystem.SECONDARY_ACTION_HEIGHT)
	reinforce.add_theme_font_size_override("font_size", UIDesignSystem.FONT_CAPTION)
	reinforce.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reinforce.pressed.connect(func(): state.reinforce_equipped(slot))
	actions.add_child(reinforce)
	return card


static func universal_equipment_grid(host: CrookedUIFactory, state: StateScript) -> PanelContainer:
	var card := host.illustrated_panel(VBoxContainer.new(), 8)
	card.name = "UniversalEquipmentCard"
	var box := card.get_child(0) as VBoxContainer
	box.add_theme_constant_override("separation", 7)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var title := host.label(text("ARSENAL_UNIVERSAL_SHEET", "FICHA UNIVERSAL"), UIDesignSystem.FONT_EMPHASIS, host.CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(host.label(text("ARSENAL_EQUIPPED_COUNT", "%d / %d EQUIPADOS", [Rules.equipped_item_count(state.player), Rules.EQUIPMENT_SLOTS.size()]), UIDesignSystem.FONT_CAPTION, host.GOLD))
	var active_secondary: Array[String] = []
	for slot_id in Content.loot_slots_for_planet(str(state.player.get("current_planet_id", "dustball_prime"))):
		if slot_id != "weapon" and slot_id != "armor" and not active_secondary.has(slot_id):
			active_secondary.append(slot_id)
	var drop_status := text("ARSENAL_NEXT_SECONDARY_DROP", "PRÓXIMO DROP SECUNDÁRIO · CAPACETE EM CONGELÁRIA S.A.")
	if not active_secondary.is_empty():
		var active_names: Array[String] = []
		for slot_id in active_secondary:
			active_names.append(EquipmentPresentation.localized_slot(slot_id).to_upper())
		drop_status = text("ARSENAL_FRONTIER_DROPS", "DROPS NESTA FRONTEIRA · %s", [" · ".join(active_names)])
	var progression := host.readable_caption(drop_status, host.LIME if not active_secondary.is_empty() else host.MUTED)
	progression.name = "SecondaryEquipmentProgression"
	progression.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(progression)
	var grid := GridContainer.new()
	grid.name = "UniversalEquipmentGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for slot_id in Rules.EQUIPMENT_SLOTS:
		var item: Dictionary = state.player.get(slot_id, {})
		var slot_panel := host.panel(HBoxContainer.new(), Color("#090f25"), 9, 8)
		slot_panel.name = "UniversalSlot_%s" % slot_id
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := slot_panel.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", 5)
		var icon_item := item.duplicate(true)
		icon_item.slot = slot_id
		row.add_child(host.equipment_icon(icon_item, 46))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(host.label(EquipmentPresentation.localized_slot(slot_id).to_upper(), UIDesignSystem.FONT_CAPTION, host.MUTED))
		var value := host.label("+%d" % int(item.get("power", 0)) if not item.is_empty() else text("HUNTER_EMPTY", "VAZIO"), UIDesignSystem.FONT_CAPTION, host.GOLD if not item.is_empty() else host.MUTED)
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(value)
		slot_panel.tooltip_text = EquipmentPresentation.localized_item_field(item, "name") if not item.is_empty() else text("ARSENAL_FUTURE_LOOT_SLOT", "Espaço reservado para loot futuro")
		grid.add_child(slot_panel)
	return card

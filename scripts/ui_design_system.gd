class_name CrookedUIDesignSystem
extends RefCounted

## Canonical measurements for the Android-first UI rebuild.
##
## Godot lays the game out at 720x1280 and scales it to the 450x800 physical
## target. Every number below is therefore expressed in logical pixels. Keeping
## the conversion here prevents a technically valid desktop layout from becoming
## unreadable on the real phone again.

const LOGICAL_VIEWPORT := Vector2(720.0, 1280.0)
const PHYSICAL_TARGET := Vector2(450.0, 800.0)
const TARGET_SCALE := PHYSICAL_TARGET.x / LOGICAL_VIEWPORT.x

const SAFE_MARGIN_X := 42
const SAFE_MARGIN_TOP := 28
const SAFE_MARGIN_BOTTOM := 24
const SHELL_GAP := 16
const HEADER_HEIGHT := 112
const NAVIGATION_HEIGHT := 104

const FONT_CAPTION := 18
const FONT_BODY := 21
const FONT_EMPHASIS := 24
const FONT_SECTION_TITLE := 28
const FONT_SCREEN_TITLE := 36
const FONT_DISPLAY := 44

const TOUCH_TARGET_MIN := 72
const PRIMARY_ACTION_HEIGHT := 88
const SECONDARY_ACTION_HEIGHT := 76
const NAVIGATION_ACTION_HEIGHT := 92

const FOCAL_ART_MIN_HEIGHT := 360
const FOCAL_PANEL_MIN_HEIGHT := 280
const SUPPORT_PANEL_PADDING := 18
const FOCAL_PANEL_PADDING := 24
const CONTROL_GAP := 12
const SECTION_GAP := 20

const MAX_SIMULTANEOUS_PRIMARY_ACTIONS := 3
const MAX_SUPPORT_SURFACES := 3
const MIN_PHYSICAL_FONT_PX := 11.0
const MIN_PHYSICAL_TOUCH_PX := 44.0

const SCREEN_COMPOSITIONS := {
	"board": {
		"subject": "target",
		"primary_action": "inspect_approaches",
		"support": ["offer_switcher", "reward_summary"],
		"secondary_sheet": ["tutorial", "mastery", "travel_detail"],
	},
	"hunter": {
		"subject": "hunter",
		"primary_action": "manage_build",
		"support": ["equipment", "attributes"],
		"secondary_sheet": ["class_detail", "derived_stats", "history"],
	},
	"arsenal": {
		"subject": "equipped_item",
		"primary_action": "equip_or_upgrade",
		"support": ["equipment_slots", "inventory_switcher"],
		"secondary_sheet": ["filters", "comparison", "recycling"],
	},
	"hangar": {
		"subject": "transport",
		"primary_action": "select_transport",
		"support": ["travel_saving", "transport_switcher"],
		"secondary_sheet": ["upgrade_detail", "collection"],
	},
	"combat": {
		"subject": "duel",
		"primary_action": "combat_pace",
		"support": ["health", "latest_exchange"],
		"secondary_sheet": ["combat_log", "build_detail"],
	},
}


static func physical_pixels(logical_pixels: float) -> float:
	return logical_pixels * TARGET_SCALE


static func is_readable_font(logical_font_size: int) -> bool:
	return physical_pixels(float(logical_font_size)) >= MIN_PHYSICAL_FONT_PX


static func is_safe_touch_target(logical_height: float) -> bool:
	return physical_pixels(logical_height) >= MIN_PHYSICAL_TOUCH_PX


static func stage_height() -> float:
	return LOGICAL_VIEWPORT.y - SAFE_MARGIN_TOP - SAFE_MARGIN_BOTTOM - HEADER_HEIGHT - NAVIGATION_HEIGHT - SHELL_GAP * 2.0


static func composition_for(screen_id: String) -> Dictionary:
	return (SCREEN_COMPOSITIONS.get(screen_id, {}) as Dictionary).duplicate(true)


static func validate_visible_action_count(action_count: int) -> bool:
	return action_count >= 1 and action_count <= MAX_SIMULTANEOUS_PRIMARY_ACTIONS

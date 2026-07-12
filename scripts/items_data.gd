class_name ItemsData
extends RefCounted
## Canonical item identifiers (mirrors docs/items.md IDs so saves, loot and merchant agree).
## Centralized here to avoid string drift across systems. See docs/roadmap.md M9/M10.

## Item categories for HUD grouping / save filtering.
enum Category { CURRENCY, ACCESS, FOOD, FUEL, RARE, EQUIPMENT, ARTIFACT }

const COIN := &"COIN"
const KEY := &"KEY"

const APPLE := &"APPLE"
const COOKIE := &"COOKIE"
const CHEESE := &"CHEESE"
const PIE := &"PIE"

const OIL_SMALL := &"OIL_SMALL"
const OIL_LARGE := &"OIL_LARGE"

const REP_SPRAY := &"REP_SPRAY"
const LIFE_AMULET := &"LIFE_AMULET"

const CLOAK := &"CLOAK"
const FIRE_MAGIC := &"FIRE_MAGIC"
const NIGHT_VISION := &"NIGHT_VISION"
const DANGER_SENSE := &"DANGER_SENSE"
const SLEEP_POTION := &"SLEEP_POTION"
const CODEX_BLOOD := &"CODEX_BLOOD"

## Items that can stack in the inventory (everything except artifacts, which are unique).
static var STACKABLE := PackedStringArray(
	[
		COIN,
		KEY,
		APPLE,
		COOKIE,
		CHEESE,
		PIE,
		OIL_SMALL,
		OIL_LARGE,
		REP_SPRAY,
		LIFE_AMULET,
		CLOAK,
		FIRE_MAGIC,
		NIGHT_VISION,
		DANGER_SENSE,
		SLEEP_POTION
	]
)

## Artifacts are unique (one per run) and tracked separately.
static var ARTIFACTS := PackedStringArray([CODEX_BLOOD])


static func is_stackable(id: StringName) -> bool:
	return id in STACKABLE


static func is_artifact(id: StringName) -> bool:
	return id in ARTIFACTS

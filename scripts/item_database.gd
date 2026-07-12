class_name ItemDatabase
extends RefCounted
## Loads the canonical item table (data/items.json) and serves lookups.
## Effects are interpreted by ItemManager (M10). See docs/roadmap.md M10 and docs/items.md.

var _by_id: Dictionary = {}  # StringName -> Dictionary


func load_from(path: String) -> void:
	_by_id.clear()
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ItemDatabase: failed to read %s" % path)
		return
	var parsed := JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("items"):
		push_error("ItemDatabase: bad schema in %s" % path)
		return
	for entry in parsed["items"]:
		var id := StringName(entry["id"])
		_by_id[id] = entry


func is_loaded() -> bool:
	return not _by_id.is_empty()


func get_def(id: StringName) -> Dictionary:
	return _by_id.get(id, {})


func has(id: StringName) -> bool:
	return _by_id.has(id)


func all_ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for id in _by_id.keys():
		out.append(id)
	return out


func effect_type(id: StringName) -> String:
	var def := get_def(id)
	if def.is_empty() or not def.has("effect"):
		return "none"
	return def["effect"].get("effect_type", def["effect"].get("type", "none"))


func effect_value(id: StringName) -> float:
	var def := get_def(id)
	if def.is_empty() or not def.has("effect"):
		return 0.0
	return float(def["effect"].get("value", 0))

class_name LevelCatalog
extends RefCounted


const LEVELS := {
	&"level_01": {
		"title": "Mosslight Run",
		"scene": "res://scenes/levels/level_01.tscn",
		"required_level": &"",
	},
}


static func has_level(level_id: StringName) -> bool:
	return LEVELS.has(level_id)


static func get_scene_path(level_id: StringName) -> String:
	if not LEVELS.has(level_id):
		return ""
	return LEVELS[level_id]["scene"] as String


static func get_title(level_id: StringName) -> String:
	if not LEVELS.has(level_id):
		return "Unknown Level"
	return LEVELS[level_id]["title"] as String


static func get_level_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for level_id: StringName in LEVELS.keys():
		ids.append(level_id)
	return ids


class_name SaveStore
extends RefCounted


const SCHEMA_VERSION := 1
var save_path := "user://save.cfg"


func load_progress() -> Dictionary:
	var defaults := {
		"completed_levels": PackedStringArray(),
		"best_times": {},
		"best_collectibles": {},
	}
	var config := ConfigFile.new()
	var error := config.load(save_path)
	if error == ERR_FILE_NOT_FOUND:
		return defaults
	if error != OK:
		push_warning("Could not load save data (%s); defaults will be used." % error_string(error))
		return defaults
	if int(config.get_value("meta", "schema_version", 0)) != SCHEMA_VERSION:
		push_warning("Unsupported save schema; defaults will be used.")
		return defaults
	return {
		"completed_levels": PackedStringArray(config.get_value("progress", "completed_levels", PackedStringArray())),
		"best_times": config.get_value("progress", "best_times", {}) as Dictionary,
		"best_collectibles": config.get_value("progress", "best_collectibles", {}) as Dictionary,
	}


func save_progress(completed_levels: PackedStringArray, best_times: Dictionary, best_collectibles: Dictionary) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	config.set_value("progress", "completed_levels", completed_levels)
	config.set_value("progress", "best_times", best_times)
	config.set_value("progress", "best_collectibles", best_collectibles)
	var error := config.save(save_path)
	if error != OK:
		push_error("Could not save progress: %s" % error_string(error))
	return error


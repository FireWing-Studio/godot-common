
extends Object
class_name FWMethods


static func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	var err = config.load('res://addons/godot_common/plugin.cfg')
	
	if err == OK:
		return config.get_value("plugin", "version", "0.0.0")
	return "0.0.0"

static func fetch_log(context: Node) -> FWLogger:
	var root: Window = context.get_tree().root
	var node: Node = root.get_node_or_null('Log')
	if node and node is FWLogger:
		return node as FWLogger
	return null

static func get_local_unix_time() -> float:
	var utc_time = Time.get_unix_time_from_system()
	
	var zone_info = Time.get_time_zone_from_system()
	var offset_seconds = zone_info.bias * 60.0
	
	return utc_time + offset_seconds

static func get_log_datetime() -> String:
	var timestamp = get_local_unix_time()
	var time_string = Time.get_datetime_string_from_unix_time(timestamp, true)
	
	var msec = int(fmod(timestamp, 1.0) * 1000)
	
	return "%s.%03d" % [time_string, msec]

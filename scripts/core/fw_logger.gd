
extends Node
class_name FWLogger

enum Level {DEBUG, INFO, WARN, ERROR}

static func level_name(level: Level):
	var keys = Level.keys()
	if level >= 0 and level < keys.size():
		return keys[level]
	return 'LOG'

const LOG_FILE_PATH = 'logs/app.log'
const CRASH_DUMP_FILE_PATH = 'logs/crash_dump.json'

var current_level = Level.DEBUG
var log_to_file = true

var _file: FileAccess

func _ready() -> void:
	if not OS.is_debug_build():
		current_level = Level.WARN
		log_to_file = true
	
	if log_to_file:
		_file = FileAccess.open('user://' + LOG_FILE_PATH, FileAccess.WRITE)

func debug(tag: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.DEBUG, tag, message, data)

func info(tag: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.INFO, tag, message, data)

func warn(tag: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.WARN, tag, message, data)

func error(tag: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.ERROR, tag, message, data)

func panic(tag: String, message: String, data: Dictionary = {}) -> void:
	error(tag, message, data)
	_dump_state()


func _log(level: Level, tag: String, message: String, data: Dictionary) -> void:
	if level < current_level:
		return
	
	var time = Time.get_datetime_string_from_system()
	
	var line = '[%s][%s][%s] %s' % [time, level_name(level), tag, message]
	if not data.is_empty():
		line += ' ' + JSON.stringify(data)
	
	print(line)
	if log_to_file:
		_file.store_line(line)

func _dump_state() -> void:
	var dump: Dictionary = {}

	dump['time'] = Time.get_datetime_string_from_system()
	dump['build'] = 'debug' if OS.is_debug_build() else 'release'
	dump['platform'] = OS.get_name()
	dump['godot_version'] = Engine.get_version_info()

	var tree = get_tree()
	dump['current_scene'] = tree.current_scene.scene_file_path \
		if tree.current_scene != null \
		else '<none>'

	dump['memory'] = {
		'static': Performance.get_monitor(Performance.MEMORY_STATIC),
		'static_max': Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		'objects': Performance.get_monitor(Performance.OBJECT_COUNT),
		'resources': Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	}

	_write_dump_file(dump)

func _write_dump_file(data: Dictionary) -> void:
	var path = 'user://' + CRASH_DUMP_FILE_PATH
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

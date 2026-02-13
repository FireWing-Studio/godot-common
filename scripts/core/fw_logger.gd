
extends Node
class_name FWLogger

enum Level {DEBUG, INFO, WARN, ERROR, PANIC}

static func level_name(level: Level):
	var keys = Level.keys()
	if level >= 0 and level < keys.size():
		return keys[level]
	return 'LOG'

const MINOR_LEVELS = [Level.DEBUG, Level.INFO]
const URGENT_LEVELS = [Level.ERROR, Level.PANIC]


const LOG_FILE_DIR = 'logs/'
const LOG_FILE_NAME = 'app.log'
const CRASH_DUMP_FILE_DIR = 'logs/dumps/'
const CRASH_DUMP_FILE_NAME = 'crash_dump-%d.json'

const FLUSH_THRESHOLD = 4096
const LOGS_STORED = 50

var log_to_file = true
var skip_minor_levels = false

var _recent_logs: Array[String] = []
var _file: FileAccess
var _flush_count: int = 0

func _ready() -> void:
	if not OS.is_debug_build():
		skip_minor_levels = true
		log_to_file = true
	
	var booton_data = {
		"game_version": Engine.get_version_info()['string'],
		"plugin_version": FWMethods.get_version()
	}
	debug('Log', 'Initialized log', booton_data)

func _exit_tree() -> void:
	_force_flush_all()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		_force_flush_all()


func debug(caller: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.DEBUG, caller, message, data)

func info(caller: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.INFO, caller, message, data)

func warn(caller: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.WARN, caller, message, data)

func error(caller: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.ERROR, caller, message, data)

func panic(caller: String, message: String, data: Dictionary = {}) -> void:
	_log(Level.PANIC, caller, message, data)
	_dump_state(message)


func _load_log_file() -> FileAccess:
	var dir = DirAccess.open('user://')
	if not dir:
		push_error("FWLogger: Could not open user:// path.")
		log_to_file = false
		return null
	
	if not dir.dir_exists(LOG_FILE_DIR):
		dir.make_dir_recursive(LOG_FILE_DIR)
	
	return FileAccess.open('user://' + LOG_FILE_DIR + LOG_FILE_NAME, FileAccess.WRITE)

func _log(level: Level, caller: String, message: String, data: Dictionary) -> void:
	if skip_minor_levels and level in MINOR_LEVELS:
		return
	
	var frame = Engine.get_frames_drawn()
	var time = FWMethods.get_log_datetime()
	
	var line = '[%s][%s][%s][%s] %s' % [time, frame, level_name(level), caller, message]
	if not data.is_empty():
		line += ' | ' + JSON.stringify(data)
	
	print(line)
	if log_to_file:
		if not _file:
			_file = _load_log_file()
			if not _file:
				push_error("FWLogger: Failed to open log file. Disabling file logging.")
				log_to_file = false
		if log_to_file:
			_file.store_line(line)
			_flush_count += line.length() + 1	# The +1 is the newline
			
			if _flush_count >= 4096 or level in URGENT_LEVELS:
				_file.flush()
				_flush_count = 0
	
	_recent_logs.push_back(line)
	if _recent_logs.size() > LOGS_STORED:
		_recent_logs.pop_front()

func _dump_state(reason: String) -> void:
	var dump = {
		'metadata': {
			'time': FWMethods.get_log_datetime(),
			'reason': reason,
			'engine_version': Engine.get_version_info()['string'],
			'os': OS.get_name(),
			'model': OS.get_model_name(),
			'executable_path': OS.get_executable_path(),
			'build': 'debug' if OS.is_debug_build() else 'release'
		},
		'performance': {
			'fps': Engine.get_frames_per_second(),
			'static_memory': Performance.get_monitor(Performance.MEMORY_STATIC),
			'static_max_memory': Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
			'resources_alive': Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
			'objects_alive': Performance.get_monitor(Performance.OBJECT_COUNT),
			'nodes_alive': Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			'draw_calls': Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		},
		'game_state': {
			'current_scene': get_tree().current_scene.name if get_tree().current_scene else 'None',
			'scene_path': get_tree().current_scene.scene_file_path if get_tree().current_scene else 'N/A',
			'active_window': DisplayServer.window_get_mode()
		},
		'breadcrumbs': _recent_logs
	}

	_write_dump_file(dump)

func _write_dump_file(data: Dictionary) -> void:
	var dir = DirAccess.open('user://')
	if not dir:
		push_error("FWLogger: Could not open user:// path for crash_dump.")
		return
	
	if not dir.dir_exists(CRASH_DUMP_FILE_DIR):
		dir.make_dir_recursive(CRASH_DUMP_FILE_DIR)
	
	var path = ('user://' + CRASH_DUMP_FILE_DIR + CRASH_DUMP_FILE_NAME) % int(Time.get_unix_time_from_system())
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.flush()
		file.close()

func _force_flush_all() -> void:
	if _file:
		_file.flush()
		_file.close()
		_file = null

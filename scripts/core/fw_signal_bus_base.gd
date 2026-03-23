
extends Node
class_name FWSignalBusBase

const CONNECTION_CHECK_TIMEOUT = 1.0

var _default_signal_names: Array[StringName]
var _custom_signal_names: Array[StringName]

var _log: FWLogger
var _log_tag: StringName

var _connection_check_timer: Timer
var _cache_connections: Dictionary[StringName, Array]

func _ready() -> void:
	_log = FWMethods.fetch_log(self)
	_log_tag = 'FWEventBusBase:%s' % [name]
	
	var sample = Node.new()
	_default_signal_names = []
	_default_signal_names.assign(sample.get_signal_list().map(func (x: Dictionary): return x['name']))
	sample.queue_free()
	
	_init_timer()
	
	var detected: Array[Dictionary] = []
	for sig in get_signal_list():
		var signal_name: StringName = sig['name']
		if signal_name in _default_signal_names:
			continue
		
		detected.append(sig)
		_custom_signal_names.append(signal_name)
		
		var arg_count: int = sig['args'].size()
		var callable: Callable = _on_signal_emitted.bind(signal_name).unbind(arg_count)
		self.connect(signal_name, callable)
		
		var cache: Array[Callable] = []
		cache.assign(get_signal_connection_list(signal_name).map(func (x: Dictionary): return x['callable']))
		_cache_connections[signal_name] = cache
	
	if _log:
		_log.debug(_log_tag, 'Detected signals', {'signals':detected})

func _init_timer() -> void:
	_connection_check_timer = Timer.new()
	_connection_check_timer.wait_time = CONNECTION_CHECK_TIMEOUT
	_connection_check_timer.one_shot = false
	_connection_check_timer.autostart = true
	
	_connection_check_timer.timeout.connect(_check_connections)
	add_child(_connection_check_timer)


func _on_signal_emitted(signal_name: StringName) -> void:
	if _log:
		_log.debug(_log_tag, 'Emitted', {'signal_name': signal_name})

func _check_connections() -> void:
	if not _log or _log.skip_minor_levels:
		return
	
	for signal_name in _custom_signal_names:
		var raw_dict_connections = get_signal_connection_list(signal_name)
		var cached_connections = _cache_connections[signal_name]
		
		if raw_dict_connections.size() == cached_connections.size():
			if raw_dict_connections.is_empty() \
			or raw_dict_connections.back()['callable'] == cached_connections.back():
				continue
		
		var raw_connections: Array[Callable] = []
		raw_connections.assign(raw_dict_connections.map(func (x: Dictionary): return x['callable']))
		
		_log_connection_diff(signal_name, raw_connections)
		_cache_connections[signal_name] = raw_connections

func _log_connection_diff(signal_name: StringName, raw_connections: Array[Callable]) -> void:
	var cached_connections: Array[Callable] = _cache_connections[signal_name]
	
	var i_raw: int = 0
	var i_cache: int = 0
	
	var raw_size: int = raw_connections.size()
	var cache_size: int = cached_connections.size()
	
	var removed: Array[Callable] = []
	var added: Array[Callable] = []
	while i_raw < raw_size and i_cache < cache_size:
		if raw_connections[i_raw] == cached_connections[i_cache]:
			i_raw += 1
			i_cache += 1
		else:
			removed.append(cached_connections[i_cache])
			i_cache += 1
	
	while i_raw < raw_size:
		added.append(raw_connections[i_raw])
		i_raw += 1
		
	if _log:
		_log.info(_log_tag, 'Changed callbacks for signal', \
		{'signal_name': signal_name, 'added': added, 'removed': removed})

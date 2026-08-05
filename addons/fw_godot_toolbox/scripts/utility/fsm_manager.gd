
class_name FSMManager
extends Node

@export var initial_state: FSMState

var _current_state: FSMState

var _log: FWLogger
var _log_tag: String
var _states: Dictionary[StringName, FSMState] = {}

func _fetch_log() -> FWLogger:
	var root := get_tree().root
	var node := root.get_node_or_null('Log')
	if node is FWLogger:
		return node as FWLogger
	return null

func _collect_states() -> Dictionary[StringName, FSMState]:
	var result: Dictionary[StringName, FSMState] = {}
	for child in get_children():
		if child is FSMState:
			result[child.name] = child
	return result


func _ready() -> void:
	_log_tag = 'FSMManager:%s' % [name]
	_log = _fetch_log()
	
	_states = _collect_states()
	
	if _states.is_empty():
		if _log:
			_log.warn(_log_tag, 'No states present')
	else:
		if _log:
			_log.debug(_log_tag, 'States initialized', _states)
	
	for state: FSMState in _states.values():
		state.actor = get_parent()
		state.finished.connect(change_state)
	
	if initial_state:
		change_state(initial_state.name)
	
	if not _current_state:
		if not _states.is_empty():
			change_state(_states.keys()[0])
			if _log:
				_log.info(_log_tag, 'Initial state not present: current state initialized to %s' % [current_state_name()])

func _process(delta: float) -> void:
	if _current_state:
		_current_state.update(delta)

func _physics_process(delta: float) -> void:
	if _current_state:
		_current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if _current_state:
		_current_state.handle_input(event)


func change_state(next_state_name: StringName, data: Dictionary = {}) -> void:
	if not next_state_name in _states:
		if _log:
			_log.error(_log_tag, 'State name [%s] not present' % [next_state_name])
		return
	
	var next_state: FSMState = _states[next_state_name]
	if _current_state == next_state:
		return
	
	if _current_state:
		_current_state.set_process(false)
		_current_state.set_physics_process(false)
		_current_state.set_process_input(false)
		_current_state.exit()
	
	var prev_state_name: StringName = current_state_name()
	
	_current_state = next_state
	
	_current_state.set_process(true)
	_current_state.set_physics_process(true)
	_current_state.set_process_input(true)
	_current_state.enter(prev_state_name, data)

func current_state_name() -> StringName:
	return _current_state.name if _current_state else &'None'

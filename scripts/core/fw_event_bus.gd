
extends Node
class_name FWEventBus

var _log: FWLogger
var _events: Dictionary[StringName, Array] = {}

func _fetch_log() -> FWLogger:
	var root := get_tree().root
	var node := root.get_node_or_null('Log')
	if node is FWLogger:
		return node as FWLogger
	return null


func _ready() -> void:
	_log = _fetch_log()


func subscribe(event_name: StringName, callback: Callable) -> void:
	if not event_name in _events:
		if _log:
			_log.debug('Bus.subscribe', 'Event [%s] was not present: the event will be initialized' % [event_name])
		_events[event_name] = []
	
	if not callback in _events[event_name]:
		_events[event_name].append(callback)
	else:
		if _log:
			_log.warn('Bus.subscribe', 'Callback [%s] already present in event [%s]' % [callback, event_name])

func unsubscribe(event_name: StringName, callback: Callable) -> void:
	if not event_name in _events:
		if _log:
			_log.warn('Bus.unsubscribe', 'Event [%s] not present' % [event_name])
		return
	
	if not callback in _events[event_name]:
		if _log:
			_log.warn('Bus.unsubscribe', 'Callback [%s] not present in event [%s]' % [callback, event_name])
		return
	
	_events[event_name].erase(callback)
	if _events[event_name].is_empty():
		_events.erase(event_name)

func emit() -> void:
	pass

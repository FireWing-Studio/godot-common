
extends Node
class_name FWEventBus

var _log: FWLogger
var _events: Dictionary[StringName, Array] = {}

func _ready() -> void:
	_log = FWMethods.fetch_log(self)


func subscribe(event_name: StringName, callback: Callable) -> void:
	if callback.get_argument_count() > 1:
		if _log:
			_log.warn(
				'Bus.subscribe',
				'Invalid signature of event: too many arguments',
				{'event': event_name, 'arguments': callback.get_argument_count()}
			)
		return
	
	if not event_name in _events:
		if _log:
			_log.info(
				'Bus.subscribe',
				'Event not present yet: the event will be initialized',
				{'event': event_name}
			)
		_events[event_name] = []
	
	if not callback in _events[event_name]:
		_events[event_name].append(callback)
	else:
		if _log:
			_log.warn(
				'Bus.subscribe',
				'Callback already present in event',
				{'callback': callback, 'event': event_name}
			)

func unsubscribe(event_name: StringName, callback: Callable) -> void:
	if not event_name in _events:
		if _log:
			_log.warn(
				'Bus.unsubscribe',
				'Event not present',
				{'event': event_name}
			)
		return
	
	if not callback in _events[event_name]:
		if _log:
			_log.warn(
				'Bus.unsubscribe',
				'Callback not present in event',
				{'callback': callback, 'event': event_name}
			)
		return
	
	_events[event_name].erase(callback)
	if _events[event_name].is_empty():
		_events.erase(event_name)

func emit(event_name: StringName, data: Dictionary = {}) -> void:
	if not event_name in _events:
		if _log:
			_log.info(
				'Bus.emit',
				'Event has no listeners',
				{'event': event_name}
			)
		return
	
	var callbacks: Array = _events[event_name].duplicate()
	
	for callback: Callable in callbacks:
		if callback.is_valid():
			match callback.get_argument_count():
				0: callback.call()
				1: callback.call(data)
				_:
					if _log:
						_log.warn(
							'Bus.emit',
							'Invalid signature of event: too many arguments',
							{'event': event_name, 'arguments': callback.get_argument_count()}
						)
					_events[event_name].erase(callback)
		else:
			if _log:
				_log.warn(
					'Bus.emit',
					'Invalid callback removed from event',
					{'event': event_name, 'callback': callback}
				)
			_events[event_name].erase(callback)
	
	if _events[event_name].is_empty():
		_events.erase(event_name)

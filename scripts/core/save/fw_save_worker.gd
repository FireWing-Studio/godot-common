
class_name FWSaveWorker

var _slot: int
var _prefix: String

static func create(slot: int) -> FWSaveWorker:
	var obj: FWSaveWorker = new()
	obj._slot = slot
	obj._prefix = 'user://saves/slot%s' % [slot]
	return obj

func _write_atomic(path: String, data: Dictionary) -> void:
	var tmp: String = path + '.tmp'
	
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		return
	
	file.store_var(data)
	file.close()
	
	#DirAccess.rename_absolute(tmp, path)

func save(data: Dictionary, version: int, name: String, path: String = '/'):
	if not path.ends_with('/'):
		path += '/'
	
	var payload = {
		"version": version,
		"data": data
	}
	
	_write_atomic('%s%s%s.save' % [_prefix, path, name], payload)

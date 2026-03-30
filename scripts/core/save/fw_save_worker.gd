
class_name FWSaveWorker

enum SaveError {
	OK,
	INVALID_DIR,
	COULD_NOT_CREATE_DIR,
	NAME_NOT_PRESENT,
	FILE_ACCESS_ERROR,
	FILE_RENAME_ERROR,
	FILE_REMOVE_ERROR,
	INVALID_HEADER_SIZE,
	INVALID_MAGIC_NUMBER,
	INVALID_HEADER_VERSION,
	INVALID_PAYLOAD_CHECKSUM,
	INVALID_HEADER_CHECKSUM
}

class Encoded:
	var payload: PackedByteArray
	var uncompressed_size: int

const BASE_DIR = 'user://saves/'

const FILE_EXTENSION = '.sav'
const FILE_NEW_EXTENSION = '.new'
const FILE_OLD_EXTENSION = '.old'
const DIR_NEW_SUFFIX = '_NEW'
const DIR_OLD_SUFFIX = '_OLD'

var prefix_dir: String

func _init(prefix_relative_dir: String = '') -> void:
	self.prefix_dir = BASE_DIR.path_join(prefix_relative_dir).simplify_path()
	if not self.prefix_dir.is_absolute_path():
		self.prefix_dir = BASE_DIR


func _ensure_dir(dir: String) -> SaveError:
	if not DirAccess.dir_exists_absolute(dir):
		var dir_err: Error = DirAccess.make_dir_recursive_absolute(dir)
		if not dir_err == OK:
			return SaveError.COULD_NOT_CREATE_DIR
	return SaveError.OK

func _write_file(path: String, encoding: FWSavePayload.SaveEncoding, payload: Dictionary) -> SaveError:
	var save_payload: FWSavePayload = FWSavePayload.new()
	save_payload.encoding = encoding
	save_payload.encode(payload)
	var save_validator: FWSaveValidator = FWSaveValidator.new()
	save_validator.save_payload = save_payload
	
	var header = save_validator.generate_header(FWSaveValidator.CURR_HEADER_VERSION)
	
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return SaveError.FILE_ACCESS_ERROR
	file.store_buffer(header)
	file.store_buffer(save_payload.encoded_payload)
	file.close()
	
	return SaveError.OK


func _write_atomic_file(dir: String, name: String, encoding: FWSavePayload.SaveEncoding, payload: Dictionary) -> SaveError:
	_ensure_dir(dir)
	var base_path: String = dir.path_join(name) + FILE_EXTENSION
	var new_path: String = base_path + FILE_NEW_EXTENSION
	var old_path: String = base_path + FILE_OLD_EXTENSION
	
	var file_write_err: SaveError = _write_file(new_path, encoding, payload)
	if not file_write_err == SaveError.OK:
		return file_write_err
	
	if FileAccess.file_exists(base_path):
		if FileAccess.file_exists(old_path):
			if not DirAccess.remove_absolute(old_path) == OK:
				return SaveError.FILE_REMOVE_ERROR
		if not DirAccess.rename_absolute(base_path, old_path) == OK:
			return SaveError.FILE_RENAME_ERROR
		if not DirAccess.rename_absolute(new_path, base_path) == OK:
			return SaveError.FILE_RENAME_ERROR
		if not DirAccess.remove_absolute(old_path) == OK:
			return SaveError.FILE_REMOVE_ERROR
	else:
		if not DirAccess.rename_absolute(new_path, base_path) == OK:
			return SaveError.FILE_RENAME_ERROR
	
	return SaveError.OK

func save(payload: Dictionary, relative_dir: String = './', encoding: FWSavePayload.SaveEncoding = FWSavePayload.SaveEncoding.BINARY) -> SaveError:
	var dir: String = prefix_dir.path_join(relative_dir).simplify_path()
	if not dir.is_absolute_path():
		return SaveError.INVALID_DIR
	
	var name: String = payload.get('name', '')
	
	if not name:
		return SaveError.NAME_NOT_PRESENT
	if not payload.has('version'):
		payload['version'] = 0
	if not payload.has('data'):
		payload['data'] = {}

	return _write_atomic_file(dir, name, encoding, payload)

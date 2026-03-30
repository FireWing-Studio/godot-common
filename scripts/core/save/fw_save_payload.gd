
class_name FWSavePayload

enum SaveEncoding {
	INVALID = 0,
	BINARY = 1, 
	JSON = 2,
	BINARY_ZSTD = 3
}

var encoded_payload: PackedByteArray
var encoding: SaveEncoding = SaveEncoding.INVALID
var compressed_size: int
var uncompressed_size: int

func encode(payload: Dictionary) -> void:
	match encoding:
		SaveEncoding.BINARY:
			encoded_payload = var_to_bytes(payload)
			compressed_size = encoded_payload.size()
			uncompressed_size = encoded_payload.size()
		SaveEncoding.JSON:
			encoded_payload = JSON.stringify(payload).to_utf8_buffer()
			compressed_size = encoded_payload.size()
			uncompressed_size = encoded_payload.size()
		SaveEncoding.BINARY_ZSTD:
			encoded_payload = var_to_bytes(payload)
			uncompressed_size = encoded_payload.size()
			encoded_payload = encoded_payload.compress(FileAccess.CompressionMode.COMPRESSION_ZSTD)
			compressed_size = encoded_payload.size()
		_:
			encoded_payload = PackedByteArray()
			compressed_size = 0
			uncompressed_size = 0

func decode() -> Dictionary:
	var payload: Dictionary
	match encoding:
		SaveEncoding.BINARY:
			payload = bytes_to_var(encoded_payload)
		SaveEncoding.JSON:
			payload = JSON.parse_string(encoded_payload.get_string_from_utf8())
		SaveEncoding.BINARY_ZSTD:
			payload = bytes_to_var(encoded_payload.decompress(uncompressed_size, encoding))
		_:
			payload = {}
	return payload


class_name FWSaveValidator

const MAGIC_NUMBER: String = 'FWSV'
const CURR_HEADER_VERSION: int = 1

var save_payload: FWSavePayload

func _generate_header_v1() -> PackedByteArray:
	var buffer = PackedByteArray()
	buffer.resize(64)
	buffer.fill(0)
	
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.data_array = buffer
	
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(save_payload.encoded_payload)
	var payload_checksum: PackedByteArray = ctx.finish()
	
	stream.put_data(MAGIC_NUMBER.to_ascii_buffer())
	stream.put_u16(1)
	stream.put_u8(save_payload.encoding)
	stream.put_u8(0)
	stream.put_u32(save_payload.compressed_size)
	stream.put_u32(save_payload.uncompressed_size)
	# TODO: game uuid
	stream.seek(32)
	stream.put_data(payload_checksum)
	
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(stream.data_array.slice(0, 48))
	var header_checksum: PackedByteArray = ctx.finish()
	
	stream.put_data(header_checksum)
	
	return stream.data_array

func generate_header(version: int) -> PackedByteArray:
	match version:
		1:	return _generate_header_v1()
		_:	return PackedByteArray()


func _validate_header_v1(header: PackedByteArray) -> FWSaveWorker.SaveError:
	if header.size() < 64:
		return FWSaveWorker.SaveError.INVALID_HEADER_SIZE
	
	if not header.slice(0, 4) == MAGIC_NUMBER.to_ascii_buffer():
		return FWSaveWorker.SaveError.INVALID_MAGIC_NUMBER
	save_payload.encoding = header.decode_u8(6)
	save_payload.compressed_size = header.decode_u32(8)
	save_payload.uncompressed_size = header.decode_u32(12)
	
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(save_payload.encoded_payload)
	var payload_checksum: PackedByteArray = ctx.finish()
	
	if not payload_checksum == header.slice(32, 48):
		return FWSaveWorker.SaveError.INVALID_PAYLOAD_CHECKSUM
	
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(header.slice(0, 48))
	var header_checksum: PackedByteArray = ctx.finish()
	
	if not header_checksum == header.slice(48, 64):
		return FWSaveWorker.SaveError.INVALID_HEADER_CHECKSUM
	
	return FWSaveWorker.SaveError.OK

func _parse_v1(buffer: PackedByteArray) -> FWSaveWorker.SaveError:
	var header: PackedByteArray = buffer.slice(0, 64)
	var payload: PackedByteArray = buffer.slice(64)
	
	save_payload = FWSavePayload.new()
	save_payload.encoded_payload = payload
	
	return _validate_header_v1(header)

func parse(buffer: PackedByteArray) -> FWSaveWorker.SaveError:
	var version: int = buffer.decode_u16(4)
	match version:
		1:	return _parse_v1(buffer)
		_:	return FWSaveWorker.SaveError.INVALID_HEADER_VERSION

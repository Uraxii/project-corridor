#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		if data_type == PB_DATA_TYPE.FLOAT:
			return bytes.decode_float(index)
		elif data_type == PB_DATA_TYPE.DOUBLE:
			return bytes.decode_double(index)
		else:
			# Convert to big endian
			var slice: PackedByteArray = bytes.slice(index, index + count)
			slice.reverse()
			return slice

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		var i: int = varint_bytes.size() - 1
		while i > -1:
			value = (value << 7) | (varint_bytes[i] & 0x7F)
			i -= 1
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var i: int = index
		while i <= index + 10: # Protobuf varint max size is 10 bytes
			if !(bytes[i] & 0x80):
				return bytes.slice(index, i + 1)
			i += 1
		return [] # Unreachable

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break							
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class Test0:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
enum Enum0 {
	NULL = 0,
	ONE = 1,
	TWO = 2,
	THREE = 3,
	FOUR = 4
}

class Test1:
	func _init():
		var service
		
		__f_double = PBField.new("f_double", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = __f_double
		data[__f_double.tag] = service
		
		__f_float = PBField.new("f_float", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f_float
		data[__f_float.tag] = service
		
		__f_int32 = PBField.new("f_int32", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __f_int32
		data[__f_int32.tag] = service
		
		__f_int64 = PBField.new("f_int64", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __f_int64
		data[__f_int64.tag] = service
		
		__f_uint32 = PBField.new("f_uint32", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __f_uint32
		data[__f_uint32.tag] = service
		
		__f_uint64 = PBField.new("f_uint64", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __f_uint64
		data[__f_uint64.tag] = service
		
		__f_sint32 = PBField.new("f_sint32", PB_DATA_TYPE.SINT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.SINT32])
		service = PBServiceField.new()
		service.field = __f_sint32
		data[__f_sint32.tag] = service
		
		__f_sint64 = PBField.new("f_sint64", PB_DATA_TYPE.SINT64, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.SINT64])
		service = PBServiceField.new()
		service.field = __f_sint64
		data[__f_sint64.tag] = service
		
		__f_fixed32 = PBField.new("f_fixed32", PB_DATA_TYPE.FIXED32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED32])
		service = PBServiceField.new()
		service.field = __f_fixed32
		data[__f_fixed32.tag] = service
		
		__f_fixed64 = PBField.new("f_fixed64", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64])
		service = PBServiceField.new()
		service.field = __f_fixed64
		data[__f_fixed64.tag] = service
		
		__f_sfixed32 = PBField.new("f_sfixed32", PB_DATA_TYPE.SFIXED32, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.SFIXED32])
		service = PBServiceField.new()
		service.field = __f_sfixed32
		data[__f_sfixed32.tag] = service
		
		__f_sfixed64 = PBField.new("f_sfixed64", PB_DATA_TYPE.SFIXED64, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.SFIXED64])
		service = PBServiceField.new()
		service.field = __f_sfixed64
		data[__f_sfixed64.tag] = service
		
		__f_bool = PBField.new("f_bool", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __f_bool
		data[__f_bool.tag] = service
		
		__f_string = PBField.new("f_string", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __f_string
		data[__f_string.tag] = service
		
		__f_bytes = PBField.new("f_bytes", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __f_bytes
		data[__f_bytes.tag] = service
		
		var __f_map_default: Array = []
		__f_map = PBField.new("f_map", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 16, true, __f_map_default)
		service = PBServiceField.new()
		service.field = __f_map
		service.func_ref = Callable(self, "add_empty_f_map")
		data[__f_map.tag] = service
		
		__f_oneof_f1 = PBField.new("f_oneof_f1", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __f_oneof_f1
		data[__f_oneof_f1.tag] = service
		
		__f_oneof_f2 = PBField.new("f_oneof_f2", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __f_oneof_f2
		data[__f_oneof_f2.tag] = service
		
		__f_empty_out = PBField.new("f_empty_out", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f_empty_out
		service.func_ref = Callable(self, "new_f_empty_out")
		data[__f_empty_out.tag] = service
		
		__f_enum_out = PBField.new("f_enum_out", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __f_enum_out
		data[__f_enum_out.tag] = service
		
		__f_empty_inner = PBField.new("f_empty_inner", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f_empty_inner
		service.func_ref = Callable(self, "new_f_empty_inner")
		data[__f_empty_inner.tag] = service
		
		__f_enum_inner = PBField.new("f_enum_inner", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __f_enum_inner
		data[__f_enum_inner.tag] = service
		
		var __rf_double_default: Array[float] = []
		__rf_double = PBField.new("rf_double", PB_DATA_TYPE.DOUBLE, PB_RULE.REPEATED, 23, true, __rf_double_default)
		service = PBServiceField.new()
		service.field = __rf_double
		data[__rf_double.tag] = service
		
		var __rf_float_default: Array[float] = []
		__rf_float = PBField.new("rf_float", PB_DATA_TYPE.FLOAT, PB_RULE.REPEATED, 24, true, __rf_float_default)
		service = PBServiceField.new()
		service.field = __rf_float
		data[__rf_float.tag] = service
		
		var __rf_int32_default: Array[int] = []
		__rf_int32 = PBField.new("rf_int32", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 25, true, __rf_int32_default)
		service = PBServiceField.new()
		service.field = __rf_int32
		data[__rf_int32.tag] = service
		
		var __rf_int64_default: Array[int] = []
		__rf_int64 = PBField.new("rf_int64", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 26, true, __rf_int64_default)
		service = PBServiceField.new()
		service.field = __rf_int64
		data[__rf_int64.tag] = service
		
		var __rf_uint32_default: Array[int] = []
		__rf_uint32 = PBField.new("rf_uint32", PB_DATA_TYPE.UINT32, PB_RULE.REPEATED, 27, true, __rf_uint32_default)
		service = PBServiceField.new()
		service.field = __rf_uint32
		data[__rf_uint32.tag] = service
		
		var __rf_uint64_default: Array[int] = []
		__rf_uint64 = PBField.new("rf_uint64", PB_DATA_TYPE.UINT64, PB_RULE.REPEATED, 28, true, __rf_uint64_default)
		service = PBServiceField.new()
		service.field = __rf_uint64
		data[__rf_uint64.tag] = service
		
		var __rf_sint32_default: Array[int] = []
		__rf_sint32 = PBField.new("rf_sint32", PB_DATA_TYPE.SINT32, PB_RULE.REPEATED, 29, true, __rf_sint32_default)
		service = PBServiceField.new()
		service.field = __rf_sint32
		data[__rf_sint32.tag] = service
		
		var __rf_sint64_default: Array[int] = []
		__rf_sint64 = PBField.new("rf_sint64", PB_DATA_TYPE.SINT64, PB_RULE.REPEATED, 30, true, __rf_sint64_default)
		service = PBServiceField.new()
		service.field = __rf_sint64
		data[__rf_sint64.tag] = service
		
		var __rf_fixed32_default: Array[int] = []
		__rf_fixed32 = PBField.new("rf_fixed32", PB_DATA_TYPE.FIXED32, PB_RULE.REPEATED, 31, true, __rf_fixed32_default)
		service = PBServiceField.new()
		service.field = __rf_fixed32
		data[__rf_fixed32.tag] = service
		
		var __rf_fixed64_default: Array[int] = []
		__rf_fixed64 = PBField.new("rf_fixed64", PB_DATA_TYPE.FIXED64, PB_RULE.REPEATED, 32, true, __rf_fixed64_default)
		service = PBServiceField.new()
		service.field = __rf_fixed64
		data[__rf_fixed64.tag] = service
		
		var __rf_sfixed32_default: Array[int] = []
		__rf_sfixed32 = PBField.new("rf_sfixed32", PB_DATA_TYPE.SFIXED32, PB_RULE.REPEATED, 33, true, __rf_sfixed32_default)
		service = PBServiceField.new()
		service.field = __rf_sfixed32
		data[__rf_sfixed32.tag] = service
		
		var __rf_sfixed64_default: Array[int] = []
		__rf_sfixed64 = PBField.new("rf_sfixed64", PB_DATA_TYPE.SFIXED64, PB_RULE.REPEATED, 34, true, __rf_sfixed64_default)
		service = PBServiceField.new()
		service.field = __rf_sfixed64
		data[__rf_sfixed64.tag] = service
		
		var __rf_bool_default: Array[bool] = []
		__rf_bool = PBField.new("rf_bool", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 35, true, __rf_bool_default)
		service = PBServiceField.new()
		service.field = __rf_bool
		data[__rf_bool.tag] = service
		
		var __rf_string_default: Array[String] = []
		__rf_string = PBField.new("rf_string", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 36, true, __rf_string_default)
		service = PBServiceField.new()
		service.field = __rf_string
		data[__rf_string.tag] = service
		
		var __rf_bytes_default: Array[PackedByteArray] = []
		__rf_bytes = PBField.new("rf_bytes", PB_DATA_TYPE.BYTES, PB_RULE.REPEATED, 37, true, __rf_bytes_default)
		service = PBServiceField.new()
		service.field = __rf_bytes
		data[__rf_bytes.tag] = service
		
		var __rf_empty_out_default: Array[Test0] = []
		__rf_empty_out = PBField.new("rf_empty_out", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 38, true, __rf_empty_out_default)
		service = PBServiceField.new()
		service.field = __rf_empty_out
		service.func_ref = Callable(self, "add_rf_empty_out")
		data[__rf_empty_out.tag] = service
		
		var __rf_enum_out_default: Array = []
		__rf_enum_out = PBField.new("rf_enum_out", PB_DATA_TYPE.ENUM, PB_RULE.REPEATED, 39, true, __rf_enum_out_default)
		service = PBServiceField.new()
		service.field = __rf_enum_out
		data[__rf_enum_out.tag] = service
		
		var __rf_empty_inner_default: Array[Test2.TestInner2] = []
		__rf_empty_inner = PBField.new("rf_empty_inner", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 40, true, __rf_empty_inner_default)
		service = PBServiceField.new()
		service.field = __rf_empty_inner
		service.func_ref = Callable(self, "add_rf_empty_inner")
		data[__rf_empty_inner.tag] = service
		
		var __rf_enum_inner_default: Array = []
		__rf_enum_inner = PBField.new("rf_enum_inner", PB_DATA_TYPE.ENUM, PB_RULE.REPEATED, 41, true, __rf_enum_inner_default)
		service = PBServiceField.new()
		service.field = __rf_enum_inner
		data[__rf_enum_inner.tag] = service
		
		var __rfu_double_default: Array[float] = []
		__rfu_double = PBField.new("rfu_double", PB_DATA_TYPE.DOUBLE, PB_RULE.REPEATED, 42, false, __rfu_double_default)
		service = PBServiceField.new()
		service.field = __rfu_double
		data[__rfu_double.tag] = service
		
		var __rfu_float_default: Array[float] = []
		__rfu_float = PBField.new("rfu_float", PB_DATA_TYPE.FLOAT, PB_RULE.REPEATED, 43, false, __rfu_float_default)
		service = PBServiceField.new()
		service.field = __rfu_float
		data[__rfu_float.tag] = service
		
		var __rfu_int32f_default: Array[int] = []
		__rfu_int32f = PBField.new("rfu_int32f", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 44, false, __rfu_int32f_default)
		service = PBServiceField.new()
		service.field = __rfu_int32f
		data[__rfu_int32f.tag] = service
		
		var __rfu_int64f_default: Array[int] = []
		__rfu_int64f = PBField.new("rfu_int64f", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 45, false, __rfu_int64f_default)
		service = PBServiceField.new()
		service.field = __rfu_int64f
		data[__rfu_int64f.tag] = service
		
		var __rfu_uint32_default: Array[int] = []
		__rfu_uint32 = PBField.new("rfu_uint32", PB_DATA_TYPE.UINT32, PB_RULE.REPEATED, 46, false, __rfu_uint32_default)
		service = PBServiceField.new()
		service.field = __rfu_uint32
		data[__rfu_uint32.tag] = service
		
		var __rfu_uint64_default: Array[int] = []
		__rfu_uint64 = PBField.new("rfu_uint64", PB_DATA_TYPE.UINT64, PB_RULE.REPEATED, 47, false, __rfu_uint64_default)
		service = PBServiceField.new()
		service.field = __rfu_uint64
		data[__rfu_uint64.tag] = service
		
		var __rfu_sint32_default: Array[int] = []
		__rfu_sint32 = PBField.new("rfu_sint32", PB_DATA_TYPE.SINT32, PB_RULE.REPEATED, 48, false, __rfu_sint32_default)
		service = PBServiceField.new()
		service.field = __rfu_sint32
		data[__rfu_sint32.tag] = service
		
		var __rfu_sint64_default: Array[int] = []
		__rfu_sint64 = PBField.new("rfu_sint64", PB_DATA_TYPE.SINT64, PB_RULE.REPEATED, 49, false, __rfu_sint64_default)
		service = PBServiceField.new()
		service.field = __rfu_sint64
		data[__rfu_sint64.tag] = service
		
		var __rfu_fixed32_default: Array[int] = []
		__rfu_fixed32 = PBField.new("rfu_fixed32", PB_DATA_TYPE.FIXED32, PB_RULE.REPEATED, 50, false, __rfu_fixed32_default)
		service = PBServiceField.new()
		service.field = __rfu_fixed32
		data[__rfu_fixed32.tag] = service
		
		var __rfu_fixed64_default: Array[int] = []
		__rfu_fixed64 = PBField.new("rfu_fixed64", PB_DATA_TYPE.FIXED64, PB_RULE.REPEATED, 51, false, __rfu_fixed64_default)
		service = PBServiceField.new()
		service.field = __rfu_fixed64
		data[__rfu_fixed64.tag] = service
		
		var __rfu_sfixed32_default: Array[int] = []
		__rfu_sfixed32 = PBField.new("rfu_sfixed32", PB_DATA_TYPE.SFIXED32, PB_RULE.REPEATED, 52, false, __rfu_sfixed32_default)
		service = PBServiceField.new()
		service.field = __rfu_sfixed32
		data[__rfu_sfixed32.tag] = service
		
		var __rfu_sfixed64_default: Array[int] = []
		__rfu_sfixed64 = PBField.new("rfu_sfixed64", PB_DATA_TYPE.SFIXED64, PB_RULE.REPEATED, 53, false, __rfu_sfixed64_default)
		service = PBServiceField.new()
		service.field = __rfu_sfixed64
		data[__rfu_sfixed64.tag] = service
		
		var __rfu_bool_default: Array[bool] = []
		__rfu_bool = PBField.new("rfu_bool", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 54, false, __rfu_bool_default)
		service = PBServiceField.new()
		service.field = __rfu_bool
		data[__rfu_bool.tag] = service
		
		var __rf_inner_default: Array[Test2.TestInner3.TestInner3_2] = []
		__rf_inner = PBField.new("rf_inner", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 55, true, __rf_inner_default)
		service = PBServiceField.new()
		service.field = __rf_inner
		service.func_ref = Callable(self, "add_rf_inner")
		data[__rf_inner.tag] = service
		
	var data = {}
	
	var __f_double: PBField
	func has_f_double() -> bool:
		if __f_double.value != null:
			return true
		return false
	func get_f_double() -> float:
		return __f_double.value
	func clear_f_double() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__f_double.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_f_double(value : float) -> void:
		__f_double.value = value
	
	var __f_float: PBField
	func has_f_float() -> bool:
		if __f_float.value != null:
			return true
		return false
	func get_f_float() -> float:
		return __f_float.value
	func clear_f_float() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__f_float.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_f_float(value : float) -> void:
		__f_float.value = value
	
	var __f_int32: PBField
	func has_f_int32() -> bool:
		if __f_int32.value != null:
			return true
		return false
	func get_f_int32() -> int:
		return __f_int32.value
	func clear_f_int32() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__f_int32.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_f_int32(value : int) -> void:
		__f_int32.value = value
	
	var __f_int64: PBField
	func has_f_int64() -> bool:
		if __f_int64.value != null:
			return true
		return false
	func get_f_int64() -> int:
		return __f_int64.value
	func clear_f_int64() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__f_int64.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_f_int64(value : int) -> void:
		__f_int64.value = value
	
	var __f_uint32: PBField
	func has_f_uint32() -> bool:
		if __f_uint32.value != null:
			return true
		return false
	func get_f_uint32() -> int:
		return __f_uint32.value
	func clear_f_uint32() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__f_uint32.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_f_uint32(value : int) -> void:
		__f_uint32.value = value
	
	var __f_uint64: PBField
	func has_f_uint64() -> bool:
		if __f_uint64.value != null:
			return true
		return false
	func get_f_uint64() -> int:
		return __f_uint64.value
	func clear_f_uint64() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__f_uint64.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_f_uint64(value : int) -> void:
		__f_uint64.value = value
	
	var __f_sint32: PBField
	func has_f_sint32() -> bool:
		if __f_sint32.value != null:
			return true
		return false
	func get_f_sint32() -> int:
		return __f_sint32.value
	func clear_f_sint32() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__f_sint32.value = DEFAULT_VALUES_3[PB_DATA_TYPE.SINT32]
	func set_f_sint32(value : int) -> void:
		__f_sint32.value = value
	
	var __f_sint64: PBField
	func has_f_sint64() -> bool:
		if __f_sint64.value != null:
			return true
		return false
	func get_f_sint64() -> int:
		return __f_sint64.value
	func clear_f_sint64() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__f_sint64.value = DEFAULT_VALUES_3[PB_DATA_TYPE.SINT64]
	func set_f_sint64(value : int) -> void:
		__f_sint64.value = value
	
	var __f_fixed32: PBField
	func has_f_fixed32() -> bool:
		if __f_fixed32.value != null:
			return true
		return false
	func get_f_fixed32() -> int:
		return __f_fixed32.value
	func clear_f_fixed32() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__f_fixed32.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED32]
	func set_f_fixed32(value : int) -> void:
		__f_fixed32.value = value
	
	var __f_fixed64: PBField
	func has_f_fixed64() -> bool:
		if __f_fixed64.value != null:
			return true
		return false
	func get_f_fixed64() -> int:
		return __f_fixed64.value
	func clear_f_fixed64() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__f_fixed64.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64]
	func set_f_fixed64(value : int) -> void:
		__f_fixed64.value = value
	
	var __f_sfixed32: PBField
	func has_f_sfixed32() -> bool:
		if __f_sfixed32.value != null:
			return true
		return false
	func get_f_sfixed32() -> int:
		return __f_sfixed32.value
	func clear_f_sfixed32() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__f_sfixed32.value = DEFAULT_VALUES_3[PB_DATA_TYPE.SFIXED32]
	func set_f_sfixed32(value : int) -> void:
		__f_sfixed32.value = value
	
	var __f_sfixed64: PBField
	func has_f_sfixed64() -> bool:
		if __f_sfixed64.value != null:
			return true
		return false
	func get_f_sfixed64() -> int:
		return __f_sfixed64.value
	func clear_f_sfixed64() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__f_sfixed64.value = DEFAULT_VALUES_3[PB_DATA_TYPE.SFIXED64]
	func set_f_sfixed64(value : int) -> void:
		__f_sfixed64.value = value
	
	var __f_bool: PBField
	func has_f_bool() -> bool:
		if __f_bool.value != null:
			return true
		return false
	func get_f_bool() -> bool:
		return __f_bool.value
	func clear_f_bool() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__f_bool.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_f_bool(value : bool) -> void:
		__f_bool.value = value
	
	var __f_string: PBField
	func has_f_string() -> bool:
		if __f_string.value != null:
			return true
		return false
	func get_f_string() -> String:
		return __f_string.value
	func clear_f_string() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__f_string.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_f_string(value : String) -> void:
		__f_string.value = value
	
	var __f_bytes: PBField
	func has_f_bytes() -> bool:
		if __f_bytes.value != null:
			return true
		return false
	func get_f_bytes() -> PackedByteArray:
		return __f_bytes.value
	func clear_f_bytes() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__f_bytes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_f_bytes(value : PackedByteArray) -> void:
		__f_bytes.value = value
	
	var __f_map: PBField
	func get_raw_f_map():
		return __f_map.value
	func get_f_map():
		return PBPacker.construct_map(__f_map.value)
	func clear_f_map():
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__f_map.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_f_map() -> Test1.map_type_f_map:
		var element = Test1.map_type_f_map.new()
		__f_map.value.append(element)
		return element
	func add_f_map(a_key, a_value) -> void:
		var idx = -1
		for i in range(__f_map.value.size()):
			if __f_map.value[i].get_key() == a_key:
				idx = i
				break
		var element = Test1.map_type_f_map.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			__f_map.value[idx] = element
		else:
			__f_map.value.append(element)
	
	var __f_oneof_f1: PBField
	func has_f_oneof_f1() -> bool:
		return data[17].state == PB_SERVICE_STATE.FILLED
	func has_f_oneof_f1() -> bool:
		if __f_oneof_f1.value != null:
			return true
		return false
	func get_f_oneof_f1() -> String:
		return __f_oneof_f1.value
	func clear_f_oneof_f1() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__f_oneof_f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_f_oneof_f1(value : String) -> void:
		data[17].state = PB_SERVICE_STATE.FILLED
		__f_oneof_f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__f_oneof_f1.value = value
	
	var __f_oneof_f2: PBField
	func has_f_oneof_f2() -> bool:
		return data[18].state == PB_SERVICE_STATE.FILLED
	func has_f_oneof_f2() -> bool:
		if __f_oneof_f2.value != null:
			return true
		return false
	func get_f_oneof_f2() -> int:
		return __f_oneof_f2.value
	func clear_f_oneof_f2() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__f_oneof_f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_f_oneof_f2(value : int) -> void:
		__f_oneof_f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[17].state = PB_SERVICE_STATE.UNFILLED
		data[18].state = PB_SERVICE_STATE.FILLED
		__f_oneof_f2.value = value
	
	var __f_empty_out: PBField
	func has_f_empty_out() -> bool:
		if __f_empty_out.value != null:
			return true
		return false
	func get_f_empty_out() -> Test0:
		return __f_empty_out.value
	func clear_f_empty_out() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__f_empty_out.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f_empty_out() -> Test0:
		__f_empty_out.value = Test0.new()
		return __f_empty_out.value
	
	var __f_enum_out: PBField
	func has_f_enum_out() -> bool:
		if __f_enum_out.value != null:
			return true
		return false
	func get_f_enum_out():
		return __f_enum_out.value
	func clear_f_enum_out() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__f_enum_out.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_f_enum_out(value) -> void:
		__f_enum_out.value = value
	
	var __f_empty_inner: PBField
	func has_f_empty_inner() -> bool:
		if __f_empty_inner.value != null:
			return true
		return false
	func get_f_empty_inner() -> Test2.TestInner2:
		return __f_empty_inner.value
	func clear_f_empty_inner() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__f_empty_inner.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f_empty_inner() -> Test2.TestInner2:
		__f_empty_inner.value = Test2.TestInner2.new()
		return __f_empty_inner.value
	
	var __f_enum_inner: PBField
	func has_f_enum_inner() -> bool:
		if __f_enum_inner.value != null:
			return true
		return false
	func get_f_enum_inner():
		return __f_enum_inner.value
	func clear_f_enum_inner() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__f_enum_inner.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_f_enum_inner(value) -> void:
		__f_enum_inner.value = value
	
	var __rf_double: PBField
	func get_rf_double() -> Array[float]:
		return __rf_double.value
	func clear_rf_double() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__rf_double.value.clear()
	func add_rf_double(value : float) -> void:
		__rf_double.value.append(value)
	
	var __rf_float: PBField
	func get_rf_float() -> Array[float]:
		return __rf_float.value
	func clear_rf_float() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__rf_float.value.clear()
	func add_rf_float(value : float) -> void:
		__rf_float.value.append(value)
	
	var __rf_int32: PBField
	func get_rf_int32() -> Array[int]:
		return __rf_int32.value
	func clear_rf_int32() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		__rf_int32.value.clear()
	func add_rf_int32(value : int) -> void:
		__rf_int32.value.append(value)
	
	var __rf_int64: PBField
	func get_rf_int64() -> Array[int]:
		return __rf_int64.value
	func clear_rf_int64() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		__rf_int64.value.clear()
	func add_rf_int64(value : int) -> void:
		__rf_int64.value.append(value)
	
	var __rf_uint32: PBField
	func get_rf_uint32() -> Array[int]:
		return __rf_uint32.value
	func clear_rf_uint32() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		__rf_uint32.value.clear()
	func add_rf_uint32(value : int) -> void:
		__rf_uint32.value.append(value)
	
	var __rf_uint64: PBField
	func get_rf_uint64() -> Array[int]:
		return __rf_uint64.value
	func clear_rf_uint64() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		__rf_uint64.value.clear()
	func add_rf_uint64(value : int) -> void:
		__rf_uint64.value.append(value)
	
	var __rf_sint32: PBField
	func get_rf_sint32() -> Array[int]:
		return __rf_sint32.value
	func clear_rf_sint32() -> void:
		data[29].state = PB_SERVICE_STATE.UNFILLED
		__rf_sint32.value.clear()
	func add_rf_sint32(value : int) -> void:
		__rf_sint32.value.append(value)
	
	var __rf_sint64: PBField
	func get_rf_sint64() -> Array[int]:
		return __rf_sint64.value
	func clear_rf_sint64() -> void:
		data[30].state = PB_SERVICE_STATE.UNFILLED
		__rf_sint64.value.clear()
	func add_rf_sint64(value : int) -> void:
		__rf_sint64.value.append(value)
	
	var __rf_fixed32: PBField
	func get_rf_fixed32() -> Array[int]:
		return __rf_fixed32.value
	func clear_rf_fixed32() -> void:
		data[31].state = PB_SERVICE_STATE.UNFILLED
		__rf_fixed32.value.clear()
	func add_rf_fixed32(value : int) -> void:
		__rf_fixed32.value.append(value)
	
	var __rf_fixed64: PBField
	func get_rf_fixed64() -> Array[int]:
		return __rf_fixed64.value
	func clear_rf_fixed64() -> void:
		data[32].state = PB_SERVICE_STATE.UNFILLED
		__rf_fixed64.value.clear()
	func add_rf_fixed64(value : int) -> void:
		__rf_fixed64.value.append(value)
	
	var __rf_sfixed32: PBField
	func get_rf_sfixed32() -> Array[int]:
		return __rf_sfixed32.value
	func clear_rf_sfixed32() -> void:
		data[33].state = PB_SERVICE_STATE.UNFILLED
		__rf_sfixed32.value.clear()
	func add_rf_sfixed32(value : int) -> void:
		__rf_sfixed32.value.append(value)
	
	var __rf_sfixed64: PBField
	func get_rf_sfixed64() -> Array[int]:
		return __rf_sfixed64.value
	func clear_rf_sfixed64() -> void:
		data[34].state = PB_SERVICE_STATE.UNFILLED
		__rf_sfixed64.value.clear()
	func add_rf_sfixed64(value : int) -> void:
		__rf_sfixed64.value.append(value)
	
	var __rf_bool: PBField
	func get_rf_bool() -> Array[bool]:
		return __rf_bool.value
	func clear_rf_bool() -> void:
		data[35].state = PB_SERVICE_STATE.UNFILLED
		__rf_bool.value.clear()
	func add_rf_bool(value : bool) -> void:
		__rf_bool.value.append(value)
	
	var __rf_string: PBField
	func get_rf_string() -> Array[String]:
		return __rf_string.value
	func clear_rf_string() -> void:
		data[36].state = PB_SERVICE_STATE.UNFILLED
		__rf_string.value.clear()
	func add_rf_string(value : String) -> void:
		__rf_string.value.append(value)
	
	var __rf_bytes: PBField
	func get_rf_bytes() -> Array[PackedByteArray]:
		return __rf_bytes.value
	func clear_rf_bytes() -> void:
		data[37].state = PB_SERVICE_STATE.UNFILLED
		__rf_bytes.value.clear()
	func add_rf_bytes(value : PackedByteArray) -> void:
		__rf_bytes.value.append(value)
	
	var __rf_empty_out: PBField
	func get_rf_empty_out() -> Array[Test0]:
		return __rf_empty_out.value
	func clear_rf_empty_out() -> void:
		data[38].state = PB_SERVICE_STATE.UNFILLED
		__rf_empty_out.value.clear()
	func add_rf_empty_out() -> Test0:
		var element = Test0.new()
		__rf_empty_out.value.append(element)
		return element
	
	var __rf_enum_out: PBField
	func get_rf_enum_out() -> Array:
		return __rf_enum_out.value
	func clear_rf_enum_out() -> void:
		data[39].state = PB_SERVICE_STATE.UNFILLED
		__rf_enum_out.value.clear()
	func add_rf_enum_out(value) -> void:
		__rf_enum_out.value.append(value)
	
	var __rf_empty_inner: PBField
	func get_rf_empty_inner() -> Array[Test2.TestInner2]:
		return __rf_empty_inner.value
	func clear_rf_empty_inner() -> void:
		data[40].state = PB_SERVICE_STATE.UNFILLED
		__rf_empty_inner.value.clear()
	func add_rf_empty_inner() -> Test2.TestInner2:
		var element = Test2.TestInner2.new()
		__rf_empty_inner.value.append(element)
		return element
	
	var __rf_enum_inner: PBField
	func get_rf_enum_inner() -> Array:
		return __rf_enum_inner.value
	func clear_rf_enum_inner() -> void:
		data[41].state = PB_SERVICE_STATE.UNFILLED
		__rf_enum_inner.value.clear()
	func add_rf_enum_inner(value) -> void:
		__rf_enum_inner.value.append(value)
	
	var __rfu_double: PBField
	func get_rfu_double() -> Array[float]:
		return __rfu_double.value
	func clear_rfu_double() -> void:
		data[42].state = PB_SERVICE_STATE.UNFILLED
		__rfu_double.value.clear()
	func add_rfu_double(value : float) -> void:
		__rfu_double.value.append(value)
	
	var __rfu_float: PBField
	func get_rfu_float() -> Array[float]:
		return __rfu_float.value
	func clear_rfu_float() -> void:
		data[43].state = PB_SERVICE_STATE.UNFILLED
		__rfu_float.value.clear()
	func add_rfu_float(value : float) -> void:
		__rfu_float.value.append(value)
	
	var __rfu_int32f: PBField
	func get_rfu_int32f() -> Array[int]:
		return __rfu_int32f.value
	func clear_rfu_int32f() -> void:
		data[44].state = PB_SERVICE_STATE.UNFILLED
		__rfu_int32f.value.clear()
	func add_rfu_int32f(value : int) -> void:
		__rfu_int32f.value.append(value)
	
	var __rfu_int64f: PBField
	func get_rfu_int64f() -> Array[int]:
		return __rfu_int64f.value
	func clear_rfu_int64f() -> void:
		data[45].state = PB_SERVICE_STATE.UNFILLED
		__rfu_int64f.value.clear()
	func add_rfu_int64f(value : int) -> void:
		__rfu_int64f.value.append(value)
	
	var __rfu_uint32: PBField
	func get_rfu_uint32() -> Array[int]:
		return __rfu_uint32.value
	func clear_rfu_uint32() -> void:
		data[46].state = PB_SERVICE_STATE.UNFILLED
		__rfu_uint32.value.clear()
	func add_rfu_uint32(value : int) -> void:
		__rfu_uint32.value.append(value)
	
	var __rfu_uint64: PBField
	func get_rfu_uint64() -> Array[int]:
		return __rfu_uint64.value
	func clear_rfu_uint64() -> void:
		data[47].state = PB_SERVICE_STATE.UNFILLED
		__rfu_uint64.value.clear()
	func add_rfu_uint64(value : int) -> void:
		__rfu_uint64.value.append(value)
	
	var __rfu_sint32: PBField
	func get_rfu_sint32() -> Array[int]:
		return __rfu_sint32.value
	func clear_rfu_sint32() -> void:
		data[48].state = PB_SERVICE_STATE.UNFILLED
		__rfu_sint32.value.clear()
	func add_rfu_sint32(value : int) -> void:
		__rfu_sint32.value.append(value)
	
	var __rfu_sint64: PBField
	func get_rfu_sint64() -> Array[int]:
		return __rfu_sint64.value
	func clear_rfu_sint64() -> void:
		data[49].state = PB_SERVICE_STATE.UNFILLED
		__rfu_sint64.value.clear()
	func add_rfu_sint64(value : int) -> void:
		__rfu_sint64.value.append(value)
	
	var __rfu_fixed32: PBField
	func get_rfu_fixed32() -> Array[int]:
		return __rfu_fixed32.value
	func clear_rfu_fixed32() -> void:
		data[50].state = PB_SERVICE_STATE.UNFILLED
		__rfu_fixed32.value.clear()
	func add_rfu_fixed32(value : int) -> void:
		__rfu_fixed32.value.append(value)
	
	var __rfu_fixed64: PBField
	func get_rfu_fixed64() -> Array[int]:
		return __rfu_fixed64.value
	func clear_rfu_fixed64() -> void:
		data[51].state = PB_SERVICE_STATE.UNFILLED
		__rfu_fixed64.value.clear()
	func add_rfu_fixed64(value : int) -> void:
		__rfu_fixed64.value.append(value)
	
	var __rfu_sfixed32: PBField
	func get_rfu_sfixed32() -> Array[int]:
		return __rfu_sfixed32.value
	func clear_rfu_sfixed32() -> void:
		data[52].state = PB_SERVICE_STATE.UNFILLED
		__rfu_sfixed32.value.clear()
	func add_rfu_sfixed32(value : int) -> void:
		__rfu_sfixed32.value.append(value)
	
	var __rfu_sfixed64: PBField
	func get_rfu_sfixed64() -> Array[int]:
		return __rfu_sfixed64.value
	func clear_rfu_sfixed64() -> void:
		data[53].state = PB_SERVICE_STATE.UNFILLED
		__rfu_sfixed64.value.clear()
	func add_rfu_sfixed64(value : int) -> void:
		__rfu_sfixed64.value.append(value)
	
	var __rfu_bool: PBField
	func get_rfu_bool() -> Array[bool]:
		return __rfu_bool.value
	func clear_rfu_bool() -> void:
		data[54].state = PB_SERVICE_STATE.UNFILLED
		__rfu_bool.value.clear()
	func add_rfu_bool(value : bool) -> void:
		__rfu_bool.value.append(value)
	
	var __rf_inner: PBField
	func get_rf_inner() -> Array[Test2.TestInner3.TestInner3_2]:
		return __rf_inner.value
	func clear_rf_inner() -> void:
		data[55].state = PB_SERVICE_STATE.UNFILLED
		__rf_inner.value.clear()
	func add_rf_inner() -> Test2.TestInner3.TestInner3_2:
		var element = Test2.TestInner3.TestInner3_2.new()
		__rf_inner.value.append(element)
		return element
	
	class map_type_f_map:
		func _init():
			var service
			
			__key = PBField.new("key", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
			__key.is_map_field = true
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
			__value.is_map_field = true
			service = PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data = {}
		
		var __key: PBField
		func has_key() -> bool:
			if __key.value != null:
				return true
			return false
		func get_key() -> int:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		func set_key(value : int) -> void:
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			if __value.value != null:
				return true
			return false
		func get_value() -> int:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		func set_value(value : int) -> void:
			__value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Test2:
	func _init():
		var service
		
		var __f1_default: Array[String] = []
		__f1 = PBField.new("f1", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 1, true, __f1_default)
		service = PBServiceField.new()
		service.field = __f1
		data[__f1.tag] = service
		
		__f2 = PBField.new("f2", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64])
		service = PBServiceField.new()
		service.field = __f2
		data[__f2.tag] = service
		
		__f3 = PBField.new("f3", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __f3
		data[__f3.tag] = service
		
		__f4 = PBField.new("f4", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f4
		service.func_ref = Callable(self, "new_f4")
		data[__f4.tag] = service
		
		__f5 = PBField.new("f5", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f5
		service.func_ref = Callable(self, "new_f5")
		data[__f5.tag] = service
		
		__f6 = PBField.new("f6", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f6
		service.func_ref = Callable(self, "new_f6")
		data[__f6.tag] = service
		
		__f7 = PBField.new("f7", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __f7
		service.func_ref = Callable(self, "new_f7")
		data[__f7.tag] = service
		
	var data = {}
	
	var __f1: PBField
	func get_f1() -> Array[String]:
		return __f1.value
	func clear_f1() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__f1.value.clear()
	func add_f1(value : String) -> void:
		__f1.value.append(value)
	
	var __f2: PBField
	func has_f2() -> bool:
		if __f2.value != null:
			return true
		return false
	func get_f2() -> int:
		return __f2.value
	func clear_f2() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64]
	func set_f2(value : int) -> void:
		__f2.value = value
	
	var __f3: PBField
	func has_f3() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func has_f3() -> bool:
		if __f3.value != null:
			return true
		return false
	func get_f3() -> String:
		return __f3.value
	func clear_f3() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_f3(value : String) -> void:
		data[3].state = PB_SERVICE_STATE.FILLED
		__f4.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__f3.value = value
	
	var __f4: PBField
	func has_f4() -> bool:
		if __f4.value != null:
			return true
		return false
	func get_f4() -> Test2.TestInner3:
		return __f4.value
	func clear_f4() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__f4.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f4() -> Test2.TestInner3:
		__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		__f4.value = Test2.TestInner3.new()
		return __f4.value
	
	var __f5: PBField
	func has_f5() -> bool:
		if __f5.value != null:
			return true
		return false
	func get_f5() -> Test2.TestInner2:
		return __f5.value
	func clear_f5() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__f5.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f5() -> Test2.TestInner2:
		__f5.value = Test2.TestInner2.new()
		return __f5.value
	
	var __f6: PBField
	func has_f6() -> bool:
		if __f6.value != null:
			return true
		return false
	func get_f6() -> Test2.TestInner3:
		return __f6.value
	func clear_f6() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__f6.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f6() -> Test2.TestInner3:
		__f6.value = Test2.TestInner3.new()
		return __f6.value
	
	var __f7: PBField
	func has_f7() -> bool:
		if __f7.value != null:
			return true
		return false
	func get_f7() -> Test2.TestInner1:
		return __f7.value
	func clear_f7() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__f7.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_f7() -> Test2.TestInner1:
		__f7.value = Test2.TestInner1.new()
		return __f7.value
	
	enum TestEnum {
		VALUE_0 = 0,
		VALUE_1 = 1,
		VALUE_2 = 2,
		VALUE_3 = 3
	}
	
	class TestInner1:
		func _init():
			var service
			
			var __f1_default: Array[float] = []
			__f1 = PBField.new("f1", PB_DATA_TYPE.DOUBLE, PB_RULE.REPEATED, 1, true, __f1_default)
			service = PBServiceField.new()
			service.field = __f1
			data[__f1.tag] = service
			
			__f2 = PBField.new("f2", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = __f2
			data[__f2.tag] = service
			
			__f3 = PBField.new("f3", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			service = PBServiceField.new()
			service.field = __f3
			data[__f3.tag] = service
			
		var data = {}
		
		var __f1: PBField
		func get_f1() -> Array[float]:
			return __f1.value
		func clear_f1() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__f1.value.clear()
		func add_f1(value : float) -> void:
			__f1.value.append(value)
		
		var __f2: PBField
		func has_f2() -> bool:
			if __f2.value != null:
				return true
			return false
		func get_f2() -> float:
			return __f2.value
		func clear_f2() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
		func set_f2(value : float) -> void:
			__f2.value = value
		
		var __f3: PBField
		func has_f3() -> bool:
			if __f3.value != null:
				return true
			return false
		func get_f3() -> String:
			return __f3.value
		func clear_f3() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_f3(value : String) -> void:
			__f3.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class TestInner2:
		func _init():
			var service
			
		var data = {}
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class TestInner3:
		func _init():
			var service
			
			var __f1_default: Array = []
			__f1 = PBField.new("f1", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 1, true, __f1_default)
			service = PBServiceField.new()
			service.field = __f1
			service.func_ref = Callable(self, "add_empty_f1")
			data[__f1.tag] = service
			
			__f2 = PBField.new("f2", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
			service = PBServiceField.new()
			service.field = __f2
			data[__f2.tag] = service
			
			__f3 = PBField.new("f3", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
			service = PBServiceField.new()
			service.field = __f3
			service.func_ref = Callable(self, "new_f3")
			data[__f3.tag] = service
			
		var data = {}
		
		var __f1: PBField
		func get_raw_f1():
			return __f1.value
		func get_f1():
			return PBPacker.construct_map(__f1.value)
		func clear_f1():
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
		func add_empty_f1() -> Test2.TestInner3.map_type_f1:
			var element = Test2.TestInner3.map_type_f1.new()
			__f1.value.append(element)
			return element
		func add_f1(a_key) -> Test2.TestInner3.TestInner3_2:
			var idx = -1
			for i in range(__f1.value.size()):
				if __f1.value[i].get_key() == a_key:
					idx = i
					break
			var element = Test2.TestInner3.map_type_f1.new()
			element.set_key(a_key)
			if idx != -1:
				__f1.value[idx] = element
			else:
				__f1.value.append(element)
			return element.new_value()
		
		var __f2: PBField
		func has_f2() -> bool:
			if __f2.value != null:
				return true
			return false
		func get_f2():
			return __f2.value
		func clear_f2() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
		func set_f2(value) -> void:
			__f2.value = value
		
		var __f3: PBField
		func has_f3() -> bool:
			if __f3.value != null:
				return true
			return false
		func get_f3() -> Test2.TestInner3.TestInner3_1:
			return __f3.value
		func clear_f3() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		func new_f3() -> Test2.TestInner3.TestInner3_1:
			__f3.value = Test2.TestInner3.TestInner3_1.new()
			return __f3.value
		
		class TestInner3_1:
			func _init():
				var service
				
			var data = {}
			
			func _to_string() -> String:
				return PBPacker.message_to_string(data)
				
			func to_bytes() -> PackedByteArray:
				return PBPacker.pack_message(data)
				
			func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
				var cur_limit = bytes.size()
				if limit != -1:
					cur_limit = limit
				var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
				if result == cur_limit:
					if PBPacker.check_required(data):
						if limit == -1:
							return PB_ERR.NO_ERRORS
					else:
						return PB_ERR.REQUIRED_FIELDS
				elif limit == -1 && result > 0:
					return PB_ERR.PARSE_INCOMPLETE
				return result
			
		class TestInner3_2:
			func _init():
				var service
				
				__f1 = PBField.new("f1", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
				service = PBServiceField.new()
				service.field = __f1
				data[__f1.tag] = service
				
				__f2 = PBField.new("f2", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
				service = PBServiceField.new()
				service.field = __f2
				data[__f2.tag] = service
				
			var data = {}
			
			var __f1: PBField
			func has_f1() -> bool:
				if __f1.value != null:
					return true
				return false
			func get_f1() -> int:
				return __f1.value
			func clear_f1() -> void:
				data[1].state = PB_SERVICE_STATE.UNFILLED
				__f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
			func set_f1(value : int) -> void:
				__f1.value = value
			
			var __f2: PBField
			func has_f2() -> bool:
				if __f2.value != null:
					return true
				return false
			func get_f2() -> int:
				return __f2.value
			func clear_f2() -> void:
				data[2].state = PB_SERVICE_STATE.UNFILLED
				__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
			func set_f2(value : int) -> void:
				__f2.value = value
			
			func _to_string() -> String:
				return PBPacker.message_to_string(data)
				
			func to_bytes() -> PackedByteArray:
				return PBPacker.pack_message(data)
				
			func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
				var cur_limit = bytes.size()
				if limit != -1:
					cur_limit = limit
				var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
				if result == cur_limit:
					if PBPacker.check_required(data):
						if limit == -1:
							return PB_ERR.NO_ERRORS
					else:
						return PB_ERR.REQUIRED_FIELDS
				elif limit == -1 && result > 0:
					return PB_ERR.PARSE_INCOMPLETE
				return result
			
		class map_type_f1:
			func _init():
				var service
				
				__key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
				__key.is_map_field = true
				service = PBServiceField.new()
				service.field = __key
				data[__key.tag] = service
				
				__value = PBField.new("value", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
				__value.is_map_field = true
				service = PBServiceField.new()
				service.field = __value
				service.func_ref = Callable(self, "new_value")
				data[__value.tag] = service
				
			var data = {}
			
			var __key: PBField
			func has_key() -> bool:
				if __key.value != null:
					return true
				return false
			func get_key() -> String:
				return __key.value
			func clear_key() -> void:
				data[1].state = PB_SERVICE_STATE.UNFILLED
				__key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
			func set_key(value : String) -> void:
				__key.value = value
			
			var __value: PBField
			func has_value() -> bool:
				if __value.value != null:
					return true
				return false
			func get_value() -> Test2.TestInner3.TestInner3_2:
				return __value.value
			func clear_value() -> void:
				data[2].state = PB_SERVICE_STATE.UNFILLED
				__value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
			func new_value() -> Test2.TestInner3.TestInner3_2:
				__value.value = Test2.TestInner3.TestInner3_2.new()
				return __value.value
			
			func _to_string() -> String:
				return PBPacker.message_to_string(data)
				
			func to_bytes() -> PackedByteArray:
				return PBPacker.pack_message(data)
				
			func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
				var cur_limit = bytes.size()
				if limit != -1:
					cur_limit = limit
				var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
				if result == cur_limit:
					if PBPacker.check_required(data):
						if limit == -1:
							return PB_ERR.NO_ERRORS
					else:
						return PB_ERR.REQUIRED_FIELDS
				elif limit == -1 && result > 0:
					return PB_ERR.PARSE_INCOMPLETE
				return result
			
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Test4:
	func _init():
		var service
		
		__f1 = PBField.new("f1", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __f1
		data[__f1.tag] = service
		
		__f2 = PBField.new("f2", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __f2
		data[__f2.tag] = service
		
		__f3 = PBField.new("f3", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f3
		data[__f3.tag] = service
		
		__f4 = PBField.new("f4", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 160, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = __f4
		data[__f4.tag] = service
		
		var __f5_default: Array = []
		__f5 = PBField.new("f5", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 99, true, __f5_default)
		service = PBServiceField.new()
		service.field = __f5
		service.func_ref = Callable(self, "add_empty_f5")
		data[__f5.tag] = service
		
	var data = {}
	
	var __f1: PBField
	func has_f1() -> bool:
		if __f1.value != null:
			return true
		return false
	func get_f1() -> int:
		return __f1.value
	func clear_f1() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_f1(value : int) -> void:
		__f1.value = value
	
	var __f2: PBField
	func has_f2() -> bool:
		if __f2.value != null:
			return true
		return false
	func get_f2() -> String:
		return __f2.value
	func clear_f2() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_f2(value : String) -> void:
		__f2.value = value
	
	var __f3: PBField
	func has_f3() -> bool:
		if __f3.value != null:
			return true
		return false
	func get_f3() -> float:
		return __f3.value
	func clear_f3() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]
	func set_f3(value : float) -> void:
		__f3.value = value
	
	var __f4: PBField
	func has_f4() -> bool:
		if __f4.value != null:
			return true
		return false
	func get_f4() -> float:
		return __f4.value
	func clear_f4() -> void:
		data[160].state = PB_SERVICE_STATE.UNFILLED
		__f4.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_f4(value : float) -> void:
		__f4.value = value
	
	var __f5: PBField
	func get_raw_f5():
		return __f5.value
	func get_f5():
		return PBPacker.construct_map(__f5.value)
	func clear_f5():
		data[99].state = PB_SERVICE_STATE.UNFILLED
		__f5.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_f5() -> Test4.map_type_f5:
		var element = Test4.map_type_f5.new()
		__f5.value.append(element)
		return element
	func add_f5(a_key, a_value) -> void:
		var idx = -1
		for i in range(__f5.value.size()):
			if __f5.value[i].get_key() == a_key:
				idx = i
				break
		var element = Test4.map_type_f5.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			__f5.value[idx] = element
		else:
			__f5.value.append(element)
	
	class map_type_f5:
		func _init():
			var service
			
			__key = PBField.new("key", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
			__key.is_map_field = true
			service = PBServiceField.new()
			service.field = __key
			data[__key.tag] = service
			
			__value = PBField.new("value", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
			__value.is_map_field = true
			service = PBServiceField.new()
			service.field = __value
			data[__value.tag] = service
			
		var data = {}
		
		var __key: PBField
		func has_key() -> bool:
			if __key.value != null:
				return true
			return false
		func get_key() -> int:
			return __key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		func set_key(value : int) -> void:
			__key.value = value
		
		var __value: PBField
		func has_value() -> bool:
			if __value.value != null:
				return true
			return false
		func get_value() -> int:
			return __value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
		func set_value(value : int) -> void:
			__value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################

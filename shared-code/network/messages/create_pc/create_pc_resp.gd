class_name CreatePcResp extends Message

func get_type() -> Action:
    return Action.create_pc_resp


func serialize() -> Dictionary:
    return { "error": error }


func deserialize(data: Dictionary) -> void:
    error = data.get("error", "Error key not found in response!")


func validate() -> bool:
    return error == ""

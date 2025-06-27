class_name GetAllPcResp extends Message


func get_type() -> Action:
    return Action.get_pc_resp


func serialize() -> Dictionary:
    return { }


func deserialize(dict: Dictionary) -> void:
    pass


func validate() -> bool:
    return true

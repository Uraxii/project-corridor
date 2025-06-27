class_name SpawnPcReq extends Message

var character_id: String


func get_type() -> Action:
    return Action.spawn_pc_req


func serialize() -> Dictionary:
    var dict := { "id": character_id }
    
    if error:
        dict["e"] = error
        
    return dict


func deserialize(data: Dictionary) -> void:
    character_id = data.get("id", "")
    error = data.get("e", "")


func validate() -> bool:
    return character_id != ""

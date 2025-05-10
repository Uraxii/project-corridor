class_name Message extends Resource


# Used to route messages
func get_type() -> String:
    push_error("get_type() must be implemented")
    return ""


func serialize() -> Dictionary:
    push_error("serialize() must be implemented")
    return {}


func deserialize(dict: Dictionary) -> void:
    push_error("deserialize() must be implemented")


func validate() -> bool:
    return true

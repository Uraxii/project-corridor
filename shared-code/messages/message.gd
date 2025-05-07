class_name Message extends Resource

# Used to route messages
func get_type() -> String:
    push_error("get_type() must be implemented")
    return ""


# Used to load from client request
func from_dict(dict: Dictionary) -> void:
    push_error("from_dict() must be implemented")


# Used to send back to client
func to_response_dict() -> Dictionary:
    push_error("to_response_dict() must be implemented")
    return {}


#validate input
func validate() -> bool:
    return true

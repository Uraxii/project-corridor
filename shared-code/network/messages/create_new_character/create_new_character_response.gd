class_name CreateNewCharacterResponse extends Message

var error: String


# Used to route messages
func get_type() -> String:
    return "CreateNewCharacterResponse"


func serialize() -> Dictionary:
    return { "error": error }


func deserialize(data: Dictionary) -> void:
    error = data.get("error", "Error key not found in response!")


func validate() -> bool:
    return error == ""

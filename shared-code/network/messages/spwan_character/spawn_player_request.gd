class_name SpawnPlayerRequest extends Message

var display_name: String


func get_type() -> String:
    return "SpawnPlayer"


func serialize() -> Dictionary:
    return { "display_name": display_name }


func deserialize(data: Dictionary) -> void:
    display_name = data.get("display_name", "")


func validate() -> bool:
    return display_name != ""
    

class_name SpawnPlayerResponse

var coordinates: Vector3
var display_name: String
var zone: String
var error: String


func get_type() -> String:
    return "SpawnPlayerResponse"


func serialize() -> Dictionary:
    return { 
        "coordinates": coordinates,
        "display_name": display_name,
        "zone": zone,    
        "error": error,
    }


func deserialize(data: Dictionary) -> void:
    coordinates = data.get("coordinates", Vector3.ZERO)
    display_name = data.get("display_name", "")
    zone = data.get("zone", "")
    error = data.get("error", "Error key not found in response!")


func validate() -> bool:
    if error:
        return false
    
    return (coordinates != Vector3.ZERO and display_name != "") and zone != ""

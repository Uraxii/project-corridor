class_name CharacterData extends Model

var coordinates: Vector3
var display_name: String
var zone: String


func serialize() -> Dictionary:
    return {
        "display_name": display_name,
        "coordinates": coordinates,
        "zone": zone
    }


func deserialize(data: Dictionary) -> void:
    display_name = data.get("display_name", "")
    coordinates = data.get("coordinates", Vector3.ZERO)
    zone = data.get("zone", "")

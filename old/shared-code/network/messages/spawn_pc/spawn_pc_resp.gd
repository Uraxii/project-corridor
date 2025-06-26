class_name SpawnPcResp extends Message

var authority: int
var coordinates: Vector3
var display_name: String
var id: int
var instance: String
var zone: String


func get_type() -> Action:
    return Action.spawn_pc_resp


func serialize() -> Dictionary:
    var dict: Dictionary = {
        "a": authority,
        "c": coordinates,
        "n": display_name,
        "id": id,
        "i": instance,
        "z": zone,
    }
    
    if error:
        dict["e"] = error
    
    return dict


func deserialize(data: Dictionary) -> void:
    authority       = data.get("a", 1)
    coordinates     = data.get("c", Vector3.ZERO)
    display_name    = data.get("n", "")
    id              = data.get("id", 0)
    instance        = data.get("i", "")
    zone            = data.get("z", "")
    error           = data.get("e", "")


func validate() -> bool:
    if error:
        return false

    return (coordinates != Vector3.ZERO and display_name != "") and zone != ""

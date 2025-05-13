class_name CharacterSelectController extends Controller


func get_routes() -> Array[Dictionary]:
    return [{"type": "get_characters", "handler": "get_characters"}]


func get_characters(peer_id: int, data: Dictionary) -> void:
    push_error("Not implemented!")

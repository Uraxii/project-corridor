class_name LoginController extends Controller


func get_routes() -> Array[Dictionary]:
    return [{"type": "login", "handler": "_on_login"}]


func _on_login(peer_id: int, data: Dictionary) -> Dictionary:
    var request := LoginRequest.new()
    request.deserialize(data)
    
    print(request.serialize())
    
    var response := LoginResponse.new()
    
    if request.username != "" and request.password != "":
        response.session_token = "insecure"
        response.success = true
    else:
        response.session_token = ""
        response.success = false
    
    return response.serialize()

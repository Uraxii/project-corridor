class_name LoginController extends Controller


func get_routes() -> Array[Dictionary]:
    return [{"message_type": "login", "handler_method": "login"}]


func login(peer_id: int, data: Dictionary) -> Dictionary:
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

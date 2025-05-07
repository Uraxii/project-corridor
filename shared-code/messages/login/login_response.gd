class_name LoginResponse extends Message

var success: bool = false
var session_token: String = ""


func to_dict() -> Dictionary:
    return {
        "type": "login_response",
        "success": success,
        "session_token": session_token
    }


func from_dict(dict: Dictionary) -> void:
    success = dict.get("success", false)
    session_token = dict.get("session_token", "")

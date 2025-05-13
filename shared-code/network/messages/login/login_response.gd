class_name LoginResponse extends Message

var success: bool = false
var session_token: String = ""


func serialize() -> Dictionary:
    return {
        "success": success,
        "session_token": session_token,
        "error_message": "",
    }


func deserialize(dict: Dictionary) -> void:
    success = dict.get("success", false)
    session_token = dict.get("session_token", "")


func validate() -> bool:
    return session_token != ""

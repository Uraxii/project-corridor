class_name LoginResp extends Message

var success: bool = false
var session_token: String = ""


func get_type() -> Action:
    return Action.login_resp


func serialize() -> Dictionary:
    return {
        "s": success,
        "t": session_token,
    }


func deserialize(dict: Dictionary) -> void:
    success = dict.get("s", false)
    session_token = dict.get("t", "")


func validate() -> bool:
    return session_token != ""

class_name LoginRequest extends Message

var username: String = ""
var password: String = ""


func get_type() -> String:
    return "login"


func from_dict(dict: Dictionary) -> void:
    username = dict.get("username", "")
    password = dict.get("password", "")


func validate() -> bool:
    return username != "" and password != ""

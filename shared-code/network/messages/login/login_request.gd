class_name LoginRequest extends Message

var username: String = ""
var password: String = ""


func serialize() -> Dictionary:
    return {
        "username": username,
        "password": password
    }


func deserialize(dict: Dictionary) -> void:
    print(dict)
    username = dict.get("username", "")
    password = dict.get("password", "")


func validate() -> bool:
    return username != "" and password != ""

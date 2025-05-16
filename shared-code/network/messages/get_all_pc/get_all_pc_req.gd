class_name GetAllPcReq extends Message

var username: String = ""
var password: String = ""


func get_type() -> Action:
    return Action.get_pc_req


func serialize() -> Dictionary:
    return {
        "u": username,
        "p": password
    }


func deserialize(dict: Dictionary) -> void:
    username = dict.get("u", "")
    password = dict.get("p", "")


func validate() -> bool:
    return username != "" and password != ""

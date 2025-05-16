class_name Message extends Object

enum Action
{
    base = 0,
    login_req,
    login_resp,
    get_pc_req,
    get_pc_resp,
    create_pc_req,
    create_pc_resp,
    spawn_pc_req,
    spawn_pc_resp,
}

var origin_peer: int = -1
# The destination peer may not always be set. Not every Messages requires it.
var dest_peer: int = -1


# Used to route messages
func get_type() -> Action:
    push_error("get_type() must be implemented")
    return Action.base


func serialize() -> Dictionary:
    push_error("serialize() must be implemented")
    return {}


func deserialize(dict: Dictionary) -> void:
    push_error("deserialize() must be implemented")


func validate() -> bool:
    push_error("validate() must be implemented!")
    return false

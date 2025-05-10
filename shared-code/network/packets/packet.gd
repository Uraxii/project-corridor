class_name Packet extends Object

enum Action {
    Login,
    Error,
}

var action: Action
var payloads: Array


func _init(_action: Action, _payloads: Array) -> void:
    action = _action
    payloads = _payloads


func serialize() -> String:
    var serialized_dict := {"a": action}
    
    for i in len(payloads):
        serialized_dict["p%d"] = payloads[i]
    
    return JSON.stringify(serialized_dict)


func deserialize(json_str: String) -> Array:
    var action: Action
    var payloads: Array = []
    var json := JSON.new()
    var err := json.parse(json_str)
    
    if err:
        push_error(
            "Failed to parse JSON str message! Error: %s" % error_string(err))
            
        return [Action.Error, [error_string(err)]]
    
    var data := json.data() as Dictionary
    
    if not data:
        push_error("Received JSON is not a Dictionary!")
        return [Action.Error, ["JSON not Dictionary."]]
    
    action = data.get("a", Action.Error)
    
    for key in data.keys():
        if key[0] == "p":
            var index: int = key.split_floats("p", true)[1]
            payloads.insert(index, data[key])
    
    return [action, payloads]
    

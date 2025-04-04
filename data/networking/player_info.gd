class_name PlayerInfo

var display_name:       String  = ""
var network_id:         int     = -1


func _init(name: String, id: int) -> void:
        self.display_name = name
        self.network_id = id

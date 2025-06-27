class_name PlayerInfo

var owner:      String
var position:   Vector3
var direction:  Vector3


func _init(owner_node: String, current_position: Vector3, current_direction: Vector3) -> void:
        self.owner = owner_node
        self.position = current_position
        self.direction = current_direction

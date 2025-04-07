class_name PlayerInfo

var owner:      int
var position:   Vector3
var direction:  Vector3


func _init(owner_id: int, current_position: Vector3, current_direction: Vector3) -> void:
        self.owner = owner_id
        self.position = current_position
        self.direction = current_direction

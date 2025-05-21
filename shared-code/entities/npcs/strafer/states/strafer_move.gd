class_name StraferPatrolState extends StateBase

@export var tollerance:         float           = 0.8
@export var patrol_locations:   Array[Node3D]   = []

var current_index:      int
var target:        Node3D


func frame_update(entity: Entity) -> void:
        var distance_to_target = entity.body.global_position.distance_to(target.global_position)

        # print('distance to target: ', distance_to_target)

        if distance_to_target <= tollerance:
                target = get_next_target()


        entity.body.look_at(target.position +  Vector3(0.001, 0.0, 0.0))
        entity.move.move_towards(target.position, entity.get_speed() * 0.8)


func get_next_target() -> Node3D:
        current_index += 1

        if current_index >= patrol_locations.size():
                current_index = 0

        # print('Next target: %s, index: %d' % [patrol_locations[current_index].name, current_index])

        return patrol_locations[current_index]


func _ready() -> void:
        current_index = 1
        target = patrol_locations[current_index]

class_name PlayerSelectTarget extends Area3D

const MAX_TARGETING_DISTACNE = 50

@onready var body: CharacterBody3D = %Body

var potential_targets: Array[Entity] = []
var next_target:int = 0
var player_owner: Entity = null


func initialize(player: Entity):
        player_owner = player
        set_monitoring(true)


func _process(_delta: float) -> void:
        global_position = body.global_position
        global_rotation = body.global_rotation

        if player_owner.target != null and position.distance_to(player_owner.target.body.position) > MAX_TARGETING_DISTACNE:
                player_owner.set_target(null)


func _on_body_entered(body):
        # print('body entered targeting zone.')

        var parent_node = body.get_parent()

        if parent_node == player_owner or parent_node is not Entity:
                return

        potential_targets.append(parent_node)


func _on_body_exited(body):
        # print('body left targeting zone.')

        var parent_node = body.get_parent()

        if parent_node is not Entity or not (parent_node in potential_targets):
                return

        potential_targets.erase(parent_node)


func set_target(new_target: Entity) -> void:
        player_owner.set_target(new_target)


func target_next() -> void:
        if potential_targets.size() == 0:
                return

        if next_target > potential_targets.size() - 1:
                next_target = 0

        # print('Current target:', potential_targets[next_target].name)

        player_owner.set_target(potential_targets[next_target])

        next_target += 1

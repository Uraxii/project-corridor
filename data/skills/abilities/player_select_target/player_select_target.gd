class_name PlayerSelectTarget extends Area3D

@export var cooldown:float = 0
@export var refresh_rate: float = 0.1

@onready var vision_timer = Timer.new()

var target_cache: Array[Entity] = []
var next_target:int = 0
var player_owner: Entity = null


func initialize(player: Entity):
        player_owner = player


func target_next() -> void:
        if target_cache.size() == 0:
                return

        # print('Current target:', target_cache[next_target].name)

        player_owner.set_target(target_cache[next_target])

        if next_target + 1 > target_cache.size() - 1:
                next_target = 0
        else:
                next_target += 1


func target_entity(new_target: Entity) -> void:
        player_owner.set_target(new_target)


func refresh_targets() -> void :
        position = player_owner.body.position

        var collisions = get_overlapping_bodies()

        target_cache.clear()

        for body in collisions:
                var entity = body.get_parent()
                if entity is Entity and entity != player_owner:
                        target_cache.append(entity)

        # print('Refreshed target_cache. Size:', target_cache.size())


func _ready() -> void:
        vision_timer.wait_time = refresh_rate
        add_child(vision_timer)
        vision_timer.timeout.connect(refresh_targets)
        vision_timer.start()

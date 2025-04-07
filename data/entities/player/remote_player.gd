class_name RemotePlayer extends Entity

@export var stats: Stats
@onready var movement: Movement = %Movement
@onready var health: Health = $Components/Health

var player_info: PlayerInfo


func _ready() -> void:
        super._ready()


func _process(delta: float) -> void:
        super._process(delta)


func _physics_process(delta: float) -> void:
        super._process(delta)

        if player_info.owner not in Server.connections.keys():
                queue_free()

        player_info = Server.connections[player_info.owner]

        if body.rotation.distance_to(player_info.direction) > 0.1:
                body.rotation = player_info.direction

        if body.position.distance_to(player_info.position) > 0.1:
                movement.move_towards(player_info.position, stats.current_speed)

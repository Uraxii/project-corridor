extends Node

signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected

const DEFAULT_SERVER_IP: String = "localhost"
const PORT: int = 7000
const MAX_CONNECTIONS: int = 2

const HOST_ID: int = 1

var entry_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var lobby_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var level_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var player_scene:       Resource = preload("res://data/entities/player/player.tscn")
var remote_player_scene:Resource = preload("res://data/entities/player/remote_player.tscn")

var connections: Dictionary[int, PlayerInfo] = {}
var current_scene: Node


@rpc("any_peer", "call_local")
func update_player_info(position: Vector3, rotation: Vector3) -> void:
        # If client is trying to control another player, ignore the request.
        var player_info = PlayerInfo.new(multiplayer.get_remote_sender_id(), position, rotation)

        if player_info.owner not in connections.keys():
                instantiate_player(player_info)

        connections[player_info.owner] = player_info


func instantiate_player(player_info: PlayerInfo) -> void:
        connections[player_info.owner] = player_info

        var new_player

        if player_info.owner == multiplayer.get_unique_id():
                new_player = player_scene.instantiate()
        else:
                new_player = remote_player_scene.instantiate()

        new_player.name = "conn=%s" % player_info.owner
        new_player.player_info = player_info

        PlayerContainer.add_child(new_player)

        print("INFO=Created player.\tDisplay Name=%s\tID=%s" % [new_player.name, player_info.owner])


func start_client(address=DEFAULT_SERVER_IP, port=PORT):
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_client(address, port)

        if error:
                return error

        multiplayer.multiplayer_peer = peer


func start_server():
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_server(PORT, MAX_CONNECTIONS)

        if error:
                return error

        multiplayer.multiplayer_peer = peer


func load_world():
        transition_scene(lobby_scene)

        if multiplayer.is_server():
                _on_connected_ok()


func transition_scene(new_scene: Resource):
        if current_scene != null:
                current_scene.queue_free()

        current_scene = new_scene.instantiate()
        get_tree().root.add_child(current_scene)


func _ready() -> void:
        multiplayer.peer_connected.connect(_on_client_connected)
        multiplayer.peer_disconnected.connect(_on_client_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_client_connected(id: int) -> void:
        print("Connected.")


func _on_client_disconnected(id):
        connections.erase(id)
        client_disconnected.emit(id)


func _on_connected_ok() -> void:
        var client_id: int = multiplayer.get_unique_id()
        var player_info = PlayerInfo.new(multiplayer.get_unique_id(), Vector3.ZERO, Vector3.ZERO)
        instantiate_player(player_info)
        client_connected.emit(client_id)


func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null


func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        connections.clear()
        server_disconnected.emit()

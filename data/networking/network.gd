#Godot global "Network"
extends Node

#region Singals
signal poll
signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected
#endregion

#region Constansts
const DEFAULT_SERVER_ADDRESS:   String  = "localhost"
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const INVALID_PEER_ID:          int     = -1
const ALL_PEERS:                int     = 0
const SERVER_ID:                int     = 1
#endregion

#region Instance Variables
var poll_timer:    Timer = Timer.new()
var polling_rate:  int   = 30:
        set(value):
                polling_rate = value
                # Inteval in seconds between network polls
                poll_timer.wait_time = 1.0 / polling_rate


@onready var player_spawner:    MultiplayerSpawner = %PlayerSpawner
@onready var npc_spawner:       MultiplayerSpawner = %NpcSpawner
@onready var level_spawner:     MultiplayerSpawner = %LevelSpawner

@onready var player_container:  Node = %Players
@onready var npc_container:     Node = %NPCs
@onready var level_container:   Node = %Levels

var my_peer_id: int:
        get():
                return multiplayer.get_unique_id()


var entry_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var lobby_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var level_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var player_scene:       Resource = preload("res://data/entities/player/player.tscn")

var connections:        Dictionary[int, PlayerInfo] = {}
var current_scene:      Node
#endregion


#region Godot Callback Functions
func _ready() -> void:
        multiplayer.peer_connected.connect(_on_client_connected)
        multiplayer.peer_disconnected.connect(_on_client_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        # Allows us to manually controll the polling rate.
        get_tree().multiplayer_poll = false
        poll_timer.autostart = true
        poll_timer.timeout.connect(_poll_network_peers)


func _exit_tree() -> void:
        multiplayer.peer_connected.disconnect(_on_client_connected)
        multiplayer.peer_disconnected.disconnect(_on_client_disconnected)
        multiplayer.connected_to_server.disconnect(_on_connected_ok)
        multiplayer.connection_failed.disconnect(_on_connected_fail)
        multiplayer.server_disconnected.disconnect(_on_server_disconnected)
#endregion


#region Player Management
func spawn_player(peer_id: int) -> void:
        if not multiplayer.is_server():
                return

        # Logger.debug("Added player.", {"client id": peer_id})

        var player: Player = player_scene.instantiate()
        player.name = str(peer_id)

        player_container.add_child(player, true)
        player.id = peer_id


func remove_player(id: int) -> void:
        if not multiplayer.is_server():
                return

        if not player_container.has_node(str(id)):
                return

        player_container.get_node(str(id)).queue_free()
#endregion


func load_world():
        _transition_scene(lobby_scene)

        if multiplayer.is_server():
                _on_connected_ok()


func _transition_scene(new_scene: Resource):
        if current_scene != null:
                current_scene.queue_free()

        current_scene = new_scene.instantiate()
        get_tree().root.add_child(current_scene)


#region Network Functions
func start_client(address: String, port: int):
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_client(address, port)

        if error:
                return error

        multiplayer.multiplayer_peer = peer

        polling_rate = DEFAULT_POLLING_RATE
        add_child(poll_timer)


func start_server(port: int, max_connections: int):
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_server(port, max_connections)

        if error:
                return error

        multiplayer.multiplayer_peer = peer

        polling_rate = DEFAULT_POLLING_RATE
        add_child(poll_timer)

        spawn_player(SERVER_ID)


func _poll_network_peers() -> void:
        # Logger.debug("Polling.", {"polling rate":polling_rate,"interval":poll_timer.wait_time})

        multiplayer.poll()
        poll.emit()


func _on_client_connected(id: int) -> void:
        spawn_player(id)


func _on_client_disconnected(id):
        remove_player(id)

        connections.erase(id)
        client_disconnected.emit(id)


func _on_connected_ok() -> void:
        var peer_id: int = multiplayer.get_unique_id()
        my_peer_id = peer_id
        client_connected.emit(peer_id)


func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null


func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        connections.clear()
        server_disconnected.emit()
#endregion

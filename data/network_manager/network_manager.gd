extends Node

signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected
signal scene_changed

const DEFAULT_SERVER_IP: String = "localhost"
const PORT: int = 7000
const MAX_CONNECTIONS: int = 2

@onready var players_node:Node = get_tree().root.get_node("Players")

var entry_scene: Resource = preload("res://Scenes/main_menu.tscn")
var lobby_scene: Resource = preload("res://Scenes/lobby.tscn")
var level_scene: Resource = preload("res://Scenes/test_level.tscn")
var player_scene: Resource = preload("res://Scenes/Characters/player.tscn")

var connections: Dictionary = {}
var players_loaded: int = 0
var players_ready: int = 0
var current_scene: Node

var player_info: PlayerInfo = SaveManager.active_save.players[0]

func _ready() -> void:
        multiplayer.allow_object_decoding = true

        multiplayer.peer_connected.connect(_on_client_connected)
        multiplayer.peer_disconnected.connect(_on_client_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        call_deferred("start_game")

func start_game() -> void:
        transition_scene(entry_scene)        

func join_game(address=""):
        print("Client.")
        if address.is_empty():
                address = DEFAULT_SERVER_IP
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_client(address, PORT)
        if error:
                return error
        multiplayer.multiplayer_peer = peer

func create_game():
        print("Server.")
        transition_scene(lobby_scene)
        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_server(PORT, MAX_CONNECTIONS)
        if error:
                return error
        multiplayer.multiplayer_peer = peer

        var id: int = 1
        client_connected.emit(id)
        player_info = PlayerInfo.new("Player", id)
        instantiate_player(id, player_info.to_dict())

func transition_scene(new_scene: Resource):
        if current_scene != null:
                current_scene.queue_free()
        current_scene = new_scene.instantiate()
        get_tree().root.add_child(current_scene)

func move_player_to_lobby():
        transition_scene(lobby_scene)
        var ready_checker: Node2D = current_scene.get_node("ReadyCheck")
        ready_checker.player_ready(_on_player_ready)
        ready_checker.player_not_ready(_on_player_not_ready)

func _on_player_ready():
        print("Player ready.")
        players_ready += 1
        if players_ready == MAX_CONNECTIONS:
                transition_scene(level_scene)

func _on_player_not_ready():
        print("Player not ready.")
        players_ready -= 1

func remove_multiplayer_peer() -> void:
        multiplayer.multiplayer_peer = null

func instantiate_player(id: int, player_data:Dictionary) -> void:
        var new_player: Node = player_scene.instantiate()
        players_node.add_child(new_player)
        var info_node = new_player.get_node("PlayerInfo")
        info_node.set_data(player_data["display_name"], player_data["authority_id"])
        new_player.name = "conn=%s (%s)" % [id, info_node.display_name]
        connections[id] = new_player
        print("INFO=Registered new player.\tDisplay Name=%s\tID=%s" % [new_player.name, id])

@rpc("any_peer", "reliable")
func player_loaded() -> void:
        if multiplayer.is_server():
                players_loaded += 1;
                if players_loaded == connections.size():
                        # TO DO: START GAME
                        print("All players loaded.")
                        players_loaded = 0

func _on_client_connected(id: int) -> void:
        print("Connected.")
        transition_scene(lobby_scene)
        _register_player.rpc_id(id, player_info.to_dict())

@rpc("any_peer", "reliable")
func _register_player(player_data: Dictionary) -> void:
        var owner_id: int = multiplayer.get_remote_sender_id()
        instantiate_player(owner_id, player_data)

func _on_client_disconnected(id):
        connections.erase(id)
        client_disconnected.emit(id)

func _on_connected_ok() -> void:
        var client_id: int = multiplayer.get_unique_id()
        player_info = PlayerInfo.new("Player", client_id)
        instantiate_player(client_id, player_info.to_dict())
        client_connected.emit(client_id)

func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null

func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        connections.clear()
        server_disconnected.emit

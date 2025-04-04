class_name NetworkManager extends Node

signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected

static var singleton: NetworkManager

const DEFAULT_SERVER_IP: String = "localhost"
const PORT: int = 7000
const MAX_CONNECTIONS: int = 2

const HOST_ID: int = 1

var entry_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var lobby_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var level_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var player_scene:       Resource = preload("res://data/entities/player/player.tscn")

var connections: Dictionary[int, Node] = {}
var players_loaded: int = 0
var players_ready: int = 0
var current_scene: Node

var players_node: Node 


func _ready() -> void:
        if singleton:
                queue_free()

        singleton = self

        multiplayer.allow_object_decoding = true # TODO: This is **insecure** !")!! Find a way to disable this before launch!!!!

        multiplayer.peer_connected.connect(_on_client_connected)
        multiplayer.peer_disconnected.connect(_on_client_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        players_node = get_tree().root.get_node("Players")


func start_game() -> void:
        create_game()


func join_game(address=DEFAULT_SERVER_IP, port=PORT):
        print('Client')

        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_client(address, port)

        if error:
                return error

        multiplayer.multiplayer_peer = peer


func create_game():
        print('Host')

        transition_scene(lobby_scene)

        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_server(PORT, MAX_CONNECTIONS)
        if error:
                return error
        multiplayer.multiplayer_peer = peer

        client_connected.emit(HOST_ID)
        instantiate_player(HOST_ID)


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


func instantiate_player(id: int) -> void:
        var new_player: Node = player_scene.instantiate()
        players_node.add_child(new_player)

        # var info_node = new_player.get_node("PlayerInfo")

        # new_player.name = "conn=%s (%s)" % [id, info_node.display_name]

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
        _register_player.rpc_id(id)


@rpc("any_peer", "reliable")
func _register_player() -> void:
        instantiate_player(multiplayer.get_remote_sender_id())


func _on_client_disconnected(id):
        connections.erase(id)
        client_disconnected.emit(id)


func _on_connected_ok() -> void:
        transition_scene(lobby_scene)
        var client_id: int = multiplayer.get_unique_id()
        instantiate_player(client_id)
        client_connected.emit(client_id)


func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null


func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        connections.clear()
        server_disconnected.emit()

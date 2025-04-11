extends Node

signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected

signal network_tick

const DEFAULT_SERVER_IP: String = "localhost"
const PORT: int = 7000
const MAX_CONNECTIONS: int = 2

const INVALID_PEER_ID: int = -1
const ALL_PEERS: int = 0
const SERVER_ID: int = 1

const GCD_INTERVAL:       float   = 1.0
const TICK_RATE:          int     = 24
const SECONDS_PER_MINUTE: int     = 60

static var tick_timer: Timer
static var tick_interval: float
static var current_tick: int

@onready var player_spawner:    MultiplayerSpawner = %PlayerSpawner
@onready var npc_spawner:       MultiplayerSpawner = %NpcSpawner
@onready var level_spawner:     MultiplayerSpawner = %LevelSpawner

@onready var player_container:  Node = %Players
@onready var npc_container:     Node = %NPCs
@onready var level_container:   Node = %Levels

var logger: Logger

var my_peer_id: int = INVALID_PEER_ID

var entry_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var lobby_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var level_scene:        Resource = preload("res://data/maps/test_scene.tscn")
var player_scene:       Resource = preload("res://data/entities/player/player.tscn")
var remote_player_scene:Resource = preload("res://data/entities/player/remote_player.tscn")

var connections: Dictionary[int, PlayerInfo] = {}
var current_scene: Node


func _ready() -> void:
        logger = Logger

        multiplayer.peer_connected.connect(_on_client_connected)
        multiplayer.peer_disconnected.connect(_on_client_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        current_tick = 0

        tick_interval = TICK_RATE/float(SECONDS_PER_MINUTE)

        tick_timer = Timer.new()
        tick_timer.wait_time = tick_interval
        tick_timer.autostart = true
        tick_timer.timeout.connect(network_tick.emit)
        add_child(tick_timer)


static func serialize(obj: Object) -> Dictionary:
        var dict = {}

        if not obj:
                return dict

        var properties: Array[String] = obj.get("PROPERTIES")

        if not properties:
                Logger.error('Did not find PROPERTIES on object when serializing. An empty Dictionary will be returned.')
                return dict

        for property in properties:
                var value = obj.get(property)

                if not value:
                        Logger.error('Did not find property when serializing! Please ensure the values in your property array are up to date.', {'property':property})
                        continue

                if value is Array or value is Dictionary:
                        dict[property] = value.duplicate()
                else:
                        dict[property] = value

        return dict


static func deserialize(obj: Object, data: Dictionary) -> Object:
        var dict = {}

        if not obj:
                return obj

        var properties: Array[String] = obj.get("PROPERTIES")

        if not properties:
                Logger.error('Did not find PROPERTIES on object when deserializing! Object will be returned with no changes.')
                return obj

        for property in properties:
                var value = data.get(property)

                if not value:
                        Logger.error('Property not found on object when peforming deserialization! Please ensure the values in your property array are up to date.', {'missing property':property, 'all properties':str(properties)})
                        continue

                obj.set(property, value)

        return obj



func spawn_player(peer_id: int) -> void:
        if not multiplayer.is_server():
                return

        logger.info('Added player.', {'client id': peer_id})

        var player: Player = player_scene.instantiate()
        player.name = str(peer_id)

        player_container.add_child(player, true)
        player.id = peer_id


func remove_player(id: int) -> void:
        if not multiplayer.is_server():
                return

        print('INFO=Removed player.\tID=%d' % id)

        if not player_container.has_node(str(id)):
                return

        player_container.get_node(str(id)).queue_free()


func start_client(address=DEFAULT_SERVER_IP, port=PORT):
        print('INFO=Started client.\tServer Adress=%s\tPort=%d' % [address, port])

        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_client(address, port)

        if error:
                return error

        multiplayer.multiplayer_peer = peer


func start_server():
        print('INFO=Started server.\tPort=%d\tMax Connections=%d' % [PORT, MAX_CONNECTIONS])

        var peer = ENetMultiplayerPeer.new()
        var error = peer.create_server(PORT, MAX_CONNECTIONS)

        if error:
                return error

        multiplayer.multiplayer_peer = peer

        spawn_player(SERVER_ID)


func load_world():
        transition_scene(lobby_scene)

        if multiplayer.is_server():
                _on_connected_ok()


func transition_scene(new_scene: Resource):
        if current_scene != null:
                current_scene.queue_free()

        current_scene = new_scene.instantiate()
        get_tree().root.add_child(current_scene)


func _on_client_connected(id: int) -> void:
        print('INFO=Client connected.\tID=%d' % id)
        spawn_player(id)


func _on_client_disconnected(id):
        remove_player(id)

        connections.erase(id)
        client_disconnected.emit(id)


func _on_connected_ok() -> void:
        var peer_id: int = multiplayer.get_unique_id()
        my_peer_id = peer_id
        # var player_info = PlayerInfo.new(multiplayer.get_unique_id(), Vector3.ZERO, Vector3.ZERO)
        # instantiate_player(player_info)
        # spawn_player(peer_id)

        client_connected.emit(peer_id)


func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null


func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        connections.clear()
        server_disconnected.emit()


func _exit_tree() -> void:
        multiplayer.peer_connected.disconnect(_on_client_connected)
        multiplayer.peer_disconnected.disconnect(_on_client_disconnected)
        multiplayer.connected_to_server.disconnect(_on_connected_ok)
        multiplayer.connection_failed.disconnect(_on_connected_fail)
        multiplayer.server_disconnected.disconnect(_on_server_disconnected)

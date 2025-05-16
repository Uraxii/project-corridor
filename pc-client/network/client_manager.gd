# Global Client
class_name ClientManager extends Node

#region Singals
signal poll(delta: float)
signal change_polling_rate(new_rate: int)
signal client_connected_ok(id: int)
signal client_connected(id: int)
signal client_disconnected(id: int)
signal server_disconnected()
#endregion

#region Constansts
const DEFAULT_SERVER_ADDRESS:   String  = "localhost"
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const INVALID_PEER_ID:          int     = -1
const ALL_PEERS_ID:             int     = 0
const SERVER_ID:                int     = 1
#endregion

#region Instance Variables
var port    := DEFAULT_PORT
var server  := DEFAULT_SERVER_ADDRESS

var poll_timer := Timer.new()

var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        change_polling_rate.emit(value)

var my_peer_id: int:
    get():
        return multiplayer.get_unique_id() if multiplayer else INVALID_PEER_ID
#endregion

#region Godot Callback Functions
func _ready() -> void:
    multiplayer.peer_connected.connect(_on_client_connected)
    multiplayer.peer_disconnected.connect(_on_client_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    NetCmd.change_polling_rate.connect(_on_chage_polling_rate)

    # Allows us to manually controll the polling rate.
    get_tree().multiplayer_poll = false
    poll_timer.autostart = true
    poll_timer.timeout.connect(_poll_network_peers)
#endregion

#region Network Functions
func start():
    print("Stating client.")
    
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(server, port)

    if err:
        print("Connection failed! Error=", error_string(err))
        return err

    multiplayer.multiplayer_peer = peer

    polling_rate = DEFAULT_POLLING_RATE
    add_child(poll_timer)


func _poll_network_peers() -> void:
    #Logger.debug("Polling.",
    #   {"polling rate":polling_rate,"interval":poll_timer.wait_time})
    
    multiplayer.poll()
    poll.emit(polling_rate)


func _on_chage_polling_rate(new_rate: int) -> void:
    print_debug("Set polling rate to ", new_rate)
    polling_rate = new_rate
    

func _on_client_connected(id: int) -> void:
    print_debug("New peer. ID=", id)
    client_connected.emit(id)


func _on_client_disconnected(id: int):
    print_debug("Peer disconnected. ID=", id)
    client_disconnected.emit(id)


func _on_connected_ok() -> void:
    print_debug("Connected to server.")
    client_connected_ok.emit(my_peer_id)
    

func _on_connected_fail() -> void:
    print_debug("Failed to conenct.")
    multiplayer.multiplayer_peer = null


func _on_server_disconnected():
    print_debug("Disconnected from server.")
    multiplayer.multiplayer_peer = null
    server_disconnected.emit()
#endregion

# Global Network
class_name Server extends Node

#region Singals
signal poll(delta: float)
signal change_polling_rate(new_rate: int)
signal client_connected(id: int)
signal client_disconnected(id: int)
#endregion

#region Constansts
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const INVALID_PEER_ID:          int     = -1
const ALL_PEERS:                int     = 0
const SERVER_ID:                int     = 1
#endregion

#region Instance Variables
var port        := DEFAULT_PORT
var max_conns   := DEFAULT_MAX_CONNECTIONS

var permit_ips: PackedStringArray = []
var deny_ips:  PackedStringArray = []

var poll_timer := Timer.new()

var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        change_polling_rate.emit(value)

var logged_in_users: Dictionary[int, String] = {}
var ready_clients: Array[int] = []
var unready_clients: Array[int] = []
#endregion

#region Godot Callback Functions
func _ready() -> void:
    multiplayer.peer_connected.connect(_on_client_connected)
    multiplayer.peer_disconnected.connect(_on_client_disconnected)

    # Allows us to manually controll the polling rate.
    get_tree().multiplayer_poll = false
    poll_timer.autostart = true
    poll_timer.timeout.connect(_on_poll_timer_timeout)
    change_polling_rate.connect(_on_change_polling_rate)
#endregion

#region Network Functions
func start_server():
    print("Server Starting...")
    
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_server(port, max_conns)

    if err:
        print("Failed to start server! Error: ", error_string(err))
        return err

    multiplayer.multiplayer_peer = peer

    polling_rate = DEFAULT_POLLING_RATE
    add_child(poll_timer)
    
    print("Server listening...")


func _on_poll_timer_timeout() -> void:
    #print_debug("Polling. Wait Time=", poll_timer.wait_time)
    multiplayer.poll()
    poll.emit(polling_rate)


func _on_change_polling_rate(new_rate: int) -> void:
    for client_id in multiplayer.get_peers():
        NetCmd.client_change_polling_rate.rpc(client_id, new_rate)


func _on_client_connected(id: int) -> void:
    print("Connected new peer ", id)


func _on_client_disconnected(id: int):
    print("Peer ", id, " disconnected.")
#endregion

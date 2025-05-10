# Global Network
class_name ServerAPI extends Node

#region Signals
signal change_polling_rate(new_rate: int)
#endregion

#region Constansts
const DEFAULT_HOST_ADDRESS:     String  = "localhost"
const DEFAULT_PORT:             int     = 9000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99
#endregion

#region Instance Variable
var message_handler := MessageHandler.new()

var peer := ENetMultiplayerPeer.new()
var host        := DEFAULT_HOST_ADDRESS
var port        := DEFAULT_PORT
var max_conns   := DEFAULT_MAX_CONNECTIONS

var permit_list: PackedStringArray = []
var deny_list:  PackedStringArray = []

var logged_in_users: Dictionary[int, String] = {}
var ready_clients: Array[int] = []
var unready_clients: Array[int] = []

var poll_timer := Timer.new()
var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        change_polling_rate.emit(value)
#endregion

func _ready() -> void:
    message_handler.generate_routes(Controllers.active)


func start_server(port, max_conns):
    var result = peer.create_server(port, max_conns)
    if result != OK:
        print("[Server] Failed to start server: ", result)
        return
    multiplayer.multiplayer_peer = peer
    print("[Server] Server started and listening on port 9000")
    
    
func send(peer_id: int, action: String, data: Dictionary) -> void:
    var msg = {
        "action": action,
        "data": data,
    }
    print("[Server] Sending message to peer ", peer_id, ":", msg)
    _on_server_response.rpc_id(peer_id, data)


@rpc("any_peer")
func _on_client_request(msg: Dictionary) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    print("[Server] Received messge from peer ", peer_id, ":", msg)
    
    var action: String = msg.get("action", "")
    var request_id = msg.get("request_id", -1)
    var data = msg.get("data", {})
    var response_data = await message_handler.dispatch(action, data, peer_id)
    var response_msg := {
        "action": "%s_response" % action,
        "request_id": request_id,
        "data": response_data,
    }
    
    print("[Server] Sending response to peer ", peer_id, " message:",
        response_msg)
        
    _on_server_response.rpc_id(peer_id, response_msg)


@rpc("authority")
func _on_server_response(response: Dictionary) -> void:
    pass
    

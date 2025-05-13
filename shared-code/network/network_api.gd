# Global Network
class_name NetworkApi extends Node

#region Constansts
const DEFAULT_HOST_ADDRESS:     String  = "localhost"
const DEFAULT_PORT:             int     = 9000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const SERVER_ID: int = 1
#endregion

#region Instance Variable
var message_routes: Array[MsgRoute] = [
    MsgRoute.new(Message.Action.base, Message, Signals.trash),
    MsgRoute.new(Message.Action.login_req, LoginReq, Signals.login_req),
    MsgRoute.new(Message.Action.login_resp, LoginResp, Signals.login_resp),
]

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
        Signals.change_polling_rate.emit(value)
#endregion

func _ready() -> void:
    Signals.connect_to_server.connect(
        func(address, port): start_client(address, port))


func start_client(server_address: String, port: int):
    if not peer:
        peer = ENetMultiplayerPeer.new()
    elif peer.get_connection_status() != peer.CONNECTION_DISCONNECTED:
        peer.close()

    var result = peer.create_client(server_address, port)

    if result != OK:
        print("[Client] Failed to connect to server: ", result)
        return

    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    multiplayer.multiplayer_peer = peer
    print("[Client] Connecting to server...")


func start_server(port, max_conns):
    var result = peer.create_server(port, max_conns)
    
    if result != OK:
        print("[Server] Failed to start server: ", result)
        return
        
    multiplayer.multiplayer_peer = peer
    print("[Server] Started listening on port 9000")


func server_send(action: Message.Action, msg: Message) -> void:
    if msg.dest_peer == -1:
        printerr("[Server] No destination peer for msg:", msg.serialize())
        return
    
    if not msg.validate():
        printerr("[Server] Failed to validate outgoing msg:", msg.serialize())
        
    var packet := {
        "a": action,
        "m": msg.serialize(),
    }
    
    print("[Server] Sending packet:", packet)    
    _on_server_message.rpc_id(msg.dest_peer, packet)


func client_send(action: Message.Action, msg: Message) -> void:
    """
    Note: This is client side validation.
    The server should NOT trust that this check has been done!
    """ 
    if not msg.validate():
        Signals.log_new_error.emit(
            "[Client] Failed to validate outgoing msg:" +
                str(msg.serialize()))

        return

    var packet := {
        "a": action,
        "m": msg.serialize(),
    }

    print("[Client] Sending packet:", packet)
    _on_client_message.rpc_id(1, packet)


@rpc("any_peer", "call_remote", "reliable", SERVER_ID)
func _on_client_message(packet: Dictionary) -> void:
    """
    Called by the client and run on the server.
    """
    var peer_id = multiplayer.get_remote_sender_id()
    print("[Server] Received packet from peer ", peer_id, ":", packet)
    _handle_message(peer_id, packet)


@rpc("authority", "call_remote", "reliable")
func _on_server_message(packet: Dictionary) -> void:
    """
    Called by the server and run on the client.
    """
    var peer_id = multiplayer.get_remote_sender_id()
    print("[Client] Received packet:", packet)
    _handle_message(peer_id, packet)


func _handle_message(peer_id, packet: Dictionary) -> void:
    if not packet.has("a"):
        printerr("No action in packet:", packet)
        return

    var action: Message.Action = packet.get("a")
    var index := message_routes.find_custom(
        func(item: MsgRoute): return item.action == action)
        
    if index == -1:
        printerr("Unable to map action to GDScript:", packet)
        return
        
    var route := message_routes[index]
    var msg: Message = route.msg_script.new()
    msg.origin_peer = peer_id
    var serialialized_msg: Dictionary = packet.get("m", {})
    msg.deserialize(serialialized_msg)
    route.sig.emit(msg)


func _on_connected_to_server() -> void:
    print("[Client] Multiplayer signal: Connected to server.")


func _on_connection_failed() -> void:
    print("[Client] Multiplayer signal: Connection to server failed.")


func _on_server_disconnected() -> void:
    print("[Client] Multiplayer signal: Disconnected from server.")


class MsgRoute:
    var action: Message.Action
    var msg_script: GDScript
    var sig: Signal
    
    func _init(_action: Message.Action, _msg_script: GDScript, _signal: Signal):
        action = _action
        msg_script = _msg_script
        sig = _signal
        

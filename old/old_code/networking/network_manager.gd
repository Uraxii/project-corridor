# Global Network
#class_name NetworkManager
extends Node

#region Signals
signal receive_message(sender: PacketPeerUDP, msg: Dictionary)
signal connect_to_server()
signal connection_failed
signal peer_disconnect(reason: int)
signal change_polling_rate(new_rate: int)
signal server_start()

#endregion

#region Constansts
const DEFAULT_HOST_ADDRESS:     String  = "localhost"
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const CONTROLLERS_DIR: String = "res://controllers"
#endregion

#region Instance Variables
var server: UDPServer
var buffers: Dictionary[PacketPeerUDP, String] = {}

var client: PacketPeerUDP

var clients: Array[PacketPeerUDP] = []
var message_controller: MessageController = Controllers.messages

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

var active := false
#endregion

#region Godot Callback Functions
func _ready() -> void:
    receive_message.connect(receive)
    peer_disconnect.connect(func(code:int): print("Disconnected. Code: ", code))
    poll_timer.autostart = true
#endregion

#region Start Functions
func start_client() -> void:
    client = PacketPeerUDP.new()
    var result := client.connect_to_host(host, port)
    
    if result != OK:
        printerr("Failed to connect to host! ", error_string(result))
        connection_failed.emit()
        return
        
    print("Successfully connected to %s:%d." % [
        client.get_connected_host(), client.get_connected_port()])
    
    buffers[client] = ""
    active = true
    connect_to_server.emit()
    
    add_child(poll_timer)
    _run_client()


func start_server() -> void:
    server = UDPServer.new()
    
    server.listen(port)
    print("Server listening on port %d..." % port)
    
    active = true
    server_start.emit()
    
    add_child(poll_timer)
    _run_sever()
#endregion

#region Send/Receive Messages
func send(msg: Dictionary, recipient: PacketPeerUDP = client) -> void:
    print("Sending message: ", msg)
    var data := JSON.stringify(msg) + "\n"
    recipient.put_utf8_string(data)


func receive(sender: PacketPeerUDP, msg: Dictionary) -> void:
    print("New message: ", msg)
    var result = await message_controller.dispatch(sender, msg)
    print("result: ", result)
    
#endregion

func _run_client() -> void:
    print("Polling started...")
    await poll_timer.timeout

    while active:
        #print("Status:", clien.get_status())
        client.poll()
        
        if client.is_socket_connected():
            active = false
            peer_disconnect.emit()
            return
            
        _process_peer(client)

        await poll_timer.timeout
        
    print("Polling finished...")


func _run_sever() -> void: 
    print("Polling started...")
    await poll_timer.timeout
    
    while active:
        _handle_new_peers()
        
        for peer in clients:
            _process_peer(peer)
            
        await poll_timer.timeout
    
    print("Polling finished...")


func _process_peer(peer: PacketPeerUDP) -> void:
    if client.is_socket_connected():
            peer_disconnect.emit()
            return

    var buffer: String = buffers.get_or_add(peer, "")

    if peer.get_available_bytes() < 0:
        print(peer.get_available_bytes())
        
    if peer.get_available_bytes() < 4:
        return  # Not enough data to even read the length prefix

    # Step 1: Read 4-byte length prefix
    var result_len = peer.get_data(4)
    var error_len = result_len[0]
    var length_bytes: PackedByteArray = result_len[1]

    if error_len != OK or length_bytes.size() < 4:
        print("Error reading length from %s: %s" % [
            peer.get_connected_host(), error_string(error_len)])
            
        return

    var content_length: int = length_bytes.decode_u32(0)

    if content_length == 0:
        print("Got empty message from %s" % peer.get_connected_host())
        return

    # Step 2: Read message content of declared length
    if peer.get_available_bytes() < content_length:
        return  # Wait until all bytes are available

    var result_msg = peer.get_data(content_length)
    var error_msg = result_msg[0]
    var message_bytes: PackedByteArray = result_msg[1]

    if error_msg != OK:
        print("Error reading message from %s: %s" % [
            peer.get_connected_host(), error_string(error_msg)])
        return

    var text := message_bytes.get_string_from_utf8()
    print("Received message from %s: %s" % [peer.get_connected_host(), text])

    # Step 3: Append to the buffer and process lines
    buffer += text
    var lines := buffer.split("\n") as Array
    buffer = lines.pop_back()  # preserve any partial line

    for line in lines:
        line = line.strip_edges()
        if line == "":
            continue

        var msg = JSON.parse_string(line)
        if typeof(msg) == TYPE_DICTIONARY:
            receive_message.emit(peer, msg) 
        else:
            printerr("Invalid JSON line: ", line)

    buffers[peer] = buffer  # store back updated buffer
    print("Remaining content in buffer:", buffers[peer])


func _handle_new_peers() -> void:
    if not server.is_connection_available():
        return
        
    var peer := server.take_connection()
    
    if peer.get_connected_host() not in deny_list:
        print("New peer ", peer.get_connected_host(), " connected.")
        clients.append(peer)
        buffers[peer] = ""
    else:
        print("Blocked ", peer.get_connected_host(), " from connecting.")

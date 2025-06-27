class_name WebSocketClient extends Node


@export var handshake_headers: PackedStringArray
@export var supported_protcols: PackedStringArray
var tls_options: TLSOptions = null

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED

var poll_timer := Timer.new()
var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        signals.change_polling_rate.emit(value)
        
var client_id: int = -1

@onready var signals := Globals.signal_bus
@onready var log := Globals.log
@onready var packets := Globals.packets


func connect_to_url(url: String, port: int) -> int:
    log.info("Connecting: %s:%d" % [url, port])
    socket.supported_protocols = supported_protcols
    socket.handshake_headers = handshake_headers

    var err := socket.connect_to_url(
        "ws://%s:%d/ws" % [url, port], tls_options)

    if err:
        log.error("Failed to connect!")
        return err
        
    signals.connected_to_server.connect(_on_connected_to_server)
    signals.connection_closed.connect(_on_connection_closed)

    last_state = socket.get_ready_state()

    poll_timer.timeout.connect(poll)
    poll_timer.one_shot = false
    poll_timer.start()
    return OK


func disconn() -> void:
    socket.close()


func send(packet: PacketManager.PACKETS.Packet) -> int:
    log.info("Sending:" + str(packet))
    packet.set_sender_id(0)
    var bytes := packet.to_bytes()
    return socket.send(bytes)


func get_packet() -> PacketManager.PACKETS.Packet:
    if socket.get_available_packet_count() < 1:
        return null

    var bytes := socket.get_packet()
    var packet := PacketManager.PACKETS.Packet.new()
    var err := packet.from_bytes(bytes)

    if err:
        log.error("Error formatting packet from data %s" % [
            bytes.get_string_from_utf8()])

    return packet


func poll() -> void:
    if socket.get_ready_state() != socket.STATE_CLOSED:
        socket.poll()

    var state := socket.get_ready_state()

    if last_state != state:
        last_state = state
        if state == socket.STATE_OPEN:
            signals.connected_to_server.emit()
        elif state == socket.STATE_CLOSED:
            signals.connection_closed.emit()

    while should_process_packet():
        var packet := get_packet()
        packets.dispatch(packet)
 

func should_process_packet() -> bool:
    var is_conn_open := socket.get_ready_state() == socket.STATE_OPEN
    var is_packet_waiting := socket.get_available_packet_count() > 0
    return is_conn_open and is_packet_waiting


func _ready() -> void:
    add_child(poll_timer)


func _on_connected_to_server() -> void:
    var host := socket.get_connected_host()
    var port := socket.get_connected_port()
    log.success("Connection started: %s:%d" % [host, port])
    
    var packet := PacketManager.new_packet()
    var hello_chat := packet.new_chat()
    hello_chat.set_content("Hello!")
    send(packet)
    
    

func _on_connection_closed() -> void:
    log.warn("Connection closed")
    poll_timer.timeout.disconnect(poll)
    poll_timer.stop()
    
    signals.connected_to_server.disconnect(_on_connected_to_server)
    signals.connection_closed.disconnect(_on_connection_closed)

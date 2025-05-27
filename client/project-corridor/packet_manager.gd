class_name PacketManager extends Node

const PACKETS := preload("res://packets.gd")

var signals: SignalBus


func _init(signal_bus: SignalBus) -> void:
    signals = signal_bus


static func new_packet() -> PACKETS.Packet:
    return PACKETS.Packet.new()


func dispatch(packet: PACKETS.Packet) -> void:
    signals.log_new_debug.emit("Got packet:" + str(packet))
    
    var sender_id := packet.get_sender_id()
    
    if packet.has_id():
        signals.login_resp.emit(packet.get_id())
    if packet.has_chat():
        var sender_name := "Client %d" % sender_id
        signals.chat.emit(sender_name, packet.get_chat().get_content())

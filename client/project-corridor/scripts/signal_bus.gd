class_name SignalBus extends Node

#region Network
signal connected_to_server
signal connection_closed
signal got_packet(packet: PacketManager.PACKETS.Packet)
signal got_client_id(msg: PacketManager.PACKETS.IdMessage)
signal chat(sender_id: int, msg: PacketManager.PACKETS.Packet)
signal login(msg: PacketManager.PACKETS.IdMessage)
#endregion

#region System
signal login_success
#endregion

#region Views
signal spawn_view(view: View)
signal despawn_view(view: View)
#endregion

#region Logging
signal log_new_message(message: String)
signal log_new_debug(message: String)
signal log_new_warning(message: String)
signal log_new_error(message: String)
signal log_new_success(message: String)
signal log_new_announcment(message: String)
#endregion

#region World
signal reload
#endregion

#region Input
signal in_accept
signal in_cancel
signal in_move(dir: Vector2)
#endregion

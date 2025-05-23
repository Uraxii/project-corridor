class_name SignalBus extends Node

#region Network
signal connected_to_server
signal connection_closed
signal message_received(packet: NetUtils.MSG.Packet)
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
signal log_new_announcment(message: String)
#endregion

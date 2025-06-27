class_name SignalBus extends Node

#region API
signal api_status_passed()
signal api_status_failed(http_code: int)

# Authentication
signal login_success(data: Dictionary)
signal login_failed(http_code: int)
signal register_success(data: Dictionary)
signal register_failed(http_code: int, error_message: String)
signal logout_success()
signal token_refresh_success()
signal token_refresh_failed(http_code: int)
signal user_info_received(user_data: Dictionary)

# Character Management
signal character_created(character_data: Dictionary)
signal character_create_failed(http_code: int, error_message: String)
signal characters_received(characters: Array, total: int)
signal characters_fetch_failed(http_code: int)
signal character_received(character_data: Dictionary)
signal character_fetch_failed(http_code: int)
signal character_updated(character_data: Dictionary)
signal character_update_failed(http_code: int)
signal character_deleted()
signal character_delete_failed(http_code: int)
signal character_not_found()
#endregion

#region Network
signal connected_to_server
signal connection_closed
signal got_packet(packet: PacketManager.PACKETS.Packet)
signal got_client_id(msg: PacketManager.PACKETS.IdMessage)
signal chat(sender_id: int, msg: PacketManager.PACKETS.Packet)
signal login(msg: PacketManager.PACKETS.IdMessage)
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

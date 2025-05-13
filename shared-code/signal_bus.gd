class_name signal_bus extends Node

signal spawn_view(view: View)
signal despawn_view(view: View)

signal load_world(character: String, location: Vector3, zone: String)

signal spwan_entity(entity: Entity)
signal despawn_entity(entity: Entity)

signal log_new_message(message: String)
signal log_new_debug(message: String)
signal log_new_warning(message: String)
signal log_new_error(message: String)
signal log_new_announcment(message: String)

signal connect_to_server(server_address: String, port: int)
signal change_polling_rate(new_rate: int)

signal login_req(data: LoginReq)
signal login_resp(data: LoginResp)

signal trash(data)

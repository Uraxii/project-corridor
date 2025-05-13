class_name signal_bus extends Node

signal spawn_view(view: View)
signal despawn_view(view: View)

signal load_world(character: String, location: Vector3, zone: String)

signal spwan_entity(entity: Entity)
signal despawn_entity(entity: Entity)

signal connect_to_server(server_address: String, port: int)
signal login(response: LoginResponse)

signal log_new_message(message: String)
signal log_new_debug(message: String)
signal log_new_warning(message: String)
signal log_new_error(message: String)
signal log_new_announcment(message: String)

signal out_null(data)

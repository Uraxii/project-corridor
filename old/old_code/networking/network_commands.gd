# Global NetCmd
class_name NetworkCommands extends Node

signal c_login_result(result: bool)
signal user_login(client_id: int, user_name: String)
signal c_get_characters(character_data: Array[Dictionary])
signal create_new_character(character_data: Dictionary)
signal spawn_entity(entity_data: Dictionary, entity_id: int, location: Vector3)
signal despawn_entity(entity_id: int)
signal update_entity_data(data: Dictionary)
signal change_polling_rate(rate: int)
signal ready_client(client_id: int)
signal unready_client(client_id: int)

const ALL_CLIENTS_ID:   int = 0
const SERVER_ID:        int = 1

var remote_sender: int:
    get(): return multiplayer.get_remote_sender_id()


#region Performed on Clients
@rpc("authority", "call_local")
func client_spawn_entity(
    entity_data: Dictionary, entity_id: int, location: Vector3
) -> void:
    spawn_entity.emit(entity_data, entity_id, location)


@rpc("authority", "call_local")
func client_despwan_entity(entity_id: int) -> void:
    despawn_entity.emit(entity_id)


@rpc("authority", "call_local")
func client_update_entity(data: Dictionary) -> void:
    update_entity_data.emit(data)


@rpc("authority", "call_local")
func client_change_polling_rate(rate: int) -> void:
    change_polling_rate.emit(rate)
    
    
@rpc("authority", "call_local")
func client_get_characters(characters: Dictionary) -> void:
    print_debug("got characters: ", characters)
    c_get_characters.emit(characters)


@rpc("authority", "call_local")
func client_login_result(result: bool) -> void:
    c_login_result.emit(result)
    
#endregion

#region Performed on Server
@rpc("any_peer", "call_remote", "reliable", SERVER_ID)
func server_user_login(user_name: String) -> void:
    user_login.emit(remote_sender, user_name)


@rpc("any_peer", "call_remote", "reliable", SERVER_ID)
func server_create_new_character(entity_data: Dictionary) -> void:
    create_new_character.emit(multiplayer.get_remote_sender_id(), entity_data)


@rpc("any_peer", "call_remote", "reliable", SERVER_ID)
func server_ready_client(character_id: int) -> void:
    ready_client.emit(multiplayer.get_remote_sender_id())
#endregion

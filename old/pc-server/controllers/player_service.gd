class_name PlayerService extends Controller

@onready var entity_con: EntityController = Global.controllers.find(
    EntityController)

var players: Dictionary[int, Player] = {}


func add_player(peer_id) -> Player:
    if players.has(peer_id):
        return
        
    var new_player := Player.new()
    players[peer_id] = new_player
    return new_player


func remove_player(peer_id) -> void:
    players.erase(peer_id)


func assign_authority(entity_id: int, peer_id: int) -> void:
    var entity := entity_con.find(entity_id)
    
    if not entity:
        return
    
    var player = players.get(peer_id)
    
    if not player:
        return
        
    var old_authority := entity.get_multiplayer_authority()
    
    if old_authority != 1:
        var old_player = players.get(old_authority)
        
        if old_player:
            old_player.authorities.remove(entity_id)
        
    player.authorities.append(entity_id)
    entity.set_multiplayer_authority(peer_id)

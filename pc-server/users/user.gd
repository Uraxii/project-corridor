class_name User extends Resource

# TODO: Make unique_id a GUID
var unique_id: int
var user_name: String
var characters: Dictionary


static func generate(username: String) -> User:
    var user := User.new()
    user.user_name = username
    user.unique_id = randi()
    user.characters = {}
    
    return user


func create_character(character_data: Dictionary) -> void:
    characters[character_data["name"]] = character_data

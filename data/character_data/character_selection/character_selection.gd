class_name CharaterSelection extends Node3D


const CHARACTERS_LIST = 'user://characters/characters.cfg'

var characters: Array[Player] = []
var character_preview: Player = Player.new()


func _ready() -> void:
        load_characters_from_disk()


func load_characters_from_disk():
        var character_list: ConfigFile = ConfigFile.new()
        character_list.load(CHARACTERS_LIST)

        var character_names: Array = character_list.get_value('characters', 'characters', [])

        for character in character_names:
                var data = CharacterData.load(character)


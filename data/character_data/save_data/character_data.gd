class_name CharacterData

const VERSION: String = '0.0.0'

const CHARACTER_LIST_FILEPATH: String = 'user://characters/characters.cfg'

static var character_data_dirpath: Callable = func (character_name:String) -> String:
        return 'user://characters/%s' % character_name

static var character_data_filepath: Callable = func (character_name: String) -> String:
        return 'user://characters/%s/character_data.cfg' % character_name


static func save(player: Player):
        var config := ConfigFile.new()

        # ========== SUMMARY ==========
        config.set_value('summary', 'version', VERSION)
        config.set_value('summary', 'display_name', player.display_name)
        # ========== APPEARANCE ==========
        config.set_value('appearance', 'skin_color', player.skin_color)
        config.set_value('appearance', 'body_mesh', player.body_mesh)
        # ========== SKILL ==========
        config.set_value('skills', 'skills', player.abilities.keys())
        # ========== BAR BINDINGS ==========
        for button in player.skill_binds.keys():
                config.set_value('bar_bindings', button, player.skill_binds[button])

        var dirpath = character_data_dirpath.call(player.display_name)
        var file_name = 'character_data.cfg'

        var err = FileUtils.save_config_file(dirpath, file_name, config)

        if err != OK:
                printerr('E=Character data NOT saved!')
                return

        var character_list: ConfigFile = ConfigFile.new()
        character_list.load(CHARACTER_LIST_FILEPATH)

        var character_names: Array = character_list.get_value('characters', 'characters', [])

        character_names.append(player.display_name)
        character_list.set_value('characters', 'characters', character_names)

        FileUtils.save_config_file('user://characters', 'characters.cfg', character_list)


static func load(character_name: String) -> Player:
        var config := ConfigFile.new()
        var filepath: String = character_data_filepath.call(character_name)
        var err: Error = config.load(filepath)

        if err != OK:
                printerr('E=Failed to load file!\tPath=', filepath, '\tDetails=', err)
                return null

        var data_file_version = config.get_value('summary', 'version')
        if data_file_version != VERSION:
                printerr('E=Character data version mismatch!\tExpected=', VERSION, '\tGot=', data_file_version)

        # TODO: Load character from data
        var player := Player.new()

        player.display_name = config.get_value('summary', 'display_name', '{ Name Missing }')
        player.skin_color= config.get_value('appearance', 'skin_color')

        print('I=Loaded character file.\tPath=', filepath)

        return player

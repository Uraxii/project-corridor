class_name FileUtils


static func save_config_file(dirpath: String, file_name: String, data: ConfigFile) -> Error:
        var err = DirAccess.make_dir_recursive_absolute(dirpath)
        if err != OK:
                return err

        var filepath = dirpath + '/' + file_name
        err = data.save(filepath)

        if err != OK:
                printerr('E=Failed to saved file!\tINFO=', err)
                return err

        return err


static func save_to_file(path:String, resource: Resource) -> Error:
        return ResourceSaver.save(resource, path)


static func load_from_file(file_name: String) -> String:
        var file = FileAccess.open(file_name, FileAccess.READ)
        var content = file.get_as_text()

        return content


static func get_dir(path: String) -> DirAccess:
        var dir: DirAccess = DirAccess.open(path)

        if not dir:
                var err = DirAccess.get_open_error()

                if err == ERR_FILE_NOT_FOUND:
                        err = DirAccess.make_dir_recursive_absolute(path)

                if err == ERR_FILE_NO_PERMISSION:
                        printerr('E=Permission denied dir!\tPath=', path, '\tErrorCode=', err)
                elif err != OK:
                        printerr('E=General error! Unable to access dir!\tPath=', path, '\tError Code=', err)

                if err != OK:
                        return null

        return dir

extends Node

static var entities:    Dictionary[String, Entity] = {}
static var cast_queue:  Array[Skill] = []


func _process(delta: float) -> void:
        _process_cast_queue()
        _process_status_effects()


func register_entity(entity: Entity) -> void:
        entities[entity.name] = entity
        # Logger.debug('Registerd entity.', {'Display Name':entity.stats.display_name,'Node Name':entity.name})


func unregister_entity(entity: Entity) -> void:
        entities.erase(entity.get_instance_id())


func get_entity(node_name: String) -> Entity:
        return entities.get(node_name)


@rpc("any_peer", "call_local", "reliable")
func queue_targeted_cast(skill_file: String, caster: String, target: String) -> void:
        if skill_file.is_empty() or caster.is_empty() or target.is_empty():
                Logger.warn("Received invalid cast request!", {"skill":skill_file,"caster":caster,"target":target,"sender":multiplayer.get_remote_sender_id()})
                return

        var skill := Skill.new(skill_file)
        skill.caster = get_entity(caster)
        skill.target = get_entity(target)

        # TODO: !!! Check if sender has authority over cater !!!

        Logger.info('Queued cast.', {'skill':skill.file,'target':skill.target.name,'caster':skill.caster.name,'sender':multiplayer.get_remote_sender_id()})

        cast_queue.push_front(skill)


@rpc("any_peer", "call_local", "reliable")
func queue_area_cast(skill_file: String, caster: String, location: Vector3) -> void:
        if skill_file.is_empty() or caster.is_empty():
                Logger.warn("Received invalid cast request!", {"skill":skill_file,"caster":caster,"location":location,"sender":multiplayer.get_remote_sender_id()})
                return

        # TODO: !!! Check if sender has authority over cater !!!
        var skill := Skill.new(skill_file)
        skill.caster = get_entity(caster)
        skill.location = location

        Logger.info('Queued cast.', {'skill': skill.file,'caster':skill.caster.name,'location':location,'sender':multiplayer.get_remote_sender_id()})

        cast_queue.push_front(skill)


func _process_cast_queue() -> void:
        while cast_queue.size() > 0:
                var skill = cast_queue.pop_front()
                var cast_result: MessageCastResult = skill.cast()
                cast_result.generate_log()

                # Logger.info(cast_result.message)


func _process_status_effects() -> void:
        # Logger.debug('Processing status effects.')
        for entity in entities.values():
                for status_effect in entity.status_effects.values():
                        var cast_result: MessageCastResult = status_effect.cast()

                        cast_result.generate_log()

                        # Logger.info(cast_result.message)

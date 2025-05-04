extends Node

static var entities:    Dictionary[String, Entity] = {}
static var statuses:    Array[SkillNew]
static var cast_queue:  Array[SkillNew] = []

#region Godot Callback Functions
func _process(_delta: float) -> void:
        _process_cast_queue()
        _process_status_effects()

#enregion

func register_entity(entity: Entity) -> void:
        entities[entity.name] = entity
        Logger.info('Registerd entity.', {'Display Name':entity.stats.display_name,'Node Name':entity.name})


func unregister_entity(entity: Entity) -> void:
        entities.erase(entity.get_instance_id())


func get_entity(node_name: String) -> Entity:
        return entities.get(node_name)


@rpc("any_peer", "call_local", "reliable")
func queue_targeted_cast(skill_id:int, caster:String, target:String) -> void:
        if skill_id == 0 or caster.is_empty() or target.is_empty():
                Logger.warn("Received invalid cast request!",
                        {"skill":skill_id,"caster":caster,"target":target,
                                "sender":multiplayer.get_remote_sender_id()})

                return

        # TODO: !!! Check if sender has authority over cater !!!

        var skill: SkillNew = SkillNew.load("", skill_id)

        skill.caster = get_entity(caster)
        skill.target = get_entity(target)

        Logger.info('Queued cast.',
                {'skill':skill.title,'target':skill.target.name,
                        'caster':skill.caster.name,
                        'sender':multiplayer.get_remote_sender_id()})

        cast_queue.push_front(skill)


@rpc("any_peer", "call_local", "reliable")
func queue_area_cast(
        skill_id:int, caster:String, location:Vector3, rotation:Vector3
) -> void:
        if caster.is_empty():
                Logger.warn("Received invalid cast request!",
                {"skill":skill_id,"caster":caster,"location":location,
                        "sender":multiplayer.get_remote_sender_id()})

                return

        # TODO: !!! Check if sender has authority over cater !!!

        var skill: SkillNew = SkillNew.load("", skill_id)

        skill.caster = get_entity(caster)
        skill.location = location
        skill.rotation = rotation

        Logger.info('Queued cast.', {'skill': skill.file,'caster':skill.caster.name,'location':location,'sender':multiplayer.get_remote_sender_id()})

        cast_queue.push_front(skill)


func _process_cast_queue() -> void:
        while cast_queue.size() > 0:
                var skill = cast_queue.pop_front()
                skill.run_cast()

                # Logger.info(cast_result.message)


func _process_status_effects() -> void:
        # Logger.info('Processing status effects.')
        for entity in entities.values():
                for status_effect in entity.status_effects.values():
                        var cast_result: MessageCastResult = status_effect.cast()

                        cast_result.generate_log()

                        # Logger.info(cast_result.message)

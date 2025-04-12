extends Node

static var entities:    Dictionary[String, Entity] = {}
static var cast_queue:  Array[CastRequest] = []


func _ready() -> void:
        Network.network_tick.connect(_process_tick)


func register_entity(entity: Entity) -> void:
        entities[entity.name] = entity
        # Logger.debug('Registerd entity.', {'Display Name':entity.stats.display_name,'Node Name':entity.name})


func unregister_entity(entity: Entity) -> void:
        entities.erase(entity.get_instance_id())


func get_entity(node_name: String) -> Entity:
        return entities.get(node_name)


@rpc("any_peer", "call_local", "reliable")
func queue_cast(message: Dictionary) -> void:
        var request := CastRequest.new().deserialize(message)

        if not request:
                Logger.error("Failed to deserialize cast request!", {"sender":multiplayer.get_remote_sender_id()})
                return

        # TODO: !!! Check if sender has authority over cater !!!

        Logger.info('Queued cast.', {'skill': request.skill,'target':request.target,'caster':request.caster,'sender':multiplayer.get_remote_sender_id()})

        cast_queue.push_front(request)


func _process_tick() -> void:
        _process_cast_queue()
        _process_status_effects()


func _process_cast_queue() -> void:
        while cast_queue.size() > 0:
                var request:    CastRequest = cast_queue.pop_front()

                var skill:      Skill   = Skill.new(request.skill)
                var caster:     Entity  = get_entity(request.caster)
                var target:     Entity  = get_entity(request.target)


                if not skill or not caster:
                        printerr('INFO=Invalid skill or caster.\tSkill=%s\tCaster=%s' % [request.skill, request.caster])
                        continue

                var cast_result: CastResult = Skill.cast(skill, caster, target)
                cast_result.generate_log()

                # Logger.info(cast_result.message)


func _process_status_effects() -> void:
        # Logger.debug('Processing status effects.')
        for entity in entities.values():
                for status_effect in entity.status_effects:
                        var cast_result: CastResult = Skill.cast(
                                status_effect,
                                status_effect.effect_caster,
                                entity
                        )

                        cast_result.generate_log()

                        # Logger.info(cast_result.message)

class_name StatusEffectView extends Control

@onready var progress_bar = $ProgressBar
@onready var icon: TextureRect = $Icon
@onready var remaining_time = $RemainingTime
@onready var timer = $Timer

var skill_id: String


func initialize(skill_id: String, entity: Entity) -> void:
        if not entity:
            return
        
        self.skill_id = skill_id
        var skill: Skill = entity.status_effects.get(skill_id)
        
        if not skill or skill.status_timer <= 0:
            return
            
        icon.texture = skill.icon

        timer.wait_time = skill.status_timer
        timer.start()

        remaining_time.text = '%3.1f' % timer.time_left
        progress_bar.value = (timer.time_left/skill.status_duration) * 100

        if not skill or skill.status_timer <= 0:
                queue_free.call_deferred()

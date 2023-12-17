class_name Ring extends Entity

export var sfxRing : AudioStream

func _on_area_entered(area):
	if area.get_parent().is_in_group("Player"):
		Audio._play_sample(sfxRing)
		Global.rings += 1
		queue_free()

extends CharacterBody3D

const radiator_count := 6
var dead_radiator_count := 0

func _on_radiator1_died() -> void:
	$FrigateModel/StrutLeft1/Radiator1.queue_free()
	radiator_died()

func _on_radiator2_died() -> void:
	$FrigateModel/StrutLeft2/Radiator2.queue_free()
	radiator_died()

func _on_radiator3_died() -> void:
	$FrigateModel/StrutLeft3/Radiator3.queue_free()
	radiator_died()

func _on_radiator4_died() -> void:
	$FrigateModel/StrutRight1/Radiator4.queue_free()
	radiator_died()

func _on_radiator5_died() -> void:
	$FrigateModel/StrutRight2/Radiator5.queue_free()
	radiator_died()

func _on_radiator6_died() -> void:
	$FrigateModel/StrutRight3/Radiator6.queue_free()
	radiator_died()

# Increment count of dead radiators. Once they
# are all gone, open the reactor shields to expose
# the reactor.
func radiator_died() -> void:
	dead_radiator_count += 1
	if dead_radiator_count >= radiator_count:
		$ReactorOpenAnimation.play("OpenReactorShield")

func _on_reactor_died() -> void:
	queue_free()

class_name EndScreen extends CanvasLayer

# This scene originally came from this Udemy tutorial:
# https://www.udemy.com/course/complete-godot-3d/
# Complete Godot 3D: Develop Your Own 3D Games Using Godot 4
# Created by GameDev.tv Team, Bram Williams
# Neal Holtschulte has since modified it.

@onready var outcome_label := $CenterContainer/PanelContainer/VBoxContainer/Label

#@onready var star_1: TextureRect = %Star1
#@onready var star_2: TextureRect = %Star2
#@onready var star_3: TextureRect = %Star3
#
#@onready var star_1_outcome:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star1Outcome
#@onready var star_2_outcome:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star2Outcome
#@onready var star_3_outcome:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star3Outcome
#
#@onready var star_1_label:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star1Label
#@onready var star_2_label:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star2Label
#@onready var star_3_label:= $CenterContainer/PanelContainer/VBoxContainer/GridContainer/Star3Label

func defeat() -> void:
	outcome_label.text = 'DEFEAT'
	visible = true
	# Make mouse visible again
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40786764#questions/20944900
func victory(_stars_earned:Array) -> void:
	outcome_label.text = 'VICTORY'
	#if stars_earned[0]:
		#star_1.modulate = Color.WHITE
		#star_1_outcome.text = 'SUCCEEDED'
		#star_1_outcome.set('theme_override_colors/font_color',Color.WHITE)
		#star_1_label.set('theme_override_colors/font_color',Color.WHITE)
	#if stars_earned[1]:
		#star_2.modulate = Color.WHITE
		#star_2_outcome.text = 'SUCCEEDED'
		#star_2_outcome.set('theme_override_colors/font_color',Color.WHITE)
		#star_2_label.set('theme_override_colors/font_color',Color.WHITE)
	#if stars_earned[2]:
		#star_3.modulate = Color.WHITE
		#star_3_outcome.text = 'SUCCEEDED'
		#star_3_outcome.set('theme_override_colors/font_color',Color.WHITE)
		#star_3_label.set('theme_override_colors/font_color',Color.WHITE)
	visible = true
	# Make mouse visible again
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_retry_button_pressed() -> void:
	Global.main_scene.retry_current_level()


func _on_quit_button_pressed() -> void:
	Global.main_scene.to_main_menu()

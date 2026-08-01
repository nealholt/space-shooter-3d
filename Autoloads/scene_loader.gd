extends Node

# This was built off of this tutorial:
# https://www.youtube.com/watch?v=m4PfHg3hmSo
# *correct* way to Load and Switch Scenes in Godot!
# by Queble https://www.youtube.com/@queblegamedevelopment4143
# And is to be used in conjunction with loading_screen.tscn

# More info can be found here:
# https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html
# And here are some alternative tutorials I have not yet looked into:
# https://www.gotut.net/loading-screen-in-godot-4/
# https://www.youtube.com/watch?v=-renxc-EmUg
# https://www.youtube.com/watch?v=dl2rUzXJtIU

signal progress_changed(progress)
signal load_finished

var loading_screen:PackedScene = preload('uid://dclw1gwerq6n') # Reference to loading_screen.tscn
var loaded_resource:PackedScene
var scene_path:String
var progress:Array = []
var use_sub_threads:bool = true


func _ready() -> void:
	set_process(false)


func load_scene(_scene_path:String) -> void:
	scene_path = _scene_path
	
	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)
	
	await new_load_screen.loading_screen_ready
	
	start_load()


func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, '', use_sub_threads)
	if state == OK:
		set_process(true)


func _process(_delta: float) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	progress_changed.emit(progress[0])
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			# The tutorial used this next get_tree line, but I load
			# every level as a child of a very particular node in
			# my main scene, so I'm not doing it this way. Instead
			# the main scene will call get_loaded_scene() after
			# it gets the load_finished signal.
			#get_tree().change_scene_to_packed(loaded_resource)
			load_finished.emit()
			set_process(false)


# Don't call this until the scene is fully loaded!
func get_loaded_scene() -> PackedScene:
	return loaded_resource

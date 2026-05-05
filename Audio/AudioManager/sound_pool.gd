@tool

class_name SoundPool
extends Node

## Also known as an "AudioCollection" by this tutorial: https://www.nightquestgames.com/building-a-simple-audio-system-in-godot/
## This code was initially copied from that tutorial.

# Enum for defining the audio playback order
enum AudioPlaybackOrder { Sequential, Random }

# Playback order of the audio collection
@export var PlaybackOrder : AudioPlaybackOrder = AudioPlaybackOrder.Random

# Default value for the current stream player index
const NO_STREAM_PLAYER : int = -1

# The current audio stream player index
var m_CurrentPlayerIndex : int = NO_STREAM_PLAYER


# The following should only be used if you want ALL
# the audio streams to play sequentially and
# automatically repeat until stop is called.
# Initialize the AudioCollection node
#func _ready() -> void:
	#_ConnectStreamSignals()


# Connect all AudioStreamPlayer children to the 'finished' signal
func _ConnectStreamSignals() -> void:
	for child in get_children():
		# Connect all AudioStreamPlayer children to the 'finished' signal to allow audio continuity
		var audioStreamPlayer : AudioStreamPlayer = child as AudioStreamPlayer
		audioStreamPlayer.finished.connect(_OnAudioStreamFinished)


# Callback function for handling stream finished playing events
func _OnAudioStreamFinished() -> void:
	Play()


# Start the audio collection playback
func Play() -> void:
	if (PlaybackOrder == AudioPlaybackOrder.Sequential):
		# Set the current player index to the next audio clip
		m_CurrentPlayerIndex = (m_CurrentPlayerIndex + 1) % get_child_count()
	
	elif (PlaybackOrder == AudioPlaybackOrder.Random):
		# Set the current player index to a random audio clip
		m_CurrentPlayerIndex = randi() % get_child_count()
	
	# Start playback of the selected audio stream player
	var selectedStreamPlayer : AudioStreamPlayer = get_child(m_CurrentPlayerIndex) as AudioStreamPlayer
	selectedStreamPlayer.play()


# Stop the audio collection playback
func Stop() -> void:
	if (m_CurrentPlayerIndex != NO_STREAM_PLAYER):
		var currentStreamPlayer : AudioStreamPlayer = get_child(m_CurrentPlayerIndex) as AudioStreamPlayer
		currentStreamPlayer.stop()


# Editor node warning for an illegal node configuration
func _get_configuration_warnings() -> PackedStringArray:
	if (get_child_count() == 0):
		# The AudioCollection node does not contain any children
		return ["The audio collection must contain at least one AudioStreamPlayer node"]
	else:
		for child in get_children():
			if (not (child is AudioStreamPlayer)):
				# At least one of the AudioCollection's child nodes has an incompatible type
				return ["Audio collection's child nodes must be of type AudioStreamPlayer"]
	# The node's configuration is legal
	return []

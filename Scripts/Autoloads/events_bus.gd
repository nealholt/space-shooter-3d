extends Node

# https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/

# Emitted after the WorldEnvironment.environment reference
# in global has been set. This is important so that the massive
# explosion scene can save the baseline world environment values.
@warning_ignore("unused_signal") # Added so the debugger stops nagging me.
signal environment_set()

extends Node

# https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/

# Emitted when any ship dies. Currently used by levels to know
# when a level has ended in victory or defeat.
@warning_ignore("unused_signal") # Added so the debugger stops nagging me.
signal ship_died(s:Ship)

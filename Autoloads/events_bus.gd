extends Node

# https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/

# Emitted when any ship dies. Currently used by levels to know
# when a level has ended in victory or defeat.
@warning_ignore("unused_signal") # Added so the debugger stops nagging me.
signal ship_died(s:Ship)

# Emitted when a projectile dies or a hitbox takes damage.
# Used to gather data on accuracy, friendly fire, and
# other damage dealing.
@warning_ignore("unused_signal") # Added so the debugger stops nagging me.
signal register_damage(dat:ShootData)

extends Node2D

func _ready() -> void:
	if has_node("TransitionLayer/FadeRect"):
		$TransitionLayer/FadeRect.color.a = 1.0
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_in")

extends Area2D

export(String) var next_level # allow next_level to be changed from drop down editor on a scene by scene basis

func get_next_scene():
	return next_level # return the name of the next level

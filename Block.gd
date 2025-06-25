extends KinematicBody2D

const UP = Vector2(0,-1) # Direction of Up
const GRAVITY = 20 # Acceleration of Gravity
var motion = Vector2(0,0) # Velocity in X and Y Directions
var closePeanut = false # If Peanut is Close to the Block
signal block_picked_up(pickedup) # Sends whether or not block is being picked up
export(Vector2) var startPos # allow startPos to be changed from drop down editor on a scene by scene basis

func do_gravity(): # move according to gravity
	motion.y += GRAVITY # increase y velocity (downward) by GRAVITY
	
func check_picked_up(): # respond to being picked up if picked up
	if closePeanut and Input.is_action_just_released("ui_down"): # if down key is pressed when block is near Peanut
		if $CollisionShape2D.disabled == false: # if the block is not picked up
			$CollisionShape2D.disabled = true # cause the block to stop interacting with other physical objects
			# this is so the block will not act as a ceiling when being picked up
			# $CollisionShape2D.disabled therefore corresponds with whether the block is being picked up or not
		else: # if the block is already picked up
			$CollisionShape2D.disabled = false # the block can interact with everything again
			position.x -= 65 # set the block down to the left
		emit_signal("block_picked_up", $CollisionShape2D.disabled) # tell Peanut whether block is set down or picked up

func _physics_process(_delta): # built-in function from KinematicBody2D node
	# runs about 60 times per second but varies based on the computer
	# delta is a built in variable that gives the inverse of the speed of the computer
	do_gravity() # move according to gravity
	check_picked_up() # respond to being picked up if picked up
	motion = move_and_slide(motion, UP) # built-in function from KinematicBody2D node
	# move and slide moves according to given velocity vector (motion) but stops x motion if it would run into a wall,
	# or y motion if it would run into a celing or floor; it returns the velocity vector caused by the collision
	# (it sets y to 0 when the character has collided with the floor)
	pass

func _on_Area2D_area_entered(area):# when the area surrounding the block (bigger CollisionShape) overlaps with another
	if area.get_name() == "PeanutArea": # if that area is Peanut
		closePeanut = true # Peanut is close to the block
	elif area.get_name() == "AnswerChecker": # if that area is the Answer Checker
		if startPos.x == 2275: # if this is the block that started at the correct place (meaning it is the correct block)
			get_tree().change_scene("res://Levels/ThirdLevel.tscn") # go to the next level
		else: # otherwise
			position.x = startPos.x # go back to original x position
			position.y = startPos.y # go back to original y position

func _on_Area2D_area_exited(area): # when the area surrounding the block no longer overlaps with another
	if area.get_name() == "PeanutArea": # if that area is Peanut
		closePeanut = false # Peanut is no longer close to the block

func _on_Peanut_position_sent(posx,posy): # when the position of Peanut is recieved
	if $CollisionShape2D.disabled: # if this block is being held
		position.x = posx # go to the same x position as Peanut
		position.y = posy-50 # go slightly above the y position of Peanut
		motion.y = 0 # ignore gravity

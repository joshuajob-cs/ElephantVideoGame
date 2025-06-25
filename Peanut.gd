extends KinematicBody2D

const UP = Vector2(0,-1) # Direction of Up
const MAX_SPEED = 400 # Maximum Horizontal Speed
const ACCELERATION = 40 # Acceleration from Walking
const JUMP = 620 # Initial Velocity When Jumping (impacts jump height)
const GRAVITY = 20 # Acceleration of Gravity
const FRICTION = 0.2 # Strength of Friction
var motion = Vector2(0,0) # Velocity in X and Y Directions
var slowing = 0 # How Much Being Slowed Down by Friction
var walking = false # If Walking
var horiz_accel = false # If Horizontally Accelerating (right or left key pressed)
var leaving = false # If Leaving to the Next Level
var lowGrav = false # If Low Gravity in This Area
var holding_block = false # If Holding a Block
signal position_sent(posx,posy) # Sends current X and Y positions

func is_positive(num): # return a boolean based on if a number is positive
	if num > 0: # if the number is positive
		return true # return true
	return false # otherwise return false

func get_pos_or_neg(is_pos): # return a 1 or -1 based on a boolean (true means positive)
	if is_pos: # if positive
		return 1 # return a 1
	return -1 # otherwise return a -1

func get_near_to_zero(num1, num2): # return the value that in closest to zero
	if abs(num1) < abs(num2): # if num1 is further from zero than num2
		return num1 # return num1
	return num2 # otherwise return num2

func set_defaults():
		slowing = 0 # not being slowed down by the floor unless stated otherwise
		walking = false # not walking unless stated otherwise
		horiz_accel = (Input.is_action_pressed("ui_right")) or (Input.is_action_pressed("ui_left"))
		# horizontally accelerating if left or right arrow keys are pressed
		pass

func do_jump(): # jump if needed
	if Input.is_action_just_pressed("ui_up") and is_on_floor(): # when up key is being pressed and on floor
		motion.y = -JUMP # y velocity is set to a large negative value (upward)

func get_divider(move_type): # get the divider which can convert ground motion to air motion
	if is_on_floor(): # if on the ground
		return 1 # don't convert movement (divide by 1)
	if move_type == "fri": # otherwise, if converting friction
		return 4 # it will end up being divided by 4
	return 5 # otherwise, it will end up being divided by 5

func do_accel_horiz(is_right): # accelerate horizontally
	if is_positive(motion.x) != is_right: # if traveling the opposite direction as the current velocity
		slowing = FRICTION/get_divider("fri") # allow friction to help slow movement significantly
	var pos_or_neg = get_pos_or_neg(is_right) # determine pos_or_neg based on direction of movement
	motion.x = get_near_to_zero(motion.x + ACCELERATION*pos_or_neg/get_divider("acc"), MAX_SPEED*pos_or_neg)
	# take into account direction and whether or not character is is the air when accelerating
	# do not change motion.x (x velocity) to be further from zero than MAX_SPEED
	pass

func do_walk(): # interpret left and right arrow keys in order to walk
	walking = is_on_floor() # set walking animation on or off based off of whether or not character is on the ground
	if Input.is_action_pressed("ui_right"): # when right key is being pressed
		do_accel_horiz(true) # accelerate to the right
	if Input.is_action_pressed("ui_left"): # when left key is being pressed
		do_accel_horiz(false) # accelerate not-to-the-right (to the left)

func set_motion(): # determine x and y velocities
	do_jump() # jump if needed
	if horiz_accel: # if horizontally accelerating
		do_walk() # walk
	else: # if not horizontally accelerating
		slowing = FRICTION/get_divider("fri")  # allow friction to help slow movement significantly

func do_slow(): # slow down if needed
	if slowing != 0: # if being slowed down by the floor
		motion.x = lerp(motion.x, 0, slowing) # decrease x velocity by a percentage specified by slowing
		# if slowing is 0.2, or 20%, loses 20% of horizontal velocity, or motion.x - 0
		pass

func set_animation(): # set the movement animation
	if walking and abs(motion.x) > ACCELERATION / 2: # if needs horizontal movement animation
		$PeanutAppearance.animation = "Walking" # use frames from Walking animation
		$PeanutAppearance.play() # play walking animation
		$PeanutAppearance.flip_h = motion.x < 0 # set built in boolean flip_h based on direction of motion
		# flip_h determines which way the visual is flipped
	else: # if not walking
		$PeanutAppearance.stop() # stop animation
		$PeanutAppearance.animation = "Staying" # use frames from Staying animation

func do_gravity(): # move according to gravity
	motion.y += GRAVITY # increase y velocity (downward) by GRAVITY
	if leaving: # if leaving to the next level
		scale *= 0.9 # decrease size by 10%
	if lowGrav:# if there is  alow gravity
		motion.y -= GRAVITY*0.75

func do_block_carry(): # when carrying the block tell block what to do
	if holding_block: # if currently carrying a block
		emit_signal("position_sent",position.x,position.y) # send that block current x and y positions

func _physics_process(_delta): # built-in function from KinematicBody2D node
	# runs about 60 times per second but varies based on the computer
	# delta is a built in variable that gives the inverse of the speed of the computer
	set_defaults() # jump if needed
	set_motion() # determine x and y velocities
	do_slow()  # slow down if needed
	set_animation() # set the movement animation
	do_block_carry() # give block information if being carried
	do_gravity() # move according to gravity
	motion = move_and_slide(motion, UP) # built-in function from KinematicBody2D node
	# move and slide moves according to given velocity vector (motion) but stops x motion if it would run into a wall,
	# or y motion if it would run into a celing or floor; it returns the velocity vector caused by the collision
	# (it sets y to 0 when the character has collided with the floor)
	pass

func _on_Area2D_area_entered(area): # when this area is overlapping another
	if area.get_name() == "MagicDoorUp": # if that area is a MagicDoor
		leaving = true # do animation for leaving to the next level
		yield(get_tree().create_timer(0.5), "timeout") # wait half a second
		get_tree().change_scene("res://Levels/" + area.get_next_scene() + ".tscn") # actually leave to the next level
	elif "LowGravityArea" in area.get_name(): # if that area is a LowGravityArea
		lowGrav = true # react to gravity as if it is lesser

func _on_Area2D_area_exited(area): # when this area is no longer overlapping another
	if "LowGravityArea" in area.get_name(): # if that area is a LowGravityArea
		lowGrav = false # react to gravity as if it is normal

func _on_Block_block_picked_up(pickedup): # when the block has just been picked up or put down
	holding_block = pickedup # change holding block to "true" or "false" accordingly

class_name PlayerCharacterController extends Node3D

# Nodes

@onready var sphere: RigidBody3D = $Sphere
@onready var raycast: RayCast3D = $Ground

# Vehicle elements

@onready var visual_model = $Container

var input: Vector3
var normal: Vector3

var acceleration: float
var angular_speed: float
var linear_speed: float

var colliding: bool

var linear_velocity: Vector3
var prev_position: Vector3

var calculated_lean: float

# Public Functions

func get_player_position() -> Vector3:
	if visual_model:
		return visual_model.global_position
	return Vector3.ZERO
	
# Functions

func _physics_process(delta):

	handle_input(delta)

	var direction = sign(linear_speed)
	if direction == 0: direction = sign(input.z) if abs(input.z) > 0.1 else 1

	var steering_grip = clamp(abs(linear_speed), 0.2, 1.0)

	var target_angular = -input.x * steering_grip * 4 * direction
	angular_speed = lerp(angular_speed, target_angular, delta * 4)

	visual_model.rotate_y(angular_speed * delta)

	# Ground alignment

	if raycast.is_colliding():
		if !colliding:
			if visual_model != null: visual_model.position = Vector3(0, 0.1, 0) # Bounce
			input.z = 0

		normal = raycast.get_collision_normal()

		# Orient model to colliding normal

		if normal.dot(visual_model.global_basis.y) > 0.5:
			var xform = align_with_y(visual_model.global_transform, normal)
			visual_model.global_transform = visual_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()

	colliding = raycast.is_colliding()

	var target_speed = input.z

	if (target_speed < 0 and linear_speed > 0.01):
		linear_speed = lerp(linear_speed, 0.0, delta * 8)
	else:
		if (target_speed < 0):
			linear_speed = lerp(linear_speed, target_speed / 2, delta * 2)
		else:
			linear_speed = lerp(linear_speed, target_speed, delta * 6)

	acceleration = lerpf(acceleration, linear_speed + (abs(sphere.angular_velocity.length() * linear_speed) / 100), delta * 1)

	# Match vehicle model to physics sphere

	visual_model.position = sphere.position - Vector3(0, 0.65, 0)
	raycast.position = sphere.position

	# Calculate vehicle model linear velocity

	linear_velocity = (visual_model.position - prev_position) / delta
	prev_position = visual_model.position

# Handle input when vehicle is colliding with ground

func handle_input(delta):

	if raycast.is_colliding():
		input.x = Input.get_axis("ui_left", "ui_right")
		input.z = Input.get_axis("ui_down", "ui_up")

	sphere.angular_velocity += visual_model.get_global_transform().basis.x * (linear_speed * 100) * delta

func align_with_y(xform, new_y):

	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

# Detect collisions and play impact sound

func _on_sphere_body_entered(_body: Node) -> void:
	print("_on_sphere_body_entered")
	if visual_model == null: return

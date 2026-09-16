extends WorldEnvironment
## Location-only experimental rendering. Restore the viewport when leaving.

var _viewport: Viewport
var _previous_msaa: Viewport.MSAA
var _previous_taa: bool
var _previous_shadow_atlas_size: int


func _ready() -> void:
	_viewport = get_viewport()
	_previous_msaa = _viewport.msaa_3d
	_previous_taa = _viewport.use_taa
	_previous_shadow_atlas_size = _viewport.positional_shadow_atlas_size
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.use_taa = true
	_viewport.positional_shadow_atlas_size = 4096


func _exit_tree() -> void:
	if is_instance_valid(_viewport):
		_viewport.msaa_3d = _previous_msaa
		_viewport.use_taa = _previous_taa
		_viewport.positional_shadow_atlas_size = _previous_shadow_atlas_size

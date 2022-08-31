tool
extends TextureRect

export(int) var cell_width := 16 setget set_cell_width, get_cell_width
export(int) var cell_height := 16 setget set_cell_height, get_cell_height
export(int) var offset_x := 0 setget set_offset_x
export(int) var offset_y := 0 setget set_offset_y
export(Color) var grid_color := Color.white setget set_color
export(bool) var show_grid := true setget set_show_grid
export(bool) var draw_debug := false

var cell_size := Vector2(16, 16)
var selected_region := Rect2()
var selecting := false

func _gui_input(event: InputEvent) -> void:
  if not event is InputEventMouseButton:
    if event is InputEventMouseMotion:
      _on_mouse_move(event)
    return
  event = event as InputEventMouseButton
  
  var left_down = event.pressed and event.button_index == BUTTON_LEFT
  var right_down = event.pressed and event.button_index == BUTTON_RIGHT
  var left_up = not event.pressed and event.button_index == BUTTON_LEFT
  var right_up = not event.pressed and event.button_index == BUTTON_RIGHT

  if right_down:
    set_selection_start(get_local_mouse_position())
    set_selection_end(get_local_mouse_position())
    selecting = true
    update()
  elif right_up:
    set_selection_end(get_local_mouse_position())
    selecting = false
    update()

func set_selection_start(pos: Vector2) -> void:
  selected_region.position = pos
  return
func set_selection_end(pos: Vector2) -> void:
  selected_region.end = pos
  return
func clear_selection() -> void:
  selected_region = Rect2()

# MEMO: maybe we can cache the result to improve performance when it become a problem
func snap_selection() -> Rect2:
  if selected_region.position.is_equal_approx(Vector2.ZERO) and selected_region.size.is_equal_approx(Vector2.ZERO):
    return Rect2()
  var offset = Vector2(offset_x, offset_y)
  var area = selected_region.abs().clip(Rect2(Vector2.ZERO, rect_size))
  area.position -= offset
  var start = (area.position / cell_size).floor()
  var end = (area.end / cell_size).ceil()
  var rect = Rect2(start*cell_size+offset, (end-start)*cell_size)
  return rect
  
func has_selection() -> bool:
  return not snap_selection().has_no_area()

func get_selection_as_texture() -> Texture:
  if not has_selection():
    return null
  var atlas = AtlasTexture.new()
  atlas.atlas = texture
  atlas.region = snap_selection()
  # prevent texture from edge pixel bleeding
  atlas.filter_clip = true # doesn't work?
  atlas.resource_local_to_scene = true
  return atlas
  
var drag_data_store

func get_drag_data(position: Vector2):
  if snap_selection().has_point(position):
    var texture = get_selection_as_texture()
    var control = TextureRect.new()
    control.texture = texture
    control.modulate = ColorN('white', 0.5)
    set_drag_preview(control)
    drag_data_store = texture
    var drag_data = {
      type = 'obj_property',
      object = self,
      property = 'drag_data_store',
      value = texture
    }
    return drag_data

func _on_mouse_move(event: InputEventMouseMotion) -> void:
  if not selecting:
    return
  selected_region.end = get_local_mouse_position()
  update()
  pass

func _draw() -> void:
  if show_grid:
    for x in range(0, (rect_size.x - offset_x) / cell_size.x + 1):
      draw_line(Vector2(x * cell_size.x + offset_x, 0), Vector2(x* cell_size.x + offset_x, rect_size.y), grid_color, 1)
    for y in range(0, (rect_size.y - offset_y) / cell_size.y + 1):
      draw_line(Vector2(0, y* cell_size.y + offset_y), Vector2(rect_size.x, y* cell_size.y + offset_y),grid_color,1)
    # draw selection
    _draw_selection_region()
    
  if draw_debug:
    draw_rect(selected_region, Color.green, false, 5)

func reset_setting():
  offset_x = 0
  offset_y = 0
  self.cell_width = 16
  self.cell_height = 16

func _draw_selection_region() -> void:
  var rect = snap_selection()
  if not rect.has_no_area():
    var color = Color.orange
    draw_rect(rect, ColorN('orange', 0.4))
    draw_rect(rect, ColorN('white', 1), false, 1.1, true)

func set_cell_width(width: int) -> void:
  clear_selection()
  cell_size.x = width
  update()
  
func get_cell_width() -> int:
  return cell_size.x as int
  
func set_cell_height(height: int) -> void:
  clear_selection()
  cell_size.y = height
  update()
  
func get_cell_height() -> int:
  return cell_size.y as int
  
func set_offset_x(value: int):
  offset_x = value
  update()
func set_offset_y(value: int):
  offset_y = value
  update()
  
func set_color(color: Color) -> void:
  grid_color = color
  update()

func set_show_grid(show: bool) -> void:
  show_grid = show
  update()

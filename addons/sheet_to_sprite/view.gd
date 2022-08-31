tool
extends Control

onready var sheet_select: TextureRect = $'%SheetSelect'
onready var margin_container: MarginContainer = $'%margin_container'
onready var scroll_container: ScrollContainer = $'%ScrollContainer'
onready var wrapper: Control = $'%Wrapper'

var plugin: EditorPlugin

func _ready() -> void:
  # originally I want to hide scroll bars, though none works
  #scroll_container.get_v_scrollbar().visible = false # doesn't work?
  #scroll_container.get_v_scrollbar().hide() # doesn't work?
  #scroll_container.get_h_scrollbar().visible = false # doesn't work?
#  scroll_container.scroll_horizontal_enabled = false # cause freeze

  reset_margin_container()
  # center image, no idea why doesn't work in editor
  yield(get_tree(), 'idle_frame')
  scroll_container.scroll_horizontal = (margin_container.rect_size.x - scroll_container.rect_size.x) / 2
  scroll_container.scroll_vertical = (margin_container.rect_size.y - scroll_container.rect_size.y) / 2
  
  if plugin:
    plugin.get_canvas_item_editor().get_parent().set_drag_forwarding(self)
  
  # setup delete function
  $ConfirmationDialog.connect('confirmed', self, '_delete_item', [])

func _notification(what: int) -> void:
  if what == NOTIFICATION_DRAG_END:
    _remove_preview()
  elif what == NOTIFICATION_PREDELETE:
    preview_node.queue_free()
  pass

# for debug
func print_tree_class(node: Node, depth: int):
  for n in node.get_children():
    if n is CanvasItem and n.visible:
      print('  '.repeat(depth),n.name, ' - ', n.get_class())
    if n.get_child_count() > 0:
      print_tree_class(n, depth+1)
  pass

func _on_ScrollContainer_resized() -> void:
  reset_margin_container()
  
func reset_margin_container() -> void:
  var scale = sheet_select.rect_scale
  var diff = sheet_select.rect_size * (scale - Vector2.ONE)
  margin_container.add_constant_override('margin_left', scroll_container.rect_size.x)
  margin_container.add_constant_override('margin_right', scroll_container.rect_size.x + diff.x)
  margin_container.add_constant_override('margin_top', scroll_container.rect_size.y)
  margin_container.add_constant_override('margin_bottom', scroll_container.rect_size.y + diff.y)

var panning := false

func _on_margin_container_gui_input(event: InputEvent) -> void:
  
  if event is InputEventMouseButton and event.pressed:
    margin_container.grab_focus()
  
  if event is InputEventMouseButton:
    event = event as InputEventMouseButton # hint type inference
    var mwup = event.pressed and event.button_index == BUTTON_WHEEL_UP
    var mwdown = event.pressed and event.button_index == BUTTON_WHEEL_DOWN
    if mwup:
      var old = sheet_select.rect_scale
      sheet_select.rect_scale = old*1.1
      reset_margin_container()
      recalc_pos(0.1)
    elif mwdown:
      var old = sheet_select.rect_scale
      sheet_select.rect_scale = old*0.9
      reset_margin_container()
      recalc_pos(-0.1)
  
  if event is InputEventMouseButton:
    var middle_down = event.pressed and event.button_index == BUTTON_MIDDLE
    var middle_up = not event.pressed and event.button_index == BUTTON_MIDDLE
    if middle_down: 
      panning = true
    elif middle_up:
      panning = false
  elif event is InputEventKey:
    var space_down = event.pressed and event.scancode == KEY_SPACE
    var space_up = not event.pressed and event.scancode == KEY_SPACE
    if space_down: 
      panning = true
    elif space_up:
      panning = false

  if event is InputEventMouseMotion:
    if panning:
      scroll_container.scroll_horizontal -= event.relative.x
      scroll_container.scroll_vertical -= event.relative.y
    pass

func recalc_pos(scale_change: float):
  var center = Vector2(scroll_container.scroll_horizontal + scroll_container.rect_size.x/2, scroll_container.scroll_vertical + scroll_container.rect_size.y/2)
  var distance = center - scroll_container.rect_size
  var offset = distance * scale_change
  scroll_container.scroll_horizontal += offset.x
  scroll_container.scroll_vertical += offset.y
  pass

func _on_input_width_value_changed(value: float) -> void:
  sheet_select.cell_width = value
  pass # Replace with function body.
func _on_input_height_value_changed(value: float) -> void:
  sheet_select.cell_height = value
  pass # Replace with function body.
func _on_input_offsetx_value_changed(value: float) -> void:
  sheet_select.offset_x = value
  pass # Replace with function body.
func _on_input_offsety_value_changed(value: float) -> void:
  sheet_select.offset_y = value
  pass # Replace with function body.

onready var item_list: ItemList = $'%ItemList'
# {'file_path': {'cell_width': 16, ...}}
var setting_dict = {} 
var last_selected = -1

func _on_ItemList_item_selected(index: int) -> void:
  if last_selected >= 0:
    # save setting
    var file_path = item_list.get_item_metadata(last_selected)
    # in case last item get deleted
    if file_path:
      var setting = {
        'cell_width': sheet_select.cell_width,
        'cell_height': sheet_select.cell_height,
        'offset_x': sheet_select.offset_x,
        'offset_y': sheet_select.offset_y,
      }
      setting_dict[file_path] = setting
    
  last_selected = index
  # load setting
  var file_path = item_list.get_item_metadata(index)
  if setting_dict.has(file_path):
    var setting = setting_dict[file_path]
    update_setting(setting)
  if file_path:
    sheet_select.texture = load(file_path)
    wrapper.rect_min_size = sheet_select.texture.get_size()
  pass # Replace with function body.

func update_setting(setting: Dictionary):
  # update canvas
  sheet_select.cell_width = setting['cell_width']
  sheet_select.cell_height = setting['cell_height']
  sheet_select.offset_x = setting['offset_x']
  sheet_select.offset_y = setting['offset_y']
  
  # update toolbar
  $'%input_width'.value = setting['cell_width']
  $'%input_height'.value = setting['cell_height']
  $'%input_offsetx'.value = setting['offset_x']
  $'%input_offsety'.value = setting['offset_y']

func can_drop_data_fw(position: Vector2, data, from) -> bool:
  print(data)
  var condition = data is Dictionary and data.type == 'obj_property' and data.value is Texture
  if condition:
    var value = data.value
    var root = plugin.get_editor_interface().get_edited_scene_root()
    var selected = plugin.get_editor_interface().get_selection().get_selected_nodes()
    var pos
    var scale = Vector2.ONE
    if selected.size() > 0:
      pos = selected[0].get_viewport().canvas_transform.affine_inverse().xform(selected[0].get_viewport().get_mouse_position())
      if selected[0] is CanvasItem:
        scale = (selected[0] as CanvasItem).get_global_transform().get_scale()
    else:
      pos = root.get_viewport().canvas_transform.affine_inverse().xform(root.get_viewport().get_mouse_position())
    if not preview_node.get_parent():
      _create_preview(value)
    preview_node.set_global_position(pos)
    preview_node.scale = scale
    return true
  return false
  
onready var preview_node := Node2D.new()
func _create_preview(value: Texture):
  var sprite = Sprite.new()
  sprite.texture = value
  sprite.modulate = ColorN('white', 0.7)
  preview_node.add_child(sprite)
  plugin.get_editor_interface().get_edited_scene_root().add_child(preview_node)
  pass
  
func _remove_preview():
  if not preview_node.get_parent():
    return
  for c in preview_node.get_children():
    preview_node.remove_child(c)
    c.queue_free()
  preview_node.get_parent().remove_child(preview_node)
  pass

func drop_data_fw(position: Vector2, data, from) -> void:
  _remove_preview()
  var condition = data is Dictionary and data.type == 'obj_property' and data.value is Texture
  if condition:
    var value = data.value
    var root = plugin.get_editor_interface().get_edited_scene_root()
    var selected = plugin.get_editor_interface().get_selection().get_selected_nodes()
    
    var history = plugin.get_undo_redo()
    history.create_action('drop sprite')
    
    var sprite = Sprite.new()
    history.add_do_reference(sprite)
    if value is AtlasTexture:
      history.add_do_property(sprite, 'region_enabled', true)
      history.add_do_property(sprite, 'region_rect', value.region)
      history.add_do_property(sprite, 'texture', value.atlas)
    else:
      history.add_do_property(sprite, 'texture', value)

    # in first selected or scene root
    if selected.size() > 0:
      var pos = selected[0].get_viewport().canvas_transform.affine_inverse().xform(selected[0].get_viewport().get_mouse_position())
      history.add_do_method(selected[0], 'add_child', sprite, true)
      history.add_undo_method(selected[0], 'remove_child', sprite)
      history.add_do_property(sprite, 'global_position', pos)
    else:
      var pos = root.get_viewport().canvas_transform.affine_inverse().xform(root.get_viewport().get_mouse_position())
      history.add_do_method(root, 'add_child', sprite, true)
      history.add_undo_method(root, 'remove_child', sprite)
      history.add_do_property(sprite, 'global_position', pos)
    history.add_do_property(sprite, 'owner', root)
    
    history.commit_action()
  pass


func _on_Delete_pressed() -> void:
  if item_list.get_selected_items().size() > 0:
    $ConfirmationDialog.popup_centered()

func _delete_item() -> void:
  if item_list.get_selected_items().size() > 0:
    for idx in item_list.get_selected_items():
      item_list.remove_item(idx)

func _on_set_preview_pressed() -> void:
  var data = sheet_select.get_selection_as_texture()
  if data and item_list.get_selected_items().size() > 0:
    item_list.set_item_icon(item_list.get_selected_items()[0], data)


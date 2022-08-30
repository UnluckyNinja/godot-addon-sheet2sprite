tool
class_name SheetToSpritePlugin
extends EditorPlugin

var plugin_view: Control

func _enter_tree() -> void:
  plugin_view = preload('res://addons/sheet_to_sprite/view.tscn').instance()
  plugin_view.plugin = self
  add_control_to_bottom_panel(plugin_view, 'SpriteSheet')
  pass

func _exit_tree() -> void:
  remove_control_from_bottom_panel(plugin_view)
  plugin_view.free()
  pass

func recursive_find_node(node: Node, match_class: String) -> Node:
  var queue = []
  queue.append_array(node.get_children())
  while not queue.empty():
    var item = queue.pop_front()
    if item.get_class() == match_class:
      return item
    queue.append_array(item.get_children())
  
  return null

func get_canvas_item_editor() -> Control:
  var viewport = get_editor_interface().get_editor_viewport()
  var canvas_editor = recursive_find_node(viewport, 'CanvasItemEditorViewport')
  if canvas_editor:
    return canvas_editor
  else:
    push_error('didn\'t found canvas item editor')
    return null

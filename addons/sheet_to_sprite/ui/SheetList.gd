tool
extends ItemList

var regex = RegEx.new()


func _ready() -> void:
  regex.compile('^(png|jpg|jpeg|webp|svg)$')

func can_drop_data(position: Vector2, data) -> bool:
  if data is Dictionary:
    if data.type == 'files':
      var file := data.files[0] as String
      if regex.search(file.get_extension()) != null:
        return true
    if data.type == 'obj_property' and data.value is Texture:
      var idx = get_item_at_position(position, true)
      if idx >= 0:
        return true
  return false

func drop_data(position: Vector2, data) -> void:
  if data is Dictionary:
    if data.type == 'files':
      var file := data.files[0] as String
      if regex.search(file.get_extension()) != null:
        var texture = load(file)
        add_item(file.get_file(), texture)
        var idx = get_item_count() - 1
        set_item_metadata(idx, file)
    if data.type == 'obj_property' and data.value is Texture:
      var idx = get_item_at_position(position, true)
      if idx >= 0:
        set_item_icon(idx, data.value)
  pass

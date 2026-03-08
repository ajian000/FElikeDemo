# 单位节点 - 管理单位的渲染和交互

class_name UnitNode

extends Node2D

# 信号
signal unit_clicked(unit)

# 单位数据
var unit_data = {}

# 视觉元素
var sprite = null
var health_bar = null
var name_label = null

# 网格大小
var grid_size = 40

# 初始化
func _ready():
	# 创建精灵
	sprite = ColorRect.new()
	sprite.rect_size = Vector2(grid_size - 8, grid_size - 8)
	sprite.rect_position = Vector2(4, 4)
	sprite.color = Color(1, 0, 0)
	add_child(sprite)
	
	# 创建生命值条
	health_bar = ColorRect.new()
	health_bar.rect_size = Vector2(grid_size - 8, 4)
	health_bar.rect_position = Vector2(4, 2)
	health_bar.color = Color(0, 1, 0)
	add_child(health_bar)
	
	# 创建名称标签
	name_label = Label.new()
	name_label.rect_position = Vector2(4, grid_size - 14)
	name_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 10)
	add_child(name_label)

# 设置单位数据
func set_unit_data(data: Dictionary) -> void:
	unit_data = data
	update_visuals()
	update_position()

# 更新视觉效果
func update_visuals():
	# 只在单位数据存在时更新
	if not unit_data:
		return
	
	# 检查是否需要更新颜色
	if not sprite.has_theme_color_override("color") or sprite.color != get_unit_color():
		sprite.color = get_unit_color()
	
	# 检查是否需要更新边框
	var expected_border_color = Color(1, 1, 1) if unit_data.owner == "player" else Color(1, 0, 0)
	if not sprite.has_theme_color_override("border_color") or sprite.get_theme_color("border_color") != expected_border_color:
		sprite.add_theme_color_override("border_color", expected_border_color)
	
	# 检查是否需要更新生命值条
	var health_percent = float(unit_data.current_hp) / float(unit_data.max_hp)
	var expected_health_bar_size = Vector2((grid_size - 8) * health_percent, 4)
	if health_bar.rect_size != expected_health_bar_size:
		health_bar.rect_size = expected_health_bar_size
	
	# 检查是否需要更新名称标签
	if name_label.text != unit_data.name:
		name_label.text = unit_data.name

# 获取单位颜色
func get_unit_color() -> Color:
	match unit_data.type:
		"physical":
			return Color(1, 0.5, 0)  # 物理单位 - 橙色
		"natural":
			return Color(0, 1, 0)  # 自然魔法 - 绿色
		"holy":
			return Color(1, 1, 0)  # 神圣魔法 - 黄色
		"ancient":
			return Color(0, 0.5, 1)  # 古代魔法 - 蓝色
		_:
			return Color(0.5, 0.5, 0.5)  # 默认 - 灰色

# 更新位置
func update_position() -> void:
	if not unit_data:
		return
	
	var expected_position = Vector2(unit_data.x * grid_size, unit_data.y * grid_size)
	if position != expected_position:
		position = expected_position

# 选择状态
func set_selected(selected: bool) -> void:
	if selected:
		sprite.add_theme_color_override("border_color", Color(0, 1, 1))
		sprite.add_theme_stylebox_override("normal", StyleBoxFlat.new())
		var stylebox = sprite.get_theme_stylebox("normal")
		if stylebox:
			stylebox.set_border_width_all(2)
	else:
		sprite.remove_theme_color_override("border_color")
		sprite.remove_theme_stylebox_override("normal")
		update_visuals()

# 单位状态更新
func update_status():
	update_visuals()
	update_position()

# 检查点击
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var global_pos = event.global_position
		if sprite.get_global_rect().has_point(global_pos):
			# 触发单位选择信号
			emit_signal("unit_clicked", unit_data)
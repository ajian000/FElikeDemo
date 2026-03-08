# 地图编辑器脚本
# 实现8种地形绘制工具、9种单位放置工具、室内/室外地图模式切换
# 地图保存和加载、地图JSON导出、一键应用到游戏、左键绘制右键擦除、拖动连续绘制、实时预览

class_name MapEditor

var terrain_system = preload("res://terrain/TerrainSystem.gd").new()

# 编辑器属性
var grid_size = 40
var map_width = 20
var map_height = 15
var current_tool = "terrain"
var current_type = "grass"
var map_type = "outdoor"
var terrain = []
var units = []
var is_drawing = false
var selected_tool_button = null

# 节点引用
var terrain_layer = null
var unit_layer = null
var grid_layer = null
var current_tool_label = null

# 初始化
func _ready():
	# 获取节点引用
	terrain_layer = $VBoxContainer/HBoxContainer/EditorContainer/ViewportContainer/Viewport/EditorGrid/TerrainLayer
	unit_layer = $VBoxContainer/HBoxContainer/EditorContainer/ViewportContainer/Viewport/EditorGrid/UnitLayer
	grid_layer = $VBoxContainer/HBoxContainer/EditorContainer/ViewportContainer/Viewport/EditorGrid/GridLayer
	current_tool_label = $VBoxContainer/HBoxContainer/EditorContainer/StatusBar/CurrentTool
	
	# 初始化地图类型选择
	var map_type_select = $VBoxContainer/HBoxContainer/ToolPanel/MapType/MapTypeSelect
	map_type_select.add_item("室外", 0)
	map_type_select.add_item("室内", 1)
	map_type_select.selected = 0
	map_type_select.connect("item_selected", Callable(self, "_on_map_type_selected"))
	
	# 创建地形工具按钮
	create_terrain_tools()
	
	# 创建单位工具按钮
	create_unit_tools()
	
	# 连接按钮信号
	$VBoxContainer/HBoxContainer/ToolPanel/ToolHeader/CloseButton.connect("pressed", Callable(self, "_on_close_button_pressed"))
	$VBoxContainer/HBoxContainer/ToolPanel/Buttons/SaveButton.connect("pressed", Callable(self, "_on_save_button_pressed"))
	$VBoxContainer/HBoxContainer/ToolPanel/Buttons/LoadButton.connect("pressed", Callable(self, "_on_load_button_pressed"))
	$VBoxContainer/HBoxContainer/ToolPanel/Buttons/ExportButton.connect("pressed", Callable(self, "_on_export_button_pressed"))
	$VBoxContainer/HBoxContainer/ToolPanel/Buttons/ApplyButton.connect("pressed", Callable(self, "_on_apply_button_pressed"))
	$VBoxContainer/HBoxContainer/ToolPanel/Buttons/ClearButton.connect("pressed", Callable(self, "_on_clear_button_pressed"))
	
	# 初始化地形
	initialize_terrain()
	
	# 绘制地图
	render()
	
	# 设置视口输入
	var viewport = $VBoxContainer/HBoxContainer/EditorContainer/ViewportContainer/Viewport
	viewport.gui_disable_input = false
	viewport.input_event.connect(Callable(self, "_on_viewport_input"))

# 创建地形工具按钮
func create_terrain_tools():
	var terrain_grid = $VBoxContainer/HBoxContainer/ToolPanel/TerrainTools/TerrainGrid
	var terrain_types = ["grass", "water", "mountain", "fire", "ice", "rock", "wall", "floor"]
	
	for terrain_type in terrain_types:
		var button = Button.new()
		button.text = terrain_system.get_terrain_type(terrain_type).name
		button.set_meta("tool", "terrain")
		button.set_meta("type", terrain_type)
		button.connect("pressed", Callable(self, "_on_tool_button_pressed"))
		terrain_grid.add_child(button)

# 创建单位工具按钮
func create_unit_tools():
	var unit_grid = $VBoxContainer/HBoxContainer/ToolPanel/UnitTools/UnitGrid
	var unit_types = [
		"player_fire", "player_ice", "player_holy",
		"player_ancient", "player_physical", "enemy_fire",
		"enemy_ice", "enemy_holy", "enemy_physical"
	]
	
	var unit_names = {
		"player_fire": "玩家火法师",
		"player_ice": "玩家冰法师",
		"player_holy": "玩家神官",
		"player_ancient": "玩家古代法师",
		"player_physical": "玩家骑士",
		"enemy_fire": "敌方火法师",
		"enemy_ice": "敌方冰法师",
		"enemy_holy": "敌方神官",
		"enemy_physical": "敌方战士"
	}
	
	for unit_type in unit_types:
		var button = Button.new()
		button.text = unit_names.get(unit_type, unit_type)
		button.set_meta("tool", "unit")
		button.set_meta("type", unit_type)
		button.connect("pressed", Callable(self, "_on_tool_button_pressed"))
		unit_grid.add_child(button)

# 初始化地形
func initialize_terrain():
	terrain.clear()
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			var base_type = "grass" if map_type == "outdoor" else "floor"
			var terrain_data = terrain_system.get_terrain_type(base_type)
			row.append({
				"type": base_type,
				"move_cost": terrain_data.move_cost,
				"def_bonus": terrain_data.def_bonus,
				"passable": terrain_data.passable,
				"effect": terrain_data.get("effect", null)
			})
		terrain.append(row)
	
	# 清空单位
	units.clear()

# 渲染地图
func render():
	# 清空现有节点
	terrain_layer.clear_children()
	unit_layer.clear_children()
	grid_layer.clear_children()
	
	# 绘制地形
	draw_terrain()
	
	# 绘制单位
	draw_units()
	
	# 绘制网格
	draw_grid()

# 绘制地形
func draw_terrain():
	for y in range(map_height):
		for x in range(map_width):
			var terrain_data = terrain[y][x]
			var terrain_type = terrain_data.type
			var color = terrain_system.get_terrain_color(terrain_type)
			
			# 创建地形单元格
			var cell = ColorRect.new()
			cell.size = Vector2(grid_size, grid_size)
			cell.position = Vector2(x * grid_size, y * grid_size)
			cell.color = color
			terrain_layer.add_child(cell)
			
			# 墙壁添加纹理
			if terrain_type == "wall":
				var texture = TextureRect.new()
				texture.size = Vector2(grid_size, grid_size)
				texture.position = Vector2(x * grid_size, y * grid_size)
				# 这里可以添加墙壁纹理
				terrain_layer.add_child(texture)
			
			# 防御加成标记
			if terrain_data.def_bonus > 0:
				var label = Label.new()
				label.text = "+%d" % terrain_data.def_bonus
				label.position = Vector2(x * grid_size + 2, y * grid_size + 2)
				label.add_theme_color_override("font_color", Color(1, 1, 0))
				label.add_theme_font_size_override("font_size", 12)
				terrain_layer.add_child(label)

# 绘制单位
func draw_units():
	for unit in units:
		var x = unit.x
		var y = unit.y
		
		# 创建单位节点
		var unit_node = ColorRect.new()
		unit_node.size = Vector2(grid_size - 8, grid_size - 8)
		unit_node.position = Vector2(x * grid_size + 4, y * grid_size + 4)
		unit_node.roundness = 1.0
		
		# 设置颜色
		if unit.owner == "player":
			match unit.type:
				"natural": unit_node.color = Color(1, 0.42, 0.42)
				"holy": unit_node.color = Color(1, 0.84, 0)
				"ancient": unit_node.color = Color(0.6, 0.35, 0.71)
				"physical": unit_node.color = Color(0.2, 0.6, 0.82)
				_: unit_node.color = Color(0.18, 0.8, 0.47)
		else:
			unit_node.color = Color(0.9, 0.3, 0.24)
		
		unit_layer.add_child(unit_node)
		
		# 单位名称
		var label = Label.new()
		label.text = unit.name.left(3)
		label.position = Vector2(x * grid_size + grid_size/2 - 10, y * grid_size + grid_size/2 - 5)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.add_theme_font_size_override("font_size", 10)
		unit_layer.add_child(label)

# 绘制网格
func draw_grid():
	for x in range(map_width + 1):
		var line = Line2D.new()
		line.points = [Vector2(x * grid_size, 0), Vector2(x * grid_size, map_height * grid_size)]
		line.width = 1
		line.color = Color(0, 0, 0, 0.2)
		grid_layer.add_child(line)
	
	for y in range(map_height + 1):
		var line = Line2D.new()
		line.points = [Vector2(0, y * grid_size), Vector2(map_width * grid_size, y * grid_size)]
		line.width = 1
		line.color = Color(0, 0, 0, 0.2)
		grid_layer.add_child(line)

# 处理视口输入
func _on_viewport_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_drawing = true
				_paint_at_position(event.position)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_erase_at_position(event.position)
		else:
			is_drawing = false
	elif event is InputEventMouseMotion and is_drawing:
		_paint_at_position(event.position)

# 在指定位置绘制
func _paint_at_position(position):
	var x = int(position.x / grid_size)
	var y = int(position.y / grid_size)
	
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return
	
	if current_tool == "terrain":
		_set_terrain(x, y, current_type)
	elif current_tool == "unit":
		_place_unit(x, y, current_type)
	
	render()

# 在指定位置擦除
func _erase_at_position(position):
	var x = int(position.x / grid_size)
	var y = int(position.y / grid_size)
	
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return
	
	# 擦除单位
	for i in range(units.size() - 1, -1, -1):
		if units[i].x == x and units[i].y == y:
			units.remove_at(i)
			break
	
	render()

# 设置地形
func _set_terrain(x, y, type):
	var terrain_data = terrain[y][x]
	terrain_system.change_terrain_type(terrain_data, type)

# 放置单位
func _place_unit(x, y, unit_type):
	# 检查是否已有单位
	for i in range(units.size()):
		if units[i].x == x and units[i].y == y:
			units[i] = _create_unit_from_type(unit_type, x, y)
			return
	
	# 添加新单位
	units.append(_create_unit_from_type(unit_type, x, y))

# 从类型创建单位
func _create_unit_from_type(type, x, y):
	var unit_templates = {
		"player_fire": {
			"owner": "player", "type": "natural", "name": "玩家火法师",
			"stats": {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4},
			"spells": [
				{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "terrain_change": "fire", "description": "燃烧地面"},
				{"name": "烈焰爆发", "type": "natural", "mp_cost": 8, "range": 1, "power": 18, "description": "高伤害"}
			]
		},
		"player_ice": {
			"owner": "player", "type": "natural", "name": "玩家冰法师",
			"stats": {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4},
			"spells": [
				{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "减速效果"},
				{"name": "冰封路径", "type": "natural", "mp_cost": 6, "range": 1, "power": 8, "terrain_change": "ice", "description": "冻结水域"}
			]
		},
		"player_holy": {
			"owner": "player", "type": "holy", "name": "玩家神官",
			"stats": {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3},
			"spells": [
				{"name": "治疗术", "type": "holy", "mp_cost": 0, "range": 2, "power": -15, "target": "ally", "description": "恢复生命"},
				{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害"},
				{"name": "净化", "type": "holy", "mp_cost": 0, "range": 1, "power": 0, "effect": "解除debuff", "target": "ally", "description": "解除负面"}
			]
		},
		"player_ancient": {
			"owner": "player", "type": "ancient", "name": "玩家古代法师",
			"stats": {"hp": 18, "atk": 3, "def": 4, "mag": 22, "spd": 6, "move": 3},
			"spells": [
				{"name": "陨石坠落", "type": "ancient", "mp_cost": 15, "range": 3, "power": 25, "cast_time": 2, "description": "超大伤害"},
				{"name": "地壳隆起", "type": "ancient", "mp_cost": 12, "range": 2, "power": 10, "cast_time": 1, "terrain_change": "rock", "description": "升起石柱"}
			]
		},
		"player_physical": {
			"owner": "player", "type": "physical", "name": "玩家骑士",
			"stats": {"hp": 30, "atk": 14, "def": 12, "mag": 0, "spd": 9, "move": 5},
			"spells": [
				{"name": "冲锋", "type": "physical", "mp_cost": 0, "range": 1, "power": 15, "description": "物理攻击"}
			]
		},
		"enemy_fire": {
			"owner": "enemy", "type": "natural", "name": "敌方火法师",
			"stats": {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4},
			"spells": [
				{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "terrain_change": "fire", "description": "燃烧地面"}
			]
		},
		"enemy_ice": {
			"owner": "enemy", "type": "natural", "name": "敌方冰法师",
			"stats": {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4},
			"spells": [
				{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "减速效果"}
			]
		},
		"enemy_holy": {
			"owner": "enemy", "type": "holy", "name": "敌方神官",
			"stats": {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3},
			"spells": [
				{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害"}
			]
		},
		"enemy_physical": {
			"owner": "enemy", "type": "physical", "name": "敌方战士",
			"stats": {"hp": 35, "atk": 16, "def": 14, "mag": 0, "spd": 7, "move": 4},
			"spells": [
				{"name": "重击", "type": "physical", "mp_cost": 0, "range": 1, "power": 18, "description": "物理攻击"}
			]
		}
	}
	
	var template = unit_templates.get(type)
	if not template:
		return null
	
	return {
		"id": str(randi()),
		"x": x,
		"y": y,
		"owner": template.owner,
		"type": template.type,
		"name": template.name,
		"stats": template.stats,
		"spells": template.spells,
		"current_hp": template.stats.hp,
		"max_hp": template.stats.hp,
		"mp": 0 if template.type == "holy" else 20,
		"max_mp": 0 if template.type == "holy" else 25,
		"has_moved": false,
		"has_attacked": false,
		"status_effects": [],
		"casting_spell": null,
		"cast_time_remaining": 0
	}

# 处理地图类型选择
func _on_map_type_selected(index):
	map_type = "outdoor" if index == 0 else "indoor"
	initialize_terrain()
	render()

# 处理工具按钮按下
func _on_tool_button_pressed():
	var button = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
	var tool = button.get_meta("tool")
	var type = button.get_meta("type")
	
	# 更新当前工具
	current_tool = tool
	current_type = type
	
	# 更新工具显示
	var tool_names = {
		"grass": "草地", "water": "水域", "mountain": "山地", "fire": "燃烧",
		"ice": "冰冻", "rock": "石柱", "wall": "墙壁", "floor": "地板",
		"player_fire": "玩家火法师", "player_ice": "玩家冰法师",
		"player_holy": "玩家神官", "player_ancient": "玩家古代法师",
		"player_physical": "玩家骑士", "enemy_fire": "敌方火法师",
		"enemy_ice": "敌方冰法师", "enemy_holy": "敌方神官",
		"enemy_physical": "敌方战士"
	}
	current_tool_label.text = "当前工具: %s" % tool_names.get(type, type)
	
	# 更新按钮状态
	if selected_tool_button:
		selected_tool_button.remove_theme_color_override("font_color")
	selected_tool_button = button
	selected_tool_button.add_theme_color_override("font_color", Color(0, 0.6, 0.8))

# 处理关闭按钮
func _on_close_button_pressed():
	queue_free()

# 处理保存按钮
func _on_save_button_pressed():
	var map_data = {
		"map_type": map_type,
		"terrain": terrain,
		"units": units,
		"version": "1.0"
	}
	
	var file = FileAccess.open("user://saved_map.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(map_data))
		file.close()
		print("地图已保存到本地存储！")
	else:
		print("保存失败！")

# 处理加载按钮
func _on_load_button_pressed():
	var file = FileAccess.open("user://saved_map.json", FileAccess.READ)
	if file:
		var json_str = file.get_as_string()
		file.close()
		
		var map_data = JSON.parse_string(json_str)
		if map_data:
			map_type = map_data.get("map_type", "outdoor")
			terrain = map_data.get("terrain", [])
			units = map_data.get("units", [])
			
			# 更新地图类型选择
			var map_type_select = $VBoxContainer/HBoxContainer/ToolPanel/MapType/MapTypeSelect
			map_type_select.selected = 0 if map_type == "outdoor" else 1
			
			render()
			print("地图加载成功！")
		else:
			print("地图数据损坏，无法加载！")
	else:
		print("没有找到保存的地图！")

# 处理导出按钮
func _on_export_button_pressed():
	var map_data = {
		"map_type": map_type,
		"terrain": terrain,
		"units": units,
		"version": "1.0"
	}
	
	var json_str = JSON.stringify(map_data, "  ")
	var file = FileAccess.open("user://map_" + str(Time.get_datetime_dict_from_system()["unix"]) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("地图已导出为JSON文件！")
	else:
		print("导出失败！")

# 处理应用到游戏按钮
func _on_apply_button_pressed():
	# 这里需要与游戏管理器通信，将地图数据传递给游戏
	# 假设游戏管理器存在于MainScene中
	var main_scene = get_tree().get_root().get_child(0)
	if main_scene and main_scene.has_node("GameManager"):
		var game_manager = main_scene.get_node("GameManager")
		game_manager.load_map_from_editor(map_type, terrain, units)
		queue_free()
	else:
		print("游戏未初始化，无法应用地图！")

# 处理清空按钮
func _on_clear_button_pressed():
	initialize_terrain()
	render()

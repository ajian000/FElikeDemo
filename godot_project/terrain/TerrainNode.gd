# 地形节点 - 管理地形网格的渲染和交互

class_name TerrainNode

extends Node2D

# 地形系统实例
var terrain_system = preload("res://terrain/TerrainSystem.gd").new()

# 地图属性
var map_width = 20
var map_height = 15
var grid_size = 40
var map_type = "outdoor"  # outdoor | indoor

# 地形网格
var terrain_grid = []

# 视觉元素
var terrain_tiles = []
var terrain_labels = []

# 初始化
func _ready():
	# 生成地形
	generate_terrain()
	# 创建地形视觉元素
	create_terrain_visuals()

# 生成地形
func generate_terrain():
	terrain_grid.clear()
	
	for y in range(map_height):
		var row = []
		for x in range(map_width):
			var base_type = "grass" if map_type == "outdoor" else "floor"
			var terrain_data = terrain_system.get_terrain_type(base_type)
			var terrain = {
				type: base_type,
				move_cost: terrain_data.move_cost,
				def_bonus: terrain_data.def_bonus,
				passable: terrain_data.passable
			}
			if terrain_data.has("effect"):
				terrain.effect = terrain_data.effect
			row.append(terrain)
		terrain_grid.append(row)
	
	# 添加一些特殊地形
	if map_type == "outdoor":
		# 室外地图添加一些特殊地形
		terrain_system.create_terrain_area(terrain_grid, 5, 6, 4, 3, "water")
		terrain_system.create_terrain_area(terrain_grid, 12, 4, 3, 2, "mountain")
		terrain_system.create_terrain_area(terrain_grid, 14, 10, 3, 2, "water")
	else:
		# 室内地图添加一些墙壁
		terrain_system.create_terrain_area(terrain_grid, 8, 5, 2, 4, "wall")
		terrain_system.create_terrain_area(terrain_grid, 14, 8, 2, 3, "wall")

# 创建地形视觉元素
func create_terrain_visuals():
	# 只在地形瓦片为空时创建
	if terrain_tiles.size() == 0:
		# 创建地形瓦片
		for y in range(map_height):
			for x in range(map_width):
				var terrain = terrain_grid[y][x]
				var tile = ColorRect.new()
				tile.rect_size = Vector2(grid_size, grid_size)
				tile.rect_position = Vector2(x * grid_size, y * grid_size)
				tile.color = terrain_system.get_terrain_color(terrain.type)
				add_child(tile)
				terrain_tiles.append(tile)
	else:
		# 更新现有瓦片
		update_terrain_visuals()
	
	# 更新或创建标签
	update_terrain_labels()

# 更新地形标签
func update_terrain_labels():
	# 清除现有标签
	for label in terrain_labels:
		label.queue_free()
	terrain_labels.clear()
	
	# 创建新标签
	for y in range(map_height):
		for x in range(map_width):
			var terrain = terrain_grid[y][x]
			
			# 添加防御加成标记
			if terrain.def_bonus > 0:
				var label = Label.new()
				label.text = "+%d" % terrain.def_bonus
				label.rect_position = Vector2(x * grid_size + 2, y * grid_size + 2)
				label.add_theme_color_override("font_color", Color(1, 1, 0))
				label.add_theme_font_override("font", load("res://default_env.tres").default_font)
				add_child(label)
				terrain_labels.append(label)
			
			# 添加地形效果标记
			if terrain.has("effect"):
				var label = Label.new()
				label.text = terrain.effect.substr(0, 2)
				label.rect_position = Vector2(x * grid_size + grid_size - 15, y * grid_size + 2)
				label.add_theme_color_override("font_color", Color(1, 1, 1))
				label.add_theme_font_override("font", load("res://default_env.tres").default_font)
				add_child(label)
				terrain_labels.append(label)

# 更新地形视觉
func update_terrain_visuals():
	var index = 0
	for y in range(map_height):
		for x in range(map_width):
			var terrain = terrain_grid[y][x]
			var tile = terrain_tiles[index]
			tile.color = terrain_system.get_terrain_color(terrain.type)
			index += 1

# 改变地形类型
func change_terrain(x: int, y: int, type: String) -> Dictionary:
	if y >= 0 and y < map_height and x >= 0 and x < map_width:
		var terrain = terrain_grid[y][x]
		var result = terrain_system.change_terrain_type(terrain, type)
		
		# 只更新特定位置的地形视觉
		var index = y * map_width + x
		if index >= 0 and index < terrain_tiles.size():
			var tile = terrain_tiles[index]
			tile.color = terrain_system.get_terrain_color(terrain.type)
		
		# 更新标签
		update_terrain_labels()
		return result
	return {}

# 获取地形信息
func get_terrain_at(x: int, y: int) -> Dictionary:
	if y >= 0 and y < map_height and x >= 0 and x < map_width:
		return terrain_grid[y][x]
	return {}

# 检查移动是否可行
func can_move_to(x: int, y: int, units: Array, moving_unit: Dictionary = null) -> bool:
	# 检查边界
	if y < 0 or y >= map_height or x < 0 or x >= map_width:
		return false
	
	# 检查地形是否可通行
	var terrain = terrain_grid[y][x]
	if not terrain_system.is_passable(terrain):
		return false
	
	# 检查是否有其他单位
	for unit in units:
		if unit.x == x and unit.y == y and unit != moving_unit:
			return false
	
	return true

# 计算移动消耗
func calculate_move_cost(path: Array) -> int:
	var total_cost = 0
	
	for pos in path:
		var terrain = terrain_grid[pos.y][pos.x]
		total_cost += terrain_system.get_move_cost(terrain)
	
	return total_cost

# 应用地形效果
func apply_terrain_effect(unit: Dictionary, x: int, y: int) -> String:
	var terrain = get_terrain_at(x, y)
	if terrain.size() > 0:
		return terrain_system.apply_terrain_effect(unit, terrain)
	return ""

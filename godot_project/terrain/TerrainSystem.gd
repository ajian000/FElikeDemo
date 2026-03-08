# 地形系统 - 管理地形类型、属性和交互

class_name TerrainSystem

# 定义8种地形类型及其属性
var terrain_types = {
	"grass": {
		name: "草地",
		move_cost: 1,
		def_bonus: 0,
		color: Color(0.56, 0.93, 0.56),
		description: "正常移动，无特殊效果",
		passable: true
	},
	"water": {
		name: "水域",
		move_cost: 999,
		def_bonus: 0,
		color: Color(0.29, 0.56, 0.88),
		description: "阻挡移动，无法通行",
		passable: false
	},
	"mountain": {
		name: "山地",
		move_cost: 2,
		def_bonus: 1,
		color: Color(0.54, 0.45, 0.33),
		description: "移动消耗增加，提供防御加成",
		passable: true
	},
	"fire": {
		name: "燃烧",
		move_cost: 2,
		def_bonus: 0,
		color: Color(1.0, 0.27, 0.0),
		description: "移动消耗增加，可能造成持续伤害",
		passable: true,
		effect: "burn"
	},
	"ice": {
		name: "冰冻",
		move_cost: 1,
		def_bonus: 0,
		color: Color(0.88, 1.0, 1.0),
		description: "可通行，可能影响移动速度",
		passable: true,
		effect: "slow"
	},
	"rock": {
		name: "石柱",
		move_cost: 999,
		def_bonus: 2,
		color: Color(0.41, 0.41, 0.41),
		description: "完全阻挡，提供高额防御加成",
		passable: false
	},
	"wall": {
		name: "墙壁",
		move_cost: 999,
		def_bonus: 1,
		color: Color(0.29, 0.29, 0.29),
		description: "室内障碍，无法通行",
		passable: false
	},
	"floor": {
		name: "地板",
		move_cost: 1,
		def_bonus: 0,
		color: Color(0.83, 0.83, 0.83),
		description: "室内地面，正常移动",
		passable: true
	}
}

# 获取地形类型信息
func get_terrain_type(type: String) -> Dictionary:
	return terrain_types.get(type, terrain_types.grass)

# 检查地形是否可通行
func is_passable(terrain: Dictionary) -> bool:
	return terrain.passable or terrain.move_cost < 999

# 计算移动消耗
func get_move_cost(terrain: Dictionary) -> int:
	return terrain.move_cost or 1

# 计算防御加成
func get_def_bonus(terrain: Dictionary) -> int:
	return terrain.def_bonus or 0

# 应用地形效果
func apply_terrain_effect(unit: Dictionary, terrain: Dictionary) -> String:
	if terrain.has("effect"):
		match terrain.effect:
			"burn":
				return apply_burn_effect(unit)
			"slow":
				return apply_slow_effect(unit)
	return ""

# 应用燃烧效果
func apply_burn_effect(unit: Dictionary) -> String:
	var burn_damage = 2
	unit.current_hp = max(1, unit.current_hp - burn_damage)
	return "燃烧造成 %d 点伤害" % burn_damage

# 应用减速效果
func apply_slow_effect(unit: Dictionary) -> String:
	var original_move = unit.stats.move
	unit.stats.move = max(1, int(original_move * 0.8))
	return "冰冻使移动速度降低"

# 恢复单位状态（移除地形效果）
func restore_unit_status(unit: Dictionary) -> void:
	# 这里可以实现状态恢复逻辑
	pass

# 改变地形类型
func change_terrain_type(terrain: Dictionary, new_type: String) -> Dictionary:
	var old_type = terrain.type
	var new_terrain_data = get_terrain_type(new_type)
	
	terrain.type = new_type
	terrain.move_cost = new_terrain_data.move_cost
	terrain.def_bonus = new_terrain_data.def_bonus
	terrain.passable = new_terrain_data.passable
	if new_terrain_data.has("effect"):
		terrain.effect = new_terrain_data.effect
	else:
		if terrain.has("effect"):
			terrain.erase("effect")
	
	return {"old_type": old_type, "new_type": new_type}

# 生成地形描述
func get_terrain_description(terrain: Dictionary) -> String:
	var type_data = get_terrain_type(terrain.type)
	var description = type_data.description
	
	if type_data.def_bonus > 0:
		description += " (防御+%d)" % type_data.def_bonus
	
	if type_data.move_cost > 1:
		description += " (移动消耗: %d)" % type_data.move_cost
	
	return description

# 检查地形是否适合特定单位
func is_terrain_suitable(unit: Dictionary, terrain: Dictionary) -> bool:
	# 这里可以实现单位与地形的互动逻辑
	# 例如：某些单位可能对特定地形有优势
	return true

# 获取地形颜色
func get_terrain_color(type: String) -> Color:
	return get_terrain_type(type).color

# 生成随机地形（用于地图生成）
func generate_random_terrain(map_type: String, x: int, y: int, width: int, height: int) -> String:
	var base_terrain = "grass" if map_type == "outdoor" else "floor"
	
	# 简单的随机地形生成
	var rand = randf()
	if rand < 0.8:
		return base_terrain
	elif rand < 0.9 and map_type == "outdoor":
		return "mountain"
	elif rand < 0.95 and map_type == "outdoor":
		return "water"
	elif map_type == "indoor":
		return "wall"
	
	return base_terrain

# 批量创建地形区域
func create_terrain_area(terrain_grid: Array, x: int, y: int, width: int, height: int, type: String) -> void:
	for dy in range(height):
		for dx in range(width):
			var target_x = x + dx
			var target_y = y + dy
			
			if target_y >= 0 and target_y < terrain_grid.size() and target_x >= 0 and target_x < terrain_grid[0].size():
				var terrain = terrain_grid[target_y][target_x]
				change_terrain_type(terrain, type)

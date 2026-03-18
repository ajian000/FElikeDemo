# 游戏管理器 - 处理游戏的主要逻辑

class_name GameManager

extends Node2D

# 游戏状态
var current_turn = 1
var current_player = "player"  # player | enemy
var selected_unit = null
var move_mode = false
var attack_mode = false
var move_range = []
var attack_range = []
var current_map_mode = "outdoor"  # outdoor | indoor
var game_state = "playing"  # playing | paused | game_over | victory

# 游戏元素
var units = []
var unit_nodes = {}
var unit_positions = {}  # 用于快速查找位置上的单位
var terrain_node = null

# 战斗日志
var battle_log = []
var max_log_entries = 50

# 单位节点类
var UnitNodeClass = preload("res://game/UnitNode.gd")

# UI元素
var ui_root = null
var status_label = null
var battle_log_text = null
var end_turn_button = null
var switch_map_button = null
var restart_button = null
var pause_button = null
var move_button = null
var attack_button = null
var wait_button = null
var unit_name_label = null
var unit_hp_label = null
var unit_mp_label = null
var unit_status_label = null
var unit_stats_label = null
var spell_list = null

# 初始化
func _ready():
	# 获取地形节点
	terrain_node = get_node("Terrain")
	
	# 创建单位
	create_units()
	
	# 创建UI
	create_ui()
	
	# 连接编辑器按钮信号
	if has_node("UILayer/EditorButton"):
		var editor_button = get_node("UILayer/EditorButton")
		editor_button.pressed.connect(_on_editor_button_pressed)
	
	# 显示游戏开始信息
	print("游戏开始！点击单位进行操作")
	add_battle_log("系统", "游戏开始！点击单位进行操作")

# 创建单位
func create_units():
	if current_map_mode == "outdoor":
		# 室外地图单位布局
		# 玩家单位
		units.append(create_unit("player", 1, 7, "火法师", "natural", {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4}, [
			{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "effect": "燃烧", "terrain_change": "fire", "description": "造成伤害并燃烧地面"},
			{"name": "烈焰爆发", "type": "natural", "mp_cost": 8, "range": 1, "power": 18, "description": "近距离高伤害"}
		]))
		
		units.append(create_unit("player", 1, 5, "冰法师", "natural", {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4}, [
			{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "造成伤害并降低速度"},
			{"name": "冰封路径", "type": "natural", "mp_cost": 6, "range": 1, "power": 8, "terrain_change": "ice", "description": "冻结水域使其可通行"}
		]))
		
		units.append(create_unit("player", 2, 6, "神官", "holy", {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3}, [
			{"name": "治疗术", "type": "holy", "mp_cost": 0, "range": 2, "power": -15, "target": "ally", "description": "恢复友军生命值（无MP消耗）"},
			{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害（无MP消耗）"},
			{"name": "净化", "type": "holy", "mp_cost": 0, "range": 1, "power": 0, "effect": "解除debuff", "target": "ally", "description": "解除负面状态"}
		]))
		
		units.append(create_unit("player", 1, 9, "古代法师", "ancient", {"hp": 18, "atk": 3, "def": 4, "mag": 22, "spd": 6, "move": 3}, [
			{"name": "陨石坠落", "type": "ancient", "mp_cost": 15, "range": 3, "power": 25, "cast_time": 2, "description": "咏唱2回合：超大范围高伤害"},
			{"name": "地壳隆起", "type": "ancient", "mp_cost": 12, "range": 2, "power": 10, "cast_time": 1, "terrain_change": "rock", "description": "咏唱1回合：升起石柱阻挡"}
		]))
		
		units.append(create_unit("player", 3, 6, "骑士", "physical", {"hp": 30, "atk": 14, "def": 12, "mag": 0, "spd": 9, "move": 5}, [
			{"name": "冲锋", "type": "physical", "mp_cost": 0, "range": 1, "power": 15, "description": "物理攻击"}
		]))
		
		# 敌方单位
		units.append(create_unit("enemy", 17, 4, "敌方火法师", "natural", {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4}, [
			{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "terrain_change": "fire", "description": "造成伤害并燃烧地面"}
		]))
		
		units.append(create_unit("enemy", 18, 7, "敌方冰法师", "natural", {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4}, [
			{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "造成伤害并降低速度"}
		]))
		
		units.append(create_unit("enemy", 17, 10, "敌方神官", "holy", {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3}, [
			{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害"}
		]))
		
		units.append(create_unit("enemy", 16, 6, "敌方战士", "physical", {"hp": 35, "atk": 16, "def": 14, "mag": 0, "spd": 7, "move": 4}, [
			{"name": "重击", "type": "physical", "mp_cost": 0, "range": 1, "power": 18, "description": "物理攻击"}
		]))
	else:
		# 室内地图单位布局
		# 玩家单位
		units.append(create_unit("player", 3, 7, "火法师", "natural", {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4}, [
			{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "effect": "燃烧", "terrain_change": "fire", "description": "造成伤害并燃烧地面"},
			{"name": "烈焰爆发", "type": "natural", "mp_cost": 8, "range": 1, "power": 18, "description": "近距离高伤害"}
		]))
		
		units.append(create_unit("player", 3, 5, "冰法师", "natural", {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4}, [
			{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "造成伤害并降低速度"},
			{"name": "冰封路径", "type": "natural", "mp_cost": 6, "range": 1, "power": 8, "terrain_change": "ice", "description": "冻结水域使其可通行"}
		]))
		
		units.append(create_unit("player", 4, 6, "神官", "holy", {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3}, [
			{"name": "治疗术", "type": "holy", "mp_cost": 0, "range": 2, "power": -15, "target": "ally", "description": "恢复友军生命值（无MP消耗）"},
			{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害（无MP消耗）"},
			{"name": "净化", "type": "holy", "mp_cost": 0, "range": 1, "power": 0, "effect": "解除debuff", "target": "ally", "description": "解除负面状态"}
		]))
		
		units.append(create_unit("player", 3, 9, "古代法师", "ancient", {"hp": 18, "atk": 3, "def": 4, "mag": 22, "spd": 6, "move": 3}, [
			{"name": "陨石坠落", "type": "ancient", "mp_cost": 15, "range": 3, "power": 25, "cast_time": 2, "description": "咏唱2回合：超大范围高伤害"},
			{"name": "地壳隆起", "type": "ancient", "mp_cost": 12, "range": 2, "power": 10, "cast_time": 1, "terrain_change": "rock", "description": "咏唱1回合：升起石柱阻挡"}
		]))
		
		units.append(create_unit("player", 5, 6, "骑士", "physical", {"hp": 30, "atk": 14, "def": 12, "mag": 0, "spd": 9, "move": 5}, [
			{"name": "冲锋", "type": "physical", "mp_cost": 0, "range": 1, "power": 15, "description": "物理攻击"}
		]))
		
		# 敌方单位
		units.append(create_unit("enemy", 15, 4, "敌方火法师", "natural", {"hp": 25, "atk": 12, "def": 5, "mag": 15, "spd": 10, "move": 4}, [
			{"name": "火球术", "type": "natural", "mp_cost": 5, "range": 2, "power": 12, "terrain_change": "fire", "description": "造成伤害并燃烧地面"}
		]))
		
		units.append(create_unit("enemy", 16, 7, "敌方冰法师", "natural", {"hp": 22, "atk": 8, "def": 6, "mag": 14, "spd": 11, "move": 4}, [
			{"name": "冰锥术", "type": "natural", "mp_cost": 5, "range": 2, "power": 10, "effect": "减速", "description": "造成伤害并降低速度"}
		]))
		
		units.append(create_unit("enemy", 15, 10, "敌方神官", "holy", {"hp": 20, "atk": 5, "def": 7, "mag": 12, "spd": 8, "move": 3}, [
			{"name": "圣光术", "type": "holy", "mp_cost": 0, "range": 2, "power": 8, "target": "enemy", "description": "神圣伤害"}
		]))
		
		units.append(create_unit("enemy", 14, 6, "敌方战士", "physical", {"hp": 35, "atk": 16, "def": 14, "mag": 0, "spd": 7, "move": 4}, [
			{"name": "重击", "type": "physical", "mp_cost": 0, "range": 1, "power": 18, "description": "物理攻击"}
		]))

# 创建单位
func create_unit(owner: String, x: int, y: int, name: String, type: String, stats: Dictionary, spells: Array) -> Dictionary:
	var unit = {
		"id": str(randi_range(0, 1000000)),
		"owner": owner,
		"x": x,
		"y": y,
		"original_x": x,
		"original_y": y,
		"name": name,
		"type": type,
		"stats": stats,
		"max_hp": stats.hp,
		"current_hp": stats.hp,
		"mp": 20,
		"max_mp": 0 if type == "holy" else 25,  # 神圣魔法无MP限制
		"spells": spells,
		"has_moved": false,
		"has_attacked": false,
		"status_effects": [],
		"casting_spell": null,
		"cast_time_remaining": 0
	}
	
	# 创建单位节点
	var unit_node = UnitNodeClass.new()
	unit_node.set_unit_data(unit)
	unit_node.unit_clicked.connect(_on_unit_clicked)
	add_child(unit_node)
	unit_nodes[unit.id] = unit_node
	
	# 更新单位位置缓存
	unit_positions["%d,%d" % [x, y]] = unit
	
	return unit

# 计算移动范围
func calculate_move_range(unit: Dictionary) -> Array:
	var range = []
	var visited = {}
	var queue = []
	
	# 初始位置
	queue.append({"x": unit.x, "y": unit.y, "remaining": unit.stats.move})
	visited["%d,%d" % [unit.x, unit.y]] = true

	# 使用广度优先搜索代替递归
	while queue.size() > 0:
		var current = queue.pop_front()
		var x = current.x
		var y = current.y
		var remaining = current.remaining
		
		# 四方向移动
		var directions = [{"dx": 1, "dy": 0}, {"dx": -1, "dy": 0}, {"dx": 0, "dy": 1}, {"dx": 0, "dy": -1}]
		for dir in directions:
			var new_x = x + dir.dx
			var new_y = y + dir.dy
			var pos_key = "%d,%d" % [new_x, new_y]
			
			# 检查边界
			if new_x < 0 or new_x >= terrain_node.map_width or new_y < 0 or new_y >= terrain_node.map_height:
				continue
			
			# 检查是否访问过
			if visited.has(pos_key):
				continue
			
			# 检查地形和单位
			var terrain = terrain_node.get_terrain_at(new_x, new_y)
			var unit_at_pos = get_unit_at(new_x, new_y)
			
			if unit_at_pos and unit_at_pos != unit:
				continue  # 被其他单位占据
			if not terrain_node.terrain_system.is_passable(terrain):
				continue  # 地形阻挡
			
			# 计算移动消耗
			var move_cost = terrain_node.terrain_system.get_move_cost(terrain)
			var new_remaining = remaining - move_cost
			
			if new_remaining < 0:
				continue  # 移动消耗超过剩余移动力
			
			# 标记为已访问
			visited[pos_key] = true
			
			# 添加到范围和队列
			range.append({"x": new_x, "y": new_y, "cost": unit.stats.move - new_remaining})
			queue.append({"x": new_x, "y": new_y, "remaining": new_remaining})
	
	return range

# 计算攻击范围
func calculate_attack_range(unit: Dictionary) -> Array:
	var range = []
	var max_range = 0
	
	# 计算最大攻击范围
	for spell in unit.spells:
		if spell.range > max_range:
			max_range = spell.range
	
	# 只计算单位周围的格子，而不是整个地图
	var start_x = max(0, unit.x - max_range)
	var end_x = min(terrain_node.map_width - 1, unit.x + max_range)
	var start_y = max(0, unit.y - max_range)
	var end_y = min(terrain_node.map_height - 1, unit.y + max_range)
	
	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			var dist = abs(x - unit.x) + abs(y - unit.y)
			if dist <= max_range and dist > 0:
				range.append({"x": x, "y": y, "dist": dist})
	
	return range

# 移动单位
func move_unit(unit: Dictionary, x: int, y: int) -> void:
	# 从旧位置移除单位
	var old_pos_key = "%d,%d" % [unit.x, unit.y]
	if unit_positions.has(old_pos_key):
		unit_positions.erase(old_pos_key)
	
	unit.original_x = unit.x
	unit.original_y = unit.y
	unit.x = x
	unit.y = y
	unit.has_moved = true
	
	# 更新单位位置缓存
	unit_positions["%d,%d" % [x, y]] = unit
	
	# 更新单位节点位置
	if unit_nodes.has(unit.id):
		unit_nodes[unit.id].update_position()
	
	# 应用地形效果
	var effect_result = terrain_node.apply_terrain_effect(unit, x, y)
	if effect_result != "":
		print("%s %s" % [unit.name, effect_result])
		add_battle_log(unit.name, effect_result)
	
	print("%s 移动到 (%d, %d)" % [unit.name, x, y])
	add_battle_log(unit.name, "移动到 (%d, %d)" % [x, y])

# 显示魔法选择
func show_spell_selection(target_unit: Dictionary) -> void:
	if not selected_unit:
		return
	
	var unit = selected_unit
	var available_spells = []
	
	for spell in unit.spells:
		if unit.type == "holy":
			available_spells.append(spell)
		elif spell.mp_cost <= unit.mp:
			var dist = abs(target_unit.x - unit.x) + abs(target_unit.y - unit.y)
			if dist <= spell.range:
				available_spells.append(spell)
	
	if available_spells.size() == 0:
		print("没有可用的魔法")
		return
	
	# 在实际游戏中，这里应该使用GUI来显示魔法选择
	# 这里简化为控制台输入
	print("选择魔法:")
	for i in range(available_spells.size()):
		print("%d. %s (MP:%d 威力:%d)" % [i + 1, available_spells[i].name, available_spells[i].mp_cost, available_spells[i].power])
	
	# 假设用户选择第一个魔法
	cast_spell(unit, available_spells[0], target_unit)

# 魔法克制关系
var spell_relations = {
	"natural": {"holy": 0.8, "ancient": 1.2},  # 自然克制古代，被神圣克制
	"holy": {"ancient": 0.8, "natural": 1.2},  # 神圣克制自然，被古代克制
	"ancient": {"natural": 0.8, "holy": 1.2}  # 古代克制神圣，被自然克制
}

# 施放魔法
func cast_spell(caster: Dictionary, spell: Dictionary, target: Dictionary) -> void:
	if caster.type != "holy" and caster.mp < spell.mp_cost:
		print("MP不足！")
		add_battle_log(caster.name, "MP不足，无法施放 %s" % spell.name)
		return
	
	# 检查是否是治疗术
	if spell.target == "ally" and target.owner == "enemy":
		print("无法对敌人使用治疗魔法")
		add_battle_log(caster.name, "无法对敌人使用治疗魔法")
		return
	
	if caster.type != "holy":
		caster.mp -= spell.mp_cost
	
	# 检查咏唱时间
	if spell.has("cast_time"):
		caster.casting_spell = spell
		caster.cast_time_remaining = spell.cast_time
		caster.has_attacked = true
		print("%s 开始咏唱 %s，需要 %d 回合" % [caster.name, spell.name, spell.cast_time])
		add_battle_log(caster.name, "开始咏唱 %s，需要 %d 回合" % [spell.name, spell.cast_time])
		# 更新施法者节点
		if unit_nodes.has(caster.id):
			unit_nodes[caster.id].update_status()
		return
	
	caster.has_attacked = true
	
	if spell.target == "ally":
		# 治疗魔法
		var heal_amount = abs(spell.power)
		target.current_hp = min(target.max_hp, target.current_hp + heal_amount)
		print("%s 对 %s 使用 %s，恢复 %d 生命值" % [caster.name, target.name, spell.name, heal_amount])
		add_battle_log(caster.name, "对 %s 使用 %s，恢复 %d 生命值" % [target.name, spell.name, heal_amount])
		
		if spell.effect == "解除debuff":
			target.status_effects = []
			print("%s 的负面状态被清除" % target.name)
			add_battle_log(caster.name, "清除了 %s 的负面状态" % target.name)
		
		# 更新目标节点
		if unit_nodes.has(target.id):
			unit_nodes[target.id].update_status()
	else:
		# 攻击魔法
		var terrain = terrain_node.get_terrain_at(target.x, target.y)
		var def_bonus = terrain_node.terrain_system.get_def_bonus(terrain)
		
		# 计算命中/回避
		if calculate_hit(caster, target):
			# 计算魔法克制关系
			var damage = max(1, spell.power + caster.stats.mag - target.stats.def - def_bonus)
			var multiplier = 1.0
			if target.type != "physical" and spell_relations.has(caster.type) and spell_relations[caster.type].has(target.type):
				multiplier = spell_relations[caster.type][target.type]
				damage = int(damage * multiplier)
				if multiplier > 1:
					print("克制效果！伤害提升！")
					add_battle_log("系统", "克制效果！伤害提升！")
				elif multiplier < 1:
					print("抵抗效果！伤害降低！")
					add_battle_log("系统", "抵抗效果！伤害降低！")
			
			target.current_hp -= damage
			print("%s 对 %s 使用 %s，造成 %d 伤害" % [caster.name, target.name, spell.name, damage])
			add_battle_log(caster.name, "对 %s 使用 %s，造成 %d 伤害" % [target.name, spell.name, damage])
			
			# 应用状态效果
			if spell.has("effect"):
				apply_status_effect(target, spell.effect)
			
			# 地形改变
			if spell.has("terrain_change"):
				terrain_node.change_terrain(target.x, target.y, spell.terrain_change)
				add_battle_log(caster.name, "改变了地形为 %s" % spell.terrain_change)
			
			# 更新目标节点
			if unit_nodes.has(target.id):
				unit_nodes[target.id].update_status()
			
			# 检查死亡
			if target.current_hp <= 0:
				unit_death(target)
		else:
			print("%s 对 %s 使用 %s，但是被回避了！" % [caster.name, target.name, spell.name])
			add_battle_log(caster.name, "对 %s 使用 %s，但是被回避了！" % [target.name, spell.name])

# 施放地形改变魔法
func cast_terrain_change(caster: Dictionary, spell: Dictionary, x: int, y: int) -> void:
	if caster.type != "holy" and caster.mp < spell.mp_cost:
		print("MP不足！")
		return
	
	if spell.has("cast_time"):
		caster.casting_spell = spell
		caster.cast_time_remaining = spell.cast_time
		caster.has_attacked = true
		print("%s 开始咏唱 %s，需要 %d 回合" % [caster.name, spell.name, spell.cast_time])
		# 更新施法者节点
		if unit_nodes.has(caster.id):
			unit_nodes[caster.id].update_status()
		return
	
	if caster.type != "holy":
		caster.mp -= spell.mp_cost
	
	caster.has_attacked = true
	terrain_node.change_terrain(x, y, spell.terrain_change)
	
	# 如果有目标单位，也造成伤害
	var target = get_unit_at(x, y)
	if target:
		var terrain = terrain_node.get_terrain_at(x, y)
		var def_bonus = terrain_node.terrain_system.get_def_bonus(terrain)
		
		# 计算魔法克制关系
		var damage = max(1, spell.power + caster.stats.mag - target.stats.def - def_bonus)
		if target.type != "physical" and spell_relations.has(caster.type) and spell_relations[caster.type].has(target.type):
			var multiplier = spell_relations[caster.type][target.type]
			damage = int(damage * multiplier)
			if multiplier > 1:
				print("克制效果！伤害提升！")
			elif multiplier < 1:
				print("抵抗效果！伤害降低！")
		
		target.current_hp -= damage
		print("%s 对 %s 造成 %d 伤害" % [caster.name, target.name, damage])
		
		# 更新目标节点
		if unit_nodes.has(target.id):
			unit_nodes[target.id].update_status()
		
		if target.current_hp <= 0:
			unit_death(target)

# 单位死亡
func unit_death(unit: Dictionary) -> void:
	print("%s 阵亡！(永久死亡)" % unit.name)
	add_battle_log("系统", "%s 阵亡！(永久死亡)" % unit.name)
	
	# 从位置缓存中移除单位
	var pos_key = "%d,%d" % [unit.x, unit.y]
	if unit_positions.has(pos_key):
		unit_positions.erase(pos_key)
	
	# 移除单位节点
	if unit_nodes.has(unit.id):
		unit_nodes[unit.id].queue_free()
		unit_nodes.erase(unit.id)
	
	units.erase(unit)
	
	if selected_unit == unit:
		selected_unit = null
	
	# 检查游戏状态
	check_game_state()

# 结束回合
func end_turn() -> void:
	if game_state != "playing":
		return
	
	# 处理状态效果
	process_status_effects()
	
	# 处理咏唱
	process_casting()
	
	if current_player == "player":
		current_player = "enemy"
		print("--- 敌方回合开始 ---")
		add_battle_log("系统", "敌方回合开始")
		
		# 延迟执行敌方回合
		await get_tree().create_timer(1.0).timeout
		enemy_turn()
	else:
		current_player = "player"
		current_turn += 1
		print("--- 玩家回合开始 --- (回合: %d)" % current_turn)
		add_battle_log("系统", "玩家回合开始 (回合: %d)" % current_turn)
		
		# 重置玩家单位状态
		for unit in units:
			if unit.owner == "player":
				unit.has_moved = false
				unit.has_attacked = false
		
		# MP恢复
		for unit in units:
			if unit.owner == "player" and unit.type != "holy":
				unit.mp = min(unit.max_mp, unit.mp + 5)
				add_battle_log(unit.name, "MP恢复5点")
	
	selected_unit = null
	
	# 检查游戏状态
	check_game_state()

# 处理咏唱
func process_casting() -> void:
	# 处理所有单位正在进行的咏唱
	for unit in units:
		if unit.casting_spell:
			unit.cast_time_remaining -= 1
			
			if unit.cast_time_remaining <= 0:
				# 咏唱完成，释放魔法
				var spell = unit.casting_spell
				
				if spell.has("terrain_change"):
					# 对单位当前位置或目标位置施放
					terrain_node.change_terrain(unit.x, unit.y, spell.terrain_change)
					
					# 检查范围内是否有敌人
					var targets = []
					for u in units:
						if u.owner != unit.owner:
							var dist = abs(u.x - unit.x) + abs(u.y - unit.y)
							if dist <= spell.range:
								targets.append(u)
					
					if targets.size() > 0:
						var target = targets[0]
						
						# 计算魔法克制关系
						var damage = max(1, spell.power + unit.stats.mag - target.stats.def)
						if target.type != "physical" and spell_relations.has(unit.type) and spell_relations[unit.type].has(target.type):
							var multiplier = spell_relations[unit.type][target.type]
							damage = int(damage * multiplier)
							if multiplier > 1:
								print("克制效果！伤害提升！")
							elif multiplier < 1:
								print("抵抗效果！伤害降低！")
						
						target.current_hp -= damage
						print("%s 咏唱完成！%s 对 %s 造成 %d 伤害" % [unit.name, spell.name, target.name, damage])
						
						# 更新目标节点
						if unit_nodes.has(target.id):
							unit_nodes[target.id].update_status()
						
						if target.current_hp <= 0:
							unit_death(target)
					else:
						print("%s 咏唱完成！%s 施放成功" % [unit.name, spell.name])
				
				unit.casting_spell = null
				unit.cast_time_remaining = 0
				# 更新施法者节点
				if unit_nodes.has(unit.id):
					unit_nodes[unit.id].update_status()
			else:
				print("%s 继续咏唱 %s (剩余 %d 回合)" % [unit.name, unit.casting_spell.name, unit.cast_time_remaining])

# 敌方回合
func enemy_turn() -> void:
	var enemy_units = units.filter(func(u): return u.owner == "enemy" and not u.has_attacked)
	
	if enemy_units.size() == 0:
		end_turn()
		return
	
	var unit = enemy_units[0]
	
	# 增强AI：选择最佳目标
	var target = select_best_target(unit)
	if not target:
		end_turn()
		return
	
	# 尝试攻击
	var spell = select_best_spell(unit, target)
	
	if spell:
		var dist = abs(target.x - unit.x) + abs(target.y - unit.y)
		if dist <= spell.range:
			# 在射程内，直接攻击
			if unit.type != "holy":
				unit.mp -= spell.mp_cost
			
			# 计算魔法克制关系
			var terrain = terrain_node.get_terrain_at(target.x, target.y)
			var def_bonus = terrain_node.terrain_system.get_def_bonus(terrain)
			var damage = max(1, spell.power + unit.stats.mag - target.stats.def - def_bonus)
			if target.type != "physical" and spell_relations.has(unit.type) and spell_relations[unit.type].has(target.type):
				var multiplier = spell_relations[unit.type][target.type]
				damage = int(damage * multiplier)
				if multiplier > 1:
					print("克制效果！伤害提升！")
					add_battle_log("系统", "克制效果！伤害提升！")
				elif multiplier < 1:
					print("抵抗效果！伤害降低！")
					add_battle_log("系统", "抵抗效果！伤害降低！")
			target.current_hp -= damage
			print("%s 对 %s 使用 %s，造成 %d 伤害" % [unit.name, target.name, spell.name, damage])
			add_battle_log(unit.name, "对 %s 使用 %s，造成 %d 伤害" % [target.name, spell.name, damage])
			
			if spell.has("terrain_change"):
				terrain_node.change_terrain(target.x, target.y, spell.terrain_change)
				add_battle_log(unit.name, "改变了地形为 %s" % spell.terrain_change)
			
			# 更新目标节点
			if unit_nodes.has(target.id):
				unit_nodes[target.id].update_status()
			
			if target.current_hp <= 0:
				unit_death(target)
			
			unit.has_attacked = true
			
			# 延迟执行下一单位
			await get_tree().create_timer(0.5).timeout
			enemy_turn()
			return
	
	# 移动靠近目标
	var move_range = calculate_move_range(unit)
	if move_range.size() > 0:
		var best_move = find_best_move(unit, target, move_range)
		unit.x = best_move.x
		unit.y = best_move.y
		unit.has_moved = true
		print("%s 移动到 (%d, %d)" % [unit.name, unit.x, unit.y])
		add_battle_log(unit.name, "移动到 (%d, %d)" % [unit.x, unit.y])
		
		# 更新单位节点位置
		if unit_nodes.has(unit.id):
			unit_nodes[unit.id].update_position()
	
	# 延迟执行下一单位
	await get_tree().create_timer(0.5).timeout
	enemy_turn()

# 选择最佳目标
func select_best_target(unit: Dictionary) -> Dictionary:
	var player_units = units.filter(func(u): return u.owner == "player")
	if player_units.size() == 0:
		return {}
	
	var best_target = null
	var highest_priority = -1
	
	for target in player_units:
		var priority = calculate_target_priority(unit, target)
		if priority > highest_priority:
			highest_priority = priority
			best_target = target
	
	return best_target

# 计算目标优先级
func calculate_target_priority(unit: Dictionary, target: Dictionary) -> float:
	var priority = 0.0
	
	# 距离优先级（越近优先级越高）
	var dist = abs(target.x - unit.x) + abs(target.y - unit.y)
	priority += max(10 - dist, 0) * 0.3
	
	# 生命值优先级（生命值越低优先级越高）
	var health_percent = float(target.current_hp) / float(target.max_hp)
	priority += (1.0 - health_percent) * 0.3
	
	# 类型克制优先级
	if target.type != "physical" and spell_relations.has(unit.type) and spell_relations[unit.type].has(target.type):
		var multiplier = spell_relations[unit.type][target.type]
		if multiplier > 1:
			priority += 2.0  # 克制关系
	
	# 单位类型优先级
	match target.type:
		"ancient":
			priority += 1.5  # 优先攻击古代法师（高伤害）
		"natural":
			priority += 1.0  # 其次攻击自然法师
		"holy":
			priority += 0.8  # 然后攻击神官
		"physical":
			priority += 0.5  # 最后攻击物理单位
	
	return priority

# 选择最佳魔法
func select_best_spell(unit: Dictionary, target: Dictionary) -> Dictionary:
	var best_spell = null
	var highest_score = -1
	
	for spell in unit.spells:
		# 检查MP是否足够
		if unit.type != "holy" and unit.mp < spell.mp_cost:
			continue
		
		# 检查射程
		var dist = abs(target.x - unit.x) + abs(target.y - unit.y)
		if dist > spell.range:
			continue
		
		# 检查目标类型
		if spell.target == "ally" and target.owner != unit.owner:
			continue
		if spell.target == "enemy" and target.owner == unit.owner:
			continue
		
		# 计算魔法得分
		var score = calculate_spell_score(unit, spell, target)
		if score > highest_score:
			highest_score = score
			best_spell = spell
	
	return best_spell

# 计算魔法得分
func calculate_spell_score(unit: Dictionary, spell: Dictionary, target: Dictionary) -> float:
	var score = 0.0
	
	# 基础伤害得分
	if spell.target == "enemy":
		score += spell.power
	elif spell.target == "ally":
		score += abs(spell.power)
	
	# 魔法克制加成
	if target.type != "physical" and spell_relations.has(unit.type) and spell_relations[unit.type].has(target.type):
		var multiplier = spell_relations[unit.type][target.type]
		score *= multiplier
	
	# 地形效果加成
	if spell.has("terrain_change"):
		score += 0.5
	
	# MP效率
	if unit.type != "holy":
		score /= max(1, spell.mp_cost)
	
	return score

# 寻找最佳移动位置
func find_best_move(unit: Dictionary, target: Dictionary, move_range: Array) -> Dictionary:
	var best_move = move_range[0]
	var highest_score = -1
	
	for pos in move_range:
		var score = calculate_move_score(unit, target, pos)
		if score > highest_score:
			highest_score = score
			best_move = pos
	
	return best_move

# 计算移动位置得分
func calculate_move_score(unit: Dictionary, target: Dictionary, pos: Dictionary) -> float:
	var score = 0.0
	
	# 距离目标的距离（越近得分越高）
	var dist = abs(target.x - pos.x) + abs(target.y - pos.y)
	score += max(10 - dist, 0)
	
	# 地形优势
	var terrain = terrain_node.get_terrain_at(pos.x, pos.y)
	var def_bonus = terrain_node.terrain_system.get_def_bonus(terrain)
	score += def_bonus * 2
	
	# 避免危险地形
	if terrain.has("effect"):
		score -= 2
	
	return score

# 获取指定位置的单位
func get_unit_at(x: int, y: int) -> Dictionary:
	return unit_positions.get("%d,%d" % [x, y], null)

# 选择单位
func select_unit(unit: Dictionary) -> void:
	selected_unit = unit
	
	# 检查是否正在咏唱
	if unit.casting_spell:
		print("%s 正在咏唱 %s (剩余 %d 回合)" % [unit.name, unit.casting_spell.name, unit.cast_time_remaining])

# 开始移动模式
func start_move_mode() -> void:
	if not selected_unit or selected_unit.owner != "player" or selected_unit.has_moved:
		print("无法移动：未选择单位或单位已行动")
		return
	
	move_mode = true
	attack_mode = false
	move_range = calculate_move_range(selected_unit)
	print("显示 %s 的移动范围" % selected_unit.name)

# 开始攻击模式
func start_attack_mode() -> void:
	if not selected_unit or selected_unit.owner != "player" or selected_unit.has_attacked:
		print("无法攻击：未选择单位或单位已攻击")
		return
	
	if selected_unit.casting_spell:
		print("%s 正在咏唱中，无法攻击" % selected_unit.name)
		return
	
	attack_mode = true
	move_mode = false
	attack_range = calculate_attack_range(selected_unit)
	print("显示 %s 的攻击范围" % selected_unit.name)

# 单位待机
func unit_wait() -> void:
	if not selected_unit or selected_unit.owner != "player":
		return
	
	selected_unit.has_moved = true
	selected_unit.has_attacked = true
	print("%s 选择待机" % selected_unit.name)
	selected_unit = null

# 单位点击事件
func _on_unit_clicked(unit: Dictionary) -> void:
	if current_player != "player":
		return
	
	# 取消之前的选择
	if selected_unit and unit_nodes.has(selected_unit.id):
		unit_nodes[selected_unit.id].set_selected(false)
	
	# 选择新单位
	selected_unit = unit
	unit_nodes[unit.id].set_selected(true)
	select_unit(unit)

# 切换地图模式
func switch_map_mode() -> void:
	current_map_mode = "indoor" if current_map_mode == "outdoor" else "outdoor"
	print("切换到%s地图模式" % ("室内" if current_map_mode == "indoor" else "室外"))
	add_battle_log("系统", "切换到%s地图模式" % ("室内" if current_map_mode == "indoor" else "室外"))
	
	# 清空现有单位
	for unit in units:
		if unit_nodes.has(unit.id):
			unit_nodes[unit.id].queue_free()
	units.clear()
	unit_nodes.clear()
	unit_positions.clear()
	
	# 重新生成地形
	terrain_node.map_type = current_map_mode
	terrain_node.generate_terrain()
	terrain_node.create_terrain_visuals()
	
	# 重新创建单位
	create_units()
	
	# 重置游戏状态
	current_turn = 1
	current_player = "player"
	selected_unit = null
	move_mode = false
	attack_mode = false
	move_range = []
	attack_range = []
	
	# 清空战斗日志
	battle_log.clear()
	add_battle_log("系统", "游戏重新开始！")

# 添加战斗日志
func add_battle_log(sender: String, message: String) -> void:
	var log_entry = {
		"sender": sender,
		"message": message,
		"turn": current_turn,
		"time": Time.get_datetime_dict_from_system()
	}
	
	battle_log.append(log_entry)
	
	# 限制日志条目数量
	if battle_log.size() > max_log_entries:
		battle_log.pop_front()
	
	# 打印日志
	print("[%s] %s: %s" % [sender, str(current_turn), message])
	
	# 更新UI
	if ui_root:
		update_ui()

# 显示战斗日志
func show_battle_log() -> void:
	print("===== 战斗日志 =====")
	for log in battle_log:
		print("[%s] 回合 %d: %s" % [log.sender, log.turn, log.message])
	print("===================")

# 清空战斗日志
func clear_battle_log() -> void:
	battle_log.clear()
	add_battle_log("系统", "战斗日志已清空")

# 计算命中/回避
func calculate_hit(caster: Dictionary, target: Dictionary) -> bool:
	# 基础命中率
	var base_hit = 90
	
	# 速度差影响命中率
	var speed_diff = target.stats.spd - caster.stats.spd
	var hit_modifier = speed_diff * 2
	
	# 最终命中率
	var final_hit = base_hit - hit_modifier
	final_hit = clamp(final_hit, 5, 95)  # 最低5%命中，最高95%命中
	
	# 随机判定
	var rand = randf_range(0, 100)
	return rand < final_hit

# 应用状态效果
func apply_status_effect(unit: Dictionary, effect: String) -> void:
	match effect:
		"燃烧":
			# 燃烧效果：每回合造成持续伤害
			var burn_effect = {"name": "burn", "duration": 3, "damage": 2}
			unit.status_effects.append(burn_effect)
			print("%s 被燃烧了！" % unit.name)
			add_battle_log("系统", "%s 被燃烧了！" % unit.name)
		"减速":
			# 减速效果：降低移动速度
			var slow_effect = {"name": "slow", "duration": 2, "move_penalty": 1}
			unit.status_effects.append(slow_effect)
			unit.stats.move = max(1, unit.stats.move - 1)
			print("%s 被减速了！" % unit.name)
			add_battle_log("系统", "%s 被减速了！" % unit.name)
		"解除debuff":
			# 解除所有负面状态
			unit.status_effects = []
			print("%s 的负面状态被清除" % unit.name)
			add_battle_log("系统", "%s 的负面状态被清除" % unit.name)

# 处理状态效果
func process_status_effects() -> void:
	for unit in units:
		if unit.status_effects.size() > 0:
			var effects_to_remove = []
			
			for effect in unit.status_effects:
				effect.duration -= 1
				
				match effect.name:
					"burn":
						# 燃烧伤害
						unit.current_hp = max(1, unit.current_hp - effect.damage)
						print("%s 燃烧造成 %d 点伤害" % [unit.name, effect.damage])
						add_battle_log("系统", "%s 燃烧造成 %d 点伤害" % [unit.name, effect.damage])
						
						# 检查死亡
						if unit.current_hp <= 0:
							unit_death(unit)
							break
					
				if effect.duration <= 0:
					# 效果结束
					if effect.name == "slow":
						# 恢复移动速度
						unit.stats.move += effect.move_penalty
						print("%s 的减速效果解除了" % unit.name)
						add_battle_log("系统", "%s 的减速效果解除了" % unit.name)
					effects_to_remove.append(effect)
				
			# 移除过期效果
			for effect in effects_to_remove:
				unit.status_effects.erase(effect)

# 检查游戏状态
func check_game_state() -> void:
	if game_state != "playing":
		return
	
	# 检查玩家是否全部阵亡
	var player_units = units.filter(func(u): return u.owner == "player")
	if player_units.size() == 0:
		game_over()
		return
	
	# 检查敌人是否全部阵亡
	var enemy_units = units.filter(func(u): return u.owner == "enemy")
	if enemy_units.size() == 0:
		victory()
		return

# 游戏结束
func game_over() -> void:
	game_state = "game_over"
	print("游戏结束！玩家失败！")
	add_battle_log("系统", "游戏结束！玩家失败！")

# 游戏胜利
func victory() -> void:
	game_state = "victory"
	print("游戏胜利！玩家成功击败所有敌人！")
	add_battle_log("系统", "游戏胜利！玩家成功击败所有敌人！")

# 暂停游戏
func pause_game() -> void:
	if game_state == "playing":
		game_state = "paused"
		print("游戏已暂停")
		add_battle_log("系统", "游戏已暂停")

# 继续游戏
func resume_game() -> void:
	if game_state == "paused":
		game_state = "playing"
		print("游戏继续")
		add_battle_log("系统", "游戏继续")

# 重启游戏
func restart_game() -> void:
	print("游戏重启")
	add_battle_log("系统", "游戏重启")
	
	# 清空现有单位
	for unit in units:
		if unit_nodes.has(unit.id):
			unit_nodes[unit.id].queue_free()
	units.clear()
	unit_nodes.clear()
	unit_positions.clear()
	
	# 重新生成地形
	terrain_node.generate_terrain()
	terrain_node.create_terrain_visuals()
	
	# 重新创建单位
	create_units()
	
	# 重置游戏状态
	current_turn = 1
	current_player = "player"
	selected_unit = null
	move_mode = false
	attack_mode = false
	move_range = []
	attack_range = []
	game_state = "playing"
	
	# 清空战斗日志
	battle_log.clear()
	add_battle_log("系统", "游戏重新开始！")
	
	# 更新UI
	update_ui()

# 创建UI
func create_ui() -> void:
	# 创建UI根节点
	ui_root = CanvasLayer.new()
	add_child(ui_root)
	
	# 创建背景面板
	var background_panel = ColorRect.new()
	background_panel.rect_position = Vector2(0, 0)
	background_panel.rect_size = Vector2(320, 768)
	background_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	ui_root.add_child(background_panel)
	
	# 创建渐变背景
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.1, 0.1, 0.2))
	gradient.add_point(1.0, Color(0.2, 0.1, 0.3))
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1
	gradient_texture.height = 768
	var gradient_bg = TextureRect.new()
	gradient_bg.rect_position = Vector2(0, 0)
	gradient_bg.rect_size = Vector2(320, 768)
	gradient_bg.texture = gradient_texture
	ui_root.add_child(gradient_bg)
	
	# 创建游戏状态标签
	status_label = Label.new()
	status_label.rect_position = Vector2(10, 10)
	status_label.rect_size = Vector2(300, 30)
	status_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	ui_root.add_child(status_label)
	
	# 创建单位信息面板
	var unit_info_panel = ColorRect.new()
	unit_info_panel.rect_position = Vector2(10, 50)
	unit_info_panel.rect_size = Vector2(300, 150)
	unit_info_panel.color = Color(0.2, 0.2, 0.2, 0.8)
	unit_info_panel.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var stylebox = unit_info_panel.get_theme_stylebox("normal")
	if stylebox:
		stylebox.set_border_width_all(1)
		stylebox.set_border_color(Color(0.4, 0.4, 0.4))
	ui_root.add_child(unit_info_panel)
	
	# 单位名称
	unit_name_label = Label.new()
	unit_name_label.rect_position = Vector2(20, 60)
	unit_name_label.rect_size = Vector2(280, 20)
	unit_name_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	unit_name_label.add_theme_font_size_override("font_size", 16)
	unit_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	unit_name_label.text = "未选择单位"
	ui_root.add_child(unit_name_label)
	
	# 单位生命值
	unit_hp_label = Label.new()
	unit_hp_label.rect_position = Vector2(20, 85)
	unit_hp_label.rect_size = Vector2(280, 20)
	unit_hp_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	unit_hp_label.add_theme_font_size_override("font_size", 14)
	unit_hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	unit_hp_label.text = "生命值: 0/0"
	ui_root.add_child(unit_hp_label)
	
	# 单位MP
	unit_mp_label = Label.new()
	unit_mp_label.rect_position = Vector2(20, 105)
	unit_mp_label.rect_size = Vector2(280, 20)
	unit_mp_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	unit_mp_label.add_theme_font_size_override("font_size", 14)
	unit_mp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	unit_mp_label.text = "MP: 0/0"
	ui_root.add_child(unit_mp_label)
	
	# 单位状态
	unit_status_label = Label.new()
	unit_status_label.rect_position = Vector2(20, 125)
	unit_status_label.rect_size = Vector2(280, 20)
	unit_status_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	unit_status_label.add_theme_font_size_override("font_size", 14)
	unit_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	unit_status_label.text = "状态: 正常"
	ui_root.add_child(unit_status_label)
	
	# 单位属性
	unit_stats_label = Label.new()
	unit_stats_label.rect_position = Vector2(20, 145)
	unit_stats_label.rect_size = Vector2(280, 20)
	unit_stats_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	unit_stats_label.add_theme_font_size_override("font_size", 14)
	unit_stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	unit_stats_label.text = "攻击力: 0 | 防御力: 0 | 魔法: 0 | 速度: 0"
	ui_root.add_child(unit_stats_label)
	
	# 创建魔法详情面板
	var spell_panel = ColorRect.new()
	spell_panel.rect_position = Vector2(10, 210)
	spell_panel.rect_size = Vector2(300, 180)
	spell_panel.color = Color(0.2, 0.2, 0.2, 0.8)
	spell_panel.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	stylebox = spell_panel.get_theme_stylebox("normal")
	if stylebox:
		stylebox.set_border_width_all(1)
		stylebox.set_border_color(Color(0.4, 0.4, 0.4))
	ui_root.add_child(spell_panel)
	
	# 魔法标题
	var spell_title_label = Label.new()
	spell_title_label.rect_position = Vector2(20, 220)
	spell_title_label.rect_size = Vector2(280, 20)
	spell_title_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	spell_title_label.add_theme_font_size_override("font_size", 14)
	spell_title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	spell_title_label.text = "可用魔法"
	ui_root.add_child(spell_title_label)
	
	# 魔法列表
	spell_list = VBoxContainer.new()
	spell_list.rect_position = Vector2(20, 240)
	spell_list.rect_size = Vector2(280, 150)
	ui_root.add_child(spell_list)
	
	# 创建战斗日志面板
	var log_panel = ColorRect.new()
	log_panel.rect_position = Vector2(10, 400)
	log_panel.rect_size = Vector2(300, 200)
	log_panel.color = Color(0.2, 0.2, 0.2, 0.8)
	log_panel.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	stylebox = log_panel.get_theme_stylebox("normal")
	if stylebox:
		stylebox.set_border_width_all(1)
		stylebox.set_border_color(Color(0.4, 0.4, 0.4))
	ui_root.add_child(log_panel)
	
	# 战斗日志标题
	var log_title_label = Label.new()
	log_title_label.rect_position = Vector2(20, 410)
	log_title_label.rect_size = Vector2(280, 20)
	log_title_label.add_theme_font_override("font", load("res://default_env.tres").default_font)
	log_title_label.add_theme_font_size_override("font_size", 14)
	log_title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	log_title_label.text = "战斗日志"
	ui_root.add_child(log_title_label)
	
	# 战斗日志文本框
	battle_log_text = TextEdit.new()
	battle_log_text.rect_position = Vector2(20, 430)
	battle_log_text.rect_size = Vector2(280, 160)
	battle_log_text.set_readonly(true)
	battle_log_text.add_theme_font_override("font", load("res://default_env.tres").default_font)
	battle_log_text.add_theme_font_size_override("font_size", 12)
	battle_log_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	battle_log_text.add_theme_color_override("bg_color", Color(0.1, 0.1, 0.1))
	ui_root.add_child(battle_log_text)
	
	# 创建操作按钮面板
	var button_panel = ColorRect.new()
	button_panel.rect_position = Vector2(10, 610)
	button_panel.rect_size = Vector2(300, 140)
	button_panel.color = Color(0.2, 0.2, 0.2, 0.8)
	button_panel.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	stylebox = button_panel.get_theme_stylebox("normal")
	if stylebox:
		stylebox.set_border_width_all(1)
		stylebox.set_border_color(Color(0.4, 0.4, 0.4))
	ui_root.add_child(button_panel)
	
	# 创建移动按钮
	move_button = Button.new()
	move_button.rect_position = Vector2(20, 620)
	move_button.rect_size = Vector2(80, 30)
	move_button.text = "移动"
	move_button.pressed.connect(_on_move_button_pressed)
	move_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	move_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var button_style = move_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.3, 0.3, 0.5))
	ui_root.add_child(move_button)
	
	# 创建攻击按钮
	attack_button = Button.new()
	attack_button.rect_position = Vector2(110, 620)
	attack_button.rect_size = Vector2(80, 30)
	attack_button.text = "攻击"
	attack_button.pressed.connect(_on_attack_button_pressed)
	attack_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	attack_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = attack_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.5, 0.3, 0.3))
	ui_root.add_child(attack_button)
	
	# 创建待机按钮
	wait_button = Button.new()
	wait_button.rect_position = Vector2(200, 620)
	wait_button.rect_size = Vector2(80, 30)
	wait_button.text = "待机"
	wait_button.pressed.connect(_on_wait_button_pressed)
	wait_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	wait_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = wait_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.3, 0.5, 0.3))
	ui_root.add_child(wait_button)
	
	# 创建结束回合按钮
	end_turn_button = Button.new()
	end_turn_button.rect_position = Vector2(20, 660)
	end_turn_button.rect_size = Vector2(80, 30)
	end_turn_button.text = "结束回合"
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	end_turn_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	end_turn_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = end_turn_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.5, 0.5, 0.3))
	ui_root.add_child(end_turn_button)
	
	# 创建切换地图按钮
	switch_map_button = Button.new()
	switch_map_button.rect_position = Vector2(110, 660)
	switch_map_button.rect_size = Vector2(80, 30)
	switch_map_button.text = "切换地图"
	switch_map_button.pressed.connect(_on_switch_map_button_pressed)
	switch_map_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	switch_map_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = switch_map_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.3, 0.5, 0.5))
	ui_root.add_child(switch_map_button)
	
	# 创建重启游戏按钮
	restart_button = Button.new()
	restart_button.rect_position = Vector2(200, 660)
	restart_button.rect_size = Vector2(80, 30)
	restart_button.text = "重启游戏"
	restart_button.pressed.connect(_on_restart_button_pressed)
	restart_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	restart_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = restart_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.5, 0.3, 0.5))
	ui_root.add_child(restart_button)
	
	# 创建技能树编辑器按钮
	var skill_editor_button = Button.new()
	skill_editor_button.rect_position = Vector2(20, 700)
	skill_editor_button.rect_size = Vector2(125, 30)
	skill_editor_button.text = "技能树编辑器"
	skill_editor_button.pressed.connect(open_skill_editor)
	skill_editor_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	skill_editor_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = skill_editor_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.5, 0.3, 0.5))
	ui_root.add_child(skill_editor_button)
	
	# 创建暂停按钮
	pause_button = Button.new()
	pause_button.rect_position = Vector2(155, 700)
	pause_button.rect_size = Vector2(125, 30)
	pause_button.text = "暂停游戏"
	pause_button.pressed.connect(_on_pause_button_pressed)
	pause_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	pause_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	button_style = pause_button.get_theme_stylebox("normal")
	if button_style:
		button_style.set_bg_color(Color(0.4, 0.4, 0.4))
	ui_root.add_child(pause_button)
	
	# 添加动画效果
	var animation_player = AnimationPlayer.new()
	ui_root.add_child(animation_player)
	
	# 创建面板淡入动画
	var fade_in = Animation.new()
	fade_in.length = 0.5
	fade_in.track_insert_key(0, 0.0, 0.0)
	fade_in.track_insert_key(0, 0.5, 1.0)
	fade_in.track_set_path(0, "gradient_bg:modulate:a")
	animation_player.add_animation("fade_in", fade_in)
	
	# 播放动画
	animation_player.play("fade_in")
	
	# 更新UI
	update_ui()

# 更新UI
func update_ui() -> void:
	# 更新游戏状态标签
	var game_state_text
	match game_state:
		"playing":
			game_state_text = "游戏中"
		"paused":
			game_state_text = "已暂停"
		"game_over":
			game_state_text = "游戏结束"
		"victory":
			game_state_text = "游戏胜利"
		_:
			game_state_text = "未知"
	var status_text = "回合: %d | 当前玩家: %s | 地图: %s | 状态: %s" % [
		current_turn, 
		"玩家" if current_player == "player" else "敌方",
		"室外" if current_map_mode == "outdoor" else "室内",
		game_state_text
	]
	if status_label.text != status_text:
		status_label.text = status_text
	
	# 更新单位信息
	if selected_unit:
		# 只在单位名称变化时更新
		if unit_name_label.text != selected_unit.name:
			unit_name_label.text = selected_unit.name
		
		# 只在生命值变化时更新
		var hp_text = "生命值: %d/%d" % [selected_unit.current_hp, selected_unit.max_hp]
		if unit_hp_label.text != hp_text:
			unit_hp_label.text = hp_text
		
		# 只在MP变化时更新
		var mp_text = "MP: %d/%d" % [selected_unit.mp, selected_unit.max_mp]
		if unit_mp_label.text != mp_text:
			unit_mp_label.text = mp_text
		
		# 只在状态效果变化时更新
		var unit_status_text = "状态: 正常"
		if selected_unit.status_effects.size() > 0:
			unit_status_text = "状态: "
			for effect in selected_unit.status_effects:
				unit_status_text += effect.name + "(" + str(effect.duration) + "), "
			unit_status_text = unit_status_text.rstrip(", ")
		if unit_status_label.text != unit_status_text:
			unit_status_label.text = unit_status_text
		
		# 只在属性变化时更新
		var stats_text = "攻击力: %d | 防御力: %d | 魔法: %d | 速度: %d" % [
			selected_unit.stats.atk, 
			selected_unit.stats.def, 
			selected_unit.stats.mag, 
			selected_unit.stats.spd
		]
		if unit_stats_label.text != stats_text:
			unit_stats_label.text = stats_text
		
		# 更新魔法列表
		update_spell_list()
	else:
		# 只在需要时更新空状态
		if unit_name_label.text != "未选择单位":
			unit_name_label.text = "未选择单位"
		if unit_hp_label.text != "生命值: 0/0":
			unit_hp_label.text = "生命值: 0/0"
		if unit_mp_label.text != "MP: 0/0":
			unit_mp_label.text = "MP: 0/0"
		if unit_status_label.text != "状态: 正常":
			unit_status_label.text = "状态: 正常"
		if unit_stats_label.text != "攻击力: 0 | 防御力: 0 | 魔法: 0 | 速度: 0":
			unit_stats_label.text = "攻击力: 0 | 防御力: 0 | 魔法: 0 | 速度: 0"
		
		# 清空魔法列表
		clear_spell_list()
	
	# 更新战斗日志
	var log_text = ""
	for log in battle_log:
		log_text += "[%s] 回合 %d: %s\n" % [log.sender, log.turn, log.message]
	if battle_log_text.text != log_text:
		battle_log_text.text = log_text
		battle_log_text.scroll_to_line(battle_log.size())

# 更新魔法列表
func update_spell_list() -> void:
	if not selected_unit:
		return
	
	# 检查是否需要更新魔法列表
	var existing_buttons = spell_list.get_children()
	var spell_count = selected_unit.spells.size()
	
	# 如果魔法数量变化，或者没有按钮，重新创建
	if existing_buttons.size() != spell_count:
		clear_spell_list()
		
		# 添加魔法按钮
		for spell in selected_unit.spells:
			var spell_button = Button.new()
			spell_button.text = "%s (MP:%d, 范围:%d)" % [spell.name, spell.mp_cost, spell.range]
			spell_button.pressed.connect(_on_spell_button_pressed.bind(spell))
			spell_button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			spell_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
			var button_style = spell_button.get_theme_stylebox("normal")
			if button_style:
				button_style.set_bg_color(Color(0.3, 0.3, 0.4))
			
			# 检查MP是否足够
			if selected_unit.type != "holy" and selected_unit.mp < spell.mp_cost:
				spell_button.disabled = true
				spell_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			
			spell_list.add_child(spell_button)
	else:
		# 只更新现有按钮的状态
		for i in range(spell_count):
			var spell = selected_unit.spells[i]
			var button = existing_buttons[i]
			
			# 检查MP是否足够
			var is_disabled = selected_unit.type != "holy" and selected_unit.mp < spell.mp_cost
			if button.disabled != is_disabled:
				button.disabled = is_disabled
				if is_disabled:
					button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				else:
					button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

# 清空魔法列表
func clear_spell_list() -> void:
	for child in spell_list.get_children():
		child.queue_free()

# 移动按钮点击
func _on_move_button_pressed() -> void:
	start_move_mode()

# 攻击按钮点击
func _on_attack_button_pressed() -> void:
	start_attack_mode()

# 待机按钮点击
func _on_wait_button_pressed() -> void:
	unit_wait()

# 魔法按钮点击
func _on_spell_button_pressed(spell: Dictionary) -> void:
	if not selected_unit:
		return
	
	# 这里可以添加魔法使用逻辑
	print("选择了魔法: %s" % spell.name)

# 结束回合按钮点击
func _on_end_turn_button_pressed() -> void:
	end_turn()

# 切换地图按钮点击
func _on_switch_map_button_pressed() -> void:
	switch_map_mode()

# 重启游戏按钮点击
func _on_restart_button_pressed() -> void:
	restart_game()

# 暂停按钮点击
func _on_pause_button_pressed() -> void:
	if game_state == "playing":
		pause_game()
		pause_button.text = "继续游戏"
	elif game_state == "paused":
		resume_game()
		pause_button.text = "暂停游戏"

# 从编辑器加载地图
func load_map_from_editor(map_type: String, terrain_data: Array, units_data: Array) -> void:
	print("从编辑器加载地图...")
	
	# 更新地图模式
	current_map_mode = map_type
	
	# 清空现有单位
	for unit in units:
		if unit_nodes.has(unit.id):
			unit_nodes[unit.id].queue_free()
	units.clear()
	unit_nodes.clear()
	
	# 更新地形
	terrain_node.map_type = map_type
	terrain_node.terrain_grid = terrain_data
	terrain_node.create_terrain_visuals()
	
	# 加载单位
	for unit_data in units_data:
		var unit = create_unit(
			unit_data.owner,
			unit_data.x,
			unit_data.y,
			unit_data.name,
			unit_data.type,
			unit_data.stats,
			unit_data.spells
		)
		# 复制额外属性
		unit.current_hp = unit_data.current_hp
		unit.max_hp = unit_data.max_hp
		unit.mp = unit_data.mp
		unit.max_mp = unit_data.max_mp
	
	# 重置游戏状态
	current_turn = 1
	current_player = "player"
	selected_unit = null
	move_mode = false
	attack_mode = false
	move_range = []
	attack_range = []
	game_state = "playing"
	
	# 清空战斗日志
	battle_log.clear()
	add_battle_log("系统", "从编辑器加载地图成功！")
	
	# 更新UI
	update_ui()
	
	print("地图加载完成！")

# 打开地图编辑器
func _on_editor_button_pressed() -> void:
	print("打开地图编辑器...")
	
	# 加载地图编辑器场景
	var editor_scene = load("res://MapEditor.tscn")
	if editor_scene:
		var editor_instance = editor_scene.instantiate()
		add_child(editor_instance)
		print("地图编辑器已打开")
	else:
		print("无法加载地图编辑器场景！")

# 打开技能树编辑器
func open_skill_editor() -> void:
	print("打开技能树编辑器...")
	
	# 加载技能树编辑器场景
	var skill_editor_scene = load("res://SkillTreeEditor.tscn")
	if skill_editor_scene:
		var skill_editor_instance = skill_editor_scene.instantiate()
		add_child(skill_editor_instance)
		print("技能树编辑器已打开")
	else:
		print("无法加载技能树编辑器场景！")

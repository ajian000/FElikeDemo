# 技能树编辑器脚本
# 实现三大魔法体系技能树、节点管理工具、节点拖拽移动、双击编辑节点、节点属性编辑
# 可视化连接线、技能树保存和加载、技能树JSON导出、一键重置为默认

class_name SkillTreeEditor

# 编辑器属性
var current_system = "natural"
var current_tool = "select"
var selected_node = null
var connecting_node = null
var dragging_node = null
var drag_offset = Vector2.ZERO

# 技能树数据
var nodes = []
var connections = []

# 三大体系的技能树
var trees = {
	"natural": { "nodes": [], "connections": [] },
	"holy": { "nodes": [], "connections": [] },
	"ancient": { "nodes": [], "connections": [] }
}

# 节点引用
var skill_tree_layer = null
var current_system_label = null
var current_tool_label = null
var node_count_label = null
var properties_content = null

# 初始化
func _ready():
	# 获取节点引用
	skill_tree_layer = $VBoxContainer/MainContainer/EditorContainer/ViewportContainer/Viewport/SkillTreeLayer
	current_system_label = $VBoxContainer/MainContainer/EditorContainer/StatusBar/CurrentSystem
	current_tool_label = $VBoxContainer/MainContainer/EditorContainer/StatusBar/CurrentTool
	node_count_label = $VBoxContainer/MainContainer/EditorContainer/StatusBar/NodeCount
	properties_content = $VBoxContainer/MainContainer/ToolPanel/NodeProperties/PropertiesContent
	
	# 连接按钮信号
	$VBoxContainer/Header/CloseButton.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	# 体系选择按钮
	$VBoxContainer/MainContainer/ToolPanel/SystemSelector/SystemGrid/NaturalButton.connect("pressed", Callable(self, "select_system").bind("natural"))
	$VBoxContainer/MainContainer/ToolPanel/SystemSelector/SystemGrid/HolyButton.connect("pressed", Callable(self, "select_system").bind("holy"))
	$VBoxContainer/MainContainer/ToolPanel/SystemSelector/SystemGrid/AncientButton.connect("pressed", Callable(self, "select_system").bind("ancient"))
	
	# 工具按钮
	$VBoxContainer/MainContainer/ToolPanel/NodeTools/ToolsGrid/SelectButton.connect("pressed", Callable(self, "set_tool").bind("select"))
	$VBoxContainer/MainContainer/ToolPanel/NodeTools/ToolsGrid/AddButton.connect("pressed", Callable(self, "set_tool").bind("add"))
	$VBoxContainer/MainContainer/ToolPanel/NodeTools/ToolsGrid/DeleteButton.connect("pressed", Callable(self, "set_tool").bind("delete"))
	$VBoxContainer/MainContainer/ToolPanel/NodeTools/ToolsGrid/ConnectButton.connect("pressed", Callable(self, "set_tool").bind("connect"))
	
	# 连接操作按钮
	$VBoxContainer/MainContainer/ToolPanel/ConnectionActions/ConnectionGrid/CreateConnectionButton.connect("pressed", Callable(self, "add_bidirectional_connection"))
	$VBoxContainer/MainContainer/ToolPanel/ConnectionActions/ConnectionGrid/RemoveConnectionsButton.connect("pressed", Callable(self, "remove_connections"))
	
	# 技能树操作按钮
	$VBoxContainer/MainContainer/ToolPanel/TreeActions/ActionsGrid/SaveButton.connect("pressed", Callable(self, "save_tree"))
	$VBoxContainer/MainContainer/ToolPanel/TreeActions/ActionsGrid/LoadButton.connect("pressed", Callable(self, "load_tree"))
	$VBoxContainer/MainContainer/ToolPanel/TreeActions/ActionsGrid/ExportButton.connect("pressed", Callable(self, "export_tree"))
	$VBoxContainer/MainContainer/ToolPanel/TreeActions/ActionsGrid/ResetButton.connect("pressed", Callable(self, "reset_tree"))
	
	# 生成默认技能树
	generate_default_trees()
	
	# 尝试自动加载保存的技能树
	auto_load_saved_trees()
	
	# 加载初始体系
	load_system("natural")
	
	# 渲染技能树
	render()
	
	# 更新显示
	update_node_count()
	update_tool_display()
	update_system_display()

# 自动加载保存的技能树
func auto_load_saved_trees():
	var systems = ["natural", "holy", "ancient"]
	var loaded_count = 0
	
	for system in systems:
		var saved_data = _load_from_file("skill_tree_" + system + ".json")
		if saved_data:
			trees[system].nodes = saved_data.nodes
			trees[system].connections = saved_data.connections
			loaded_count += 1
	
	if loaded_count > 0:
		print("已自动加载 " + str(loaded_count) + " 个技能树")

# 生成默认技能树
func generate_default_trees():
	# 自然魔法体系 - 环形结构
	var center_x = 450
	var center_y = 350
	
	# 核心层 - 四元素基础魔法
	var core_nodes = [
		{ "id": "fire_base", "name": "火球术", "type": "basic", "element": "fire", "x": center_x, "y": center_y - 150, "cost": 1, "effect": "造成火焰伤害" },
		{ "id": "ice_base", "name": "冰锥术", "type": "basic", "element": "ice", "x": center_x + 150, "y": center_y - 50, "cost": 1, "effect": "造成冰冻伤害" },
		{ "id": "wind_base", "name": "风刃术", "type": "basic", "element": "wind", "x": center_x + 100, "y": center_y + 120, "cost": 1, "effect": "造成风刃伤害" },
		{ "id": "thunder_base", "name": "雷击术", "type": "basic", "element": "thunder", "x": center_x - 100, "y": center_y + 120, "cost": 1, "effect": "造成雷击伤害" }
	]
	
	# 内层 - 元素强化
	var inner_nodes = [
		{ "id": "fire_enhance", "name": "火焰精通", "type": "advanced", "element": "fire", "x": center_x - 80, "y": center_y - 120, "cost": 3, "effect": "提升火焰魔法伤害" },
		{ "id": "ice_enhance", "name": "冰霜精通", "type": "advanced", "element": "ice", "x": center_x + 120, "y": center_y - 100, "cost": 3, "effect": "提升冰冻魔法伤害" },
		{ "id": "wind_enhance", "name": "风暴精通", "type": "advanced", "element": "wind", "x": center_x + 80, "y": center_y + 80, "cost": 3, "effect": "提升风刃魔法伤害" },
		{ "id": "thunder_enhance", "name": "雷霆精通", "type": "advanced", "element": "thunder", "x": center_x - 120, "y": center_y + 80, "cost": 3, "effect": "提升雷击魔法伤害" }
	]
	
	# 中层 - 高级技能
	var middle_nodes = [
		{ "id": "fire_burst", "name": "烈焰爆发", "type": "expert", "element": "fire", "x": center_x - 140, "y": center_y - 180, "cost": 5, "effect": "大范围火焰伤害" },
		{ "id": "ice_storm", "name": "冰封风暴", "type": "expert", "element": "ice", "x": center_x + 180, "y": center_y - 120, "cost": 5, "effect": "大范围冰冻控制" },
		{ "id": "wind_tornado", "name": "狂风", "type": "expert", "element": "wind", "x": center_x + 140, "y": center_y + 150, "cost": 5, "effect": "击退敌人" },
		{ "id": "thunder_chain", "name": "连锁闪电", "type": "expert", "element": "thunder", "x": center_x - 160, "y": center_y + 140, "cost": 5, "effect": "跳跃攻击多个目标" }
	]
	
	# 外层 - 终极技能与跨系节点
	var outer_nodes = [
		{ "id": "fire_ultimate", "name": "陨石陨落", "type": "ultimate", "element": "fire", "x": center_x - 180, "y": center_y - 220, "cost": 10, "effect": "超大范围毁灭性伤害", "isCore": true },
		{ "id": "ice_ultimate", "name": "绝对零度", "type": "ultimate", "element": "ice", "x": center_x + 220, "y": center_y - 160, "cost": 10, "effect": "冻结大片区域", "isCore": true },
		{ "id": "cross_fire_ice", "name": "元素共鸣", "type": "cross", "element": "cross", "x": center_x + 250, "y": center_y - 40, "cost": 8, "effect": "可学习冰系技能", "canUnlockCross": true, "hasDebuff": true },
		{ "id": "cross_wind_thunder", "name": "元素共鸣", "type": "cross", "element": "cross", "x": center_x - 200, "y": center_y + 20, "cost": 8, "effect": "可学习雷系技能", "canUnlockCross": true, "hasDebuff": true }
	]
	
	trees.natural.nodes = core_nodes + inner_nodes + middle_nodes + outer_nodes
	
	# 连接
	trees.natural.connections = [
		# 核心→内层
		{ "from": "fire_base", "to": "fire_enhance" },
		{ "from": "ice_base", "to": "ice_enhance" },
		{ "from": "wind_base", "to": "wind_enhance" },
		{ "from": "thunder_base", "to": "thunder_enhance" },
		# 内层→中层
		{ "from": "fire_enhance", "to": "fire_burst" },
		{ "from": "ice_enhance", "to": "ice_storm" },
		{ "from": "wind_enhance", "to": "wind_tornado" },
		{ "from": "thunder_enhance", "to": "thunder_chain" },
		# 中层→外层
		{ "from": "fire_burst", "to": "fire_ultimate" },
		{ "from": "ice_storm", "to": "ice_ultimate" },
		{ "from": "ice_storm", "to": "cross_fire_ice" },
		{ "from": "wind_tornado", "to": "cross_fire_ice" },
		{ "from": "thunder_chain", "to": "cross_wind_thunder" }
	]
	
	# 神圣魔法体系 - 三角形结构
	var triangle_center = 450
	var triangle_top = 150
	
	# 三个角的基础技能
	var holy_nodes = [
		{ "id": "judgment_base", "name": "圣裁", "type": "basic", "element": "judgment", "x": triangle_center, "y": triangle_top, "cost": 1, "effect": "神圣攻击" },
		{ "id": "grace_base", "name": "祝福", "type": "basic", "element": "grace", "x": triangle_center - 200, "y": triangle_top + 250, "cost": 1, "effect": "提升友军属性" },
		{ "id": "redemption_base", "name": "治愈", "type": "basic", "element": "redemption", "x": triangle_center + 200, "y": triangle_top + 250, "cost": 1, "effect": "恢复友军生命" },
		# 进阶技能
		{ "id": "judgment_adv", "name": "神罚", "type": "advanced", "element": "judgment", "x": triangle_center - 50, "y": triangle_top + 100, "cost": 3, "effect": "强力神圣伤害" },
		{ "id": "grace_adv", "name": "圣盾", "type": "advanced", "element": "grace", "x": triangle_center - 150, "y": triangle_top + 180, "cost": 3, "effect": "增加防御" },
		{ "id": "redemption_adv", "name": "群体治疗", "type": "advanced", "element": "redemption", "x": triangle_center + 150, "y": triangle_top + 180, "cost": 3, "effect": "治疗多个友军" },
		# 高阶技能
		{ "id": "judgment_expert", "name": "审判之剑", "type": "expert", "element": "judgment", "x": triangle_center - 100, "y": triangle_top + 250, "cost": 6, "effect": "超远距离攻击" },
		{ "id": "grace_expert", "name": "神圣护盾", "type": "expert", "element": "grace", "x": triangle_center - 120, "y": triangle_top + 320, "cost": 6, "effect": "全队防御加成" },
		{ "id": "redemption_expert", "name": "复苏之光", "type": "expert", "element": "redemption", "x": triangle_center + 120, "y": triangle_top + 320, "cost": 6, "effect": "大量恢复生命" },
		# 终极技能
		{ "id": "holy_ultimate", "name": "三位一体", "type": "ultimate", "element": "holy", "x": triangle_center, "y": triangle_top + 380, "cost": 12, "effect": "攻击+治疗+护盾三重效果", "isCore": true }
	]
	
	trees.holy.nodes = holy_nodes
	
	# 三角形连接
	trees.holy.connections = [
		# 三个角向外延伸
		{ "from": "judgment_base", "to": "judgment_adv" },
		{ "from": "grace_base", "to": "grace_adv" },
		{ "from": "redemption_base", "to": "redemption_adv" },
		# 向中心汇聚
		{ "from": "judgment_adv", "to": "judgment_expert" },
		{ "from": "grace_adv", "to": "grace_expert" },
		{ "from": "redemption_adv", "to": "redemption_expert" },
		# 汇聚到终极
		{ "from": "judgment_expert", "to": "holy_ultimate" },
		{ "from": "grace_expert", "to": "holy_ultimate" },
		{ "from": "redemption_expert", "to": "holy_ultimate" }
	]
	
	# 古代魔法体系 - 丰字形结构
	var center_x2 = 450
	var start_y = 100
	
	var ancient_nodes = [
		# 核心主线（纵向）
		{ "id": "ancient_base", "name": "魔法飞弹", "type": "basic", "element": "ancient", "x": center_x2, "y": start_y, "cost": 1, "effect": "基础魔法攻击" },
		{ "id": "ancient_lv1", "name": "裂隙冲击", "type": "advanced", "element": "ancient", "x": center_x2, "y": start_y + 120, "cost": 4, "effect": "中等范围伤害", "castTime": 1 },
		{ "id": "ancient_lv2", "name": "时空崩坏", "type": "expert", "element": "ancient", "x": center_x2, "y": start_y + 240, "cost": 8, "effect": "大范围伤害", "castTime": 2 },
		{ "id": "ancient_ultimate", "name": "世界崩塌", "type": "ultimate", "element": "ancient", "x": center_x2, "y": start_y + 360, "cost": 16, "effect": "毁灭性超大范围伤害", "castTime": 3, "isCore": true },
		# 支线（横向）
		{ "id": "ancient_passive1", "name": "咏唱加速", "type": "passive", "element": "ancient", "x": center_x2 - 150, "y": start_y + 120, "cost": 2, "effect": "减少1回合咏唱时间" },
		{ "id": "ancient_passive2", "name": "魔法护盾", "type": "passive", "element": "ancient", "x": center_x2 + 150, "y": start_y + 120, "cost": 2, "effect": "咏唱期间获得护盾" },
		{ "id": "ancient_passive3", "name": "咏唱保护", "type": "passive", "element": "ancient", "x": center_x2 - 150, "y": start_y + 240, "cost": 3, "effect": "咏唱时免疫控制" },
		{ "id": "ancient_passive4", "name": "爆发增幅", "type": "passive", "element": "ancient", "x": center_x2 + 150, "y": start_y + 240, "cost": 3, "effect": "提升最终伤害20%" }
	]
	
	trees.ancient.nodes = ancient_nodes
	
	# 丰字形连接
	trees.ancient.connections = [
		# 主线
		{ "from": "ancient_base", "to": "ancient_lv1" },
		{ "from": "ancient_lv1", "to": "ancient_lv2" },
		{ "from": "ancient_lv2", "to": "ancient_ultimate" },
		# 支线连接
		{ "from": "ancient_lv1", "to": "ancient_passive1" },
		{ "from": "ancient_lv1", "to": "ancient_passive2" },
		{ "from": "ancient_lv2", "to": "ancient_passive3" },
		{ "from": "ancient_lv2", "to": "ancient_passive4" }
	]

# 选择体系
func select_system(system):
	current_system = system
	load_system(system)
	render()
	update_node_count()
	update_system_display()

# 加载体系
func load_system(system):
	# 优先使用保存的技能树数据
	var saved_data = _load_from_file("skill_tree_" + system + ".json")
	if saved_data:
		nodes = saved_data.nodes
		connections = saved_data.connections
	else:
		nodes = trees[system].nodes.duplicate(true)
		connections = trees[system].connections.duplicate(true)
	
	selected_node = null
	connecting_node = null
	update_properties_panel()

# 设置工具
func set_tool(tool):
	current_tool = tool
	update_tool_display()

# 渲染技能树
func render():
	# 清空现有节点
	skill_tree_layer.clear_children()
	
	# 绘制连接线
	draw_connections()
	
	# 绘制节点
	draw_nodes()

# 绘制连接线
func draw_connections():
	# 去重连接
	var unique_connections = {} 
	for conn in connections:
		var key = str(min(conn.from, conn.to)) + "|" + str(max(conn.from, conn.to))
		unique_connections[key] = conn
	
	for key in unique_connections.keys():
		var conn = unique_connections[key]
		var from_node = _find_node_by_id(conn.from)
		var to_node = _find_node_by_id(conn.to)
		
		if from_node and to_node:
			# 检查是否是不可学习的连接
			var is_unlearnable = from_node.cost == -1 or to_node.cost == -1
			
			# 创建连接线
			var line = Line2D.new()
			line.points = [Vector2(from_node.x, from_node.y), Vector2(to_node.x, to_node.y)]
			line.width = 3
			line.color = Color(1, 0.65, 0) if not is_unlearnable else Color(1, 0.25, 0.25)
			skill_tree_layer.add_child(line)

# 绘制节点
func draw_nodes():
	for node in nodes:
		var is_selected = selected_node and selected_node.id == node.id
		
		# 节点颜色根据类型
		var color
		match node.type:
			"basic": color = Color(0.29, 0.62, 0.31)
			"advanced": color = Color(0.13, 0.59, 0.94)
			"expert": color = Color(0.6, 0.16, 0.71)
			"ultimate": color = Color(1, 0.65, 0)
			"passive": color = Color(0.37, 0.49, 0.54)
			"cross": color = Color(1, 0.34, 0.13)
			_: color = Color(0.62, 0.62, 0.62)
		
		# 不可学习的节点用灰色
		if node.cost == -1:
			color = Color(0.4, 0.4, 0.4)
		
		# 创建节点
		var node_sprite = ColorRect.new()
		node_sprite.position = Vector2(node.x - 25, node.y - 25)
		node_sprite.size = Vector2(50, 50)
		node_sprite.roundness = 1.0
		node_sprite.color = color
		node_sprite.set_meta("node_id", node.id)
		skill_tree_layer.add_child(node_sprite)
		
		# 选中效果
		if is_selected:
			var selection = ColorRect.new()
			selection.position = Vector2(node.x - 30, node.y - 30)
			selection.size = Vector2(60, 60)
			selection.roundness = 1.0
			selection.color = Color(1, 1, 1, 0.3)
			skill_tree_layer.add_child(selection)
		
		# 核心技能标记
		if node.isCore:
			var core_label = Label.new()
			core_label.position = Vector2(node.x - 10, node.y - 10)
			core_label.text = "⭐"
			core_label.add_theme_font_size_override("font_size", 20)
			skill_tree_layer.add_child(core_label)
		
		# 跨系标记
		if node.canUnlockCross:
			var cross_label = Label.new()
			cross_label.position = Vector2(node.x + 15, node.y + 15)
			cross_label.text = "🔄"
			cross_label.add_theme_font_size_override("font_size", 16)
			skill_tree_layer.add_child(cross_label)
		
		# 技能名称
		var name_label = Label.new()
		name_label.position = Vector2(node.x - 20, node.y - 5)
		name_label.text = node.name.left(5)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
		name_label.add_theme_font_size_override("font_size", 10)
		skill_tree_layer.add_child(name_label)
		
		# 技能点
		var cost_label = Label.new()
		cost_label.position = Vector2(node.x - 15, node.y + 10)
		var cost_text = "不可学" if node.cost == -1 else str(node.cost) + "点"
		cost_label.text = cost_text
		cost_label.add_theme_color_override("font_color", Color(1, 1, 1))
		cost_label.add_theme_font_size_override("font_size", 8)
		skill_tree_layer.add_child(cost_label)

# 处理输入
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var viewport = $VBoxContainer/MainContainer/EditorContainer/ViewportContainer/Viewport
				var position = viewport.get_local_mouse_position()
				_handle_mouse_down(position)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# 右键取消选择
				selected_node = null
				update_properties_panel()
				render()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging_node = null
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var viewport = $VBoxContainer/MainContainer/EditorContainer/ViewportContainer/Viewport
			var position = viewport.get_local_mouse_position()
			_handle_double_click(position)
	elif event is InputEventMouseMotion:
		var viewport = $VBoxContainer/MainContainer/EditorContainer/ViewportContainer/Viewport
		var position = viewport.get_local_mouse_position()
		_handle_mouse_move(position)

# 处理鼠标按下
func _handle_mouse_down(position):
	var clicked_node = _find_node_at(position)
	
	if current_tool == "select":
		if clicked_node:
			selected_node = clicked_node
			dragging_node = clicked_node
			drag_offset = position - Vector2(clicked_node.x, clicked_node.y)
			update_properties_panel()
		else:
			selected_node = null
			update_properties_panel()
	elif current_tool == "add":
		if not clicked_node:
			add_node(position.x, position.y)
	elif current_tool == "delete":
		if clicked_node:
			delete_node(clicked_node)
	elif current_tool == "connect":
		if clicked_node:
			if not connecting_node:
				connecting_node = clicked_node
			else:
				connect_nodes(connecting_node, clicked_node)
				connecting_node = null
		else:
			connecting_node = null
	
	render()

# 处理鼠标移动
func _handle_mouse_move(position):
	if dragging_node:
		dragging_node.x = position.x - drag_offset.x
		dragging_node.y = position.y - drag_offset.y
		render()

# 处理双击
func _handle_double_click(position):
	var clicked_node = _find_node_at(position)
	if clicked_node:
		open_node_edit(clicked_node)

# 查找节点
func _find_node_at(position):
	for node in nodes:
		var distance = position.distance_to(Vector2(node.x, node.y))
		if distance <= 25:
			return node
	return null

# 根据ID查找节点
func _find_node_by_id(id):
	for node in nodes:
		if node.id == id:
			return node
	return null

# 添加节点
func add_node(x, y):
	var new_node = {
		"id": "node_" + str(randi()),
		"name": "新技能",
		"type": "basic",
		"element": "fire" if current_system == "natural" else ("judgment" if current_system == "holy" else "ancient"),
		"x": x,
		"y": y,
		"cost": 1,
		"effect": "技能效果描述"
	}
	
	nodes.append(new_node)
	update_node_count()
	render()

# 删除节点
func delete_node(node):
	# 删除节点
	nodes = nodes.filter(func(n): return n.id != node.id)
	
	# 删除相关连接
	connections = connections.filter(func(c): return c.from != node.id and c.to != node.id)
	
	if selected_node and selected_node.id == node.id:
		selected_node = null
		update_properties_panel()
	
	update_node_count()
	render()

# 连接节点
func connect_nodes(node1, node2):
	# 检查是否已存在连接
	var key = str(min(node1.id, node2.id)) + "|" + str(max(node1.id, node2.id))
	var exists = false
	for conn in connections:
		var existing_key = str(min(conn.from, conn.to)) + "|" + str(max(conn.from, conn.to))
		if existing_key == key:
			exists = true
			break
	
	if not exists and node1.id != node2.id:
		connections.append({ "from": node1.id, "to": node2.id })
		render()

# 打开节点编辑
func open_node_edit(node):
	selected_node = node
	# 这里可以打开一个编辑窗口，暂时使用简单的输入框
	var dialog = AcceptDialog.new()
	dialog.title = "编辑技能节点"
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	# 技能名称
	var name_hbox = HBoxContainer.new()
	vbox.add_child(name_hbox)
	var name_label = Label.new()
	name_label.text = "技能名称:"
	name_hbox.add_child(name_label)
	var name_line_edit = LineEdit.new()
	name_line_edit.text = node.name
	name_hbox.add_child(name_line_edit)
	
	# 技能点
	var cost_hbox = HBoxContainer.new()
	vbox.add_child(cost_hbox)
	var cost_label = Label.new()
	cost_label.text = "技能点:"
	cost_hbox.add_child(cost_label)
	var cost_spin_box = SpinBox.new()
	cost_spin_box.min_value = -1
	cost_spin_box.max_value = 100
	cost_spin_box.value = node.cost
	cost_hbox.add_child(cost_spin_box)
	
	# 技能效果
	var effect_hbox = HBoxContainer.new()
	vbox.add_child(effect_hbox)
	var effect_label = Label.new()
	effect_label.text = "效果:"
	effect_hbox.add_child(effect_label)
	var effect_text_edit = TextEdit.new()
	effect_text_edit.text = node.effect
	effect_text_edit.size = Vector2(200, 100)
	effect_hbox.add_child(effect_text_edit)
	
	dialog.add_button("保存", OK)
	dialog.add_button("取消", CANCEL)
	
	dialog.connect("confirmed", Callable(self, "_on_node_edit_confirmed").bind(node, name_line_edit, cost_spin_box, effect_text_edit))
	
	add_child(dialog)
	dialog.popup_centered()

# 处理节点编辑确认
func _on_node_edit_confirmed(node, name_line_edit, cost_spin_box, effect_text_edit):
	node.name = name_line_edit.text
	node.cost = cost_spin_box.value
	node.effect = effect_text_edit.text
	
	update_properties_panel()
	render()

# 更新属性面板
func update_properties_panel():
	# 清空现有内容
	properties_content.clear_children()
	
	if not selected_node:
		var no_selection = Label.new()
		no_selection.text = "选择节点以编辑属性"
		properties_content.add_child(no_selection)
		return
	
	var node = selected_node
	
	# 技能名称
	var name_hbox = HBoxContainer.new()
	properties_content.add_child(name_hbox)
	var name_label = Label.new()
	name_label.text = "技能名称:"
	name_hbox.add_child(name_label)
	var name_value = Label.new()
	name_value.text = node.name
	name_hbox.add_child(name_value)
	
	# 技能类型
	var type_hbox = HBoxContainer.new()
	properties_content.add_child(type_hbox)
	var type_label = Label.new()
	type_label.text = "技能类型:"
	type_hbox.add_child(type_label)
	var type_value = Label.new()
	var type_names = {
		"basic": "基础技能", "advanced": "进阶技能", "expert": "高阶技能",
		"ultimate": "终极技能", "passive": "被动技能", "cross": "跨系节点"
	}
	type_value.text = type_names.get(node.type, "未知")
	type_hbox.add_child(type_value)
	
	# 技能点
	var cost_hbox = HBoxContainer.new()
	properties_content.add_child(cost_hbox)
	var cost_label = Label.new()
	cost_label.text = "技能点:"
	cost_hbox.add_child(cost_label)
	var cost_value = Label.new()
	cost_value.text = str(node.cost)
	cost_hbox.add_child(cost_value)
	
	# 效果
	var effect_hbox = HBoxContainer.new()
	properties_content.add_child(effect_hbox)
	var effect_label = Label.new()
	effect_label.text = "效果:"
	effect_hbox.add_child(effect_label)
	var effect_value = Label.new()
	effect_value.text = node.effect
	effect_hbox.add_child(effect_value)
	
	# 连接的节点
	var connected_nodes = get_connected_nodes(node)
	if connected_nodes.size() > 0:
		var connected_hbox = HBoxContainer.new()
		properties_content.add_child(connected_hbox)
		var connected_label = Label.new()
		connected_label.text = "连接节点:"
		connected_hbox.add_child(connected_label)
		var connected_value = Label.new()
		var connected_names = []
		for n in connected_nodes:
			connected_names.append(n.name)
		connected_value.text = ", ".join(connected_names)
		connected_hbox.add_child(connected_value)
	
	# 编辑按钮
	var edit_button = Button.new()
	edit_button.text = "✏️ 编辑节点"
	edit_button.connect("pressed", Callable(self, "open_node_edit").bind(node))
	properties_content.add_child(edit_button)
	
	# 删除按钮
	var delete_button = Button.new()
	delete_button.text = "🗑️ 删除节点"
	delete_button.connect("pressed", Callable(self, "delete_node").bind(node))
	properties_content.add_child(delete_button)

# 获取连接的节点
func get_connected_nodes(node):
	var connected_node_ids = {}
	for conn in connections:
		if conn.from == node.id:
			connected_node_ids[conn.to] = true
		if conn.to == node.id:
			connected_node_ids[conn.from] = true
	
	var connected_nodes = []
	for n in nodes:
		if n.id in connected_node_ids:
			connected_nodes.append(n)
	
	return connected_nodes

# 添加双向连接
func add_bidirectional_connection():
	if not selected_node:
		print("请先选择一个节点！")
		return
	
	var node1 = selected_node
	var connected_nodes = get_connected_nodes(node1)
	
	if connected_nodes.size() == 0:
		print("该节点没有连接到其他节点！")
		return
	
	if connected_nodes.size() == 1:
		create_connection(node1, connected_nodes[0])
	else:
		# 显示连接节点选择
		var dialog = AcceptDialog.new()
		dialog.title = "选择要连接的节点"
		
		var vbox = VBoxContainer.new()
		dialog.add_child(vbox)
		
		var list = ItemList.new()
		list.size = Vector2(200, 200)
		vbox.add_child(list)
		
		for n in connected_nodes:
			list.add_item(n.name)
		
		dialog.add_button("确定", OK)
		dialog.add_button("取消", CANCEL)
		
		dialog.connect("confirmed", Callable(self, "_on_connection_selected").bind(node1, connected_nodes, list))
		
		add_child(dialog)
		dialog.popup_centered()

# 处理连接选择
func _on_connection_selected(node1, connected_nodes, list):
	var selected_index = list.get_selected_items()[0]
	if selected_index >= 0 and selected_index < connected_nodes.size():
		create_connection(node1, connected_nodes[selected_index])

# 创建连接
func create_connection(node1, node2):
	# 检查是否已存在连接
	var key = str(min(node1.id, node2.id)) + "|" + str(max(node1.id, node2.id))
	var exists = false
	for conn in connections:
		var existing_key = str(min(conn.from, conn.to)) + "|" + str(max(conn.from, conn.to))
		if existing_key == key:
			exists = true
			break
	
	if exists:
		print("已经存在连接！")
		return
	
	# 创建连接
	connections.append({ "from": node1.id, "to": node2.id })
	print("已创建 " + node1.name + " ↔ " + node2.name + " 的连接！")
	update_properties_panel()
	render()

# 删除连接
func remove_connections():
	if not selected_node:
		print("请先选择一个节点！")
		return
	
	var node = selected_node
	var connected_nodes = get_connected_nodes(node)
	
	if connected_nodes.size() == 0:
		print("该节点没有连接！")
		return
	
	# 确认删除
	var dialog = ConfirmationDialog.new()
	dialog.title = "删除连接"
	dialog.text = "确定要删除 " + node.name + " 的所有连接吗？"
	dialog.connect("confirmed", Callable(self, "_on_remove_connections_confirmed").bind(node))
	add_child(dialog)
	dialog.popup_centered()

# 确认删除连接
func _on_remove_connections_confirmed(node):
	# 删除所有与该节点相关的连接
	var initial_count = connections.size()
	connections = connections.filter(func(c): return c.from != node.id and c.to != node.id)
	
	var removed_count = initial_count - connections.size()
	print("已删除 " + str(removed_count) + " 个连接！")
	update_properties_panel()
	render()

# 保存技能树
func save_tree():
	trees[current_system].nodes = nodes.duplicate(true)
	trees[current_system].connections = connections.duplicate(true)
	
	var tree_data = {
		"nodes": nodes,
		"connections": connections,
		"version": "1.0"
	}
	
	_save_to_file("skill_tree_" + current_system + ".json", tree_data)
	print(get_system_name(current_system) + "技能树已保存！")

# 加载技能树
func load_tree():
	var saved_data = _load_from_file("skill_tree_" + current_system + ".json")
	if not saved_data:
		print("没有找到保存的技能树！")
		return
	
	nodes = saved_data.nodes
	connections = saved_data.connections
	trees[current_system].nodes = nodes.duplicate(true)
	trees[current_system].connections = connections.duplicate(true)
	
	render()
	update_node_count()
	print("技能树加载成功！")

# 导出技能树
func export_tree():
	var tree_data = {
		"system": current_system,
		"nodes": nodes,
		"connections": connections,
		"version": "1.0"
	}
	
	var json_str = JSON.stringify(tree_data, "  ")
	var file_name = "skilltree_" + current_system + "_" + str(Time.get_datetime_dict_from_system()["unix"]) + ".json"
	_save_to_file(file_name, tree_data)
	print("技能树已导出为JSON文件！")

# 重置技能树
func reset_tree():
	# 确认重置
	var dialog = ConfirmationDialog.new()
	dialog.title = "重置技能树"
	dialog.text = "确定要重置当前技能树吗？这将恢复到默认状态。"
	dialog.connect("confirmed", Callable(self, "_on_reset_tree_confirmed"))
	add_child(dialog)
	dialog.popup_centered()

# 确认重置技能树
func _on_reset_tree_confirmed():
	generate_default_trees()
	load_system(current_system)
	render()
	update_node_count()
	print("技能树已重置为默认状态！")

# 更新节点数量
func update_node_count():
	node_count_label.text = "节点数量: " + str(nodes.size())

# 更新工具显示
func update_tool_display():
	var tool_names = {
		"select": "选择/查看",
		"add": "添加节点",
		"delete": "删除节点",
		"connect": "连接节点"
	}
	current_tool_label.text = "当前工具: " + tool_names.get(current_tool, current_tool)

# 更新体系显示
func update_system_display():
	current_system_label.text = "当前体系: " + get_system_name(current_system)

# 获取体系名称
func get_system_name(system):
	var names = {
		"natural": "自然魔法",
		"holy": "神圣魔法",
		"ancient": "古代魔法"
	}
	return names.get(system, system)

# 保存到文件
func _save_to_file(file_name, data):
	var file = FileAccess.open("user://" + file_name, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		return true
	return false

# 从文件加载
func _load_from_file(file_name):
	var file = FileAccess.open("user://" + file_name, FileAccess.READ)
	if file:
		var json_str = file.get_as_string()
		file.close()
		return JSON.parse_string(json_str)
	return null

# 处理关闭按钮
func _on_close_button_pressed():
	queue_free()

# Godot 项目架构设计文档

## 1. 项目概述

本项目是一个基于 Godot 引擎的战术角色扮演游戏（TRPG），包含地图编辑器和游戏核心系统。项目旨在将现有的浏览器-based 地图编辑器功能迁移到 Godot 引擎中，并构建完整的游戏系统。

## 2. 节点结构设计

### 2.1 主场景节点树

```
Main
├── GameManager (Node)
├── MapEditor (Node)
├── UIManager (CanvasLayer)
│   ├── MainMenu (Panel)
│   ├── GameHUD (Panel)
│   ├── EditorUI (Panel)
│   └── BattleUI (Panel)
└── World (Node2D)
    ├── Map (TileMap)
    ├── Units (Node2D)
    │   ├── PlayerUnit1 (Unit)
    │   ├── EnemyUnit1 (Unit)
    │   └── ...
    └── Effects (Node2D)
        ├── SpellEffect1 (Node2D)
        └── ...
```

### 2.2 核心节点说明

| 节点名称 | 类型 | 功能描述 |
|---------|------|----------|
| GameManager | Node | 游戏核心管理器，负责游戏状态、回合管理、战斗逻辑 |
| MapEditor | Node | 地图编辑器，提供地图创建、编辑、保存功能 |
| UIManager | CanvasLayer | UI 管理器，处理所有界面元素 |
| World | Node2D | 游戏世界容器，包含地图和单位 |
| Map | TileMap | 地图瓦片系统，存储和渲染地形 |
| Units | Node2D | 单位容器，管理所有游戏单位 |
| Effects | Node2D | 特效容器，管理技能和环境特效 |

## 3. 脚本组织方式

### 3.1 目录结构

```
src/
├── managers/
│   ├── GameManager.gd
│   ├── MapEditor.gd
│   ├── UIManager.gd
│   └── DataManager.gd
├── nodes/
│   ├── Unit.gd
│   ├── Tile.gd
│   └── SpellEffect.gd
├── data/
│   ├── terrain_data.gd
│   ├── unit_data.gd
│   └── spell_data.gd
├── ui/
│   ├── MainMenu.gd
│   ├── GameHUD.gd
│   ├── EditorUI.gd
│   └── BattleUI.gd
└── utils/
    ├── pathfinding.gd
    ├── math_utils.gd
    └── save_system.gd
```

### 3.2 脚本职责

| 脚本名称 | 职责描述 |
|---------|----------|
| GameManager.gd | 管理游戏状态、回合流程、战斗逻辑 |
| MapEditor.gd | 处理地图编辑功能，包括地形绘制、单位放置 |
| UIManager.gd | 管理所有 UI 界面，处理用户输入 |
| DataManager.gd | 管理游戏数据，包括加载和保存 |
| Unit.gd | 单位基类，处理单位属性、移动、攻击 |
| Tile.gd | 地形瓦片类，存储地形属性和效果 |
| SpellEffect.gd | 技能特效类，处理技能动画和效果 |
| terrain_data.gd | 地形数据定义 |
| unit_data.gd | 单位数据定义 |
| spell_data.gd | 技能数据定义 |
| pathfinding.gd | 寻路算法实现 |
| save_system.gd | 游戏存档系统 |

## 4. 核心数据结构

### 4.1 地形数据结构

```gdscript
# terrain_data.gd
export var terrain_types = {
    "grass": {
        "name": "草地",
        "move_cost": 1,
        "def_bonus": 0,
        "tile_id": 0
    },
    "water": {
        "name": "水域",
        "move_cost": 999,
        "def_bonus": 0,
        "tile_id": 1
    },
    "mountain": {
        "name": "山地",
        "move_cost": 2,
        "def_bonus": 1,
        "tile_id": 2
    },
    "fire": {
        "name": "燃烧",
        "move_cost": 2,
        "def_bonus": 0,
        "tile_id": 3
    },
    "ice": {
        "name": "冰冻",
        "move_cost": 1,
        "def_bonus": 0,
        "tile_id": 4
    },
    "rock": {
        "name": "石柱",
        "move_cost": 999,
        "def_bonus": 2,
        "tile_id": 5
    },
    "wall": {
        "name": "墙壁",
        "move_cost": 999,
        "def_bonus": 1,
        "tile_id": 6
    },
    "floor": {
        "name": "地板",
        "move_cost": 1,
        "def_bonus": 0,
        "tile_id": 7
    }
}
```

### 4.2 单位数据结构

```gdscript
# unit_data.gd
export var unit_templates = {
    "player_fire": {
        "owner": "player",
        "type": "natural",
        "name": "玩家火法师",
        "stats": {
            "hp": 25,
            "atk": 12,
            "def": 5,
            "mag": 15,
            "spd": 10,
            "move": 4
        },
        "spells": ["fire_ball", "flame_burst"]
    },
    "player_ice": {
        "owner": "player",
        "type": "natural",
        "name": "玩家冰法师",
        "stats": {
            "hp": 22,
            "atk": 8,
            "def": 6,
            "mag": 14,
            "spd": 11,
            "move": 4
        },
        "spells": ["ice_shard", "freeze_path"]
    },
    # 其他单位模板...
}
```

### 4.3 技能数据结构

```gdscript
# spell_data.gd
export var spell_templates = {
    "fire_ball": {
        "name": "火球术",
        "type": "natural",
        "mp_cost": 5,
        "range": 2,
        "power": 12,
        "terrain_change": "fire",
        "description": "燃烧地面"
    },
    "ice_shard": {
        "name": "冰锥术",
        "type": "natural",
        "mp_cost": 5,
        "range": 2,
        "power": 10,
        "effect": "slow",
        "description": "减速效果"
    },
    # 其他技能模板...
}
```

### 4.4 地图数据结构

```gdscript
# 地图数据结构
export var map_data = {
    "map_type": "outdoor",  # outdoor 或 indoor
    "width": 20,
    "height": 15,
    "terrain": [],  # 二维数组，存储地形类型
    "units": [],    # 单位列表
    "version": "1.0"
}
```

## 5. 系统间通信机制

### 5.1 信号系统

使用 Godot 的信号系统实现模块间通信：

| 信号名称 | 发送者 | 接收者 | 功能描述 |
|---------|-------|-------|----------|
| map_updated | MapEditor | GameManager | 地图更新时触发 |
| unit_selected | UIManager | GameManager | 单位被选择时触发 |
| turn_changed | GameManager | UIManager | 回合变更时触发 |
| unit_moved | Unit | GameManager | 单位移动完成时触发 |
| spell_cast | Unit | GameManager | 技能释放时触发 |
| unit_defeated | Unit | GameManager | 单位被击败时触发 |

### 5.2 事件总线

创建全局事件总线，处理跨系统的事件：

```gdscript
# EventBus.gd

extends Node

# 信号定义
signal map_updated(map_data)
signal unit_selected(unit)
signal turn_changed(turn, player)
signal unit_moved(unit, old_pos, new_pos)
signal spell_cast(unit, spell, target)
signal unit_defeated(unit)

# 单例模式
var instance = null

func _ready():
    if instance == null:
        instance = self
        set_process(false)
    else:
        queue_free()

static func get_instance():
    return instance
```

### 5.3 数据共享

使用全局数据管理器共享游戏数据：

```gdscript
# DataManager.gd

extends Node

var current_map = null
var game_state = {}
var unit_data = {}

# 单例模式
var instance = null

func _ready():
    if instance == null:
        instance = self
        set_process(false)
    else:
        queue_free()

static func get_instance():
    return instance

func load_map(map_path):
    # 加载地图数据
    pass

func save_map(map_path):
    # 保存地图数据
    pass
```

## 6. 核心系统设计

### 6.1 地图编辑器系统

- **功能**：创建和编辑地图，包括地形绘制、单位放置、地图保存和加载
- **实现**：使用 TileMap 节点和自定义编辑器界面
- **数据流向**：编辑器操作 → 地图数据更新 → 事件触发 → 游戏系统响应

### 6.2 游戏核心系统

- **功能**：管理游戏状态、回合流程、战斗逻辑
- **实现**：使用状态机管理游戏状态，回合制系统处理行动顺序
- **数据流向**：用户输入 → 游戏逻辑处理 → 状态更新 → UI 刷新

### 6.3 单位系统

- **功能**：处理单位属性、移动、攻击、技能释放
- **实现**：基于 Unit 基类的继承体系，每个单位类型有自己的特性
- **数据流向**：单位操作 → 状态更新 → 事件触发 → 游戏系统响应

### 6.4 UI 系统

- **功能**：提供用户界面，包括主菜单、游戏 HUD、编辑器界面、战斗界面
- **实现**：使用 Godot 的 UI 系统，包括 Panel、Button、Label 等控件
- **数据流向**：用户输入 → UI 事件 → 系统响应 → UI 更新

## 7. 技术实现要点

### 7.1 地图系统

- 使用 Godot 的 TileMap 节点实现地图渲染
- 自定义 TileSet 包含所有地形类型
- 实现地图数据与 TileMap 的双向同步

### 7.2 单位系统

- 使用 Node2D 作为单位基础节点
- 实现单位的移动动画和路径寻路
- 处理单位的属性计算和状态管理

### 7.3 战斗系统

- 实现回合制战斗逻辑
- 处理技能释放和效果计算
- 实现地形对战斗的影响

### 7.4 保存系统

- 使用 JSON 格式存储地图和游戏数据
- 实现自动保存和手动保存功能
- 支持地图导出和导入

## 8. 性能优化策略

- 使用对象池管理单位和特效
- 实现地图数据的惰性加载
- 优化寻路算法，使用 A* 算法
- 合理使用 Godot 的渲染系统，避免过度绘制

## 9. 扩展性考虑

- 模块化设计，便于添加新的地形类型、单位类型和技能
- 支持自定义单位和技能数据
- 预留扩展接口，便于添加新的游戏功能

## 10. 开发计划

1. **阶段一**：搭建基础项目结构，实现地图编辑器
2. **阶段二**：实现游戏核心系统，包括回合制战斗
3. **阶段三**：实现单位系统和技能系统
4. **阶段四**：完善 UI 系统和用户体验
5. **阶段五**：测试和优化

## 11. 结论

本架构设计文档提供了一个基于 Godot 引擎的战术角色扮演游戏的完整架构方案。通过合理的节点结构设计、脚本组织和数据管理，实现了地图编辑器和游戏核心系统的功能。该架构具有良好的扩展性和可维护性，为后续的开发工作提供了清晰的指导。
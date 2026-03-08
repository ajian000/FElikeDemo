// 地形系统 - 管理地形类型、属性和交互

class TerrainSystem {
    constructor() {
        // 定义8种地形类型及其属性
        this.terrainTypes = {
            grass: {
                name: '草地',
                moveCost: 1,
                defBonus: 0,
                color: '#90ee90',
                description: '正常移动，无特殊效果',
                passable: true
            },
            water: {
                name: '水域',
                moveCost: 999,
                defBonus: 0,
                color: '#4a90e2',
                description: '阻挡移动，无法通行',
                passable: false
            },
            mountain: {
                name: '山地',
                moveCost: 2,
                defBonus: 1,
                color: '#8b7355',
                description: '移动消耗增加，提供防御加成',
                passable: true
            },
            fire: {
                name: '燃烧',
                moveCost: 2,
                defBonus: 0,
                color: '#ff4500',
                description: '移动消耗增加，可能造成持续伤害',
                passable: true,
                effect: 'burn'
            },
            ice: {
                name: '冰冻',
                moveCost: 1,
                defBonus: 0,
                color: '#e0ffff',
                description: '可通行，可能影响移动速度',
                passable: true,
                effect: 'slow'
            },
            rock: {
                name: '石柱',
                moveCost: 999,
                defBonus: 2,
                color: '#696969',
                description: '完全阻挡，提供高额防御加成',
                passable: false
            },
            wall: {
                name: '墙壁',
                moveCost: 999,
                defBonus: 1,
                color: '#4a4a4a',
                description: '室内障碍，无法通行',
                passable: false
            },
            floor: {
                name: '地板',
                moveCost: 1,
                defBonus: 0,
                color: '#d4d4d4',
                description: '室内地面，正常移动',
                passable: true
            }
        };
    }
    
    // 获取地形类型信息
    getTerrainType(type) {
        return this.terrainTypes[type] || this.terrainTypes.grass;
    }
    
    // 检查地形是否可通行
    isPassable(terrain) {
        return terrain.passable || terrain.moveCost < 999;
    }
    
    // 计算移动消耗
    getMoveCost(terrain) {
        return terrain.moveCost || 1;
    }
    
    // 计算防御加成
    getDefBonus(terrain) {
        return terrain.defBonus || 0;
    }
    
    // 应用地形效果
    applyTerrainEffect(unit, terrain) {
        if (terrain.effect) {
            switch (terrain.effect) {
                case 'burn':
                    this.applyBurnEffect(unit);
                    break;
                case 'slow':
                    this.applySlowEffect(unit);
                    break;
            }
        }
    }
    
    // 应用燃烧效果
    applyBurnEffect(unit) {
        const burnDamage = 2;
        unit.currentHp = Math.max(1, unit.currentHp - burnDamage);
        return `燃烧造成 ${burnDamage} 点伤害`;
    }
    
    // 应用减速效果
    applySlowEffect(unit) {
        const originalMove = unit.stats.move;
        unit.stats.move = Math.max(1, Math.floor(originalMove * 0.8));
        return `冰冻使移动速度降低`;
    }
    
    // 恢复单位状态（移除地形效果）
    restoreUnitStatus(unit) {
        // 这里可以实现状态恢复逻辑
    }
    
    // 改变地形类型
    changeTerrainType(terrain, newType) {
        const oldType = terrain.type;
        const newTerrainData = this.getTerrainType(newType);
        
        terrain.type = newType;
        terrain.moveCost = newTerrainData.moveCost;
        terrain.defBonus = newTerrainData.defBonus;
        terrain.passable = newTerrainData.passable;
        terrain.effect = newTerrainData.effect;
        
        return { oldType, newType };
    }
    
    // 生成地形描述
    getTerrainDescription(terrain) {
        const typeData = this.getTerrainType(terrain.type);
        let description = typeData.description;
        
        if (typeData.defBonus > 0) {
            description += ` (防御+${typeData.defBonus})`;
        }
        
        if (typeData.moveCost > 1) {
            description += ` (移动消耗: ${typeData.moveCost})`;
        }
        
        return description;
    }
    
    // 检查地形是否适合特定单位
    isTerrainSuitable(unit, terrain) {
        // 这里可以实现单位与地形的互动逻辑
        // 例如：某些单位可能对特定地形有优势
        return true;
    }
    
    // 获取地形颜色
    getTerrainColor(type) {
        return this.getTerrainType(type).color;
    }
    
    // 生成随机地形（用于地图生成）
    generateRandomTerrain(mapType, x, y, width, height) {
        const baseTerrain = mapType === 'outdoor' ? 'grass' : 'floor';
        
        // 简单的随机地形生成
        const rand = Math.random();
        if (rand < 0.8) {
            return baseTerrain;
        } else if (rand < 0.9 && mapType === 'outdoor') {
            return 'mountain';
        } else if (rand < 0.95 && mapType === 'outdoor') {
            return 'water';
        } else if (mapType === 'indoor') {
            return 'wall';
        }
        
        return baseTerrain;
    }
    
    // 批量创建地形区域
    createTerrainArea(terrainGrid, x, y, width, height, type) {
        for (let dy = 0; dy < height; dy++) {
            for (let dx = 0; dx < width; dx++) {
                const targetX = x + dx;
                const targetY = y + dy;
                
                if (targetY >= 0 && targetY < terrainGrid.length && 
                    targetX >= 0 && targetX < terrainGrid[0].length) {
                    
                    const terrain = terrainGrid[targetY][targetX];
                    this.changeTerrainType(terrain, type);
                }
            }
        }
    }
}

// 导出地形系统实例
const terrainSystem = new TerrainSystem();

// 工具函数：获取地形系统
export function getTerrainSystem() {
    return terrainSystem;
}

// 工具函数：检查移动是否可行
export function canMoveTo(x, y, terrainGrid, units, movingUnit) {
    // 检查边界
    if (y < 0 || y >= terrainGrid.length || x < 0 || x >= terrainGrid[0].length) {
        return false;
    }
    
    // 检查地形是否可通行
    const terrain = terrainGrid[y][x];
    if (!terrainSystem.isPassable(terrain)) {
        return false;
    }
    
    // 检查是否有其他单位
    const unitAtPos = units.find(u => u.x === x && u.y === y);
    if (unitAtPos && unitAtPos !== movingUnit) {
        return false;
    }
    
    return true;
}

// 工具函数：计算移动消耗
export function calculateMoveCost(path, terrainGrid) {
    let totalCost = 0;
    
    path.forEach(pos => {
        const terrain = terrainGrid[pos.y][pos.x];
        totalCost += terrainSystem.getMoveCost(terrain);
    });
    
    return totalCost;
}

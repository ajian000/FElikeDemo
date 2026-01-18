// 魔法战棋 - 核心游戏逻辑

class Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.gridSize = 40;
        this.mapWidth = 20;
        this.mapHeight = 15;
        this.mapType = 'outdoor'; // outdoor | indoor
        
        this.currentTurn = 1;
        this.currentPlayer = 'player'; // player | enemy
        this.selectedUnit = null;
        this.moveMode = false;
        this.attackMode = false;
        this.moveRange = [];
        this.attackRange = [];
        
        this.units = [];
        this.terrain = [];
        this.effects = [];
        
        this.init();
    }
    
    init() {
        this.generateTerrain();
        this.createUnits();
        this.setupEventListeners();
        this.render();
        this.log("游戏开始！点击单位进行操作", "system");
    }
    
    // 生成地形
    generateTerrain() {
        for (let y = 0; y < this.mapHeight; y++) {
            this.terrain[y] = [];
            for (let x = 0; x < this.mapWidth; x++) {
                this.terrain[y][x] = {
                    type: this.mapType === 'outdoor' ? 'grass' : 'floor',
                    moveCost: 1,
                    defBonus: 0
                };
            }
        }
        
        if (this.mapType === 'outdoor') {
            // 室外地图添加一些特殊地形
            this.createWaterArea(5, 6, 4, 3);
            this.createMountainArea(12, 4, 3, 2);
            this.createWaterArea(14, 10, 3, 2);
        } else {
            // 室外地图添加一些墙壁
            this.createWallArea(8, 5, 2, 4);
            this.createWallArea(14, 8, 2, 3);
        }
    }
    
    createWaterArea(x, y, width, height) {
        for (let dy = 0; dy < height; dy++) {
            for (let dx = 0; dx < width; dx++) {
                if (y + dy < this.mapHeight && x + dx < this.mapWidth) {
                    this.terrain[y + dy][x + dx].type = 'water';
                    this.terrain[y + dy][x + dx].moveCost = 999; // 阻挡
                }
            }
        }
    }
    
    createMountainArea(x, y, width, height) {
        for (let dy = 0; dy < height; dy++) {
            for (let dx = 0; dx < width; dx++) {
                if (y + dy < this.mapHeight && x + dx < this.mapWidth) {
                    this.terrain[y + dy][x + dx].type = 'mountain';
                    this.terrain[y + dy][x + dx].moveCost = 2;
                    this.terrain[y + dy][x + dx].defBonus = 1;
                }
            }
        }
    }
    
    createWallArea(x, y, width, height) {
        for (let dy = 0; dy < height; dy++) {
            for (let dx = 0; dx < width; dx++) {
                if (y + dy < this.mapHeight && x + dx < this.mapWidth) {
                    this.terrain[y + dy][x + dx].type = 'wall';
                    this.terrain[y + dy][x + dx].moveCost = 999;
                    this.terrain[y + dy][x + dx].defBonus = 1;
                }
            }
        }
    }
    
    // 创建单位
    createUnits() {
        // 玩家单位
        this.units.push(
            this.createUnit('player', 1, 7, '火法师', 'natural', {
                hp: 25, atk: 12, def: 5, mag: 15, spd: 10, move: 4
            }, [
                { name: '火球术', type: 'natural', mpCost: 5, range: 2, power: 12, 
                  effect: '燃烧', terrainChange: 'fire', description: '造成伤害并燃烧地面' },
                { name: '烈焰爆发', type: 'natural', mpCost: 8, range: 1, power: 18, 
                  description: '近距离高伤害' }
            ]),
            this.createUnit('player', 1, 5, '冰法师', 'natural', {
                hp: 22, atk: 8, def: 6, mag: 14, spd: 11, move: 4
            }, [
                { name: '冰锥术', type: 'natural', mpCost: 5, range: 2, power: 10, 
                  effect: '减速', description: '造成伤害并降低速度' },
                { name: '冰封路径', type: 'natural', mpCost: 6, range: 1, power: 8, 
                  terrainChange: 'ice', description: '冻结水域使其可通行' }
            ]),
            this.createUnit('player', 2, 6, '神官', 'holy', {
                hp: 20, atk: 5, def: 7, mag: 12, spd: 8, move: 3
            }, [
                { name: '治疗术', type: 'holy', mpCost: 0, range: 2, power: -15, 
                  target: 'ally', description: '恢复友军生命值（无MP消耗）' },
                { name: '圣光术', type: 'holy', mpCost: 0, range: 2, power: 8, 
                  target: 'enemy', description: '神圣伤害（无MP消耗）' },
                { name: '净化', type: 'holy', mpCost: 0, range: 1, power: 0, 
                  effect: '解除debuff', target: 'ally', description: '解除负面状态' }
            ]),
            this.createUnit('player', 1, 9, '古代法师', 'ancient', {
                hp: 18, atk: 3, def: 4, mag: 22, spd: 6, move: 3
            }, [
                { name: '陨石坠落', type: 'ancient', mpCost: 15, range: 3, power: 25, 
                  castTime: 2, description: '咏唱2回合：超大范围高伤害' },
                { name: '地壳隆起', type: 'ancient', mpCost: 12, range: 2, power: 10, 
                  castTime: 1, terrainChange: 'rock', description: '咏唱1回合：升起石柱阻挡' }
            ]),
            this.createUnit('player', 3, 6, '骑士', 'physical', {
                hp: 30, atk: 14, def: 12, mag: 0, spd: 9, move: 5
            }, [
                { name: '冲锋', type: 'physical', mpCost: 0, range: 1, power: 15, 
                  description: '物理攻击' }
            ])
        );
        
        // 敌方单位
        this.units.push(
            this.createUnit('enemy', 17, 4, '敌方火法师', 'natural', {
                hp: 25, atk: 12, def: 5, mag: 15, spd: 10, move: 4
            }, [
                { name: '火球术', type: 'natural', mpCost: 5, range: 2, power: 12, 
                  terrainChange: 'fire', description: '造成伤害并燃烧地面' }
            ]),
            this.createUnit('enemy', 18, 7, '敌方冰法师', 'natural', {
                hp: 22, atk: 8, def: 6, mag: 14, spd: 11, move: 4
            }, [
                { name: '冰锥术', type: 'natural', mpCost: 5, range: 2, power: 10, 
                  effect: '减速', description: '造成伤害并降低速度' }
            ]),
            this.createUnit('enemy', 17, 10, '敌方神官', 'holy', {
                hp: 20, atk: 5, def: 7, mag: 12, spd: 8, move: 3
            }, [
                { name: '圣光术', type: 'holy', mpCost: 0, range: 2, power: 8, 
                  target: 'enemy', description: '神圣伤害' }
            ]),
            this.createUnit('enemy', 16, 6, '敌方战士', 'physical', {
                hp: 35, atk: 16, def: 14, mag: 0, spd: 7, move: 4
            }, [
                { name: '重击', type: 'physical', mpCost: 0, range: 1, power: 18, 
                  description: '物理攻击' }
            ])
        );
    }
    
    createUnit(owner, x, y, name, type, stats, spells) {
        return {
            id: Math.random().toString(36).substr(2, 9),
            owner: owner,
            x: x,
            y: y,
            originalX: x,
            originalY: y,
            name: name,
            type: type,
            stats: { ...stats },
            maxHp: stats.hp,
            currentHp: stats.hp,
            mp: 20,
            maxMp: type === 'holy' ? 0 : 25, // 神圣魔法无MP限制
            spells: spells,
            hasMoved: false,
            hasAttacked: false,
            statusEffects: [],
            castingSpell: null,
            castTimeRemaining: 0
        };
    }
    
    setupEventListeners() {
        this.canvas.addEventListener('click', (e) => this.handleClick(e));
        this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e));
    }
    
    handleClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = Math.floor((e.clientX - rect.left) / this.gridSize);
        const y = Math.floor((e.clientY - rect.top) / this.gridSize);
        
        if (this.currentPlayer !== 'player') return;
        
        const clickedUnit = this.getUnitAt(x, y);
        
        if (this.moveMode && this.selectedUnit && !this.selectedUnit.hasMoved) {
            if (this.moveRange.some(pos => pos.x === x && pos.y === y)) {
                this.moveUnit(this.selectedUnit, x, y);
                this.moveMode = false;
                this.moveRange = [];
                this.render();
                return;
            }
        }
        
        if (this.attackMode && this.selectedUnit && !this.selectedUnit.hasAttacked) {
            if (clickedUnit && this.attackRange.some(pos => pos.x === x && pos.y === y)) {
                // 选择魔法攻击
                this.showSpellSelection(clickedUnit);
                this.attackMode = false;
                this.attackRange = [];
                this.render();
                return;
            } else if (!clickedUnit && this.selectedUnit.type === 'ancient') {
                // 古代魔法可能用于地形改变
                const spell = this.selectedUnit.spells.find(s => s.terrainChange);
                if (spell && this.attackRange.some(pos => pos.x === x && pos.y === y)) {
                    this.castTerrainChange(this.selectedUnit, spell, x, y);
                    this.attackMode = false;
                    this.attackRange = [];
                    this.render();
                    return;
                }
            }
        }
        
        if (clickedUnit && clickedUnit.owner === 'player') {
            this.selectUnit(clickedUnit);
        } else if (clickedUnit && clickedUnit.owner === 'enemy' && this.selectedUnit) {
            this.selectUnit(this.selectedUnit);
        }
        
        this.moveMode = false;
        this.attackMode = false;
        this.moveRange = [];
        this.attackRange = [];
        this.render();
    }
    
    handleMouseMove(e) {
        // 可以添加鼠标悬停效果
    }
    
    selectUnit(unit) {
        this.selectedUnit = unit;
        this.updateUI();
        
        // 检查是否正在咏唱
        if (unit.castingSpell) {
            this.log(`${unit.name} 正在咏唱 ${unit.castingSpell.name} (剩余 ${unit.castTimeRemaining} 回合)`, "system");
        }
    }
    
    startMoveMode() {
        if (!this.selectedUnit || this.selectedUnit.owner !== 'player' || this.selectedUnit.hasMoved) {
            this.log("无法移动：未选择单位或单位已行动", "system");
            return;
        }
        
        this.moveMode = true;
        this.attackMode = false;
        this.moveRange = this.calculateMoveRange(this.selectedUnit);
        this.log(`显示 ${this.selectedUnit.name} 的移动范围`, "system");
        this.render();
    }
    
    startAttackMode() {
        if (!this.selectedUnit || this.selectedUnit.owner !== 'player' || this.selectedUnit.hasAttacked) {
            this.log("无法攻击：未选择单位或单位已攻击", "system");
            return;
        }
        
        if (this.selectedUnit.castingSpell) {
            this.log(`${this.selectedUnit.name} 正在咏唱中，无法攻击`, "system");
            return;
        }
        
        this.attackMode = true;
        this.moveMode = false;
        this.attackRange = this.calculateAttackRange(this.selectedUnit);
        this.log(`显示 ${this.selectedUnit.name} 的攻击范围`, "system");
        this.render();
    }
    
    unitWait() {
        if (!this.selectedUnit || this.selectedUnit.owner !== 'player') return;
        
        this.selectedUnit.hasMoved = true;
        this.selectedUnit.hasAttacked = true;
        this.log(`${this.selectedUnit.name} 选择待机`, "player");
        this.selectUnit(null);
        this.render();
    }
    
    calculateMoveRange(unit) {
        const range = [];
        const visited = new Set();
        
        const visit = (x, y, remaining, cost) => {
            if (x < 0 || x >= this.mapWidth || y < 0 || y >= this.mapHeight) return;
            if (remaining < 0) return;
            if (visited.has(`${x},${y}`)) return;
            
            const terrain = this.terrain[y][x];
            const unitAtPos = this.getUnitAt(x, y);
            
            if (unitAtPos && unitAtPos !== unit) return; // 被其他单位占据
            if (terrain.moveCost > remaining) return; // 地形阻挡
            
            visited.add(`${x},${y}`);
            range.push({ x, y, cost: unit.stats.move - remaining });
            
            // 四方向移动
            visit(x + 1, y, remaining - terrain.moveCost, cost + terrain.moveCost);
            visit(x - 1, y, remaining - terrain.moveCost, cost + terrain.moveCost);
            visit(x, y + 1, remaining - terrain.moveCost, cost + terrain.moveCost);
            visit(x, y - 1, remaining - terrain.moveCost, cost + terrain.moveCost);
        };
        
        visit(unit.x, unit.y, unit.stats.move, 0);
        
        return range.filter(pos => !(pos.x === unit.x && pos.y === unit.y));
    }
    
    calculateAttackRange(unit) {
        const range = [];
        const maxRange = Math.max(...unit.spells.map(s => s.range));
        
        for (let y = 0; y < this.mapHeight; y++) {
            for (let x = 0; x < this.mapWidth; x++) {
                const dist = Math.abs(x - unit.x) + Math.abs(y - unit.y);
                if (dist <= maxRange && dist > 0) {
                    range.push({ x, y, dist });
                }
            }
        }
        
        return range;
    }
    
    moveUnit(unit, x, y) {
        unit.originalX = unit.x;
        unit.originalY = unit.y;
        unit.x = x;
        unit.y = y;
        unit.hasMoved = true;
        this.log(`${unit.name} 移动到 (${x}, ${y})`, "player");
        this.updateUI();
    }
    
    showSpellSelection(targetUnit) {
        if (!this.selectedUnit) return;
        
        const unit = this.selectedUnit;
        const availableSpells = unit.spells.filter(spell => {
            if (unit.type === 'holy') return true; // 神圣魔法无MP限制
            if (spell.mpCost > unit.mp) return false;
            
            const dist = Math.abs(targetUnit.x - unit.x) + Math.abs(targetUnit.y - unit.y);
            
            // 室内地图限制：超远程技能(射程≥4)无法使用
            if (this.mapType === 'indoor' && spell.range >= 4) {
                return false;
            }
            
            return dist <= spell.range;
        });
        
        if (availableSpells.length === 0) {
            this.log("没有可用的魔法" + (this.mapType === 'indoor' ? " (室内地图禁用超远程技能)" : ""), "system");
            return;
        }
        
        const spellName = prompt("选择魔法:\n" + 
            availableSpells.map((s, i) => `${i + 1}. ${s.name} (MP:${s.mpCost} 威力:${s.power})`).join('\n'),
            "1");
        
        const index = parseInt(spellName) - 1;
        if (index >= 0 && index < availableSpells.length) {
            this.castSpell(unit, availableSpells[index], targetUnit);
        }
    }
    
    castSpell(caster, spell, target) {
        if (caster.type !== 'holy' && caster.mp < spell.mpCost) {
            this.log("MP不足！", "system");
            return;
        }
        
        // 检查是否是治疗术
        if (spell.target === 'ally' && target.owner === 'enemy') {
            this.log("无法对敌人使用治疗魔法", "system");
            return;
        }
        
        if (caster.type !== 'holy') {
            caster.mp -= spell.mpCost;
        }
        
        // 检查咏唱时间
        if (spell.castTime) {
            caster.castingSpell = spell;
            caster.castTimeRemaining = spell.castTime;
            caster.hasAttacked = true;
            this.log(`${caster.name} 开始咏唱 ${spell.name}，需要 ${spell.castTime} 回合`, "player");
            this.render();
            return;
        }
        
        caster.hasAttacked = true;
        
        if (spell.target === 'ally') {
            // 治疗魔法
            const healAmount = Math.abs(spell.power);
            target.currentHp = Math.min(target.maxHp, target.currentHp + healAmount);
            this.log(`${caster.name} 对 ${target.name} 使用 ${spell.name}，恢复 ${healAmount} 生命值`, "player");
            
            if (spell.effect === '解除debuff') {
                target.statusEffects = [];
                this.log(`${target.name} 的负面状态被清除`, "player");
            }
        } else {
            // 攻击魔法
            const defBonus = this.terrain[target.y][target.x].defBonus;
            const damage = Math.max(1, spell.power + caster.stats.mag - target.stats.def - defBonus);
            target.currentHp -= damage;
            this.log(`${caster.name} 对 ${target.name} 使用 ${spell.name}，造成 ${damage} 伤害`, "player");
            
            // 地形改变
            if (spell.terrainChange) {
                this.changeTerrain(target.x, target.y, spell.terrainChange);
            }
        }
        
        // 检查死亡
        if (target.currentHp <= 0) {
            this.unitDeath(target);
        }
        
        this.updateUI();
        this.render();
    }
    
    castTerrainChange(caster, spell, x, y) {
        if (caster.type !== 'holy' && caster.mp < spell.mpCost) {
            this.log("MP不足！", "system");
            return;
        }
        
        if (spell.castTime) {
            caster.castingSpell = spell;
            caster.castTimeRemaining = spell.castTime;
            caster.hasAttacked = true;
            this.log(`${caster.name} 开始咏唱 ${spell.name}，需要 ${spell.castTime} 回合`, "player");
            this.render();
            return;
        }
        
        if (caster.type !== 'holy') {
            caster.mp -= spell.mpCost;
        }
        
        caster.hasAttacked = true;
        this.changeTerrain(x, y, spell.terrainChange);
        
        // 如果有目标单位，也造成伤害
        const target = this.getUnitAt(x, y);
        if (target) {
            const defBonus = this.terrain[y][x].defBonus;
            const damage = Math.max(1, spell.power + caster.stats.mag - target.stats.def - defBonus);
            target.currentHp -= damage;
            this.log(`${caster.name} 对 ${target.name} 造成 ${damage} 伤害`, "player");
            
            if (target.currentHp <= 0) {
                this.unitDeath(target);
            }
        }
        
        this.updateUI();
        this.render();
    }
    
    changeTerrain(x, y, type) {
        const terrain = this.terrain[y][x];
        const oldType = terrain.type;
        
        switch (type) {
            case 'fire':
                terrain.type = 'fire';
                terrain.moveCost = 2;
                terrain.defBonus = 0;
                this.log(`(${x}, ${y}) 的地形变为燃烧状态`, "player");
                break;
            case 'ice':
                terrain.type = 'ice';
                terrain.moveCost = 1;
                terrain.defBonus = 0;
                this.log(`(${x}, ${y}) 的地形被冻结`, "player");
                break;
            case 'rock':
                terrain.type = 'rock';
                terrain.moveCost = 999;
                terrain.defBonus = 2;
                this.log(`(${x}, ${y}) 升起石柱`, "player");
                break;
        }
        
        this.render();
    }
    
    unitDeath(unit) {
        this.log(`${unit.name} 阵亡！(永久死亡)`, unit.owner === 'player' ? "player" : "enemy");
        this.units = this.units.filter(u => u !== unit);
        
        if (this.selectedUnit === unit) {
            this.selectedUnit = null;
        }
    }
    
    endTurn() {
        this.processCasting();
        
        if (this.currentPlayer === 'player') {
            this.currentPlayer = 'enemy';
            document.getElementById('currentPlayer').textContent = '当前行动: 敌方';
            this.log("--- 敌方回合开始 ---", "system");
            
            setTimeout(() => this.enemyTurn(), 1000);
        } else {
            this.currentPlayer = 'player';
            this.currentTurn++;
            document.getElementById('currentTurn').textContent = `回合: ${this.currentTurn}`;
            document.getElementById('currentPlayer').textContent = '当前行动: 玩家';
            
            // 重置玩家单位状态
            this.units.filter(u => u.owner === 'player').forEach(unit => {
                unit.hasMoved = false;
                unit.hasAttacked = false;
            });
            
            // MP恢复
            this.units.filter(u => u.owner === 'player' && u.type !== 'holy').forEach(unit => {
                unit.mp = Math.min(unit.maxMp, unit.mp + 5);
            });
            
            this.log("--- 玩家回合开始 ---", "system");
        }
        
        this.selectedUnit = null;
        this.updateUI();
        this.render();
    }
    
    processCasting() {
        // 处理所有单位正在进行的咏唱
        this.units.filter(u => u.castingSpell).forEach(unit => {
            unit.castTimeRemaining--;
            
            if (unit.castTimeRemaining <= 0) {
                // 咏唱完成，释放魔法
                const spell = unit.castingSpell;
                
                if (spell.terrainChange) {
                    // 对单位当前位置或目标位置施放
                    this.changeTerrain(unit.x, unit.y, spell.terrainChange);
                    
                    // 检查范围内是否有敌人
                    const targets = this.units.filter(u => 
                        u.owner !== unit.owner &&
                        Math.abs(u.x - unit.x) + Math.abs(u.y - unit.y) <= spell.range
                    );
                    
                    if (targets.length > 0) {
                        const target = targets[0];
                        const damage = Math.max(1, spell.power + unit.stats.mag - target.stats.def);
                        target.currentHp -= damage;
                        this.log(`${unit.name} 咏唱完成！${spell.name} 对 ${target.name} 造成 ${damage} 伤害`, 
                            unit.owner === 'player' ? "player" : "enemy");
                        
                        if (target.currentHp <= 0) {
                            this.unitDeath(target);
                        }
                    } else {
                        this.log(`${unit.name} 咏唱完成！${spell.name} 施放成功`, 
                            unit.owner === 'player' ? "player" : "enemy");
                    }
                }
                
                unit.castingSpell = null;
                unit.castTimeRemaining = 0;
            } else {
                this.log(`${unit.name} 继续咏唱 ${spell.name} (剩余 ${unit.castTimeRemaining} 回合)`, 
                    unit.owner === 'player' ? "player" : "enemy");
            }
        });
    }
    
    enemyTurn() {
        const enemyUnits = this.units.filter(u => u.owner === 'enemy' && !u.hasAttacked);
        
        if (enemyUnits.length === 0) {
            this.endTurn();
            return;
        }
        
        const unit = enemyUnits[0];
        
        // 简单AI：寻找最近的玩家单位
        const playerUnits = this.units.filter(u => u.owner === 'player');
        if (playerUnits.length === 0) {
            this.endTurn();
            return;
        }
        
        let target = playerUnits[0];
        let minDist = Infinity;
        
        playerUnits.forEach(p => {
            const dist = Math.abs(p.x - unit.x) + Math.abs(p.y - unit.y);
            if (dist < minDist) {
                minDist = dist;
                target = p;
            }
        });
        
        // 尝试攻击
        const spell = unit.spells.find(s => {
            const dist = Math.abs(target.x - unit.x) + Math.abs(target.y - unit.y);
            return dist <= s.range && (unit.type === 'holy' || unit.mp >= s.mpCost);
        });
        
        if (spell) {
            const dist = Math.abs(target.x - unit.x) + Math.abs(target.y - unit.y);
            if (dist <= spell.range) {
                // 在射程内，直接攻击
                if (unit.type !== 'holy') {
                    unit.mp -= spell.mpCost;
                }
                
                const damage = Math.max(1, spell.power + unit.stats.mag - target.stats.def);
                target.currentHp -= damage;
                this.log(`${unit.name} 对 ${target.name} 使用 ${spell.name}，造成 ${damage} 伤害`, "enemy");
                
                if (spell.terrainChange) {
                    this.changeTerrain(target.x, target.y, spell.terrainChange);
                }
                
                if (target.currentHp <= 0) {
                    this.unitDeath(target);
                }
                
                unit.hasAttacked = true;
                this.render();
                
                setTimeout(() => this.enemyTurn(), 500);
                return;
            }
        }
        
        // 移动靠近目标
        const moveRange = this.calculateMoveRange(unit);
        if (moveRange.length > 0) {
            let bestMove = moveRange[0];
            let bestDistAfterMove = Infinity;
            
            moveRange.forEach(pos => {
                const dist = Math.abs(target.x - pos.x) + Math.abs(target.y - pos.y);
                if (dist < bestDistAfterMove) {
                    bestDistAfterMove = dist;
                    bestMove = pos;
                }
            });
            
            unit.x = bestMove.x;
            unit.y = bestMove.y;
            unit.hasMoved = true;
            this.log(`${unit.name} 移动到 (${unit.x}, ${unit.y})`, "enemy");
        }
        
        this.render();
        
        setTimeout(() => this.enemyTurn(), 500);
    }
    
    getUnitAt(x, y) {
        return this.units.find(u => u.x === x && u.y === y);
    }
    
    updateUI() {
        document.getElementById('unitDetails').innerHTML = '';
        document.getElementById('magicDetails').innerHTML = '';
        
        if (this.selectedUnit) {
            const unit = this.selectedUnit;
            const detailsHtml = `
                <p><strong>${unit.name}</strong> (${unit.type === 'natural' ? '自然魔法' : 
                    unit.type === 'holy' ? '神圣魔法' : 
                    unit.type === 'ancient' ? '古代魔法' : '物理'})</p>
                <div class="stat-row"><span>HP:</span><span class="stat-value">${unit.currentHp}/${unit.maxHp}</span></div>
                <div class="stat-row"><span>MP:</span><span class="stat-value">${unit.type === 'holy' ? '无限制' : unit.mp + '/' + unit.maxMp}</span></div>
                <div class="stat-row"><span>攻击:</span><span class="stat-value">${unit.stats.atk}</span></div>
                <div class="stat-row"><span>防御:</span><span class="stat-value">${unit.stats.def}</span></div>
                <div class="stat-row"><span>魔法:</span><span class="stat-value">${unit.stats.mag}</span></div>
                <div class="stat-row"><span>速度:</span><span class="stat-value">${unit.stats.spd}</span></div>
                <div class="stat-row"><span>移动:</span><span class="stat-value">${unit.stats.move}</span></div>
                <div class="stat-row"><span>已行动:</span><span class="stat-value">${unit.hasAttacked ? '是' : '否'}</span>
            `;
            document.getElementById('unitDetails').innerHTML = detailsHtml;
            
            // 显示魔法列表
            let magicHtml = '';
            unit.spells.forEach(spell => {
                magicHtml += `
                    <div class="magic-item ${spell.type}">
                        <span class="magic-name">${spell.name}</span>
                        <div class="magic-info">
                            射程: ${spell.range} | 威力: ${spell.power} | MP: ${spell.mpCost}
                        </div>
                        <div class="magic-info">${spell.description}</div>
                    </div>
                `;
            });
            document.getElementById('magicDetails').innerHTML = magicHtml;
        } else {
            document.getElementById('unitDetails').innerHTML = '<p>点击单位查看详情</p>';
            document.getElementById('magicDetails').innerHTML = '<p>选择单位后显示可用魔法</p>';
        }
        
        // 更新按钮状态
        const canAct = this.selectedUnit && this.selectedUnit.owner === 'player' && 
                      !this.selectedUnit.hasAttacked && !this.selectedUnit.castingSpell;
        document.getElementById('btnMove').disabled = !canAct || this.selectedUnit?.hasMoved;
        document.getElementById('btnAttack').disabled = !canAct;
        document.getElementById('btnWait').disabled = !this.selectedUnit || this.selectedUnit.owner !== 'player';
    }
    
    log(message, type) {
        const logDiv = document.getElementById('battleLog');
        const entry = document.createElement('div');
        entry.className = `log-entry ${type}`;
        entry.textContent = message;
        logDiv.insertBefore(entry, logDiv.firstChild);
        
        // 保持最多20条日志
        while (logDiv.children.length > 20) {
            logDiv.removeChild(logDiv.lastChild);
        }
    }
    
    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // 绘制地形
        this.drawTerrain();
        
        // 绘制移动范围
        this.drawMoveRange();
        
        // 绘制攻击范围
        this.drawAttackRange();
        
        // 绘制单位
        this.drawUnits();
        
        // 绘制选择框
        if (this.selectedUnit) {
            this.drawSelection(this.selectedUnit.x, this.selectedUnit.y);
        }
    }
    
    drawTerrain() {
        for (let y = 0; y < this.mapHeight; y++) {
            for (let x = 0; x < this.mapWidth; x++) {
                const terrain = this.terrain[y][x];
                const px = x * this.gridSize;
                const py = y * this.gridSize;
                
                // 根据地形类型设置颜色
                let color;
                switch (terrain.type) {
                    case 'grass': color = '#90ee90'; break;
                    case 'water': color = '#4a90e2'; break;
                    case 'mountain': color = '#8b7355'; break;
                    case 'fire': color = '#ff4500'; break;
                    case 'ice': color = '#e0ffff'; break;
                    case 'rock': color = '#696969'; break;
                    case 'wall': color = '#4a4a4a'; break;
                    case 'floor': color = '#d4d4d4'; break;
                    default: color = '#90ee90';
                }
                
                this.ctx.fillStyle = color;
                this.ctx.fillRect(px, py, this.gridSize, this.gridSize);
                
                // 墙壁添加纹理
                if (terrain.type === 'wall') {
                    this.ctx.strokeStyle = '#3a3a3a';
                    this.ctx.lineWidth = 2;
                    this.ctx.beginPath();
                    this.ctx.moveTo(px, py);
                    this.ctx.lineTo(px + this.gridSize, py + this.gridSize);
                    this.ctx.moveTo(px + this.gridSize, py);
                    this.ctx.lineTo(px, py + this.gridSize);
                    this.ctx.stroke();
                }
                
                // 绘制网格线
                this.ctx.strokeStyle = 'rgba(0, 0, 0, 0.1)';
                this.ctx.lineWidth = 1;
                this.ctx.strokeRect(px, py, this.gridSize, this.gridSize);
                
                // 防御加成标记
                if (terrain.defBonus > 0) {
                    this.ctx.fillStyle = '#ffd700';
                    this.ctx.font = '12px Arial';
                    this.ctx.fillText(`+${terrain.defBonus}`, px + 2, py + 12);
                }
            }
        }
    }
    
    drawMoveRange() {
        this.moveRange.forEach(pos => {
            const px = pos.x * this.gridSize;
            const py = pos.y * this.gridSize;
            
            this.ctx.fillStyle = 'rgba(0, 255, 0, 0.3)';
            this.ctx.fillRect(px, py, this.gridSize, this.gridSize);
        });
    }
    
    drawAttackRange() {
        this.attackRange.forEach(pos => {
            const px = pos.x * this.gridSize;
            const py = pos.y * this.gridSize;
            
            this.ctx.fillStyle = 'rgba(255, 0, 0, 0.3)';
            this.ctx.fillRect(px, py, this.gridSize, this.gridSize);
        });
    }
    
    drawUnits() {
        this.units.forEach(unit => {
            const px = unit.x * this.gridSize + this.gridSize / 2;
            const py = unit.y * this.gridSize + this.gridSize / 2;
            const radius = this.gridSize / 2 - 4;
            
            // 根据阵营和类型设置颜色
            let color;
            if (unit.owner === 'player') {
                switch (unit.type) {
                    case 'natural': color = '#ff6b6b'; break;
                    case 'holy': color = '#ffd700'; break;
                    case 'ancient': color = '#9b59b6'; break;
                    case 'physical': color = '#3498db'; break;
                    default: color = '#2ecc71';
                }
            } else {
                color = '#e74c3c';
            }
            
            // 绘制单位圆圈
            this.ctx.beginPath();
            this.ctx.arc(px, py, radius, 0, Math.PI * 2);
            this.ctx.fillStyle = color;
            this.ctx.fill();
            this.ctx.strokeStyle = '#fff';
            this.ctx.lineWidth = 2;
            this.ctx.stroke();
            
            // 已行动标记
            if (unit.hasAttacked) {
                this.ctx.fillStyle = 'rgba(0, 0, 0, 0.5)';
                this.ctx.beginPath();
                this.ctx.arc(px, py, radius, 0, Math.PI * 2);
                this.ctx.fill();
            }
            
            // 咏唱标记
            if (unit.castingSpell) {
                this.ctx.fillStyle = '#fff';
                this.ctx.font = '20px Arial';
                this.ctx.fillText('✧', px - 7, py + 7);
            }
            
            // HP条
            const hpPercent = unit.currentHp / unit.maxHp;
            const hpWidth = this.gridSize - 8;
            const hpHeight = 4;
            const hpX = unit.x * this.gridSize + 4;
            const hpY = unit.y * this.gridSize + 2;
            
            this.ctx.fillStyle = '#333';
            this.ctx.fillRect(hpX, hpY, hpWidth, hpHeight);
            
            this.ctx.fillStyle = hpPercent > 0.5 ? '#2ecc71' : hpPercent > 0.25 ? '#f1c40f' : '#e74c3c';
            this.ctx.fillRect(hpX, hpY, hpWidth * hpPercent, hpHeight);
            
            // 单位名称
            this.ctx.fillStyle = '#fff';
            this.ctx.font = '10px Arial';
            this.ctx.textAlign = 'center';
            this.ctx.fillText(unit.name.substring(0, 3), px, py + 4);
        });
    }
    
    drawSelection(x, y) {
        const px = x * this.gridSize;
        const py = y * this.gridSize;
        
        this.ctx.strokeStyle = '#ffd700';
        this.ctx.lineWidth = 3;
        this.ctx.strokeRect(px, py, this.gridSize, this.gridSize);
    }
}

// 初始化游戏
const game = new Game();

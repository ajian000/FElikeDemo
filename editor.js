// 地图编辑器
class MapEditor {
    constructor() {
        this.canvas = document.getElementById('editorCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.gridSize = 40;
        this.mapWidth = 20;
        this.mapHeight = 15;
        
        this.currentTool = 'terrain';
        this.currentType = 'grass';
        this.mapType = 'outdoor';
        
        this.terrain = [];
        this.units = [];
        this.isDrawing = false;
        
        this.init();
    }
    
    init() {
        this.initializeTerrain();
        this.setupEventListeners();
        this.render();
        this.updateToolDisplay();
    }
    
    initializeTerrain() {
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
    }
    
    setupEventListeners() {
        this.canvas.addEventListener('mousedown', (e) => this.handleMouseDown(e));
        this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e));
        this.canvas.addEventListener('mouseup', () => this.isDrawing = false);
        this.canvas.addEventListener('mouseleave', () => this.isDrawing = false);
        this.canvas.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.handleRightClick(e);
        });
    }
    
    handleMouseDown(e) {
        if (e.button === 0) { // 左键
            this.isDrawing = true;
            this.paint(e);
        }
    }
    
    handleMouseMove(e) {
        if (this.isDrawing) {
            this.paint(e);
        }
    }
    
    handleRightClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = Math.floor((e.clientX - rect.left) / this.gridSize);
        const y = Math.floor((e.clientY - rect.top) / this.gridSize);
        
        if (x >= 0 && x < this.mapWidth && y >= 0 && y < this.mapHeight) {
            // 擦除单位
            const unitIndex = this.units.findIndex(u => u.x === x && u.y === y);
            if (unitIndex !== -1) {
                this.units.splice(unitIndex, 1);
                this.render();
            }
        }
    }
    
    paint(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = Math.floor((e.clientX - rect.left) / this.gridSize);
        const y = Math.floor((e.clientY - rect.top) / this.gridSize);
        
        if (x < 0 || x >= this.mapWidth || y < 0 || y >= this.mapHeight) return;
        
        if (this.currentTool === 'terrain') {
            this.setTerrain(x, y, this.currentType);
        } else if (this.currentTool === 'unit') {
            this.placeUnit(x, y, this.currentType);
        }
        
        this.render();
    }
    
    setTerrain(x, y, type) {
        this.terrain[y][x].type = type;
        
        switch (type) {
            case 'grass':
                this.terrain[y][x].moveCost = 1;
                this.terrain[y][x].defBonus = 0;
                break;
            case 'water':
                this.terrain[y][x].moveCost = 999;
                this.terrain[y][x].defBonus = 0;
                break;
            case 'mountain':
                this.terrain[y][x].moveCost = 2;
                this.terrain[y][x].defBonus = 1;
                break;
            case 'fire':
                this.terrain[y][x].moveCost = 2;
                this.terrain[y][x].defBonus = 0;
                break;
            case 'ice':
                this.terrain[y][x].moveCost = 1;
                this.terrain[y][x].defBonus = 0;
                break;
            case 'rock':
                this.terrain[y][x].moveCost = 999;
                this.terrain[y][x].defBonus = 2;
                break;
            case 'wall':
                this.terrain[y][x].moveCost = 999;
                this.terrain[y][x].defBonus = 1;
                break;
            case 'floor':
                this.terrain[y][x].moveCost = 1;
                this.terrain[y][x].defBonus = 0;
                break;
        }
    }
    
    placeUnit(x, y, unitType) {
        // 检查是否已有单位
        const existingIndex = this.units.findIndex(u => u.x === x && u.y === y);
        if (existingIndex !== -1) {
            this.units[existingIndex] = this.createUnitFromType(unitType, x, y);
        } else {
            this.units.push(this.createUnitFromType(unitType, x, y));
        }
    }
    
    createUnitFromType(type, x, y) {
        const unitTemplates = {
            'player_fire': {
                owner: 'player', type: 'natural', name: '玩家火法师',
                stats: { hp: 25, atk: 12, def: 5, mag: 15, spd: 10, move: 4 },
                spells: [
                    { name: '火球术', type: 'natural', mpCost: 5, range: 2, power: 12, terrainChange: 'fire', description: '燃烧地面' },
                    { name: '烈焰爆发', type: 'natural', mpCost: 8, range: 1, power: 18, description: '高伤害' }
                ]
            },
            'player_ice': {
                owner: 'player', type: 'natural', name: '玩家冰法师',
                stats: { hp: 22, atk: 8, def: 6, mag: 14, spd: 11, move: 4 },
                spells: [
                    { name: '冰锥术', type: 'natural', mpCost: 5, range: 2, power: 10, effect: '减速', description: '减速效果' },
                    { name: '冰封路径', type: 'natural', mpCost: 6, range: 1, power: 8, terrainChange: 'ice', description: '冻结水域' }
                ]
            },
            'player_holy': {
                owner: 'player', type: 'holy', name: '玩家神官',
                stats: { hp: 20, atk: 5, def: 7, mag: 12, spd: 8, move: 3 },
                spells: [
                    { name: '治疗术', type: 'holy', mpCost: 0, range: 2, power: -15, target: 'ally', description: '恢复生命' },
                    { name: '圣光术', type: 'holy', mpCost: 0, range: 2, power: 8, target: 'enemy', description: '神圣伤害' },
                    { name: '净化', type: 'holy', mpCost: 0, range: 1, power: 0, effect: '解除debuff', target: 'ally', description: '解除负面' }
                ]
            },
            'player_ancient': {
                owner: 'player', type: 'ancient', name: '玩家古代法师',
                stats: { hp: 18, atk: 3, def: 4, mag: 22, spd: 6, move: 3 },
                spells: [
                    { name: '陨石坠落', type: 'ancient', mpCost: 15, range: 3, power: 25, castTime: 2, description: '超大伤害' },
                    { name: '地壳隆起', type: 'ancient', mpCost: 12, range: 2, power: 10, castTime: 1, terrainChange: 'rock', description: '升起石柱' }
                ]
            },
            'player_physical': {
                owner: 'player', type: 'physical', name: '玩家骑士',
                stats: { hp: 30, atk: 14, def: 12, mag: 0, spd: 9, move: 5 },
                spells: [
                    { name: '冲锋', type: 'physical', mpCost: 0, range: 1, power: 15, description: '物理攻击' }
                ]
            },
            'enemy_fire': {
                owner: 'enemy', type: 'natural', name: '敌方火法师',
                stats: { hp: 25, atk: 12, def: 5, mag: 15, spd: 10, move: 4 },
                spells: [
                    { name: '火球术', type: 'natural', mpCost: 5, range: 2, power: 12, terrainChange: 'fire', description: '燃烧地面' }
                ]
            },
            'enemy_ice': {
                owner: 'enemy', type: 'natural', name: '敌方冰法师',
                stats: { hp: 22, atk: 8, def: 6, mag: 14, spd: 11, move: 4 },
                spells: [
                    { name: '冰锥术', type: 'natural', mpCost: 5, range: 2, power: 10, effect: '减速', description: '减速效果' }
                ]
            },
            'enemy_holy': {
                owner: 'enemy', type: 'holy', name: '敌方神官',
                stats: { hp: 20, atk: 5, def: 7, mag: 12, spd: 8, move: 3 },
                spells: [
                    { name: '圣光术', type: 'holy', mpCost: 0, range: 2, power: 8, target: 'enemy', description: '神圣伤害' }
                ]
            },
            'enemy_physical': {
                owner: 'enemy', type: 'physical', name: '敌方战士',
                stats: { hp: 35, atk: 16, def: 14, mag: 0, spd: 7, move: 4 },
                spells: [
                    { name: '重击', type: 'physical', mpCost: 0, range: 1, power: 18, description: '物理攻击' }
                ]
            }
        };
        
        const template = unitTemplates[type];
        if (!template) return null;
        
        return {
            id: Math.random().toString(36).substr(2, 9),
            x: x,
            y: y,
            ...template,
            currentHp: template.stats.hp,
            maxHp: template.stats.hp,
            mp: type.includes('holy') ? 0 : 20,
            maxMp: type.includes('holy') ? 0 : 25,
            hasMoved: false,
            hasAttacked: false,
            statusEffects: [],
            castingSpell: null,
            castTimeRemaining: 0
        };
    }
    
    setMapType(type) {
        this.mapType = type;
        document.getElementById('currentMapType').textContent = type === 'outdoor' ? '室外' : '室内';
        
        // 清空并重新初始化地形
        this.initializeTerrain();
        this.units = [];
        this.render();
    }
    
    clearMap() {
        this.initializeTerrain();
        this.units = [];
        this.render();
    }
    
    fillGrass() {
        for (let y = 0; y < this.mapHeight; y++) {
            for (let x = 0; x < this.mapWidth; x++) {
                this.setTerrain(x, y, this.mapType === 'outdoor' ? 'grass' : 'floor');
            }
        }
        this.render();
    }
    
    saveMap() {
        const mapData = {
            mapType: this.mapType,
            terrain: this.terrain,
            units: this.units,
            version: '1.0'
        };
        
        localStorage.setItem('savedMap', JSON.stringify(mapData));
        alert('地图已保存到本地存储！');
    }
    
    loadMap() {
        const savedData = localStorage.getItem('savedMap');
        if (!savedData) {
            alert('没有找到保存的地图！');
            return;
        }
        
        try {
            const mapData = JSON.parse(savedData);
            this.mapType = mapData.mapType || 'outdoor';
            this.terrain = mapData.terrain;
            this.units = mapData.units || [];
            
            document.getElementById('mapType').value = this.mapType;
            document.getElementById('currentMapType').textContent = this.mapType === 'outdoor' ? '室外' : '室内';
            
            this.render();
            alert('地图加载成功！');
        } catch (e) {
            alert('地图数据损坏，无法加载！');
        }
    }
    
    exportMap() {
        const mapData = {
            mapType: this.mapType,
            terrain: this.terrain,
            units: this.units,
            version: '1.0'
        };
        
        const jsonStr = JSON.stringify(mapData, null, 2);
        const blob = new Blob([jsonStr], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = 'map_' + Date.now() + '.json';
        a.click();
        
        URL.revokeObjectURL(url);
    }
    
    applyToGame() {
        if (typeof game !== 'undefined') {
            // 更新游戏的地形和单位
            game.mapType = this.mapType;
            game.terrain = JSON.parse(JSON.stringify(this.terrain));
            
            // 创建游戏单位
            game.units = [];
            this.units.forEach(unit => {
                game.units.push({
                    ...unit,
                    currentHp: unit.stats.hp,
                    maxHp: unit.stats.hp,
                    mp: unit.type === 'holy' ? 0 : 20,
                    maxMp: unit.type === 'holy' ? 0 : 25,
                    hasMoved: false,
                    hasAttacked: false,
                    statusEffects: [],
                    castingSpell: null,
                    castTimeRemaining: 0
                });
            });
            
            // 重置游戏状态
            game.currentTurn = 1;
            game.currentPlayer = 'player';
            game.selectedUnit = null;
            
            // 更新UI
            document.getElementById('currentTurn').textContent = '回合: 1';
            document.getElementById('currentPlayer').textContent = '当前行动: 玩家';
            
            game.render();
            game.log('自定义地图已加载到游戏！', 'system');
            
            // 关闭编辑器
            closeEditor();
        } else {
            alert('游戏未初始化，无法应用地图！');
        }
    }
    
    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // 绘制地形
        this.drawTerrain();
        
        // 绘制单位
        this.drawUnits();
        
        // 绘制网格线
        this.drawGrid();
    }
    
    drawTerrain() {
        for (let y = 0; y < this.mapHeight; y++) {
            for (let x = 0; x < this.mapWidth; x++) {
                const terrain = this.terrain[y][x];
                const px = x * this.gridSize;
                const py = y * this.gridSize;
                
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
                
                // 防御加成标记
                if (terrain.defBonus > 0) {
                    this.ctx.fillStyle = '#ffd700';
                    this.ctx.font = '12px Arial';
                    this.ctx.fillText(`+${terrain.defBonus}`, px + 2, py + 12);
                }
            }
        }
    }
    
    drawUnits() {
        this.units.forEach(unit => {
            const px = unit.x * this.gridSize + this.gridSize / 2;
            const py = unit.y * this.gridSize + this.gridSize / 2;
            const radius = this.gridSize / 2 - 4;
            
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
            
            // 单位名称
            this.ctx.fillStyle = '#fff';
            this.ctx.font = '10px Arial';
            this.ctx.textAlign = 'center';
            this.ctx.fillText(unit.name.substring(0, 3), px, py + 4);
        });
    }
    
    drawGrid() {
        this.ctx.strokeStyle = 'rgba(0, 0, 0, 0.2)';
        this.ctx.lineWidth = 1;
        
        for (let x = 0; x <= this.mapWidth; x++) {
            this.ctx.beginPath();
            this.ctx.moveTo(x * this.gridSize, 0);
            this.ctx.lineTo(x * this.gridSize, this.mapHeight * this.gridSize);
            this.ctx.stroke();
        }
        
        for (let y = 0; y <= this.mapHeight; y++) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y * this.gridSize);
            this.ctx.lineTo(this.mapWidth * this.gridSize, y * this.gridSize);
            this.ctx.stroke();
        }
    }
    
    updateToolDisplay() {
        const toolNames = {
            'grass': '草地', 'water': '水域', 'mountain': '山地', 'fire': '燃烧',
            'ice': '冰冻', 'rock': '石柱', 'wall': '墙壁', 'floor': '地板',
            'player_fire': '玩家火法师', 'player_ice': '玩家冰法师',
            'player_holy': '玩家神官', 'player_ancient': '玩家古代法师',
            'player_physical': '玩家骑士', 'enemy_fire': '敌方火法师',
            'enemy_ice': '敌方冰法师', 'enemy_holy': '敌方神官',
            'enemy_physical': '敌方战士'
        };
        
        document.getElementById('currentTool').textContent = toolNames[this.currentType] || this.currentType;
    }
}

// 初始化编辑器
let editor;

function openEditor() {
    editor = new MapEditor();
    document.getElementById('editorModal').classList.add('active');
}

function closeEditor() {
    document.getElementById('editorModal').classList.remove('active');
}

function selectTool(tool, type) {
    if (!editor) return;
    
    editor.currentTool = tool;
    editor.currentType = type;
    editor.updateToolDisplay();
    
    // 更新按钮状态
    document.querySelectorAll('.tool-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tool === tool && btn.dataset.type === type) {
            btn.classList.add('active');
        }
    });
}

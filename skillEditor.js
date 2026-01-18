// 技能树编辑器
class SkillTreeEditor {
    constructor() {
        this.canvas = document.getElementById('skillTreeCanvas');
        this.ctx = this.canvas.getContext('2d');

        this.currentSystem = 'natural';
        this.currentTool = 'select';
        this.selectedNode = null;
        this.connectingNode = null;
        this.draggingNode = null;
        this.dragOffset = { x: 0, y: 0 };

        this.nodes = [];
        this.connections = [];

        // 初始化三大体系的技能树
        this.trees = {
            natural: { nodes: [], connections: [] },
            holy: { nodes: [], connections: [] },
            ancient: { nodes: [], connections: [] }
        };

        // 生成默认技能树
        this.generateDefaultTrees();

        // 尝试自动加载保存的技能树
        this.autoLoadSavedTrees();

        this.setupEventListeners();
        this.render();
        this.updateNodeCount();
    }

    autoLoadSavedTrees() {
        const systems = ['natural', 'holy', 'ancient'];
        let loadedCount = 0;

        systems.forEach(system => {
            const savedData = localStorage.getItem('skillTree_' + system);
            if (savedData) {
                try {
                    const data = JSON.parse(savedData);
                    this.trees[system].nodes = data.nodes;
                    this.trees[system].connections = data.connections;
                    loadedCount++;
                } catch (e) {
                    console.error(`加载 ${system} 技能树失败:`, e);
                }
            }
        });

        if (loadedCount > 0) {
            console.log(`已自动加载 ${loadedCount} 个技能树`);
            // 重新加载当前系统
            this.loadSystem(this.currentSystem);
        }
    }
    
    generateDefaultTrees() {
        // 自然魔法体系 - 环形结构
        const centerX = 450, centerY = 350;
        
        // 核心层 - 四元素基础魔法
        const coreNodes = [
            { id: 'fire_base', name: '火球术', type: 'basic', element: 'fire', x: centerX, y: centerY - 150, cost: 1, effect: '造成火焰伤害' },
            { id: 'ice_base', name: '冰锥术', type: 'basic', element: 'ice', x: centerX + 150, y: centerY - 50, cost: 1, effect: '造成冰冻伤害' },
            { id: 'wind_base', name: '风刃术', type: 'basic', element: 'wind', x: centerX + 100, y: centerY + 120, cost: 1, effect: '造成风刃伤害' },
            { id: 'thunder_base', name: '雷击术', type: 'basic', element: 'thunder', x: centerX - 100, y: centerY + 120, cost: 1, effect: '造成雷击伤害' }
        ];
        
        // 内层 - 元素强化
        const innerNodes = [
            { id: 'fire_enhance', name: '火焰精通', type: 'advanced', element: 'fire', x: centerX - 80, y: centerY - 120, cost: 3, effect: '提升火焰魔法伤害' },
            { id: 'ice_enhance', name: '冰霜精通', type: 'advanced', element: 'ice', x: centerX + 120, y: centerY - 100, cost: 3, effect: '提升冰冻魔法伤害' },
            { id: 'wind_enhance', name: '风暴精通', type: 'advanced', element: 'wind', x: centerX + 80, y: centerY + 80, cost: 3, effect: '提升风刃魔法伤害' },
            { id: 'thunder_enhance', name: '雷霆精通', type: 'advanced', element: 'thunder', x: centerX - 120, y: centerY + 80, cost: 3, effect: '提升雷击魔法伤害' }
        ];
        
        // 中层 - 高级技能
        const middleNodes = [
            { id: 'fire_burst', name: '烈焰爆发', type: 'expert', element: 'fire', x: centerX - 140, y: centerY - 180, cost: 5, effect: '大范围火焰伤害' },
            { id: 'ice_storm', name: '冰封风暴', type: 'expert', element: 'ice', x: centerX + 180, y: centerY - 120, cost: 5, effect: '大范围冰冻控制' },
            { id: 'wind_tornado', name: '狂风', type: 'expert', element: 'wind', x: centerX + 140, y: centerY + 150, cost: 5, effect: '击退敌人' },
            { id: 'thunder_chain', name: '连锁闪电', type: 'expert', element: 'thunder', x: centerX - 160, y: centerY + 140, cost: 5, effect: '跳跃攻击多个目标' }
        ];
        
        // 外层 - 终极技能与跨系节点
        const outerNodes = [
            { id: 'fire_ultimate', name: '陨石陨落', type: 'ultimate', element: 'fire', x: centerX - 180, y: centerY - 220, cost: 10, effect: '超大范围毁灭性伤害', isCore: true },
            { id: 'ice_ultimate', name: '绝对零度', type: 'ultimate', element: 'ice', x: centerX + 220, y: centerY - 160, cost: 10, effect: '冻结大片区域', isCore: true },
            { id: 'cross_fire_ice', name: '元素共鸣', type: 'cross', element: 'cross', x: centerX + 250, y: centerY - 40, cost: 8, effect: '可学习冰系技能', canUnlockCross: true, hasDebuff: true },
            { id: 'cross_wind_thunder', name: '元素共鸣', type: 'cross', element: 'cross', x: centerX - 200, y: centerY + 20, cost: 8, effect: '可学习雷系技能', canUnlockCross: true, hasDebuff: true }
        ];
        
        this.trees.natural.nodes = [...coreNodes, ...innerNodes, ...middleNodes, ...outerNodes];
        
        // 连接
        this.trees.natural.connections = [
            // 核心→内层
            { from: 'fire_base', to: 'fire_enhance' },
            { from: 'ice_base', to: 'ice_enhance' },
            { from: 'wind_base', to: 'wind_enhance' },
            { from: 'thunder_base', to: 'thunder_enhance' },
            // 内层→中层
            { from: 'fire_enhance', to: 'fire_burst' },
            { from: 'ice_enhance', to: 'ice_storm' },
            { from: 'wind_enhance', to: 'wind_tornado' },
            { from: 'thunder_enhance', to: 'thunder_chain' },
            // 中层→外层
            { from: 'fire_burst', to: 'fire_ultimate' },
            { from: 'ice_storm', to: 'ice_ultimate' },
            { from: 'ice_storm', to: 'cross_fire_ice' },
            { from: 'wind_tornado', to: 'cross_fire_ice' },
            { from: 'thunder_chain', to: 'cross_wind_thunder' }
        ];
        
        // 神圣魔法体系 - 三角形结构
        const triangleCenter = 450, triangleTop = 150;
        
        // 三个角的基础技能
        const holyNodes = [
            { id: 'judgment_base', name: '圣裁', type: 'basic', element: 'judgment', x: triangleCenter, y: triangleTop, cost: 1, effect: '神圣攻击' },
            { id: 'grace_base', name: '祝福', type: 'basic', element: 'grace', x: triangleCenter - 200, y: triangleTop + 250, cost: 1, effect: '提升友军属性' },
            { id: 'redemption_base', name: '治愈', type: 'basic', element: 'redemption', x: triangleCenter + 200, y: triangleTop + 250, cost: 1, effect: '恢复友军生命' },
            // 进阶技能
            { id: 'judgment_adv', name: '神罚', type: 'advanced', element: 'judgment', x: triangleCenter - 50, y: triangleTop + 100, cost: 3, effect: '强力神圣伤害' },
            { id: 'grace_adv', name: '圣盾', type: 'advanced', element: 'grace', x: triangleCenter - 150, y: triangleTop + 180, cost: 3, effect: '增加防御' },
            { id: 'redemption_adv', name: '群体治疗', type: 'advanced', element: 'redemption', x: triangleCenter + 150, y: triangleTop + 180, cost: 3, effect: '治疗多个友军' },
            // 高阶技能
            { id: 'judgment_expert', name: '审判之剑', type: 'expert', element: 'judgment', x: triangleCenter - 100, y: triangleTop + 250, cost: 6, effect: '超远距离攻击' },
            { id: 'grace_expert', name: '神圣护盾', type: 'expert', element: 'grace', x: triangleCenter - 120, y: triangleTop + 320, cost: 6, effect: '全队防御加成' },
            { id: 'redemption_expert', name: '复苏之光', type: 'expert', element: 'redemption', x: triangleCenter + 120, y: triangleTop + 320, cost: 6, effect: '大量恢复生命' },
            // 终极技能
            { id: 'holy_ultimate', name: '三位一体', type: 'ultimate', element: 'holy', x: triangleCenter, y: triangleTop + 380, cost: 12, effect: '攻击+治疗+护盾三重效果', isCore: true }
        ];
        
        this.trees.holy.nodes = holyNodes;
        
        // 三角形连接
        this.trees.holy.connections = [
            // 三个角向外延伸
            { from: 'judgment_base', to: 'judgment_adv' },
            { from: 'grace_base', to: 'grace_adv' },
            { from: 'redemption_base', to: 'redemption_adv' },
            // 向中心汇聚
            { from: 'judgment_adv', to: 'judgment_expert' },
            { from: 'grace_adv', to: 'grace_expert' },
            { from: 'redemption_adv', to: 'redemption_expert' },
            // 汇聚到终极
            { from: 'judgment_expert', to: 'holy_ultimate' },
            { from: 'grace_expert', to: 'holy_ultimate' },
            { from: 'redemption_expert', to: 'holy_ultimate' }
        ];
        
        // 古代魔法体系 - 丰字形结构
        const centerX2 = 450, startY = 100;
        
        const ancientNodes = [
            // 核心主线（纵向）
            { id: 'ancient_base', name: '魔法飞弹', type: 'basic', element: 'ancient', x: centerX2, y: startY, cost: 1, effect: '基础魔法攻击' },
            { id: 'ancient_lv1', name: '裂隙冲击', type: 'advanced', element: 'ancient', x: centerX2, y: startY + 120, cost: 4, effect: '中等范围伤害', castTime: 1 },
            { id: 'ancient_lv2', name: '时空崩坏', type: 'expert', element: 'ancient', x: centerX2, y: startY + 240, cost: 8, effect: '大范围伤害', castTime: 2 },
            { id: 'ancient_ultimate', name: '世界崩塌', type: 'ultimate', element: 'ancient', x: centerX2, y: startY + 360, cost: 16, effect: '毁灭性超大范围伤害', castTime: 3, isCore: true },
            // 支线（横向）
            { id: 'ancient_passive1', name: '咏唱加速', type: 'passive', element: 'ancient', x: centerX2 - 150, y: startY + 120, cost: 2, effect: '减少1回合咏唱时间' },
            { id: 'ancient_passive2', name: '魔法护盾', type: 'passive', element: 'ancient', x: centerX2 + 150, y: startY + 120, cost: 2, effect: '咏唱期间获得护盾' },
            { id: 'ancient_passive3', name: '咏唱保护', type: 'passive', element: 'ancient', x: centerX2 - 150, y: startY + 240, cost: 3, effect: '咏唱时免疫控制' },
            { id: 'ancient_passive4', name: '爆发增幅', type: 'passive', element: 'ancient', x: centerX2 + 150, y: startY + 240, cost: 3, effect: '提升最终伤害20%' }
        ];
        
        this.trees.ancient.nodes = ancientNodes;
        
        // 丰字形连接
        this.trees.ancient.connections = [
            // 主线
            { from: 'ancient_base', to: 'ancient_lv1' },
            { from: 'ancient_lv1', to: 'ancient_lv2' },
            { from: 'ancient_lv2', to: 'ancient_ultimate' },
            // 支线连接
            { from: 'ancient_lv1', to: 'ancient_passive1' },
            { from: 'ancient_lv1', to: 'ancient_passive2' },
            { from: 'ancient_lv2', to: 'ancient_passive3' },
            { from: 'ancient_lv2', to: 'ancient_passive4' }
        ];
        
        // 加载初始体系
        this.loadSystem('natural');
    }
    
    selectSystem(system) {
        this.currentSystem = system;
        
        // 更新按钮状态
        document.querySelectorAll('.system-btn').forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.system === system) {
                btn.classList.add('active');
            }
        });
        
        this.loadSystem(system);
        this.render();
        this.updateNodeCount();
        this.updateSystemDisplay();
    }
    
    loadSystem(system) {
        // 优先使用保存的技能树数据
        const savedData = localStorage.getItem('skillTree_' + system);
        if (savedData) {
            try {
                const data = JSON.parse(savedData);
                this.nodes = data.nodes;
                this.connections = data.connections;
            } catch (e) {
                // 如果加载失败，使用默认数据
                this.nodes = JSON.parse(JSON.stringify(this.trees[system].nodes));
                this.connections = JSON.parse(JSON.stringify(this.trees[system].connections));
            }
        } else {
            this.nodes = JSON.parse(JSON.stringify(this.trees[system].nodes));
            this.connections = JSON.parse(JSON.stringify(this.trees[system].connections));
        }
        this.selectedNode = null;
        this.connectingNode = null;
        this.updatePropertiesPanel();
    }
    
    setTool(tool) {
        this.currentTool = tool;
        
        // 更新按钮状态
        document.querySelectorAll('.node-tool-btn').forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.tool === tool) {
                btn.classList.add('active');
            }
        });
        
        this.updateToolDisplay();
    }
    
    setupEventListeners() {
        this.canvas.addEventListener('mousedown', (e) => this.handleMouseDown(e));
        this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e));
        this.canvas.addEventListener('mouseup', (e) => this.handleMouseUp(e));
        this.canvas.addEventListener('mouseleave', () => {
            this.draggingNode = null;
        });
        this.canvas.addEventListener('dblclick', (e) => this.handleDoubleClick(e));
    }
    
    handleMouseDown(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        const clickedNode = this.findNodeAt(x, y);
        
        if (this.currentTool === 'select') {
            if (clickedNode) {
                this.selectedNode = clickedNode;
                this.draggingNode = clickedNode;
                this.dragOffset = { x: x - clickedNode.x, y: y - clickedNode.y };
                this.updatePropertiesPanel();
            } else {
                this.selectedNode = null;
                this.updatePropertiesPanel();
            }
        } else if (this.currentTool === 'add') {
            if (!clickedNode) {
                this.addNode(x, y);
            }
        } else if (this.currentTool === 'delete') {
            if (clickedNode) {
                this.deleteNode(clickedNode);
            }
        } else if (this.currentTool === 'connect') {
            if (clickedNode) {
                if (!this.connectingNode) {
                    this.connectingNode = clickedNode;
                } else {
                    this.connectNodes(this.connectingNode, clickedNode);
                    this.connectingNode = null;
                }
            } else {
                this.connectingNode = null;
            }
        }
        
        this.render();
    }
    
    handleMouseMove(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        if (this.draggingNode) {
            this.draggingNode.x = x - this.dragOffset.x;
            this.draggingNode.y = y - this.dragOffset.y;
            this.render();
        }
        
        // 悬停效果
        const hoveredNode = this.findNodeAt(x, y);
        this.canvas.style.cursor = hoveredNode ? 'pointer' : 'crosshair';
    }
    
    handleMouseUp(e) {
        this.draggingNode = null;
    }
    
    handleDoubleClick(e) {
        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        const clickedNode = this.findNodeAt(x, y);
        if (clickedNode) {
            this.openNodeEdit(clickedNode);
        }
    }
    
    findNodeAt(x, y) {
        for (let i = this.nodes.length - 1; i >= 0; i--) {
            const node = this.nodes[i];
            const radius = 20;
            const dist = Math.sqrt((x - node.x) ** 2 + (y - node.y) ** 2);
            if (dist <= radius) {
                return node;
            }
        }
        return null;
    }
    
    addNode(x, y) {
        const newNode = {
            id: 'node_' + Date.now(),
            name: '新技能',
            type: 'basic',
            element: this.currentSystem === 'holy' ? 'judgment' : 'fire',
            x: x,
            y: y,
            cost: 1,
            effect: '技能效果描述'
        };
        
        this.nodes.push(newNode);
        this.updateNodeCount();
        this.render();
    }
    
    deleteNode(node) {
        // 删除节点
        this.nodes = this.nodes.filter(n => n.id !== node.id);
        
        // 删除相关连接
        this.connections = this.connections.filter(c => c.from !== node.id && c.to !== node.id);
        
        if (this.selectedNode === node) {
            this.selectedNode = null;
            this.updatePropertiesPanel();
        }
        
        this.updateNodeCount();
        this.render();
    }
    
    connectNodes(node1, node2) {
        // 检查是否已存在连接（双向连接只存储一个方向）
        const key = [node1.id, node2.id].sort().join('|');
        const exists = this.connections.some(c => {
            const existingKey = [c.from, c.to].sort().join('|');
            return existingKey === key;
        });

        if (!exists && node1.id !== node2.id) {
            // 只保存一个方向的连接，代表双向
            this.connections.push({ from: node1.id, to: node2.id });
            this.render();
        }
    }
    
    openNodeEdit(node) {
        this.selectedNode = node;

        // 填充表单
        document.getElementById('nodeName').value = node.name;
        document.getElementById('nodeType').value = node.type || 'basic';
        document.getElementById('nodeElement').value = node.element || 'fire';
        document.getElementById('nodeCost').value = node.cost || 1;
        document.getElementById('nodeEffect').value = node.effect || '';
        document.getElementById('nodeDamage').value = node.damage || 0;
        document.getElementById('nodeRange').value = node.range || 1;
        document.getElementById('nodeDuration').value = node.duration || 0;
        document.getElementById('nodeCastTime').value = node.castTime || 0;
        document.getElementById('nodeCooldown').value = node.cooldown || 0;
        document.getElementById('nodeHitRate').value = node.hitRate || 90;
        document.getElementById('nodeCanUnlockCross').checked = node.canUnlockCross || false;
        document.getElementById('nodeHasDebuff').checked = node.hasDebuff || false;
        document.getElementById('nodeIsCore').checked = node.isCore || false;
        document.getElementById('nodeIsPassive').checked = node.isPassive || false;

        // 显示编辑模态框
        document.getElementById('nodeEditModal').classList.add('active');
    }
    
    saveNodeEdit() {
        if (!this.selectedNode) return;

        this.selectedNode.name = document.getElementById('nodeName').value;
        this.selectedNode.type = document.getElementById('nodeType').value;
        this.selectedNode.element = document.getElementById('nodeElement').value;
        this.selectedNode.cost = parseInt(document.getElementById('nodeCost').value);
        this.selectedNode.effect = document.getElementById('nodeEffect').value;
        this.selectedNode.damage = parseInt(document.getElementById('nodeDamage').value);
        this.selectedNode.range = parseInt(document.getElementById('nodeRange').value);
        this.selectedNode.duration = parseInt(document.getElementById('nodeDuration').value);
        this.selectedNode.castTime = parseInt(document.getElementById('nodeCastTime').value);
        this.selectedNode.cooldown = parseInt(document.getElementById('nodeCooldown').value);
        this.selectedNode.hitRate = parseInt(document.getElementById('nodeHitRate').value);
        this.selectedNode.canUnlockCross = document.getElementById('nodeCanUnlockCross').checked;
        this.selectedNode.hasDebuff = document.getElementById('nodeHasDebuff').checked;
        this.selectedNode.isCore = document.getElementById('nodeIsCore').checked;
        this.selectedNode.isPassive = document.getElementById('nodeIsPassive').checked;

        this.updatePropertiesPanel();
        this.render();
        closeNodeEdit();
    }
    
    updatePropertiesPanel() {
        const panel = document.getElementById('nodeProperties');

        if (!this.selectedNode) {
            panel.innerHTML = '<p class="no-selection">选择节点以编辑属性</p>';
            return;
        }

        const node = this.selectedNode;
        const typeNames = {
            basic: '基础技能', advanced: '进阶技能', expert: '高阶技能',
            ultimate: '终极技能', passive: '被动技能', cross: '跨系节点'
        };
        const elementNames = {
            fire: '火', ice: '冰', wind: '风', thunder: '雷',
            judgment: '裁决', grace: '恩典', redemption: '救赎',
            ancient: '古代', holy: '神圣'
        };

        // 获取连接的节点
        const connectedNodes = this.getConnectedNodes(node);

        panel.innerHTML = `
            <div class="property-row"><span>技能名称:</span><span class="property-value">${node.name}</span></div>
            <div class="property-row"><span>技能类型:</span><span class="property-value">${typeNames[node.type] || '未知'}</span></div>
            <div class="property-row"><span>属性:</span><span class="property-value">${elementNames[node.element] || '未知'}</span></div>
            <div class="property-row"><span>技能点:</span><span class="property-value">${node.cost}</span></div>
            <div class="property-row"><span>伤害:</span><span class="property-value">${node.damage || 0}</span></div>
            <div class="property-row"><span>范围:</span><span class="property-value">${node.range || 1}</span></div>
            <div class="property-row"><span>持续时间:</span><span class="property-value">${node.duration || 0}</span></div>
            <div class="property-row"><span>咏唱回合:</span><span class="property-value">${node.castTime || 0}</span></div>
            <div class="property-row"><span>冷却回合:</span><span class="property-value">${node.cooldown || 0}</span></div>
            <div class="property-row"><span>命中率:</span><span class="property-value">${node.hitRate || 90}%</span></div>
            <div class="property-row"><span>效果:</span><span class="property-value">${node.effect || '无'}</span></div>
            <div class="property-row"><span>跨系解锁:</span><span class="property-value">${node.canUnlockCross ? '是' : '否'}</span></div>
            <div class="property-row"><span>负面效果:</span><span class="property-value">${node.hasDebuff ? '有' : '无'}</span></div>
            <div class="property-row"><span>核心技能:</span><span class="property-value">${node.isCore ? '是' : '否'}</span></div>
            <div class="property-row"><span>被动效果:</span><span class="property-value">${node.isPassive ? '是' : '否'}</span></div>
            ${connectedNodes.length > 0 ? `<div class="property-row"><span>连接节点:</span><span class="property-value">${connectedNodes.map(n => n.name).join(', ')}</span></div>` : ''}
            <button class="action-btn" onclick="skillEditor.openNodeEdit(skillEditor.selectedNode)" style="margin-top: 10px;">✏️ 编辑节点</button>
            <button class="action-btn" onclick="skillEditor.deleteNode(skillEditor.selectedNode)" style="margin-top: 5px;">🗑️ 删除节点</button>
        `;
    }

    getConnectedNodes(node) {
        const connectedNodeIds = new Set();
        this.connections.forEach(conn => {
            if (conn.from === node.id) {
                connectedNodeIds.add(conn.to);
            }
            if (conn.to === node.id) {
                connectedNodeIds.add(conn.from);
            }
        });
        return this.nodes.filter(n => connectedNodeIds.has(n.id));
    }

    addBidirectionalConnection() {
        if (!this.selectedNode) {
            alert('请先选择一个节点！');
            return;
        }

        const node1 = this.selectedNode;
        const connectedNodes = this.getConnectedNodes(node1);

        if (connectedNodes.length === 0) {
            alert('该节点没有连接到其他节点！');
            return;
        }

        if (connectedNodes.length === 1) {
            this.createConnection(node1, connectedNodes[0]);
        } else {
            // 显示连接节点选择
            const nodeNames = connectedNodes.map(n => n.name);
            const index = prompt(`选择要连接的节点:\n${nodeNames.map((n, i) => `${i + 1}. ${n}`).join('\n')}\n\n请输入序号 (1-${connectedNodes.length}):`);
            const selectedIndex = parseInt(index) - 1;

            if (selectedIndex >= 0 && selectedIndex < connectedNodes.length) {
                this.createConnection(node1, connectedNodes[selectedIndex]);
            }
        }
    }

    createConnection(node1, node2) {
        // 检查是否已存在连接
        const key = [node1.id, node2.id].sort().join('|');
        const exists = this.connections.some(c => {
            const existingKey = [c.from, c.to].sort().join('|');
            return existingKey === key;
        });

        if (exists) {
            alert('已经存在连接！');
            return;
        }

        // 创建双向连接（只保存一个方向）
        this.connections.push({ from: node1.id, to: node2.id });
        alert(`已创建 ${node1.name} ↔ ${node2.name} 的连接！`);
        this.updatePropertiesPanel();
        this.render();
    }

    removeConnections() {
        if (!this.selectedNode) {
            alert('请先选择一个节点！');
            return;
        }

        const node = this.selectedNode;
        const connectedNodes = this.getConnectedNodes(node);

        if (connectedNodes.length === 0) {
            alert('该节点没有连接！');
            return;
        }

        if (confirm(`确定要删除 ${node.name} 的所有连接吗？`)) {
            // 删除所有与该节点相关的连接
            const initialCount = this.connections.length;
            this.connections = this.connections.filter(c => c.from !== node.id && c.to !== node.id);

            const removedCount = initialCount - this.connections.length;
            alert(`已删除 ${removedCount} 个连接！`);
            this.updatePropertiesPanel();
            this.render();
        }
    }
    
    saveTree() {
        this.trees[this.currentSystem].nodes = JSON.parse(JSON.stringify(this.nodes));
        this.trees[this.currentSystem].connections = JSON.parse(JSON.stringify(this.connections));
        
        localStorage.setItem('skillTree_' + this.currentSystem, JSON.stringify({
            nodes: this.nodes,
            connections: this.connections
        }));
        
        alert(`${this.getSystemName(this.currentSystem)}技能树已保存！`);
    }
    
    loadTree() {
        const savedData = localStorage.getItem('skillTree_' + this.currentSystem);
        if (!savedData) {
            alert('没有找到保存的技能树！');
            return;
        }
        
        try {
            const data = JSON.parse(savedData);
            this.nodes = data.nodes;
            this.connections = data.connections;
            this.trees[this.currentSystem].nodes = JSON.parse(JSON.stringify(this.nodes));
            this.trees[this.currentSystem].connections = JSON.parse(JSON.stringify(this.connections));
            
            this.render();
            alert('技能树加载成功！');
        } catch (e) {
            alert('技能树数据损坏！');
        }
    }
    
    exportTree() {
        const treeData = {
            system: this.currentSystem,
            nodes: this.nodes,
            connections: this.connections,
            version: '1.0'
        };
        
        const jsonStr = JSON.stringify(treeData, null, 2);
        const blob = new Blob([jsonStr], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `skilltree_${this.currentSystem}_${Date.now()}.json`;
        a.click();
        
        URL.revokeObjectURL(url);
    }
    
    resetTree() {
        if (confirm('确定要重置当前技能树吗？这将恢复到默认状态。')) {
            this.generateDefaultTrees();
            this.loadSystem(this.currentSystem);
            this.render();
            this.updateNodeCount();
        }
    }
    
    render() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // 绘制背景网格
        this.drawGrid();
        
        // 绘制连接线
        this.drawConnections();
        
        // 绘制节点
        this.drawNodes();
        
        // 绘制连接预览
        if (this.connectingNode && this.currentTool === 'connect') {
            this.ctx.strokeStyle = '#ffd700';
            this.ctx.lineWidth = 3;
            this.ctx.setLineDash([5, 5]);
            this.ctx.beginPath();
            this.ctx.arc(this.connectingNode.x, this.connectingNode.y, 20, 0, Math.PI * 2);
            this.ctx.stroke();
            this.ctx.setLineDash([]);
        }
    }
    
    drawGrid() {
        this.ctx.strokeStyle = 'rgba(255, 215, 0, 0.1)';
        this.ctx.lineWidth = 1;
        
        for (let x = 0; x <= this.canvas.width; x += 50) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, this.canvas.height);
            this.ctx.stroke();
        }
        
        for (let y = 0; y <= this.canvas.height; y += 50) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(this.canvas.width, y);
            this.ctx.stroke();
        }
    }
    
    drawConnections() {
        // 去重连接（只保留唯一的双向连接对）
        const uniqueConnections = new Set();
        this.connections.forEach(conn => {
            const key = [conn.from, conn.to].sort().join('|');
            uniqueConnections.add(key);
        });

        uniqueConnections.forEach(key => {
            const [fromId, toId] = key.split('|');
            const fromNode = this.nodes.find(n => n.id === fromId);
            const toNode = this.nodes.find(n => n.id === toId);

            if (fromNode && toNode) {
                // 检查是否是不可学习的连接（任一节点 cost 为 -1）
                const isUnlearnable = fromNode.cost === -1 || toNode.cost === -1;

                // 可学习连接用金色，不可学习用红色
                this.ctx.strokeStyle = isUnlearnable ? '#FF4444' : '#FFD700';
                this.ctx.lineWidth = 3;

                // 绘制直线连接（无箭头）
                this.ctx.beginPath();
                this.ctx.moveTo(fromNode.x, fromNode.y);
                this.ctx.lineTo(toNode.x, toNode.y);
                this.ctx.stroke();
            }
        });
    }
    
    drawNodes() {
        this.nodes.forEach(node => {
            const isSelected = this.selectedNode && this.selectedNode.id === node.id;

            // 节点颜色根据类型
            let color;
            switch (node.type) {
                case 'basic': color = '#4CAF50'; break;
                case 'advanced': color = '#2196F3'; break;
                case 'expert': color = '#9C27B0'; break;
                case 'ultimate': color = '#FFD700'; break;
                case 'passive': color = '#607D8B'; break;
                case 'cross': color = '#FF5722'; break;
                default: color = '#9E9E9E';
            }

            // 不可学习的节点用灰色
            if (node.cost === -1) {
                color = '#666666';
            }

            // 绘制节点圆
            this.ctx.beginPath();
            this.ctx.arc(node.x, node.y, 25, 0, Math.PI * 2);
            this.ctx.fillStyle = color;
            this.ctx.fill();

            // 选中效果
            if (isSelected) {
                this.ctx.strokeStyle = '#fff';
                this.ctx.lineWidth = 4;
                this.ctx.stroke();

                // 发光效果
                this.ctx.shadowColor = '#ffd700';
                this.ctx.shadowBlur = 20;
                this.ctx.stroke();
                this.ctx.shadowBlur = 0;
            } else {
                this.ctx.strokeStyle = '#fff';
                this.ctx.lineWidth = 2;
                this.ctx.stroke();
            }

            // 核心技能标记
            if (node.isCore) {
                this.ctx.fillStyle = '#fff';
                this.ctx.font = '14px Arial';
                this.ctx.textAlign = 'center';
                this.ctx.textBaseline = 'middle';
                this.ctx.fillText('⭐', node.x, node.y);
            }

            // 跨系标记
            if (node.canUnlockCross) {
                this.ctx.fillStyle = '#fff';
                this.ctx.font = '10px Arial';
                this.ctx.fillText('🔄', node.x, node.y + 35);
            }

            // 技能名称
            this.ctx.fillStyle = '#fff';
            this.ctx.font = 'bold 10px Arial';
            this.ctx.textAlign = 'center';
            this.ctx.fillText(node.name.substring(0, 5), node.x, node.y);

            // 技能点（显示 -1 或实际点数）
            this.ctx.font = '8px Arial';
            const costText = node.cost === -1 ? '不可学' : `${node.cost}点`;
            this.ctx.fillText(costText, node.x, node.y + 12);
        });
    }
    
    updateNodeCount() {
        document.getElementById('nodeCount').textContent = this.nodes.length;
    }
    
    updateToolDisplay() {
        const toolNames = {
            select: '选择/查看',
            add: '添加节点',
            delete: '删除节点',
            connect: '连接节点'
        };
        document.getElementById('currentSkillTool').textContent = toolNames[this.currentTool];
    }
    
    updateSystemDisplay() {
        document.getElementById('currentSystem').textContent = this.getSystemName(this.currentSystem);
    }
    
    getSystemName(system) {
        const names = {
            natural: '自然魔法',
            holy: '神圣魔法',
            ancient: '古代魔法'
        };
        return names[system] || system;
    }
}

// 全局函数
let skillEditor;

function openSkillEditor() {
    if (!skillEditor) {
        skillEditor = new SkillTreeEditor();
    }
    document.getElementById('skillEditorModal').classList.add('active');
}

function closeSkillEditor() {
    document.getElementById('skillEditorModal').classList.remove('active');
}

function closeNodeEdit() {
    document.getElementById('nodeEditModal').classList.remove('active');
}

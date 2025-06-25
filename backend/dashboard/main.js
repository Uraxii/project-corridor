// Global state
let ws = null;
let entities = new Map(); // entityId -> entity data
let entitiesByInstance = new Map(); // instanceId -> Map(entityId -> entity)
let currentInstanceId = 1;

// Utility functions
function log(message, type = 'info') {
    const messages = document.getElementById('messages');
    const timestamp = new Date().toLocaleTimeString();
    const color = type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#495057';
    messages.innerHTML += `<div style="color: ${color}">[${timestamp}] ${message}</div>`;
    messages.scrollTop = messages.scrollHeight;
}

function updateConnectionUI(connected) {
    const status = document.getElementById('status');
    const connectBtn = document.getElementById('connectBtn');
    
    if (connected) {
        status.textContent = 'Connected';
        status.className = 'status connected';
        connectBtn.textContent = 'Disconnect';
    } else {
        status.textContent = 'Disconnected';
        status.className = 'status disconnected';
        connectBtn.textContent = 'Connect';
    }
}

// Connection management
function toggleConnection() {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.close();
    } else {
        connect();
    }
}

function connect() {
    const url = document.getElementById('serverUrl').value;
    log(`Connecting to ${url}...`);
    
    ws = new WebSocket(url);
    
    ws.onopen = function() {
        updateConnectionUI(true);
        log('Connected to server!', 'success');
        
        // Send a hello message
        sendChatMessage('Hello from web client!');
    };
    
    ws.onclose = function() {
        updateConnectionUI(false);
        log('Disconnected from server', 'error');
    };
    
    ws.onerror = function(error) {
        log(`Connection error: ${error}`, 'error');
    };
    
    ws.onmessage = function(event) {
        try {
            if (event.data instanceof ArrayBuffer) {
                // Handle binary protobuf messages (would need protobuf.js)
                log('Received binary message (protobuf parsing not implemented in this demo)');
            } else {
                // Handle text messages for basic testing
                log(`Received: ${event.data}`, 'success');
            }
        } catch (error) {
            log(`Error processing message: ${error}`, 'error');
        }
    };
}

function sendChatMessage(content) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        // Send as text message for testing
        const message = {
            type: 'chat',
            content: content,
            timestamp: Date.now()
        };
        ws.send(JSON.stringify(message));
        log(`Sent chat: ${content}`);
    } else {
        log('Not connected to server', 'error');
    }
}

// Instance management
function switchInstance() {
    const newInstanceId = parseInt(document.getElementById('instanceId').value);
    currentInstanceId = newInstanceId;
    document.getElementById('currentInstance').textContent = `Current: ${newInstanceId}`;
    document.getElementById('entityInstanceDisplay').textContent = newInstanceId;
    log(`Switched to instance ${newInstanceId}`);
    updateEntityDisplay();
}

// Entity creation helpers
function createMockEntity(name, model, state, x, y, z, stats, equippedItems = []) {
    const entityId = Math.floor(Math.random() * 100000) + 1;
    return {
        authorityId: 0,
        entityId: entityId,
        instanceId: currentInstanceId,
        displayName: name,
        model: model,
        state: state,
        position: { x, y, z },
        equippedItemIds: equippedItems,
        stats: stats
    };
}

function spawnEntityLocal(entity) {
    entities.set(entity.entityId, entity);
    
    if (!entitiesByInstance.has(entity.instanceId)) {
        entitiesByInstance.set(entity.instanceId, new Map());
    }
    entitiesByInstance.get(entity.instanceId).set(entity.entityId, entity);
    
    updateEntityDisplay();
}

// Entity spawning functions
function spawnPlayer() {
    const name = document.getElementById('playerName').value || 'TestPlayer';
    const x = parseFloat(document.getElementById('playerX').value) || 0;
    const y = parseFloat(document.getElementById('playerY').value) || 0;
    const z = parseFloat(document.getElementById('playerZ').value) || 0;
    
    const entity = createMockEntity(name, 'player_character.glb', 'idle', x, y, z, {
        health: { current: 100, max: 100, extra: 0 },
        energy: { current: 100, max: 100, extra: 0 },
        vigor: { current: 10, max: 10, extra: 0 },
        strength: { current: 10, max: 10, extra: 0 },
        agility: { current: 10, max: 10, extra: 0 },
        intelligence: { current: 10, max: 10, extra: 0 }
    });
    
    spawnEntityLocal(entity);
    log(`Spawned player: ${name} at (${x}, ${y}, ${z}) in instance ${currentInstanceId}`, 'success');
}

function spawnWarrior() {
    const name = document.getElementById('warriorName').value || 'GuardCaptain';
    const x = parseFloat(document.getElementById('warriorX').value) || 5;
    const y = parseFloat(document.getElementById('warriorY').value) || 0;
    const z = parseFloat(document.getElementById('warriorZ').value) || 5;
    
    const entity = createMockEntity(name, 'warrior_npc.glb', 'patrol', x, y, z, {
        health: { current: 150, max: 150, extra: 0 },
        energy: { current: 80, max: 80, extra: 0 },
        vigor: { current: 15, max: 15, extra: 0 },
        strength: { current: 20, max: 20, extra: 5 },
        agility: { current: 12, max: 12, extra: 0 },
        intelligence: { current: 8, max: 8, extra: 0 }
    }, [1001, 2003]);
    
    spawnEntityLocal(entity);
    log(`Spawned warrior: ${name} at (${x}, ${y}, ${z}) in instance ${currentInstanceId}`, 'success');
}

function spawnMage() {
    const name = document.getElementById('mageName').value || 'CourtWizard';
    const x = parseFloat(document.getElementById('mageX').value) || -5;
    const y = parseFloat(document.getElementById('mageY').value) || 0;
    const z = parseFloat(document.getElementById('mageZ').value) || -5;
    
    const entity = createMockEntity(name, 'mage_npc.glb', 'casting', x, y, z, {
        health: { current: 80, max: 80, extra: 0 },
        energy: { current: 150, max: 150, extra: 20 },
        vigor: { current: 8, max: 8, extra: 0 },
        strength: { current: 6, max: 6, extra: 0 },
        agility: { current: 14, max: 14, extra: 0 },
        intelligence: { current: 25, max: 25, extra: 10 }
    }, [3001, 4002]);
    
    spawnEntityLocal(entity);
    log(`Spawned mage: ${name} at (${x}, ${y}, ${z}) in instance ${currentInstanceId}`, 'success');
}

function spawnTreasure() {
    const x = parseFloat(document.getElementById('treasureX').value) || 10;
    const y = parseFloat(document.getElementById('treasureY').value) || 0;
    const z = parseFloat(document.getElementById('treasureZ').value) || 10;
    
    const entity = createMockEntity('Treasure Chest', 'treasure_chest.glb', 'closed', x, y, z, {
        durability: { current: 100, max: 100, extra: 0 }
    });
    
    spawnEntityLocal(entity);
    log(`Spawned treasure chest at (${x}, ${y}, ${z}) in instance ${currentInstanceId}`, 'success');
}

// Entity management functions
function despawnEntity() {
    const entityId = parseInt(document.getElementById('targetEntityId').value);
    const instanceId = parseInt(document.getElementById('targetInstanceId').value) || currentInstanceId;
    
    if (!entityId) {
        log('Please enter an entity ID', 'error');
        return;
    }
    
    entities.delete(entityId);
    if (entitiesByInstance.has(instanceId)) {
        entitiesByInstance.get(instanceId).delete(entityId);
        if (entitiesByInstance.get(instanceId).size === 0) {
            entitiesByInstance.delete(instanceId);
        }
    }
    
    updateEntityDisplay();
    log(`Despawned entity ${entityId} from instance ${instanceId}`, 'success');
}

function requestEntityUpdate() {
    const entityId = parseInt(document.getElementById('targetEntityId').value);
    const instanceId = parseInt(document.getElementById('targetInstanceId').value) || currentInstanceId;
    
    if (!entityId) {
        log('Please enter an entity ID', 'error');
        return;
    }
    
    const entity = entities.get(entityId);
    if (entity && entity.instanceId === instanceId) {
        // Simulate updating entity stats
        if (entity.stats.health) {
            entity.stats.health.current = Math.max(0, entity.stats.health.current - 10);
        }
        updateEntityDisplay();
        log(`Updated entity ${entityId} in instance ${instanceId}`, 'success');
    } else {
        log(`Entity ${entityId} not found in instance ${instanceId}`, 'error');
    }
}

function listAllInstances() {
    log('=== All Instances ===');
    if (entitiesByInstance.size === 0) {
        log('No instances with entities found');
        return;
    }
    
    for (const [instanceId, instanceEntities] of entitiesByInstance) {
        const marker = instanceId === currentInstanceId ? ' <-- CURRENT' : '';
        log(`Instance ${instanceId}: ${instanceEntities.size} entities${marker}`);
    }
}

function listCurrentInstance() {
    log(`=== Current Instance: ${currentInstanceId} ===`);
    const instanceEntities = entitiesByInstance.get(currentInstanceId);
    if (!instanceEntities || instanceEntities.size === 0) {
        log('No entities in current instance');
        return;
    }
    
    for (const entity of instanceEntities.values()) {
        log(`- ${entity.displayName} (ID: ${entity.entityId}) at (${entity.position.x}, ${entity.position.y}, ${entity.position.z})`);
    }
}

function clearCurrentInstance() {
    const instanceEntities = entitiesByInstance.get(currentInstanceId);
    if (instanceEntities) {
        for (const entityId of instanceEntities.keys()) {
            entities.delete(entityId);
        }
        entitiesByInstance.delete(currentInstanceId);
        updateEntityDisplay();
        log(`Cleared all entities from instance ${currentInstanceId}`, 'success');
    } else {
        log(`No entities in instance ${currentInstanceId}`, 'error');
    }
}

// Display functions
function updateEntityDisplay() {
    const entityList = document.getElementById('entityList');
    const instanceEntities = entitiesByInstance.get(currentInstanceId);
    
    if (!instanceEntities || instanceEntities.size === 0) {
        entityList.innerHTML = '<p class="text-muted">No entities in this instance</p>';
        return;
    }
    
    let html = '';
    for (const entity of instanceEntities.values()) {
        html += createEntityHTML(entity);
    }
    
    entityList.innerHTML = html;
}

function createEntityHTML(entity) {
    let statsHTML = '';
    for (const [statName, stat] of Object.entries(entity.stats)) {
        const percentage = stat.max > 0 ? (stat.current / stat.max) * 100 : 0;
        const statClass = statName === 'health' ? 'health' : statName === 'energy' ? 'energy' : 'other-stat';
        
        statsHTML += `
            <div>
                <small>${statName.charAt(0).toUpperCase() + statName.slice(1)}: ${stat.current}/${stat.max} ${stat.extra > 0 ? `(+${stat.extra})` : ''}</small>
                <div class="stat-bar">
                    <div class="stat-fill ${statClass}" style="width: ${percentage}%"></div>
                </div>
            </div>
        `;
    }
    
    const equippedHTML = entity.equippedItemIds.length > 0 ? 
        `<div><small>🎒 Equipped: ${entity.equippedItemIds.join(', ')}</small></div>` : '';
    
    return `
        <div class="entity-item">
            <div class="entity-header">
                ${entity.displayName} (ID: ${entity.entityId})
            </div>
            <div class="entity-details">
                <div><small>📍 Position: (${entity.position.x}, ${entity.position.y}, ${entity.position.z})</small></div>
                <div><small>🎭 State: ${entity.state}</small></div>
                <div><small>🎨 Model: ${entity.model}</small></div>
                <div><small>⚡ Authority: ${entity.authorityId}</small></div>
                ${equippedHTML}
                ${statsHTML}
            </div>
        </div>
    `;
}

function clearMessages() {
    document.getElementById('messages').innerHTML = '';
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    updateEntityDisplay();
    updateConnectionUI(false);
});
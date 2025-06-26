// Entity-specific JavaScript functionality
class EntityManager {
    constructor() {
        this.currentForms = {};
        this.apiBase = '/entity/api';
    }

    /**
     * Initialize entity management
     */
    init(schemas) {
        // Initialize form generator with schemas
        FormGenerator.init(schemas);
        
        // Generate entity-related forms
        this.generateEntityForms();
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Start message refresh
        this.startMessageRefresh();
        
        console.log('Entity Manager initialized');
    }

    /**
     * Generate forms for entity-related message types
     */
    generateEntityForms() {
        const entityMessageTypes = FormGenerator.messageTypes.filter(type => 
            type.includes('Entity') || type.includes('Spawn')
        );

        console.log('Generating forms for entity types:', entityMessageTypes);

        // Generate spawn form
        if (entityMessageTypes.includes('SpawnEntityMessage')) {
            const spawnFormId = FormGenerator.generateForm('SpawnEntityMessage', 'spawnFormContainer', {
                title: 'Spawn Entity',
                formId: 'spawnEntityForm'
            });
            this.currentForms.spawn = spawnFormId;
        }

        // Generate update form
        if (entityMessageTypes.includes('EntityUpdateMessage')) {
            const updateFormId = FormGenerator.generateForm('EntityUpdateMessage', 'updateFormContainer', {
                title: 'Update Entity',
                formId: 'updateEntityForm'
            });
            this.currentForms.update = updateFormId;
        }

        // Generate despawn form
        if (entityMessageTypes.includes('EntityDespawnMessage')) {
            const despawnFormId = FormGenerator.generateForm('EntityDespawnMessage', 'despawnFormContainer', {
                title: 'Despawn Entity',
                formId: 'despawnEntityForm'
            });
            this.currentForms.despawn = despawnFormId;
        }
    }

    /**
     * Set up event listeners
     */
    setupEventListeners() {
        // Listen for schema form submissions
        document.addEventListener('schemaFormSubmit', (event) => {
            this.handleFormSubmit(event.detail);
        });

        // Set up custom form handlers
        this.setupCustomHandlers();
    }

    /**
     * Set up custom form handlers for specific actions
     */
    setupCustomHandlers() {
        // Quick spawn button
        const quickSpawnBtn = document.getElementById('quickSpawnBtn');
        if (quickSpawnBtn) {
            quickSpawnBtn.addEventListener('click', () => this.quickSpawn());
        }

        // Quick despawn button
        const quickDespawnBtn = document.getElementById('quickDespawnBtn');
        if (quickDespawnBtn) {
            quickDespawnBtn.addEventListener('click', () => this.quickDespawn());
        }
    }

    /**
     * Handle form submission
     */
    async handleFormSubmit(detail) {
        const { messageType, formData, formId } = detail;
        
        console.log(`Submitting ${messageType}:`, formData);
        
        let endpoint;
        switch (messageType) {
            case 'SpawnEntityMessage':
                endpoint = '/spawn';
                break;
            case 'EntityUpdateMessage':
                endpoint = '/update';
                break;
            case 'EntityDespawnMessage':
                endpoint = '/despawn';
                break;
            default:
                endpoint = '/send';
        }

        const result = await Util.apiRequest(`${this.apiBase}${endpoint}`, {
            method: 'POST',
            body: JSON.stringify(endpoint === '/send' ? {
                message_type: messageType,
                message_data: formData
            } : formData)
        });

        if (result.success) {
            Util.addLogMessage('SUCCESS', `${messageType} sent successfully`);
            this.onSuccessfulSubmit(messageType, formId);
        } else {
            Util.addLogMessage('ERROR', `${messageType} failed: ${result.error}`);
        }
    }

    /**
     * Handle successful form submission
     */
    onSuccessfulSubmit(messageType, formId) {
        // Reset form for spawn operations
        if (messageType === 'SpawnEntityMessage') {
            this.resetForm(formId);
        }
        
        // Clear update form after successful update/despawn
        if (messageType === 'EntityUpdateMessage' || messageType === 'EntityDespawnMessage') {
            this.clearForm(formId);
        }
    }

    /**
     * Reset form to default values
     */
    resetForm(formId) {
        const form = document.getElementById(formId);
        if (!form) return;

        form.reset();
        
        // Reset any custom default values
        const defaultValues = {
            'instance_id': '1',
            'x_pos': '0',
            'y_pos': '0', 
            'z_pos': '0',
            'state': 'idle'
        };

        Object.entries(defaultValues).forEach(([field, value]) => {
            const input = form.querySelector(`[name="${field}"]`);
            if (input) input.value = value;
        });

        // Clear dynamic fields
        form.querySelectorAll('.array-items').forEach(container => {
            container.innerHTML = '';
        });
        
        form.querySelectorAll('.map-entries').forEach(container => {
            container.innerHTML = '';
        });
    }

    /**
     * Clear form completely
     */
    clearForm(formId) {
        const form = document.getElementById(formId);
        if (!form) return;

        form.reset();
        
        // Clear all dynamic fields
        form.querySelectorAll('.array-items').forEach(container => {
            container.innerHTML = '';
        });
        
        form.querySelectorAll('.map-entries').forEach(container => {
            container.innerHTML = '';
        });
    }

    /**
     * Quick spawn with default values
     */
    async quickSpawn() {
        const entityData = {
            instance_id: 1,
            display_name: `Entity_${Date.now()}`,
            model: 'default_model',
            state: 'idle',
            x_pos: Math.floor(Math.random() * 20) - 10,
            y_pos: 0,
            z_pos: Math.floor(Math.random() * 20) - 10,
            stats: {
                health: { current: 100, max: 100, extra: 0 },
                mana: { current: 50, max: 50, extra: 0 }
            }
        };

        const result = await Util.apiRequest(`${this.apiBase}/spawn`, {
            method: 'POST',
            body: JSON.stringify(entityData)
        });

        if (result.success) {
            Util.addLogMessage('SUCCESS', `Quick spawned: ${entityData.display_name}`);
        } else {
            Util.addLogMessage('ERROR', `Quick spawn failed: ${result.error}`);
        }
    }

    /**
     * Quick despawn by entity ID
     */
    async quickDespawn() {
        const entityId = prompt('Enter Entity ID to despawn:');
        if (!entityId) return;

        const instanceId = prompt('Enter Instance ID:', '1');
        if (!instanceId) return;

        const despawnData = {
            entity_id: parseInt(entityId),
            instance_id: parseInt(instanceId)
        };

        const result = await Util.apiRequest(`${this.apiBase}/despawn`, {
            method: 'POST',
            body: JSON.stringify(despawnData)
        });

        if (result.success) {
            Util.addLogMessage('SUCCESS', `Despawned entity: ${entityId}`);
        } else {
            Util.addLogMessage('ERROR', `Despawn failed: ${result.error}`);
        }
    }

    /**
     * Add predefined stats to a form
     */
    addPredefinedStats(formId, statsPreset = 'default') {
        const statsContainer = document.querySelector(`#${formId} [id$="_stats_entries"]`);
        if (!statsContainer) return;

        const presets = {
            default: {
                health: { current: 100, max: 100, extra: 0 },
                mana: { current: 50, max: 50, extra: 0 }
            },
            warrior: {
                health: { current: 150, max: 150, extra: 0 },
                mana: { current: 20, max: 20, extra: 0 },
                strength: { current: 15, max: 20, extra: 0 },
                defense: { current: 12, max: 15, extra: 0 }
            },
            mage: {
                health: { current: 80, max: 80, extra: 0 },
                mana: { current: 120, max: 120, extra: 0 },
                intelligence: { current: 18, max: 20, extra: 0 },
                wisdom: { current: 16, max: 20, extra: 0 }
            }
        };

        const stats = presets[statsPreset] || presets.default;
        
        // Clear existing stats
        statsContainer.innerHTML = '';
        
        // Add preset stats
        Object.entries(stats).forEach(([statName, statData]) => {
            this.addStatEntry(statsContainer.id.replace('_entries', ''), statName, statData);
        });
    }

    /**
     * Add a stat entry to a map field
     */
    addStatEntry(fieldId, statName, statData) {
        const container = document.getElementById(`${fieldId}_entries`);
        if (!container) return;

        const entryId = `${fieldId}_entry_${Date.now()}_${statName}`;
        
        const entryElement = document.createElement('div');
        entryElement.className = 'map-entry';
        entryElement.innerHTML = `
            <input type="text" placeholder="Stat name" id="${entryId}_key" value="${statName}" style="flex: 1;">
            <div style="display: flex; gap: 5px; flex: 2;">
                <input type="number" placeholder="Current" step="0.1" id="${entryId}_current" value="${statData.current}">
                <input type="number" placeholder="Max" step="0.1" id="${entryId}_max" value="${statData.max}">
                <input type="number" placeholder="Extra" step="0.1" id="${entryId}_extra" value="${statData.extra}">
            </div>
            <button type="button" class="btn small danger" onclick="this.parentElement.remove()">Remove</button>
        `;
        
        container.appendChild(entryElement);
    }

    /**
     * Start automatic message refresh
     */
    startMessageRefresh() {
        // Initial refresh
        Util.refreshMessages();
        
        // Auto-refresh every 3 seconds
        setInterval(() => {
            Util.refreshMessages();
        }, 3000);
    }

    /**
     * Query entities from server
     */
    async queryEntities(instanceId = null) {
        const queryData = {};
        if (instanceId !== null) {
            queryData.instance_id = instanceId;
        }

        const result = await Util.apiRequest(`${this.apiBase}/query`, {
            method: 'POST',
            body: JSON.stringify(queryData)
        });

        if (result.success) {
            Util.addLogMessage('INFO', 'Entity query sent');
        } else {
            Util.addLogMessage('ERROR', `Query failed: ${result.error}`);
        }
    }

    /**
     * Get health status of entity management
     */
    async getHealth() {
        const result = await Util.apiRequest(`${this.apiBase}/health`);
        
        if (result.success) {
            console.log('Entity Management Health:', result.data);
            return result.data;
        } else {
            console.error('Health check failed:', result.error);
            return null;
        }
    }
}

// Global entity manager instance
const EntityMgr = new EntityManager();

// Global functions for template compatibility
function spawnEntity() {
    const form = document.getElementById('spawnEntityForm');
    if (form) {
        submitSchemaForm('spawnEntityForm');
    }
}

function updateEntity() {
    const form = document.getElementById('updateEntityForm');
    if (form) {
        submitSchemaForm('updateEntityForm');
    }
}

function despawnEntity() {
    const form = document.getElementById('despawnEntityForm');
    if (form) {
        submitSchemaForm('despawnEntityForm');
    }
}

function addStatGroup() {
    const statName = prompt('Enter stat name:');
    if (!statName) return;
    
    // Find active form with stats
    const activeForms = ['spawnEntityForm', 'updateEntityForm'];
    
    for (const formId of activeForms) {
        const statsContainer = document.querySelector(`#${formId} [id*="_stats_entries"]`);
        if (statsContainer) {
            EntityMgr.addStatEntry(
                statsContainer.id.replace('_entries', ''),
                statName,
                { current: 0, max: 100, extra: 0 }
            );
            break;
        }
    }
}

function resetSpawnForm() {
    EntityMgr.resetForm('spawnEntityForm');
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Check if schemas are available
    if (typeof loadedSchemas !== 'undefined') {
        EntityMgr.init(loadedSchemas);
    } else {
        console.warn('No schemas loaded for entity management');
    }
});

// Export for global access
window.EntityManager = EntityMgr;

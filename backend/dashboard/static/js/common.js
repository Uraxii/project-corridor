// Common utilities and schema-based form generator
class SchemaFormGenerator {
    constructor() {
        this.schemas = {};
        this.messageTypes = [];
    }

    /**
     * Initialize with loaded schemas
     */
    init(schemas) {
        this.schemas = schemas;
        this.messageTypes = this.extractMessageTypes(schemas);
        console.log('Schema Form Generator initialized with types:', this.messageTypes);
    }

    /**
     * Extract message types from schemas
     */
    extractMessageTypes(schemas) {
        const messageTypes = [];
        
        Object.keys(schemas).forEach(schemaKey => {
            const schema = schemas[schemaKey];
            
            // Check if this schema has definitions with message types
            if (schema.definitions) {
                Object.keys(schema.definitions).forEach(defKey => {
                    // Only include message types that:
                    // 1. End with 'Message'
                    // 2. Don't have a package prefix (no dots)
                    // 3. Are not the main Packet type
                    if (defKey.endsWith('Message') && !defKey.includes('.') && defKey !== 'Packet') {
                        messageTypes.push(defKey);
                    }
                });
            }
            
            // Also check if the schema key itself is a message type
            if (schemaKey.endsWith('Message') && !schemaKey.includes('.') && schemaKey !== 'Packet') {
                messageTypes.push(schemaKey);
            }
        });
        
        // Remove duplicates
        return [...new Set(messageTypes)];
    }

    /**
     * Generate a form for a specific message type
     */
    generateForm(messageType, containerId, options = {}) {
        const container = document.getElementById(containerId);
        if (!container) {
            console.error(`Container ${containerId} not found`);
            return null;
        }

        const schema = this.findSchemaDefinition(messageType);
        if (!schema) {
            container.innerHTML = `<div class="error">Schema not found for ${messageType}</div>`;
            return null;
        }

        const formId = options.formId || `form_${messageType}_${Date.now()}`;
        const formHtml = this.generateFormHTML(messageType, schema, formId, options);
        
        container.innerHTML = formHtml;
        
        // Initialize any dynamic features
        this.initializeDynamicFields(formId);
        
        return formId;
    }

    /**
     * Generate HTML for a form based on schema
     */
    generateFormHTML(messageType, schema, formId, options = {}) {
        const displayName = options.title || this.formatMessageTypeName(messageType);
        const showActions = options.showActions !== false;
        
        let html = `
            <form id="${formId}" class="schema-form" data-message-type="${messageType}">
                <div class="form-header">
                    <h3>${displayName}</h3>
                </div>
        `;
        
        if (schema.properties) {
            html += this.generateFieldsFromProperties(schema.properties, messageType, '', formId);
        } else {
            html += '<p class="no-properties">No properties found in schema</p>';
        }
        
        if (showActions) {
            html += `
                <div class="form-actions">
                    <button type="button" class="btn primary" onclick="submitSchemaForm('${formId}')">
                        Send ${displayName}
                    </button>
                    <button type="reset" class="btn secondary">Reset</button>
                </div>
            `;
        }
        
        html += '</form>';
        return html;
    }

    /**
     * Generate form fields from schema properties
     */
    generateFieldsFromProperties(properties, messageType, prefix, formId) {
        let html = '';
        
        for (const [fieldName, fieldSchema] of Object.entries(properties)) {
            const fieldId = prefix ? `${prefix}_${fieldName}` : fieldName;
            const fullFieldId = `${formId}_${fieldId}`;
            const displayName = this.formatFieldName(fieldName);
            
            // Handle $ref references
            if (fieldSchema.$ref) {
                const refDefinition = this.resolveReference(fieldSchema.$ref);
                if (refDefinition && refDefinition.properties) {
                    html += `
                        <div class="field-section" data-field-type="object">
                            <div class="field-section-title">${displayName}</div>
                            <div class="nested-object">
                                ${this.generateFieldsFromProperties(refDefinition.properties, messageType, fieldId, formId)}
                            </div>
                        </div>
                    `;
                }
                continue;
            }
            
            if (fieldSchema.type === 'object' && fieldSchema.properties) {
                // Nested object
                html += `
                    <div class="field-section" data-field-type="object">
                        <div class="field-section-title">${displayName}</div>
                        <div class="nested-object">
                            ${this.generateFieldsFromProperties(fieldSchema.properties, messageType, fieldId, formId)}
                        </div>
                    </div>
                `;
            } else if (fieldSchema.type === 'object' && fieldSchema.additionalProperties) {
                // Map field (like stats)
                html += `
                    <div class="field-section" data-field-type="map">
                        <div class="field-section-title">
                            ${displayName}
                            <button type="button" class="btn small add-map-entry" 
                                    onclick="addMapEntry('${fullFieldId}', '${fieldSchema.additionalProperties.type || 'object'}')">
                                Add ${displayName.slice(0, -1)}
                            </button>
                        </div>
                        <div class="map-field" id="${fullFieldId}_container">
                            <div id="${fullFieldId}_entries" class="map-entries"></div>
                        </div>
                    </div>
                `;
            } else if (fieldSchema.type === 'array') {
                // Array field
                const itemType = fieldSchema.items ? fieldSchema.items.type : 'string';
                html += `
                    <div class="field-section" data-field-type="array">
                        <div class="field-section-title">
                            ${displayName}
                            <button type="button" class="btn small add-array-item"
                                    onclick="addArrayItem('${fullFieldId}', '${itemType}')">
                                Add Item
                            </button>
                        </div>
                        <div class="array-field">
                            <input type="${this.getInputType(itemType)}" 
                                   id="${fullFieldId}_new" 
                                   placeholder="Enter ${itemType} value"
                                   class="array-new-input">
                            <div class="array-items" id="${fullFieldId}_items"></div>
                        </div>
                    </div>
                `;
            } else {
                // Simple field
                const inputType = this.getInputType(fieldSchema.type);
                const placeholder = this.getPlaceholder(fieldName, fieldSchema.type);
                const required = this.isFieldRequired(fieldName, messageType);
                
                html += `
                    <div class="form-group" data-field-type="simple">
                        <label for="${fullFieldId}">${displayName}</label>
                        <input type="${inputType}" 
                               id="${fullFieldId}" 
                               name="${fieldId}" 
                               placeholder="${placeholder}"
                               ${required ? 'required' : ''}
                               data-field-name="${fieldName}"
                               data-field-type="${fieldSchema.type}">
                    </div>
                `;
            }
        }
        
        return html;
    }

    /**
     * Find schema definition for a message type
     */
    findSchemaDefinition(messageType) {
        for (const schemaKey in this.schemas) {
            const schema = this.schemas[schemaKey];
            
            // Check definitions first
            if (schema.definitions && schema.definitions[messageType]) {
                return schema.definitions[messageType];
            }
            
            // Check if the schema itself is the message type
            if (schemaKey === messageType && schema.properties) {
                return schema;
            }
        }
        return null;
    }

    /**
     * Resolve $ref references
     */
    resolveReference(ref) {
        if (ref.startsWith('#/definitions/')) {
            const defName = ref.replace('#/definitions/', '');
            
            for (const schemaKey in this.schemas) {
                const schema = this.schemas[schemaKey];
                if (schema.definitions && schema.definitions[defName]) {
                    return schema.definitions[defName];
                }
            }
        }
        return null;
    }

    /**
     * Get HTML input type for schema type
     */
    getInputType(schemaType) {
        switch (schemaType) {
            case 'integer':
            case 'number': return 'number';
            case 'boolean': return 'checkbox';
            case 'string': return 'text';
            default: return 'text';
        }
    }

    /**
     * Get placeholder text for a field
     */
    getPlaceholder(fieldName, schemaType) {
        if (fieldName.includes('name')) return 'Enter name...';
        if (fieldName.includes('pos') || fieldName.includes('position')) return '0.0';
        if (fieldName.includes('id')) return '1';
        if (fieldName.includes('content')) return 'Enter content...';
        if (schemaType === 'number' || schemaType === 'integer') return '0';
        return 'Enter value...';
    }

    /**
     * Determine if a field is required
     */
    isFieldRequired(fieldName, messageType) {
        const requiredFields = {
            'SpawnEntityMessage': ['instance_id', 'display_name', 'model', 'x_pos', 'y_pos', 'z_pos'],
            'EntityUpdateMessage': ['entity_id', 'instance_id'],
            'EntityDespawnMessage': ['entity_id', 'instance_id']
        };
        
        return requiredFields[messageType]?.includes(fieldName) || false;
    }

    /**
     * Format message type name for display
     */
    formatMessageTypeName(messageType) {
        return messageType
            .replace('Message', '')
            .replace(/([A-Z])/g, ' $1')
            .trim();
    }

    /**
     * Format field name for display
     */
    formatFieldName(fieldName) {
        return fieldName
            .replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase());
    }

    /**
     * Initialize dynamic field features
     */
    initializeDynamicFields(formId) {
        // Add any initialization code for dynamic fields
        console.log(`Initialized dynamic fields for form: ${formId}`);
    }

    /**
     * Collect form data and convert to proper types
     */
    collectFormData(formId) {
        const form = document.getElementById(formId);
        if (!form) return null;

        const data = {};
        
        // Collect simple fields
        const inputs = form.querySelectorAll('input[name]');
        inputs.forEach(input => {
            const name = input.name;
            let value = input.value.trim();
            
            if (value === '' && !input.hasAttribute('required')) return;
            
            // Convert based on field type
            const fieldType = input.dataset.fieldType;
            if (input.type === 'number') {
                value = input.step && input.step.includes('.') ? parseFloat(value) : parseInt(value);
            } else if (input.type === 'checkbox') {
                value = input.checked;
            }
            
            this.setNestedValue(data, name.split('_'), value);
        });
        
        // Collect array fields
        const arrayContainers = form.querySelectorAll('[id$="_items"]');
        arrayContainers.forEach(container => {
            const fieldPath = container.id.replace(`${formId}_`, '').replace('_items', '');
            const items = Array.from(container.children).map(item => {
                const text = item.textContent.replace('×', '').trim();
                return isNaN(text) ? text : (text.includes('.') ? parseFloat(text) : parseInt(text));
            });
            if (items.length > 0) {
                this.setNestedValue(data, fieldPath.split('_'), items);
            }
        });
        
        // Collect map fields
        const mapContainers = form.querySelectorAll('[id$="_entries"]');
        mapContainers.forEach(container => {
            const fieldPath = container.id.replace(`${formId}_`, '').replace('_entries', '');
            const mapData = {};
            
            Array.from(container.children).forEach(entry => {
                const keyInput = entry.querySelector('[id$="_key"]');
                const valueInput = entry.querySelector('[id$="_value"]');
                
                if (keyInput && valueInput && keyInput.value.trim()) {
                    mapData[keyInput.value.trim()] = this.convertValue(valueInput.value, 'string');
                } else {
                    // Handle complex objects (like stats)
                    const currentInput = entry.querySelector('[id$="_current"]');
                    const maxInput = entry.querySelector('[id$="_max"]');
                    const extraInput = entry.querySelector('[id$="_extra"]');
                    
                    if (keyInput && currentInput && keyInput.value.trim()) {
                        mapData[keyInput.value.trim()] = {
                            current: parseFloat(currentInput.value) || 0,
                            max: parseFloat(maxInput.value) || 0,
                            extra: parseFloat(extraInput.value) || 0
                        };
                    }
                }
            });
            
            if (Object.keys(mapData).length > 0) {
                this.setNestedValue(data, fieldPath.split('_'), mapData);
            }
        });
        
        return data;
    }

    /**
     * Set nested value in object
     */
    setNestedValue(obj, path, value) {
        let current = obj;
        for (let i = 0; i < path.length - 1; i++) {
            if (!current[path[i]]) current[path[i]] = {};
            current = current[path[i]];
        }
        current[path[path.length - 1]] = value;
    }

    /**
     * Convert value to appropriate type
     */
    convertValue(value, type) {
        switch (type) {
            case 'integer': return parseInt(value) || 0;
            case 'number': return parseFloat(value) || 0;
            case 'boolean': return value === 'true' || value === '1';
            default: return value;
        }
    }
}

// Global utilities
const Util = {
    /**
     * Add log message to message log
     */
    addLogMessage(type, content) {
        const timestamp = new Date().toLocaleTimeString();
        const entry = document.createElement('div');
        entry.className = 'message-entry';
        
        const typeClass = type.toLowerCase();
        entry.innerHTML = `
            <span class="message-timestamp">${timestamp}</span>
            <span class="message-direction ${typeClass}">${type}</span>
            <span class="message-content">${content}</span>
        `;
        
        const log = document.getElementById('messageLog');
        if (log) {
            log.appendChild(entry);
            log.scrollTop = log.scrollHeight;
        }
    },

    /**
     * Make API request with error handling
     */
    async apiRequest(url, options = {}) {
        try {
            const response = await fetch(url, {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            });
            
            const result = await response.json();
            
            if (response.ok) {
                return { success: true, data: result };
            } else {
                return { success: false, error: result.error || 'Unknown error' };
            }
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    /**
     * Refresh message log
     */
    async refreshMessages() {
        const result = await this.apiRequest('/api/messages');
        if (result.success) {
            this.displayMessages(result.data);
        }
    },

    /**
     * Display messages in log
     */
    displayMessages(messages) {
        const log = document.getElementById('messageLog');
        if (!log) return;

        const currentHeight = log.scrollHeight;
        const currentScroll = log.scrollTop;
        const shouldAutoScroll = currentScroll >= currentHeight - log.clientHeight - 50;
        
        log.innerHTML = '';
        messages.forEach(msg => {
            const entry = document.createElement('div');
            entry.className = 'message-entry';
            
            const directionClass = msg.direction.toLowerCase();
            entry.innerHTML = `
                <span class="message-timestamp">${msg.timestamp}</span>
                <span class="message-direction ${directionClass}">${msg.direction}</span>
                <span class="message-content">${msg.content}</span>
                ${msg.size ? `<span style="color: #666;"> (${msg.size} bytes)</span>` : ''}
            `;
            
            log.appendChild(entry);
        });
        
        if (shouldAutoScroll) {
            log.scrollTop = log.scrollHeight;
        }
    },

    /**
     * Clear message log
     */
    async clearMessages() {
        const result = await this.apiRequest('/api/clear_messages', { method: 'POST' });
        if (result.success) {
            const log = document.getElementById('messageLog');
            if (log) log.innerHTML = '';
        }
    }
};

// Global form generator instance
const FormGenerator = new SchemaFormGenerator();

// Global functions for backwards compatibility
function submitSchemaForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return;
    
    const messageType = form.dataset.messageType;
    const formData = FormGenerator.collectFormData(formId);
    
    // Trigger custom event or call route-specific handler
    const event = new CustomEvent('schemaFormSubmit', {
        detail: { messageType, formData, formId }
    });
    document.dispatchEvent(event);
}

function addMapEntry(fieldId, valueType) {
    const container = document.getElementById(`${fieldId}_entries`);
    if (!container) return;
    
    const entryId = `${fieldId}_entry_${Date.now()}`;
    
    let valueInput = '';
    if (valueType === 'object') {
        valueInput = `
            <div style="display: flex; gap: 5px; flex: 2;">
                <input type="number" placeholder="Current" step="0.1" id="${entryId}_current">
                <input type="number" placeholder="Max" step="0.1" id="${entryId}_max">
                <input type="number" placeholder="Extra" step="0.1" id="${entryId}_extra">
            </div>
        `;
    } else {
        valueInput = `<input type="${FormGenerator.getInputType(valueType)}" placeholder="Value" id="${entryId}_value" style="flex: 1;">`;
    }
    
    const entryElement = document.createElement('div');
    entryElement.className = 'map-entry';
    entryElement.innerHTML = `
        <input type="text" placeholder="Key name" id="${entryId}_key" style="flex: 1;">
        ${valueInput}
        <button type="button" class="btn small danger" onclick="this.parentElement.remove()">Remove</button>
    `;
    
    container.appendChild(entryElement);
}

function addArrayItem(fieldId, itemType) {
    const newInput = document.getElementById(`${fieldId}_new`);
    const container = document.getElementById(`${fieldId}_items`);
    
    if (!newInput || !container) return;
    
    const value = newInput.value.trim();
    if (!value) return;
    
    const convertedValue = FormGenerator.convertValue(value, itemType);
    
    const itemElement = document.createElement('div');
    itemElement.className = 'array-item';
    itemElement.innerHTML = `
        ${convertedValue}
        <span class="remove" onclick="this.parentElement.remove()">×</span>
    `;
    
    container.appendChild(itemElement);
    newInput.value = '';
}

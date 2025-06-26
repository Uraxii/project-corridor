// Dashboard JavaScript
let connectionStatus = false;
let schemas = {};
let currentMessageType = '';
let messageData = {};

// Initialize with schemas passed from Flask
function initializeSchemas(loadedSchemas) {
    schemas = loadedSchemas;
    console.log('Loaded schemas:', schemas);
}

// Connection Management
async function toggleConnection() {
    if (connectionStatus) {
        await disconnect();
    } else {
        await connect();
    }
}

async function connect() {
    const url = document.getElementById('serverUrl').value;
    try {
        const response = await fetch('/api/connect', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({server_url: url})
        });
        
        if (response.ok) {
            updateConnectionUI(true);
            addLogMessage('SYSTEM', `Connected to ${url}`);
        }
    } catch (error) {
        addLogMessage('SYSTEM', `Connection error: ${error}`);
    }
}

async function disconnect() {
    try {
        await fetch('/api/disconnect', {method: 'POST'});
        updateConnectionUI(false);
        addLogMessage('SYSTEM', 'Disconnected from server');
    } catch (error) {
        addLogMessage('SYSTEM', `Disconnect error: ${error}`);
    }
}

function updateConnectionUI(connected) {
    const status = document.getElementById('status');
    const connectBtn = document.getElementById('connectBtn');
    
    connectionStatus = connected;
    
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

// Message Log Management
function addLogMessage(direction, content, size) {
    const timestamp = new Date().toLocaleTimeString();
    const entry = document.createElement('div');
    entry.className = 'message-entry';
    
    const directionClass = direction.toLowerCase();
    entry.innerHTML = `
        <span class="message-timestamp">${timestamp}</span>
        <span class="message-direction ${directionClass}">${direction}</span>
        <span class="message-content">${content}</span>
        ${size ? `<span style="color: #666;"> (${size} bytes)</span>` : ''}
    `;
    
    const log = document.getElementById('messageLog');
    log.appendChild(entry);
    log.scrollTop = log.scrollHeight;
}

async function clearMessages() {
    try {
        await fetch('/api/clear_messages', {method: 'POST'});
        document.getElementById('messageLog').innerHTML = '';
    } catch (error) {
        console.error('Error clearing messages:', error);
    }
}

async function refreshMessages() {
    try {
        const response = await fetch('/api/messages');
        const messages = await response.json();
        
        const log = document.getElementById('messageLog');
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
    } catch (error) {
        console.error('Error refreshing messages:', error);
    }
}

// Schema-based Form Generation
function generateMessageForms() {
    const panel = document.getElementById('messagePanel');
    
    if (!schemas || Object.keys(schemas).length === 0) {
        console.log('No schemas available');
        return;
    }
    
    console.log('Schema keys:', Object.keys(schemas));
    
    // Get message types from schemas - look in definitions or top-level
    const messageTypes = [];
    const allFoundTypes = []; // For debugging
    
    Object.keys(schemas).forEach(schemaKey => {
        const schema = schemas[schemaKey];
        
        // Check if this schema has definitions with message types
        if (schema.definitions) {
            Object.keys(schema.definitions).forEach(defKey => {
                allFoundTypes.push(defKey); // Debug: track all found types
                
                // Only include message types that:
                // 1. End with 'Message'
                // 2. Don't have a package prefix (no dots)
                // 3. Are not the main Packet type
                if (defKey.endsWith('Message') && !defKey.includes('.') && defKey !== 'Packet') {
                    messageTypes.push(defKey);
                }
            });
        }
        
        // Also check if the schema key itself is a message type (without package prefix)
        if (schemaKey.endsWith('Message') && !schemaKey.includes('.') && schemaKey !== 'Packet') {
            messageTypes.push(schemaKey);
            allFoundTypes.push(schemaKey); // Debug: track all found types
        }
    });
    
    console.log('All found types:', allFoundTypes);
    console.log('Filtered message types:', messageTypes);
    
    // Remove duplicates
    const uniqueMessageTypes = [...new Set(messageTypes)];
    console.log('Found message types:', uniqueMessageTypes);
    
    if (uniqueMessageTypes.length === 0) {
        const debugDiv = panel.querySelector('.debug-info');
        if (debugDiv) {
            debugDiv.innerHTML += '<br><strong>No message types found in schemas!</strong>';
        }
        return;
    }
    
    // Find the schema info div and add the selector after it
    const schemaInfoDiv = panel.querySelector('.schema-info');
    const debugDiv = panel.querySelector('.debug-info');
    
    if (schemaInfoDiv) {
        let html = `
            <div class="message-type-selector">
                <label for="messageTypeSelect">Select Message Type:</label>
                <select id="messageTypeSelect" onchange="switchMessageForm()">
                    <option value="">-- Choose Message Type --</option>
        `;
        
        uniqueMessageTypes.forEach(messageType => {
            const displayName = messageType.replace('Message', '').replace(/([A-Z])/g, ' $1').trim();
            html += `<option value="${messageType}">${displayName}</option>`;
        });
        
        html += `
                </select>
            </div>
            <div id="dynamicForms"></div>
        `;
        
        // Insert after debug div or schema info div
        const insertAfter = debugDiv || schemaInfoDiv;
        insertAfter.insertAdjacentHTML('afterend', html);
        
        // Remove the placeholder text
        const placeholder = panel.querySelector('.no-schemas');
        if (placeholder && placeholder.textContent.includes('Select a message type')) {
            placeholder.remove();
        }
    }
}

function switchMessageForm() {
    const selector = document.getElementById('messageTypeSelect');
    const messageType = selector.value;
    const formsContainer = document.getElementById('dynamicForms');
    
    if (!messageType) {
        formsContainer.innerHTML = '';
        return;
    }
    
    currentMessageType = messageType;
    messageData[messageType] = messageData[messageType] || {};
    
    // Find the schema definition for this message type
    const schemaDefinition = findSchemaDefinition(messageType);
    if (!schemaDefinition) {
        formsContainer.innerHTML = '<div class="no-schemas">Schema definition not found for this message type.</div>';
        return;
    }
    
    console.log(`Generating form for ${messageType}:`, schemaDefinition);
    const formHtml = generateFormForSchema(messageType, schemaDefinition);
    formsContainer.innerHTML = formHtml;
}

function findSchemaDefinition(messageType) {
    // Look through all schemas to find the definition for this message type
    for (const schemaKey in schemas) {
        const schema = schemas[schemaKey];
        
        // Check if it's directly in definitions
        if (schema.definitions && schema.definitions[messageType]) {
            return schema.definitions[messageType];
        }
        
        // Check if the schema itself is the message type
        if (schemaKey === messageType && schema.properties) {
            return schema;
        }
        
        // Check if this schema has a $ref that points to our message type
        if (schema.$ref && schema.$ref.endsWith(messageType)) {
            // Follow the $ref to get the actual definition
            const refDefinition = resolveReference(schema.$ref);
            if (refDefinition) {
                return refDefinition;
            }
        }
        
        // Check for prefixed definitions (like packets.MessageType) - but only use them if no clean version exists
        if (schema.definitions) {
            for (const defKey in schema.definitions) {
                if (defKey.endsWith(messageType) || defKey.includes(messageType)) {
                    // Only use prefixed version if we haven't found a clean one
                    const cleanVersion = schema.definitions[messageType];
                    if (!cleanVersion) {
                        return schema.definitions[defKey];
                    }
                }
            }
        }
    }
    
    return null;
}

function generateFormForSchema(messageType, schema) {
    const displayName = messageType.replace('Message', '').replace(/([A-Z])/g, ' $1').trim();
    let html = `
        <div class="message-form active">
            <h3>${displayName}</h3>
    `;
    
    if (schema.properties) {
        html += generateFieldsFromProperties(schema.properties, messageType, '');
    } else {
        html += '<p>No properties found in schema</p>';
    }
    
    html += `
            <button class="btn" onclick="sendMessage('${messageType}')">Send ${displayName}</button>
        </div>
    `;
    
    return html;
}

function generateFieldsFromProperties(properties, messageType, prefix) {
    let html = '';
    
    for (const [fieldName, fieldSchema] of Object.entries(properties)) {
        const fieldId = prefix ? `${prefix}_${fieldName}` : fieldName;
        const fullFieldId = `${messageType}_${fieldId}`;
        const displayName = fieldName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
        
        // Handle $ref references
        if (fieldSchema.$ref) {
            const refDefinition = resolveReference(fieldSchema.$ref);
            if (refDefinition && refDefinition.properties) {
                html += `
                    <div class="field-section">
                        <div class="field-section-title">${displayName}</div>
                        <div class="nested-object">
                            ${generateFieldsFromProperties(refDefinition.properties, messageType, fieldId)}
                        </div>
                    </div>
                `;
            }
            continue;
        }
        
        if (fieldSchema.type === 'object' && fieldSchema.properties) {
            // Nested object
            html += `
                <div class="field-section">
                    <div class="field-section-title">${displayName}</div>
                    <div class="nested-object">
                        ${generateFieldsFromProperties(fieldSchema.properties, messageType, fieldId)}
                    </div>
                </div>
            `;
        } else if (fieldSchema.type === 'object' && fieldSchema.additionalProperties) {
            // Map field (like stats)
            const valueType = fieldSchema.additionalProperties.$ref ? 'object' : (fieldSchema.additionalProperties.type || 'object');
            html += `
                <div class="field-section">
                    <div class="field-section-title">
                        ${displayName}
                        <button type="button" class="btn small" onclick="addMapEntry('${fullFieldId}', '${valueType}')">Add ${displayName.slice(0, -1)}</button>
                    </div>
                    <div class="map-field" id="${fullFieldId}_container">
                        <div id="${fullFieldId}_entries"></div>
                    </div>
                </div>
            `;
        } else if (fieldSchema.type === 'array') {
            // Array field
            const itemType = fieldSchema.items ? fieldSchema.items.type : 'string';
            html += `
                <div class="field-section">
                    <div class="field-section-title">
                        ${displayName}
                        <button type="button" class="btn small" onclick="addArrayItem('${fullFieldId}', '${itemType}')">Add Item</button>
                    </div>
                    <div class="array-field">
                        <input type="${getInputType(itemType)}" id="${fullFieldId}_new" placeholder="Enter ${itemType} value">
                        <div class="array-items" id="${fullFieldId}_items"></div>
                    </div>
                </div>
            `;
        } else {
            // Simple field
            const inputType = getInputType(fieldSchema.type);
            const placeholder = getPlaceholder(fieldName, fieldSchema.type);
            
            html += `
                <div class="form-group">
                    <label for="${fullFieldId}">${displayName}</label>
                    <input type="${inputType}" id="${fullFieldId}" name="${fieldId}" placeholder="${placeholder}">
                </div>
            `;
        }
    }
    
    return html;
}

function resolveReference(ref) {
    // Handle JSON Schema $ref like "#/definitions/packets.EntityDataMessage"
    if (ref.startsWith('#/definitions/')) {
        const defName = ref.replace('#/definitions/', '');
        
        // Look through all schemas to find this definition
        for (const schemaKey in schemas) {
            const schema = schemas[schemaKey];
            if (schema.definitions && schema.definitions[defName]) {
                return schema.definitions[defName];
            }
        }
    }
    
    return null;
}

function getInputType(schemaType) {
    switch (schemaType) {
        case 'integer':
        case 'number': return 'number';
        case 'boolean': return 'checkbox';
        default: return 'text';
    }
}

function getPlaceholder(fieldName, schemaType) {
    if (fieldName.includes('name')) return 'Enter name...';
    if (fieldName.includes('pos') || fieldName.includes('position')) return '0.0';
    if (fieldName.includes('id')) return '1';
    if (fieldName.includes('content')) return 'Enter message content...';
    if (schemaType === 'number' || schemaType === 'integer') return '0';
    return 'Enter value...';
}

// Dynamic field management
function addArrayItem(fieldId, itemType) {
    const newInput = document.getElementById(`${fieldId}_new`);
    const container = document.getElementById(`${fieldId}_items`);
    const value = newInput.value.trim();
    
    if (!value) return;
    
    const convertedValue = convertValue(value, itemType);
    
    const itemElement = document.createElement('div');
    itemElement.className = 'array-item';
    itemElement.innerHTML = `
        ${convertedValue}
        <span class="remove" onclick="this.parentElement.remove()">×</span>
    `;
    
    container.appendChild(itemElement);
    newInput.value = '';
}

function addMapEntry(fieldId, valueType) {
    const container = document.getElementById(`${fieldId}_entries`);
    const entryId = `${fieldId}_entry_${Date.now()}`;
    
    let valueInput = '';
    if (valueType === 'object') {
        // For complex objects like StatMessage
        valueInput = `
            <div style="display: flex; gap: 5px; flex: 2;">
                <input type="number" placeholder="Current" step="0.1" id="${entryId}_current">
                <input type="number" placeholder="Max" step="0.1" id="${entryId}_max">
                <input type="number" placeholder="Extra" step="0.1" id="${entryId}_extra">
            </div>
        `;
    } else {
        valueInput = `<input type="${getInputType(valueType)}" placeholder="Value" id="${entryId}_value" style="flex: 1;">`;
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

function convertValue(value, type) {
    switch (type) {
        case 'integer': return parseInt(value) || 0;
        case 'number': return parseFloat(value) || 0;
        case 'boolean': return value === 'true' || value === '1';
        default: return value;
    }
}

// Form data collection
function collectFormData(messageType) {
    const data = {};
    const form = document.querySelector('.message-form.active');
    
    if (!form) return data;
    
    // Collect simple fields
    const inputs = form.querySelectorAll('input[name]');
    inputs.forEach(input => {
        const name = input.name;
        let value = input.value.trim();
        
        if (value === '') return;
        
        if (input.type === 'number') {
            value = input.step && input.step.includes('.') ? parseFloat(value) : parseInt(value);
        } else if (input.type === 'checkbox') {
            value = input.checked;
        }
        
        setNestedValue(data, name.split('_'), value);
    });
    
    // Collect array fields
    const arrayContainers = form.querySelectorAll('[id$="_items"]');
    arrayContainers.forEach(container => {
        const fieldPath = container.id.replace(`${messageType}_`, '').replace('_items', '');
        const items = Array.from(container.children).map(item => {
            const text = item.textContent.replace('×', '').trim();
            return isNaN(text) ? text : (text.includes('.') ? parseFloat(text) : parseInt(text));
        });
        if (items.length > 0) {
            setNestedValue(data, fieldPath.split('_'), items);
        }
    });
    
    // Collect map fields
    const mapContainers = form.querySelectorAll('[id$="_entries"]');
    mapContainers.forEach(container => {
        const fieldPath = container.id.replace(`${messageType}_`, '').replace('_entries', '');
        const mapData = {};
        
        Array.from(container.children).forEach(entry => {
            const keyInput = entry.querySelector('[id$="_key"]');
            const valueInput = entry.querySelector('[id$="_value"]');
            
            if (keyInput && valueInput && keyInput.value.trim()) {
                mapData[keyInput.value.trim()] = convertValue(valueInput.value, 'string');
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
            setNestedValue(data, fieldPath.split('_'), mapData);
        }
    });
    
    return data;
}

function setNestedValue(obj, path, value) {
    let current = obj;
    for (let i = 0; i < path.length - 1; i++) {
        if (!current[path[i]]) current[path[i]] = {};
        current = current[path[i]];
    }
    current[path[path.length - 1]] = value;
}

// Message sending
async function sendMessage(messageType) {
    try {
        const formData = collectFormData(messageType);
        
        const response = await fetch('/api/send_message', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                message_type: messageType,
                message_data: formData
            })
        });
        
        if (response.ok) {
            addLogMessage('SENT', `${messageType}: ${JSON.stringify(formData)}`);
        } else {
            const error = await response.json();
            addLogMessage('SYSTEM', `Send error: ${error.error}`);
        }
    } catch (error) {
        addLogMessage('SYSTEM', `Send error: ${error}`);
    }
}

function resetAllForms() {
    const forms = document.querySelectorAll('.message-form');
    forms.forEach(form => {
        const inputs = form.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            if (input.type === 'checkbox') {
                input.checked = false;
            } else {
                input.value = '';
            }
        });
        
        // Clear dynamic content
        const arrayContainers = form.querySelectorAll('[id$="_items"]');
        arrayContainers.forEach(container => container.innerHTML = '');
        
        const mapContainers = form.querySelectorAll('[id$="_entries"]');
        mapContainers.forEach(container => container.innerHTML = '');
    });
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    generateMessageForms();
    refreshMessages();
    
    // Auto-refresh messages every 2 seconds
    setInterval(refreshMessages, 2000);
});

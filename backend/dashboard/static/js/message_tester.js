// Message Tester JavaScript - Using common.js utilities
class MessageTesterManager {
    constructor() {
        this.connectionStatus = false;
        this.schemas = {};
        this.currentMessageType = '';
        this.apiBase = '/message_tester/api';
    }

    /**
     * Initialize message tester
     */
    init(schemas) {
        this.schemas = schemas;
        
        // Initialize form generator with schemas
        FormGenerator.init(schemas);
        
        // Populate message type selector
        this.populateMessageTypeSelector();
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Start message refresh
        this.startMessageRefresh();
        
        console.log('Message Tester initialized with schemas:', schemas);
    }

    /**
     * Populate the message type selector dropdown
     */
    populateMessageTypeSelector() {
        const selector = document.getElementById('messageTypeSelect');
        if (!selector) return;

        // Clear existing options except the first one
        selector.innerHTML = '<option value="">-- Choose Message Type --</option>';

        // Add all available message types
        FormGenerator.messageTypes.forEach(messageType => {
            const displayName = FormGenerator.formatMessageTypeName(messageType);
            const option = document.createElement('option');
            option.value = messageType;
            option.textContent = displayName;
            selector.appendChild(option);
        });

        console.log('Populated selector with message types:', FormGenerator.messageTypes);
    }

    /**
     * Set up event listeners
     */
    setupEventListeners() {
        // Listen for schema form submissions
        document.addEventListener('schemaFormSubmit', (event) => {
            this.handleFormSubmit(event.detail);
        });

        // Connection management
        this.setupConnectionHandlers();
    }

    /**
     * Set up connection management handlers
     */
    setupConnectionHandlers() {
        const connectBtn = document.getElementById('connectBtn');
        if (connectBtn) {
            connectBtn.addEventListener('click', () => this.toggleConnection());
        }
    }

    /**
     * Handle form submission
     */
    async handleFormSubmit(detail) {
        const { messageType, formData, formId } = detail;
        
        console.log(`Submitting ${messageType}:`, formData);
        
        const result = await Util.apiRequest(`${this.apiBase}/send_message`, {
            method: 'POST',
            body: JSON.stringify({
                message_type: messageType,
                message_data: formData
            })
        });

        if (result.success) {
            Util.addLogMessage('SENT', `${messageType}: ${JSON.stringify(formData)}`);
        } else {
            Util.addLogMessage('ERROR', `${messageType} failed: ${result.error}`);
        }
    }

    /**
     * Toggle connection to server
     */
    async toggleConnection() {
        if (this.connectionStatus) {
            await this.disconnect();
        } else {
            await this.connect();
        }
    }

    /**
     * Connect to server
     */
    async connect() {
        const url = document.getElementById('serverUrl').value;
        
        const result = await Util.apiRequest('/api/connect', {
            method: 'POST',
            body: JSON.stringify({ server_url: url })
        });

        if (result.success) {
            this.updateConnectionUI(true);
            Util.addLogMessage('SYSTEM', `Connected to ${url}`);
        } else {
            Util.addLogMessage('ERROR', `Connection failed: ${result.error}`);
        }
    }

    /**
     * Disconnect from server
     */
    async disconnect() {
        const result = await Util.apiRequest('/api/disconnect', {
            method: 'POST'
        });

        if (result.success) {
            this.updateConnectionUI(false);
            Util.addLogMessage('SYSTEM', 'Disconnected from server');
        } else {
            Util.addLogMessage('ERROR', `Disconnect failed: ${result.error}`);
        }
    }

    /**
     * Update connection UI
     */
    updateConnectionUI(connected) {
        const status = document.getElementById('status');
        const connectBtn = document.getElementById('connectBtn');
        
        this.connectionStatus = connected;
        
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

    /**
     * Start automatic message refresh
     */
    startMessageRefresh() {
        // Initial refresh
        Util.refreshMessages();
        
        // Auto-refresh every 2 seconds
        setInterval(() => {
            Util.refreshMessages();
        }, 2000);
    }

    /**
     * Reset all forms
     */
    resetAllForms() {
        const forms = document.querySelectorAll('.schema-form');
        forms.forEach(form => {
            form.reset();
            
            // Clear dynamic content
            const arrayContainers = form.querySelectorAll('.array-items');
            arrayContainers.forEach(container => container.innerHTML = '');
            
            const mapContainers = form.querySelectorAll('.map-entries');
            mapContainers.forEach(container => container.innerHTML = '');
        });

        // Reset selector
        const selector = document.getElementById('messageTypeSelect');
        if (selector) {
            selector.value = '';
            this.switchMessageForm();
        }
    }

    /**
     * Switch message form based on selector
     */
    switchMessageForm() {
        const selector = document.getElementById('messageTypeSelect');
        const messageType = selector.value;
        const formsContainer = document.getElementById('dynamicForms');
        
        if (!messageType) {
            formsContainer.innerHTML = '';
            this.currentMessageType = '';
            return;
        }
        
        this.currentMessageType = messageType;
        
        // Generate form using FormGenerator
        const formId = FormGenerator.generateForm(messageType, 'dynamicForms', {
            title: FormGenerator.formatMessageTypeName(messageType),
            formId: `messageTester_${messageType}_form`,
            showActions: true
        });

        console.log(`Generated form for ${messageType} with ID: ${formId}`);
    }
}

// Global message tester manager instance
const MessageTester = new MessageTesterManager();

// Global functions for backwards compatibility and template usage
function switchMessageForm() {
    MessageTester.switchMessageForm();
}

function toggleConnection() {
    MessageTester.toggleConnection();
}

function resetAllForms() {
    MessageTester.resetAllForms();
}

// Legacy function for any remaining direct calls
function sendMessage(messageType) {
    const formId = `messageTester_${messageType}_form`;
    const form = document.getElementById(formId);
    if (form) {
        submitSchemaForm(formId);
    }
}

// Compatibility function for old schema initialization
function initializeSchemas(schemas) {
    MessageTester.init(schemas);
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Check if schemas are available
    if (typeof loadedSchemas !== 'undefined') {
        MessageTester.init(loadedSchemas);
    } else {
        console.warn('No schemas loaded for message tester');
    }
});

// Export for global access
window.MessageTester = MessageTester;appendChild(itemElement);
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
        
        const response = await fetch('/message_tester/api/send_message', {
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

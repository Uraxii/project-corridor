from flask import Blueprint, render_template, request, jsonify
import json
import threading
import time
from datetime import datetime
import google.protobuf.json_format as json_format

# Create blueprint for message testing
message_tester_bp = Blueprint('message_tester', __name__, url_prefix='/message_tester')

def get_game_client():
    """Get the global game client instance"""
    from app import game_client
    return game_client

def log_message(direction, content, size=None):
    """Log message to the global message log"""
    from app import message_log
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    entry = {
        "timestamp": timestamp,
        "direction": direction,
        "content": content,
        "size": size
    }
    message_log.append(entry)
    
    # Keep only last 100 messages
    if len(message_log) > 100:
        message_log.pop(0)

def load_schemas():
    """Load schemas for this route"""
    from app import load_schemas
    return load_schemas()

def parse_form_data(data, schema):
    """Convert form data to protobuf-compatible structure"""
    result = {}
    
    # Handle basic fields
    for key, value in data.items():
        if key.startswith('_'):  # Skip internal form fields
            continue
            
        # Handle nested fields (like stats.health.current)
        if '.' in key:
            parts = key.split('.')
            current = result
            for part in parts[:-1]:
                if part not in current:
                    current[part] = {}
                current = current[part]
            
            # Convert numeric strings to numbers
            try:
                if '.' in value or 'e' in value.lower():
                    current[parts[-1]] = float(value)
                else:
                    current[parts[-1]] = int(value)
            except ValueError:
                current[parts[-1]] = value
        else:
            # Handle simple fields
            if value == '':
                continue
                
            try:
                # Try to convert to appropriate type
                if '.' in value or 'e' in value.lower():
                    result[key] = float(value)
                elif value.isdigit():
                    result[key] = int(value)
                else:
                    result[key] = value
            except ValueError:
                result[key] = value
    
    return result

@message_tester_bp.route('/')
def message_tester_dashboard():
    """Message tester dashboard page"""
    from app import connection_status, connection_lock
    
    schemas = load_schemas()
    with connection_lock:
        status = connection_status.copy()
    
    return render_template('message_tester.html', 
                         schemas=schemas, 
                         connection_status=status)

@message_tester_bp.route('/api/send_message', methods=['POST'])
def send_message():
    try:
        data = request.get_json()
        message_type = data.get('message_type')
        message_data = data.get('message_data', {})
        
        client = get_game_client()
        if not client.connected:
            return jsonify({"error": "Not connected to server"}), 400
        
        # For now, send as text message for debugging
        # TODO: Convert to protobuf binary when protobuf Python bindings are available
        text_message = f"{message_type}: {json.dumps(message_data)}"
        
        # Send in a thread-safe way
        def send_async():
            if client.loop and client.loop.is_running():
                import asyncio
                asyncio.run_coroutine_threadsafe(
                    client.send_text_message(text_message),
                    client.loop
                )
        
        threading.Thread(target=send_async, daemon=True).start()
        
        return jsonify({"status": "sent", "message_type": message_type})
        
    except Exception as e:
        from app import app
        app.logger.error(f"Error sending message: {e}")
        return jsonify({"error": str(e)}), 500

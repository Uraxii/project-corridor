from flask import Flask, request, jsonify
import json
import asyncio
import websockets
import threading
import time
import os
from datetime import datetime
import google.protobuf.json_format as json_format
from google.protobuf.message import Message
import sys
import logging

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

# Import and register all route blueprints
from routes import register_blueprints
register_blueprints(app)

# Global state
connection_status = {"connected": False, "url": None}
message_log = []
websocket_connection = None
connection_lock = threading.Lock()

class GameServerClient:
    def __init__(self):
        self.websocket = None
        self.connected = False
        self.loop = None
        self.thread = None
        
    async def connect(self, server_url):
        try:
            self.websocket = await websockets.connect(server_url)
            self.connected = True
            app.logger.info(f"Connected to game server at {server_url}")
            
            # Listen for messages
            async for message in self.websocket:
                await self.handle_message(message)
                
        except Exception as e:
            app.logger.error(f"WebSocket connection failed: {e}")
            self.connected = False
            with connection_lock:
                connection_status["connected"] = False
            
    async def send_binary_message(self, protobuf_data):
        if self.websocket and self.connected:
            await self.websocket.send(protobuf_data)
            log_message("SENT", "Binary protobuf message", len(protobuf_data))
            
    async def send_text_message(self, content):
        if self.websocket and self.connected:
            message = {
                "type": "chat",
                "content": content,
                "timestamp": int(time.time() * 1000)
            }
            await self.websocket.send(json.dumps(message))
            log_message("SENT", f"Text: {content}")
            
    async def handle_message(self, message):
        try:
            if isinstance(message, bytes):
                log_message("RECEIVED", f"Binary message ({len(message)} bytes)")
                # TODO: Parse protobuf here if needed for display
            else:
                log_message("RECEIVED", f"Text: {message}")
        except Exception as e:
            app.logger.error(f"Error handling message: {e}")
            
    def disconnect(self):
        if self.websocket:
            asyncio.create_task(self.websocket.close())
        self.connected = False
        with connection_lock:
            connection_status["connected"] = False
        
    def start_client_thread(self, server_url):
        def run_client():
            self.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self.loop)
            self.loop.run_until_complete(self.connect(server_url))
            
        self.thread = threading.Thread(target=run_client, daemon=True)
        self.thread.start()

# Global client instance
game_client = GameServerClient()

def log_message(direction, content, size=None):
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
    """Load all JSON schemas from the schemas directory"""
    schemas = {}
    schema_dir = os.path.join(os.path.dirname(__file__), 'schemas')
    
    if not os.path.exists(schema_dir):
        app.logger.warning(f"Schema directory not found: {schema_dir}")
        return schemas
    
    for filename in os.listdir(schema_dir):
        if filename.endswith('.json'):
            schema_name = filename[:-5]  # Remove .json extension
            try:
                with open(os.path.join(schema_dir, filename), 'r') as f:
                    schemas[schema_name] = json.load(f)
                app.logger.info(f"Loaded schema: {schema_name}")
            except Exception as e:
                app.logger.error(f"Error loading schema {filename}: {e}")
    
    return schemas

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

# Global API endpoints (shared across all routes)
@app.route('/api/connect', methods=['POST'])
def connect_to_server():
    data = request.get_json()
    server_url = data.get('server_url', 'ws://localhost:8080/ws')
    
    global game_client
    if game_client.connected:
        game_client.disconnect()
        time.sleep(0.5)
    
    game_client = GameServerClient()
    game_client.start_client_thread(server_url)
    
    with connection_lock:
        connection_status["connected"] = True
        connection_status["url"] = server_url
    
    log_message("SYSTEM", f"Connecting to {server_url}")
    return jsonify({"status": "connecting", "server_url": server_url})

@app.route('/api/disconnect', methods=['POST'])
def disconnect_from_server():
    game_client.disconnect()
    log_message("SYSTEM", "Disconnected from server")
    return jsonify({"status": "disconnected"})

@app.route('/api/status')
def get_connection_status():
    with connection_lock:
        return jsonify(connection_status)

@app.route('/api/send_message', methods=['POST'])
def send_message():
    try:
        data = request.get_json()
        message_type = data.get('message_type')
        message_data = data.get('message_data', {})
        
        if not game_client.connected:
            return jsonify({"error": "Not connected to server"}), 400
        
        # For now, send as text message for debugging
        # TODO: Convert to protobuf binary when protobuf Python bindings are available
        text_message = f"{message_type}: {json.dumps(message_data)}"
        
        # Send in a thread-safe way
        def send_async():
            if game_client.loop and game_client.loop.is_running():
                asyncio.run_coroutine_threadsafe(
                    game_client.send_text_message(text_message),
                    game_client.loop
                )
        
        threading.Thread(target=send_async, daemon=True).start()
        
        return jsonify({"status": "sent", "message_type": message_type})
        
    except Exception as e:
        app.logger.error(f"Error sending message: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/messages')
def get_messages():
    return jsonify(message_log)

@app.route('/api/clear_messages', methods=['POST'])
def clear_messages():
    global message_log
    message_log = []
    return jsonify({"status": "cleared"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

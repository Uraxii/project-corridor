from flask import Blueprint, request, jsonify
import json
import threading
import time
from datetime import datetime
import google.protobuf.json_format as json_format

# Create blueprint for entity management
entity_bp = Blueprint('entity', __name__, url_prefix='/api/entity')

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

def send_protobuf_message(message_type, message_data):
    """Send a protobuf message through the websocket connection"""
    client = get_game_client()
    
    if not client.connected:
        return {"error": "Not connected to server"}, 400
    
    # Convert to the format expected by the server
    text_message = f"{message_type}: {json.dumps(message_data)}"
    
    def send_async():
        if client.loop and client.loop.is_running():
            import asyncio
            asyncio.run_coroutine_threadsafe(
                client.send_text_message(text_message),
                client.loop
            )
    
    threading.Thread(target=send_async, daemon=True).start()
    log_message("SENT", f"Entity {message_type}: {json.dumps(message_data)}")
    return {"status": "sent", "message_type": message_type}

@entity_bp.route('/spawn', methods=['POST'])
def spawn_entity():
    """Spawn a new entity on the server"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['instance_id', 'display_name', 'model', 'x_pos', 'y_pos', 'z_pos']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Prepare spawn message data
        spawn_data = {
            "instance_id": int(data['instance_id']),
            "display_name": str(data['display_name']),
            "model": str(data['model']),
            "state": str(data.get('state', 'idle')),
            "x_pos": float(data['x_pos']),
            "y_pos": float(data['y_pos']),
            "z_pos": float(data['z_pos']),
            "equipped_item_ids": data.get('equipped_item_ids', []),
            "stats": {}
        }
        
        # Process stats if provided
        if 'stats' in data and isinstance(data['stats'], dict):
            for stat_name, stat_value in data['stats'].items():
                if isinstance(stat_value, dict):
                    spawn_data["stats"][stat_name] = {
                        "current": float(stat_value.get('current', 0)),
                        "max": float(stat_value.get('max', 100)),
                        "extra": float(stat_value.get('extra', 0))
                    }
                else:
                    # If just a number is provided, use it as current with max=100
                    spawn_data["stats"][stat_name] = {
                        "current": float(stat_value),
                        "max": 100.0,
                        "extra": 0.0
                    }
        
        result, status_code = send_protobuf_message("SpawnEntityMessage", spawn_data)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@entity_bp.route('/update', methods=['POST'])
def update_entity():
    """Update an existing entity on the server"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['entity_id', 'instance_id']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Prepare entity data for update
        entity_data = {}
        
        # Add fields that can be updated
        updatable_fields = ['display_name', 'model', 'state', 'x_pos', 'y_pos', 'z_pos']
        for field in updatable_fields:
            if field in data:
                if field.endswith('_pos'):
                    entity_data[field] = float(data[field])
                else:
                    entity_data[field] = str(data[field])
        
        # Handle equipped items
        if 'equipped_item_ids' in data:
            entity_data['equipped_item_ids'] = data['equipped_item_ids']
        
        # Handle stats updates
        if 'stats' in data and isinstance(data['stats'], dict):
            entity_data['stats'] = {}
            for stat_name, stat_value in data['stats'].items():
                if isinstance(stat_value, dict):
                    entity_data['stats'][stat_name] = {
                        "current": float(stat_value.get('current', 0)),
                        "max": float(stat_value.get('max', 100)),
                        "extra": float(stat_value.get('extra', 0))
                    }
                else:
                    entity_data['stats'][stat_name] = {
                        "current": float(stat_value),
                        "max": 100.0,
                        "extra": 0.0
                    }
        
        # Prepare update message
        update_data = {
            "entity_id": int(data['entity_id']),
            "instance_id": int(data['instance_id']),
            "entity": entity_data
        }
        
        result, status_code = send_protobuf_message("EntityUpdateMessage", update_data)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@entity_bp.route('/despawn', methods=['POST'])
def despawn_entity():
    """Remove an entity from the server"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['entity_id', 'instance_id']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Prepare despawn message
        despawn_data = {
            "entity_id": int(data['entity_id']),
            "instance_id": int(data['instance_id'])
        }
        
        result, status_code = send_protobuf_message("EntityDespawnMessage", despawn_data)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@entity_bp.route('/list', methods=['GET'])
def list_entities():
    """Get a list of all entities (this is a mock endpoint as we can't directly query the Go server)"""
    try:
        # Note: This would need to be implemented by adding a query mechanism to the Go server
        # For now, we'll return information about how to get entity data
        
        return jsonify({
            "message": "Entity listing not yet implemented",
            "note": "To see entities, connect to the server and monitor the message log for EntitySpawnedMessage events",
            "suggestion": "Consider adding a QueryEntitiesMessage to the protobuf definition and server handler"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@entity_bp.route('/query', methods=['POST'])
def query_entities():
    """Request entity information from the server"""
    try:
        data = request.get_json()
        instance_id = data.get('instance_id')
        
        # Prepare query message (this would need to be added to the protobuf definition)
        query_data = {}
        if instance_id is not None:
            query_data['instance_id'] = int(instance_id)
        
        # For now, we'll send a custom query message
        # This would require adding QueryEntitiesMessage to packets.proto
        result, status_code = send_protobuf_message("QueryEntitiesMessage", query_data)
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Health check endpoint
@entity_bp.route('/health', methods=['GET'])
def health_check():
    """Check if entity management is working"""
    client = get_game_client()
    return jsonify({
        "status": "healthy",
        "connected": client.connected if client else False,
        "endpoints": [
            "/api/entity/spawn - POST - Spawn new entity",
            "/api/entity/update - POST - Update existing entity", 
            "/api/entity/despawn - POST - Remove entity",
            "/api/entity/list - GET - List entities (not implemented)",
            "/api/entity/query - POST - Query entities from server",
            "/api/entity/health - GET - Health check"
        ]
    })

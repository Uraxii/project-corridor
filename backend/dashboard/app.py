from flask import Flask, render_template, request, jsonify
import json
import asyncio
import websockets
import threading
import time
import os
from collections import defaultdict
import logging

app = Flask(__name__)
app.logger.setLevel(logging.INFO)

# Global state for entities
entities = {}  # entityId -> entity data
entities_by_instance = defaultdict(dict)  # instanceId -> {entityId -> entity}
current_instance_id = 1

class GameServerClient:
    def __init__(self, server_url=None):
        if server_url is None:
            # Try environment variable first, then default
            server_url = os.getenv('GAME_SERVER_URL', 'ws://localhost:5000/ws')
        self.server_url = server_url
        self.websocket = None
        self.connected = False
        self.loop = None
        self.thread = None
        
    async def connect(self):
        try:
            self.websocket = await websockets.connect(self.server_url)
            self.connected = True
            app.logger.info(f"Connected to game server at {self.server_url}")
            
            # Send hello message
            await self.send_text_message("Hello from Flask dashboard!")
            
            # Listen for messages
            async for message in self.websocket:
                await self.handle_message(message)
                
        except Exception as e:
            app.logger.error(f"WebSocket connection failed: {e}")
            self.connected = False
            
    async def send_text_message(self, content):
        if self.websocket and self.connected:
            message = {
                "type": "chat",
                "content": content,
                "timestamp": int(time.time() * 1000)
            }
            await self.websocket.send(json.dumps(message))
            app.logger.info(f"Sent message: {content}")
            
    async def handle_message(self, message):
        try:
            if isinstance(message, bytes):
                app.logger.info("Received binary protobuf message (parsing not implemented)")
            else:
                app.logger.info(f"Received text message: {message}")
        except Exception as e:
            app.logger.error(f"Error handling message: {e}")
            
    def disconnect(self):
        if self.websocket:
            asyncio.create_task(self.websocket.close())
        self.connected = False
        
    def start_client_thread(self):
        def run_client():
            self.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self.loop)
            self.loop.run_until_complete(self.connect())
            
        self.thread = threading.Thread(target=run_client, daemon=True)
        self.thread.start()

# Global client instance
game_client = GameServerClient()

@app.route('/')
def dashboard():
    return render_template('dashboard.html')

@app.route('/api/connect', methods=['POST'])
def connect_to_server():
    data = request.get_json()
    server_url = data.get('server_url', 'ws://localhost:5000/ws')
    
    if game_client.connected:
        game_client.disconnect()
        time.sleep(0.5)  # Give time to disconnect
    
    game_client.server_url = server_url
    game_client.start_client_thread()
    
    return jsonify({"status": "connecting", "server_url": server_url})

@app.route('/api/disconnect', methods=['POST'])
def disconnect_from_server():
    game_client.disconnect()
    return jsonify({"status": "disconnected"})

@app.route('/api/status')
def get_connection_status():
    return jsonify({"connected": game_client.connected})

@app.route('/api/entities')
def get_entities():
    instance_id = request.args.get('instance_id', current_instance_id, type=int)
    instance_entities = entities_by_instance.get(instance_id, {})
    return jsonify(list(instance_entities.values()))

@app.route('/api/instances')
def get_instances():
    return jsonify({
        "current": current_instance_id,
        "all": list(entities_by_instance.keys())
    })

@app.route('/api/spawn/player', methods=['POST'])
def spawn_player():
    data = request.get_json()
    entity = create_mock_entity(
        name=data.get('name', 'TestPlayer'),
        model='player_character.glb',
        state='idle',
        x=data.get('x', 0),
        y=data.get('y', 0),
        z=data.get('z', 0),
        stats={
            'health': {'current': 100, 'max': 100, 'extra': 0},
            'energy': {'current': 100, 'max': 100, 'extra': 0},
            'vigor': {'current': 10, 'max': 10, 'extra': 0},
            'strength': {'current': 10, 'max': 10, 'extra': 0},
            'agility': {'current': 10, 'max': 10, 'extra': 0},
            'intelligence': {'current': 10, 'max': 10, 'extra': 0}
        }
    )
    spawn_entity_local(entity)
    return jsonify(entity)

@app.route('/api/spawn/warrior', methods=['POST'])
def spawn_warrior():
    data = request.get_json()
    entity = create_mock_entity(
        name=data.get('name', 'GuardCaptain'),
        model='warrior_npc.glb',
        state='patrol',
        x=data.get('x', 5),
        y=data.get('y', 0),
        z=data.get('z', 5),
        stats={
            'health': {'current': 150, 'max': 150, 'extra': 0},
            'energy': {'current': 80, 'max': 80, 'extra': 0},
            'vigor': {'current': 15, 'max': 15, 'extra': 0},
            'strength': {'current': 20, 'max': 20, 'extra': 5},
            'agility': {'current': 12, 'max': 12, 'extra': 0},
            'intelligence': {'current': 8, 'max': 8, 'extra': 0}
        },
        equipped_items=[1001, 2003]
    )
    spawn_entity_local(entity)
    return jsonify(entity)

@app.route('/api/spawn/mage', methods=['POST'])
def spawn_mage():
    data = request.get_json()
    entity = create_mock_entity(
        name=data.get('name', 'CourtWizard'),
        model='mage_npc.glb',
        state='casting',
        x=data.get('x', -5),
        y=data.get('y', 0),
        z=data.get('z', -5),
        stats={
            'health': {'current': 80, 'max': 80, 'extra': 0},
            'energy': {'current': 150, 'max': 150, 'extra': 20},
            'vigor': {'current': 8, 'max': 8, 'extra': 0},
            'strength': {'current': 6, 'max': 6, 'extra': 0},
            'agility': {'current': 14, 'max': 14, 'extra': 0},
            'intelligence': {'current': 25, 'max': 25, 'extra': 10}
        },
        equipped_items=[3001, 4002]
    )
    spawn_entity_local(entity)
    return jsonify(entity)

@app.route('/api/spawn/treasure', methods=['POST'])
def spawn_treasure():
    data = request.get_json()
    entity = create_mock_entity(
        name='Treasure Chest',
        model='treasure_chest.glb',
        state='closed',
        x=data.get('x', 10),
        y=data.get('y', 0),
        z=data.get('z', 10),
        stats={
            'durability': {'current': 100, 'max': 100, 'extra': 0}
        }
    )
    spawn_entity_local(entity)
    return jsonify(entity)

@app.route('/api/entity/<int:entity_id>/despawn', methods=['DELETE'])
def despawn_entity(entity_id):
    instance_id = request.args.get('instance_id', current_instance_id, type=int)
    
    if entity_id in entities:
        del entities[entity_id]
    
    if instance_id in entities_by_instance and entity_id in entities_by_instance[instance_id]:
        del entities_by_instance[instance_id][entity_id]
        if not entities_by_instance[instance_id]:
            del entities_by_instance[instance_id]
    
    return jsonify({"status": "despawned", "entity_id": entity_id})

@app.route('/api/entity/<int:entity_id>/update', methods=['PUT'])
def update_entity(entity_id):
    instance_id = request.args.get('instance_id', current_instance_id, type=int)
    
    if entity_id in entities and entities[entity_id]['instanceId'] == instance_id:
        entity = entities[entity_id]
        # Simulate updating entity stats (reduce health)
        if 'health' in entity['stats']:
            entity['stats']['health']['current'] = max(0, entity['stats']['health']['current'] - 10)
        
        return jsonify(entity)
    
    return jsonify({"error": "Entity not found"}), 404

@app.route('/api/instance/<int:instance_id>/switch', methods=['POST'])
def switch_instance(instance_id):
    global current_instance_id
    current_instance_id = instance_id
    return jsonify({"current_instance": current_instance_id})

@app.route('/api/instance/<int:instance_id>/clear', methods=['DELETE'])
def clear_instance(instance_id):
    if instance_id in entities_by_instance:
        for entity_id in list(entities_by_instance[instance_id].keys()):
            if entity_id in entities:
                del entities[entity_id]
        del entities_by_instance[instance_id]
    
    return jsonify({"status": "cleared", "instance_id": instance_id})

def create_mock_entity(name, model, state, x, y, z, stats, equipped_items=None):
    import random
    entity_id = random.randint(1, 100000)
    
    if equipped_items is None:
        equipped_items = []
    
    return {
        'authorityId': 0,
        'entityId': entity_id,
        'instanceId': current_instance_id,
        'displayName': name,
        'model': model,
        'state': state,
        'position': {'x': x, 'y': y, 'z': z},
        'equippedItemIds': equipped_items,
        'stats': stats
    }

def spawn_entity_local(entity):
    entities[entity['entityId']] = entity
    entities_by_instance[entity['instanceId']][entity['entityId']] = entity

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)

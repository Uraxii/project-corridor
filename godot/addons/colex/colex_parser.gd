@tool
extends RefCounted
class_name CollisionParser

# Data structures for collision data
class CollisionNodeData:
        var name: String
        var type: String
        var transform: Transform3D
        var aabb: AABB
        var collision_layer: int
        var collision_mask: int
        var is_static: bool
        var mesh_path: String
        var collision_shapes: Array[CollisionShapeData] = []

class CollisionShapeData:
        var type: String  # "box", "sphere", "capsule", "mesh", etc.
        var size: Vector3
        var radius: float
        var height: float
        var vertices: PackedVector3Array
        var indices: PackedInt32Array

class SceneCollisionData:
        var scene_name: String
        var scene_path: String
        var nodes: Array[CollisionNodeData] = []
        var static_objects: Array[CollisionNodeData] = []
        var dynamic_objects: Array[CollisionNodeData] = []

# Parse the current scene and extract collision data
func parse_scene(scene_root: Node) -> SceneCollisionData:
        var scene_data = SceneCollisionData.new()
        scene_data.scene_name = scene_root.name
        scene_data.scene_path = scene_root.scene_file_path
        
        print("Parsing scene: ", scene_data.scene_name)
        _parse_node_recursive(scene_root, scene_data)
        
        # Separate static and dynamic objects
        for node_data in scene_data.nodes:
                if node_data.is_static:
                        scene_data.static_objects.append(node_data)
                else:
                        scene_data.dynamic_objects.append(node_data)
        
        print("Found ", scene_data.nodes.size(), " collision nodes")
        print("Static: ", scene_data.static_objects.size(), " Dynamic: ", scene_data.dynamic_objects.size())
        
        return scene_data

func _parse_node_recursive(node: Node, scene_data: SceneCollisionData):
        if _should_have_collision(node):
                var node_data = _extract_node_data(node)
                scene_data.nodes.append(node_data)
                print("  ✓ ", node.name, " (", node.get_class(), ")")
        
        # Parse children
        for child in node.get_children():
                _parse_node_recursive(child, scene_data)

func _should_have_collision(node: Node) -> bool:
        # Skip nodes explicitly marked to skip collision
        if node.has_meta("skip_collision") and node.get_meta("skip_collision"):
                return false
        
        # Include physics bodies
        if node is StaticBody3D or node is RigidBody3D or node is CharacterBody3D:
                return true
        
        # Include MeshInstance3D nodes
        if node is MeshInstance3D:
                return true
        
        # Include Node3D with collision keywords
        if node is Node3D:
                var node_name = node.name.to_lower()
                var keywords = ["block", "platform", "wall", "ground", "floor", "building", "obstacle", "barrier"]
                for keyword in keywords:
                        if keyword in node_name:
                                return true
        
        # Include nodes with CollisionShape3D children
        for child in node.get_children():
                if child is CollisionShape3D:
                        return true
        
        return false

func _extract_node_data(node: Node) -> CollisionNodeData:
        var node_data = CollisionNodeData.new()
        node_data.name = node.name
        node_data.type = node.get_class()
        
        if node is Node3D:
                node_data.transform = node.global_transform
                node_data.aabb = _calculate_node_aabb(node)
        
        # Determine if static or dynamic
        node_data.is_static = _is_static_object(node)
        
        # Extract collision layer and mask if it's a physics body
        if node is CollisionObject3D:
                var physics_body = node as CollisionObject3D
                node_data.collision_layer = physics_body.collision_layer
                node_data.collision_mask = physics_body.collision_mask
        else:
                # Default collision layers based on object type
                node_data.collision_layer = _get_default_collision_layer(node)
                node_data.collision_mask = _get_default_collision_mask(node)
        
        # Extract mesh path if it's a MeshInstance3D
        if node is MeshInstance3D:
                var mesh_instance = node as MeshInstance3D
                if mesh_instance.mesh and mesh_instance.mesh.resource_path:
                        node_data.mesh_path = mesh_instance.mesh.resource_path
        
        # Extract collision shapes
        node_data.collision_shapes = _extract_collision_shapes(node)
        
        return node_data

func _calculate_node_aabb(node: Node3D) -> AABB:
        var aabb = AABB()
        
        # If it's a MeshInstance3D, use the mesh AABB
        if node is MeshInstance3D:
                var mesh_instance = node as MeshInstance3D
                if mesh_instance.mesh:
                        aabb = mesh_instance.mesh.get_aabb()
                        # Transform the AABB by the node's transform
                        aabb = node.transform * aabb
                        return aabb
        
        # If it has CollisionShape3D children, combine their AABBs
        var has_collision = false
        for child in node.get_children():
                if child is CollisionShape3D:
                        var collision_shape = child as CollisionShape3D
                        if collision_shape.shape:
                                var shape_aabb = _get_shape_aabb(collision_shape.shape)
                                shape_aabb = collision_shape.transform * shape_aabb
                                if not has_collision:
                                        aabb = shape_aabb
                                        has_collision = true
                                else:
                                        aabb = aabb.merge(shape_aabb)
        
        if has_collision:
                aabb = node.transform * aabb
                return aabb
        
        # Default AABB for nodes without mesh or collision shapes
        return AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1, 1, 1))

func _get_shape_aabb(shape: Shape3D) -> AABB:
        if shape is BoxShape3D:
                var box = shape as BoxShape3D
                var size = box.size
                return AABB(-size / 2, size)
        elif shape is SphereShape3D:
                var sphere = shape as SphereShape3D
                var r = sphere.radius
                return AABB(Vector3(-r, -r, -r), Vector3(r * 2, r * 2, r * 2))
        elif shape is CapsuleShape3D:
                var capsule = shape as CapsuleShape3D
                var r = capsule.radius
                var h = capsule.height
                return AABB(Vector3(-r, -h/2, -r), Vector3(r * 2, h, r * 2))
        else:
                # Default AABB for complex shapes
                return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))

func _is_static_object(node: Node) -> bool:
        # RigidBody3D and CharacterBody3D are dynamic
        if node is RigidBody3D or node is CharacterBody3D:
                return false
        
        # StaticBody3D is static
        if node is StaticBody3D:
                return true
        
        # Check for dynamic keywords in name
        var node_name = node.name.to_lower()
        var dynamic_keywords = ["player", "enemy", "npc", "pickup", "projectile", "dynamic"]
        for keyword in dynamic_keywords:
                if keyword in node_name:
                        return false
        
        # Default to static
        return true

func _get_default_collision_layer(node: Node) -> int:
        var node_name = node.name.to_lower()
        
        if "player" in node_name:
                return 2  # Player layer
        elif "enemy" in node_name:
                return 4  # Enemy layer
        elif "npc" in node_name:
                return 8  # NPC layer
        elif "pickup" in node_name or "item" in node_name:
                return 16  # Item layer
        else:
                return 1  # Environment layer (default)

func _get_default_collision_mask(node: Node) -> int:
        var node_name = node.name.to_lower()
        
        if "player" in node_name:
                return 1 | 4 | 8 | 16  # Collides with environment, enemies, NPCs, items
        elif "enemy" in node_name:
                return 1 | 2 | 8  # Collides with environment, players, NPCs
        elif "npc" in node_name:
                return 1 | 2 | 4  # Collides with environment, players, enemies
        elif "pickup" in node_name or "item" in node_name:
                return 2  # Only collides with players
        else:
                return 2 | 4 | 8  # Environment collides with players, enemies, NPCs

func _extract_collision_shapes(node: Node) -> Array[CollisionShapeData]:
        var shapes: Array[CollisionShapeData] = []
        
        # Look for CollisionShape3D children
        for child in node.get_children():
                if child is CollisionShape3D:
                        var collision_shape = child as CollisionShape3D
                        if collision_shape.shape:
                                var shape_data = _convert_shape_to_data(collision_shape.shape)
                                shapes.append(shape_data)
        
        # If no collision shapes found but it's a MeshInstance3D, create a mesh collision shape
        if shapes.is_empty() and node is MeshInstance3D:
                var mesh_instance = node as MeshInstance3D
                if mesh_instance.mesh:
                        var shape_data = CollisionShapeData.new()
                        shape_data.type = "mesh"
                        # For mesh shapes, we would extract vertices and indices
                        # This is simplified for now
                        shapes.append(shape_data)
        
        return shapes

func _convert_shape_to_data(shape: Shape3D) -> CollisionShapeData:
        var shape_data = CollisionShapeData.new()
        
        if shape is BoxShape3D:
                var box = shape as BoxShape3D
                shape_data.type = "box"
                shape_data.size = box.size
        elif shape is SphereShape3D:
                var sphere = shape as SphereShape3D
                shape_data.type = "sphere"
                shape_data.radius = sphere.radius
        elif shape is CapsuleShape3D:
                var capsule = shape as CapsuleShape3D
                shape_data.type = "capsule"
                shape_data.radius = capsule.radius
                shape_data.height = capsule.height
        elif shape is ConvexPolygonShape3D:
                var convex = shape as ConvexPolygonShape3D
                shape_data.type = "convex"
                shape_data.vertices = convex.points
        elif shape is ConcavePolygonShape3D:
                var concave = shape as ConcavePolygonShape3D
                shape_data.type = "concave"
                # Convert faces to vertices and indices
                _extract_mesh_data_from_faces(concave.faces, shape_data)
        else:
                shape_data.type = "unknown"
        
        return shape_data

func _extract_mesh_data_from_faces(faces: PackedVector3Array, shape_data: CollisionShapeData):
        # Convert triangle faces to vertices and indices
        shape_data.vertices = faces
        shape_data.indices = PackedInt32Array()
        
        # Generate indices (simple sequential indexing for triangles)
        for i in range(faces.size()):
                shape_data.indices.append(i)

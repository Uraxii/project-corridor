@tool
extends RefCounted
class_name CollisionExporter

# Export scene collision data to JSON format
func export_to_json(scene_data: CollisionParser.SceneCollisionData, file_path: String) -> bool:
        var json_data = _convert_to_json_dict(scene_data)
        
        var json_string = JSON.stringify(json_data, "\t")
        
        var file = FileAccess.open(file_path, FileAccess.WRITE)
        if file == null:
                print("Error: Could not open file for writing: ", file_path)
                return false
        
        file.store_string(json_string)
        file.close()
        
        print("Exported collision data to: ", file_path)
        return true

func _convert_to_json_dict(scene_data: CollisionParser.SceneCollisionData) -> Dictionary:
        var json_dict = {
                "scene_name": scene_data.scene_name,
                "scene_path": scene_data.scene_path,
                "timestamp": Time.get_unix_time_from_system(),
                "nodes": [],
                "static_objects": [],
                "dynamic_objects": []
        }
        
        # Convert all nodes
        for node_data in scene_data.nodes:
                json_dict.nodes.append(_convert_node_to_dict(node_data))
        
        # Convert static objects
        for node_data in scene_data.static_objects:
                json_dict.static_objects.append(_convert_node_to_dict(node_data))
        
        # Convert dynamic objects  
        for node_data in scene_data.dynamic_objects:
                json_dict.dynamic_objects.append(_convert_node_to_dict(node_data))
        
        return json_dict

func _convert_node_to_dict(node_data: CollisionParser.CollisionNodeData) -> Dictionary:
        var node_dict = {
                "name": node_data.name,
                "type": node_data.type,
                "is_static": node_data.is_static,
                "collision_layer": node_data.collision_layer,
                "collision_mask": node_data.collision_mask,
                "transform": {
                        "position": _vector3_to_dict(node_data.transform.origin),
                        "rotation": _vector3_to_dict(node_data.transform.basis.get_euler()),
                        "scale": _vector3_to_dict(node_data.transform.basis.get_scale())
                },
                "aabb": {
                        "position": _vector3_to_dict(node_data.aabb.position),
                        "size": _vector3_to_dict(node_data.aabb.size),
                        "center": _vector3_to_dict(node_data.aabb.get_center()),
                        "end": _vector3_to_dict(node_data.aabb.end)
                },
                "mesh_path": node_data.mesh_path,
                "collision_shapes": []
        }
        
        # Convert collision shapes
        for shape_data in node_data.collision_shapes:
                node_dict.collision_shapes.append(_convert_shape_to_dict(shape_data))
        
        return node_dict

func _convert_shape_to_dict(shape_data: CollisionParser.CollisionShapeData) -> Dictionary:
        var shape_dict = {
                "type": shape_data.type
        }
        
        match shape_data.type:
                "box":
                        shape_dict.size = _vector3_to_dict(shape_data.size)
                "sphere":
                        shape_dict.radius = shape_data.radius
                "capsule":
                        shape_dict.radius = shape_data.radius
                        shape_dict.height = shape_data.height
                "convex", "concave", "mesh":
                        if shape_data.vertices.size() > 0:
                                shape_dict.vertices = _vector3_array_to_array(shape_data.vertices)
                        if shape_data.indices.size() > 0:
                                shape_dict.indices = Array(shape_data.indices)

        return shape_dict

func _vector3_to_dict(vec: Vector3) -> Dictionary:
        return {"x": vec.x, "y": vec.y, "z": vec.z}

func _vector3_array_to_array(vertices: PackedVector3Array) -> Array:
        var result = []
        for vertex in vertices:
                result.append(_vector3_to_dict(vertex))
        return result

# Export to binary format for efficient server loading
func export_to_binary(scene_data: CollisionParser.SceneCollisionData, file_path: String) -> bool:
        # TODO: Implement binary export similar to protobuf serialization
        print("Binary export not yet implemented")
        return false

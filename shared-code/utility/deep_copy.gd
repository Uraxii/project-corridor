class_name DeepCopy extends RefCounted


# Internal copy function that handles the actual copying
static func copy_object(obj, context: Dictionary = {}):
    # Handle null
    if obj == null:
        return null

    # Handle already copied objects (prevents infinite recursion with circular references)
    if obj is Object and obj in context:
        return context[obj]

    # Handle primitive types (which are already copied by value)
    if not (obj is Object) and not (obj is Array) and not (obj is Dictionary):
        return obj
    
    # Use built-in methods where available
    
    # Arrays have duplicate() which can perform deep copy
    if obj is Array:
        return obj.duplicate(true)
        
    # Dictionaries have duplicate() which can perform deep copy
    elif obj is Dictionary:
        return obj.duplicate(true)
        
    # Resources have duplicate() which can perform deep copy when true is passed
    elif obj is Resource:
        return obj.duplicate(true)
        
    # Custom objects
    elif obj is Object:
        var copy = _deep_copy_object(obj, context)
        if obj is Object:
            context[obj] = copy
        return copy

    # Something went wrong, return null
    return null


# Deep copy an object
static func _deep_copy_object(obj, context):
    # If object has its own deep_copy method, use that
    if obj.has_method("deep_copy"):
        return obj.deep_copy()
    
    # Special case for nodes
    if obj is Node:
        return _copy_node(obj, context)
    
    # Otherwise create a new instance and copy all properties
    if obj.get_script() == null:
        push_error("Cannot deep copy object without script: " + str(obj))
        return null
        
    var copy = obj.get_script().new()
    
    # Get all properties of this object
    var properties = obj.get_property_list()
    
    for prop in properties:
        # Skip built-in properties and methods
        if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
            continue
            
        var prop_name = prop.name
        var value = obj.get(prop_name)
        
        # Use the copy function recursively for the value
        copy.set(prop_name, copy_object(value, context))
    
    return copy


# Specialized function for deep copying a node without children
static func _copy_node(node, context):
    if node == null:
        return null
        
    # Create instance of same type
    var copy = node.duplicate(false)  # Don't duplicate children
    
    # Copy script properties (not handled by duplicate)
    if node.get_script():
        var properties = node.get_property_list()
        
        for prop in properties:
            # Only copy script variables
            if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                var prop_name = prop.name
                var value = node.get(prop_name)
                
                # Use the copy function recursively for the value
                copy.set(prop_name, copy_object(value, context))
    
    return copy


# Public function to copy a node with all its children
static func copy_node(node, include_children = true):
    var context = {}  # Create a new tracking context for this copy operation
    
    # First duplicate the node structure
    var result = node.duplicate(include_children)
    
    # Then handle script variables which aren't automatically copied by duplicate()
    if node.get_script():
        _copy_script_properties(node, result, context)
    
    # If we're including children, handle their script properties too
    if include_children:
        var source_children = node.get_children()
        var result_children = result.get_children()
        
        for i in range(source_children.size()):
            if i < result_children.size() and source_children[i].get_script():
                _copy_script_properties(source_children[i], result_children[i], context)
    
    return result


# Helper to copy script properties between nodes
static func _copy_script_properties(source, target, context):
    var properties = source.get_property_list()
    
    for prop in properties:
        if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
            var prop_name = prop.name
            var value = source.get(prop_name)
            
            # Use deep copy for the value
            target.set(prop_name, copy_object(value, context))


# Utility function for copying multiple objects at once while maintaining references between them
static func copy_multiple(objects):
    var context = {}  # Shared context for all objects in this batch
    var results = []
    
    for obj in objects:
        results.append(copy_object(obj, context))
    
    return results

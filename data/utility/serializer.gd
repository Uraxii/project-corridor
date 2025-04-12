class_name Serializer

# Name:
#       Serialize
# Description:
#       Serializes an object into a Dictionary that can be sent over the network.
# Input:
#       - obj (Object): Object to serialize.
#       - schema (Dictionary[String, int]): properties to serialize from obj.
#                       - Key (String) = The property name.
#                       - Value (int) = The Varient.Type that the property should be.
# Output:
#       - Success: Dictionary containing property names and their values (serialized obj).
#       - Failues: An empty Dictionay (i.e. {} )
static func serialize(obj: Object, schema: Dictionary[String, int]) -> Dictionary:
        var dict = {}

        if not obj:
                Logger.error("Serialization failed! Returning an empty Dictionary.")
                return dict

        if not schema or schema.size() == 0:
                Logger.error("Serialization failed! schema array is null or size == 0! Returning an empty Dictionary.")
                return dict

        for property in schema.keys():
                var value = obj.get(property)

                if not value:
                        Logger.error("Did not find property when serializing Object! Please ensure the property names in the schema are up to date.", {"bad property":property,"schema":schema})
                        return {}

                if typeof(value) != schema[property]:
                        Logger.error("Serialization failed! Found property, but it is not the expected type!", {"property name": property,"expected": schema[property],"got":typeof(value),"value":value,"schema":schema})
                        return {}

                if value is Array or value is Dictionary:
                        dict[property] = value.duplicate()
                else:
                        dict[property] = value

        return dict


# Name:
#       Deserialize
# Desctiption:
#       Deserializes a serialized_data into an Object.
# Input:
#       - obj (Object): The Object to assign values of the serialized_data.
#       - schema (Dictionary[String, int]): The properties to deserialzie from serialized_data.
#               Note: Each property should key, value pair.
#                       - Key (String) = The property name.
#                       - Value (int) = The Varient.Type that the property is.
#       - serialized_data (Dictionary): Data to deserialize
# Output:
#       - Success: Deserialized object
#       - Failues: null
static func deserialize(
                obj: Object,
                schema: Dictionary[String, int],
                serialized_data: Dictionary
        ) -> Object:

        if not obj:
                Logger.error("Deserialization failed! Returning null.")
                return null

        if not schema or schema.size() == 0:
                Logger.error("Deserialization failed! schema dictionary ({ Property Name : Varient.Type }) is null or size == 0! Returning null.")
                return null

        for property in schema.keys():
                var value = serialized_data.get(property)

                if not value:
                        Logger.error("Property not found on object when peforming deserialization! Please ensure the values in your property array are up to date.", {"missing property":property, "schema":schema})
                        return null

                if typeof(value) != schema[property]:
                        Logger.error("Received property, but the type is incorrect.", {"property name":property,"expected":schema[property],"got":typeof(value),"schema":schema})
                        return null

                obj.set(property, value)

        return obj

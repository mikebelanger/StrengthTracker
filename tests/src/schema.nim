import jsonschema
import json

# Schema definitions
jsonSchema:
    Movement:
        name: string
        movement_plane: string

if isMainModule:

    let x = create(Movement, name = "stuff", movement_plane = "Horizontal")

    echo x.JsonNode
    echo x.JsonNode.isValid(Movement)
import allographer/query_builder
import json
import schema_validation
import create_database

# CREATE
proc create_movement*(input_json: JsonNode) =
    RDB().table("movement").insert(input_json)


if isMainModule:
    
    let some_json = parseJson("""{
        "name": "Pull-up",
        "movement_plane": "Horizontal"
    }
    """)

    echo some_json.is_a_valid(movement)
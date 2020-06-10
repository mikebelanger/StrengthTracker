import allographer/query_builder
import json
import schema_validation
import create_database
import strutils, strformat

# CREATE
proc create_movement*(input_json: JsonNode) =
    RDB().table("movement").insert(input_json)


if isMainModule:
    
    let some_json = parseJson("""{
        "name": "Pull-up",
        "movement_plane": "Horizontal",
        "movement_category": "Push",
        "body_area": "Toes",
        "movement_type": "Unilateral"
    }
    """)

    echo some_json{"movement_plane"}.getStr

    echo some_json.is_a_valid(movement)

    var insert_json = %*{ "name" : some_json{"name"} }

    for column in movement:

        if column.name.contains("_id"):
            
            let 
                real_name = column.name.replace("_id", "")
                thing = RDB().table(real_name)
                             .select("id")
                             .where("name", "=", some_json{real_name}.getStr).get()

            
            if thing.len == 1:
                var id = thing[0]{"id"}
                insert_json.add(key = column.name, val = %id)

    
    echo insert_json

    RDB().table("movement").insert(insert_json)
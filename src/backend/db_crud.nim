import allographer/[query_builder, schema_builder]
import json
import schema_validation
import create_database
import strutils

# HELPERS
proc get_foreign_keys(db_columns: openArray[Column], input_json, return_json: JsonNode, id_search_term = "_id"): JsonNode =
    
    for column in db_columns:

        if column.name.contains(id_search_term):
            
            let
                real_name = column.name.replace(id_search_term, "")
                thing = RDB().table(real_name)
                             .select("id")
                             .where("name", "=", input_json{real_name}.getStr).get()

            if thing.len == 1:
                var id = thing[0]{"id"}
                return_json.add(key = column.name, val = %id)

    return return_json

# CREATE
proc create_movement*(input_json: JsonNode) =

    if input_json.is_a_valid(movement):

        try:

            var to_insert = get_foreign_keys(db_columns = movement,
                                            input_json = input_json,
                                            return_json = %*{ "name" : input_json{"name"}})
                

            echo to_insert

            RDB().table("movement").insert(to_insert)

        except:
            echo getCurrentExceptionMsg()


if isMainModule:
    
    let some_json = parseJson("""{
        "name": "Double KB Overhead press",
        "movement_plane": "Vertical",
        "movement_category": "Push",
        "body_area": "Toes",
        "movement_type": "Bilateral"
    }
    """)

    create_movement(some_json)
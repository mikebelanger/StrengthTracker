import allographer/query_builder
import json
import ../app_types
import strutils

# HELPERS
proc get_foreign_key_for(table_name: string, named: string): JsonNode =

    var thing = RDB().table(table_name)
                     .select("id")
                     .where("name", "=", named)
                     .get()

    if thing.len == 1:
        var id = thing[0]{"id"}
        return %*id
    else:
        return %*""


proc get_foreign_keys(movement_params: Movement): JsonNode =

    result = %*{
        "name": movement_params.name,
        "movement_plane_id": get_foreign_key_for(table_name = "movement_plane", 
                                                  named = $movement_params.movement_plane),
        "body_area_id": get_foreign_key_for(table_name = "body_area",
                                            named = $movement_params.body_area),
        "movement_type_id": get_foreign_key_for(table_name = "movement_type",
                                                named = $movement_params.movement_type),
        "movement_category_id": get_foreign_key_for(table_name = "movement_category",
                                                    named = $movement_params.movement_category)
    }

proc get_name_from_id(table_name: string, id: int, name = "name"): JsonNode =

    # TODO: make this less assuming
    var query = RDB().table(table_name).select(name).find(id)

    if query.len == 1:
        result = query{name}
    else:
        result = parseJson("{}")

#####################
####### CREATE ######
#####################

proc db_insert*(input_movement: Movement): CRUDObject =

    let to_insert = input_movement.get_foreign_keys()
    RDB().table("movement").insert(to_insert)

    return CRUDObject(status: Complete)


proc db_insert*(movement_combo: MovementCombo): CRUDObject =
    
    # first create the movement in the database
    let
        to_insert = %*{
            "name": movement_combo.name
        }
        combo_id = RDB().table("movement_combo").insertID(to_insert)

    # now loop through each movement and add it, if it exists
    for movement in movement_combo.movements:
        var movement_id = get_foreign_key_for(table_name = "movement", named = movement)

        if movement_id.getInt > 0:

            # create movement assignment 
            RDB().table("movement_combo_assignment").insert(%*{
                "movement_id": movement_id,
                "movement_combo_id": combo_id    
            })
        
        else:
            return CRUDObject(status: Error, error: movement & " does not exist.")


    return CRUDObject(status: Complete)

########################
######## READ ##########
########################

proc db_read_row*(movement: Movement): CRUDObject =
    
    var 
        query_seq = RDB().table("movement")
                         .select("name", "movement_plane_id", "body_area_id", "movement_type_id", "movement_category_id")
                         .where("name", "=", movement.name)
                         .get()
        query_json = parseJson("{}")


    if query_seq.len == 1:

        try:

            query_json{"name"}= query_seq[0]{"name"}

            query_json{"movement_plane"} = get_name_from_id(table_name = "movement_plane",
                                                        id = query_seq[0]{"movement_plane_id"}.getInt)

            query_json{"body_area"}= get_name_from_id(table_name = "body_area",
                                                        id = query_seq[0]{"body_area_id"}.getInt)


            query_json{"movement_type"}= get_name_from_id(table_name = "movement_type",
                                                            id = query_seq[0]{"movement_type_id"}.getInt)

            query_json{"movement_category"}= get_name_from_id(table_name = "movement_category",
                                                                id = query_seq[0]{"movement_category_id"}.getInt)
            
            # this is for schema validation
            discard query_json.to(Movement)

            # if schema validates (object gets created successfully) then return that json
            return CRUDObject(status: Complete, error: "", content: query_json)

        except:

            return CRUDObject(status: Incomplete, error: getCurrentExceptionMsg())

    else:

        return CRUDObject(status: Error, error: "row with name: " & movement.name & " not found.", content: parseJson("{}"))


proc db_read_all_rows_for*(movement: Movement): CRUDObject =

    # first get names
    var 
        movement_names = RDB().table("movement").select("name").get()
        for_json: seq[JsonNode]

    for m in movement_names:
        var queried_movement = db_read_row(Movement(name: m{"name"}.getStr))

        if queried_movement.status == Complete:

            for_json.add(queried_movement.content)

    result.status = Complete
    result.content = %*for_json

if isMainModule:
    
    # let 
    #     some_json = parseJson("""{
    #         "name": "Barbell Shoulder Press",
    #         "movement_plane": "Vertical",
    #         "movement_category": "Push",
    #         "body_area": "Lower",
    #         "movement_type": "Bilateral",
    #         "status": "Incomplete",
    #         "error": ""
    #     }
    #     """)

    #     mv = some_json.to(Movement)
    
    # echo db_insert(mv)
    # discard RDB().table("movement").select("name")
    # let newMovementCombo = MovementCombo(name: "Workout: A - Pull-up + Split Squat", movements: @["Pull-up", "Step Up"])
    # echo db_insert(newMovementCombo)
    # var m = db_read_row(Movement(name : "Pull-Up"))
    # var x = db_read_row(Movement(name : "Step Up"))
    # echo %*m, %*x
    var all_movements = db_read_all_rows_for(Movement())
    echo all_movements
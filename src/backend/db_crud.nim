import allographer/query_builder
import json
import ../app_types
import strutils
import sequtils

type
    QueryResult = enum
        Empty, One, Many

proc kind_of_result(input: seq[JsonNode] | JsonNode): QueryResult =
    case input.len:
        of 0: result = Empty
        of 1: result = One
        else: result = Many

proc get_id(input: JsonNode): int =
    try:
        result = input.getInt
    except:
        result = -1

# HELPERS
proc get_foreign_key_for(table_name: string, named: string): JsonNode =

    var 
        query = RDB().table(table_name)
                     .select("id")
                     .where("name", "=", named)
                     .get()

    case query.kind_of_result: 
        of Empty: result = %*""
        else: result = query[0]


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

    case query.kind_of_result:
        of One: result = query{name}
        else: result = parseJson("{}")

#####################
####### CREATE ######
#####################

proc db_insert*(input_movement: Movement): CRUDObject =

    let to_insert = input_movement.get_foreign_keys()
    RDB().table("movement").insert(to_insert)

    return CRUDObject(status: Complete, error: "", content: parseJson("{}"))


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

proc db_read*(movement: Movement): CRUDObject =
    
    var query_seq = RDB().table("movement")
                         .select("name", "movement_plane_id", "body_area_id", "movement_type_id", "movement_category_id")
                         .where("name", "=", movement.name)
                         .get()

    case query_seq.kind_of_result:

        of One:

            var query_json = parseJson("{}")

            try:

                query_json{"name"}= query_seq[0]{"name"}

                query_json{"movement_plane"} = get_name_from_id(table_name = "movement_plane",
                                                            id = query_seq[0]{"movement_plane_id"}.get_id)

                query_json{"body_area"}= get_name_from_id(table_name = "body_area",
                                                            id = query_seq[0]{"body_area_id"}.get_id)


                query_json{"movement_type"}= get_name_from_id(table_name = "movement_type",
                                                                id = query_seq[0]{"movement_type_id"}.get_id)

                query_json{"movement_category"}= get_name_from_id(table_name = "movement_category",
                                                                    id = query_seq[0]{"movement_category_id"}.get_id)
                
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
        var queried_movement = db_read(Movement(name: m{"name"}.getStr))

        if queried_movement.status == Complete:

            for_json.add(queried_movement.content)

    result.status = Complete
    result.content = %*for_json


proc db_read*(movement_combo: MovementCombo): CRUDObject =

    var 
        movement_combo_id = get_foreign_key_for(table_name = "movement_combo", named = movement_combo.name)
        these_movement_combo_assignments = 

                      RDB().table("movement_combo_assignment")
                           .select("id", "movement_id", "movement_combo_id")
                           .where("movement_combo_id", "=", movement_combo_id.getInt)
                           .get()
        
        # make sure we have them all
        all_assignments_exist = these_movement_combo_assignments.mapIt(it.get_id)
                                                                .allIt(it > 0)

    
    if all_assignments_exist:

        echo "true"
    
    else:
        echo "false"



    

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
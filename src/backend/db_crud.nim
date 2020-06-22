import allographer/query_builder
import json
import ../app_types

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

# # CREATE
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

    echo $combo_id

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
    discard RDB().table("movement").select("name")
    let newMovementCombo = MovementCombo(name: "Workout: A - Pull-up + Split Squat", movements: @["Pull-up", "Step Up"])
    echo db_insert(newMovementCombo)
import ../app_types, database_schema
import allographer/query_builder
import json
import sequtils, strutils

#################
#### HELPERS ####
#################

proc exists*(i: int): bool =
    i > 0

proc all_good*(i: seq[int]): bool =
    if i.len == 0:
        return false
    
    else:
        for x in i:
            if x < 0:
                return false

        return true

proc worked*[T](i: seq[T]): bool =
    if i.len == 0:
        return false

    return true

proc all_true*(i: seq[bool]): bool =
    if i.len == 0:
        return false
    
    else:
        return i.allIt(it)

proc obj_to_json*(obj: object): JsonNode =
    %*obj

proc tuple_to_json*(tu: tuple): JsonNode =
    %*tu

proc movement_to_json*(m: NewMovement | ExistingMovement): JsonNode =
    obj_to_json(m)
    
# For some reason I can't override the `%*` template for tuples
proc to_json*(t: tuple): JsonNode =
    result = parseJson("{}")
    for key, val in t.fieldPairs:
        result{key}= %val

# convenience function for when querying an equals with an orWhere
proc query_matching_any*(table: RDB, criteria: tuple): RDB =

    result = table
        
    for each_property, content in criteria.fieldPairs:

        result = table.orWhere(each_property, "=", $content)

# convenience function for when querying an equals with a Where
proc query_matching_all*(table: RDB, criteria: tuple): RDB =
    
    result = table

    for each_property, content in criteria.fieldPairs:

        result = table.where(each_property, "=", $content)


proc db_connect*(data_table: DataTable): RDB =
    RDB().table($data_table).select()

proc interpretJson*(input: string): seq[JsonNode] =
    result = @[]
    try:
        let j = parseJson(input)
        result.add(j)
    except:
        echo getCurrentExceptionMsg()

proc is_complete*(x: object): bool =

    for key, val in x.fieldPairs:

        case key:
            of "Description":
                return true
            
            else:
                var value = $val
                if value.len == 0 or value.contains("Unspecified"):
                    return false

    return true


################
#### CREATE ####
################

proc db_create*(table: RDB, obj: object): int =

    result = table.insertID(%*obj)


proc db_create*(nmc: NewMovementCombo): ExistingMovementCombo =

    let movement_combo_table = MovementComboTable.db_connect
    var result = ExistingMovementCombo(
            name: nmc.name
        )

    try:
        result.id = movement_combo_table.db_create(nmc)

    except:
        echo getCurrentExceptionMsg()
    

proc db_create*(nmca: NewMovementComboAssignment): ExistingMovementComboAssignment =
    
    let 
        movement_combo_assignment_table = MovementComboAssignmentTable.db_connect
        to_insert = (movement_id: nmca.movement.id, movement_combo_id: nmca.movement_combo.id)
    
    var emca = ExistingMovementComboAssignment(movement: nmca.movement, movement_combo: nmca.movement_combo)
    
    try:
        result = emca
        result.id = movement_combo_assignment_table.db_create(emca)

    except:
        echo getCurrentExceptionMsg()

################
##### READ #####
################

proc db_read*(table: RDB): seq[JsonNode] =

    try:
        result = table.get()
    
    except:
        echo getCurrentExceptionMsg()
        result = @[parseJson("{}")]

################
#### UPDATE ####
################

proc db_update*(table: RDB, input: JsonNode): bool =
    try:
        table.update(input)
        result = true
    except:
        echo getCurrentExceptionMsg()
        result = false

################
#### DELETE ####
################

# if isMainModule:

#     let 
#         criteria = (
#             symmetry: Bilateral,
#             concentric_type: Push, 
#         )

    
#     var results = MovementTable.db_connect
#                                .query_matching_all(criteria)
#                                .select("name")
#                                .db_read
#     echo results
    # echo all
    # echo any.len, all.len

if isMainModule:

    let x = """
    { "stuf : erger' }
    """

    let y = """
    { "name" : "my fantastic movement" }
    """

    let movements_completed = 
    
        y.interpretJson.map(proc (j: JsonNode): NewMovement =
            try:
                result = j.to(NewMovement)
            except:
                echo getCurrentExceptionMsg()
        ).mapIt(it.is_complete)

    if movements_completed.all_true:
        echo "they work!"
    else:
        echo "They don't work"

    echo "but I got to the end of the program!!!"
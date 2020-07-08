import ../app_types
import allographer/query_builder
import json

#################
#### HELPERS ####
#################

converter exists*(i: int): bool =
    i > 0

converter all_good*(i: seq[int]): bool =
    if i.len == 0:
        return false
    
    else:
        for x in i:
            if x < 0:
                return false

        return true

proc obj_to_json*(obj: object): JsonNode =
    %*obj

proc tuple_to_json*(tu: tuple): JsonNode =
    %*tu

converter movement_to_json*(m: Movement | ExistingMovement): JsonNode =
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

################
#### CREATE ####
################

proc db_create*(table: RDB, obj: object): int =

    result = table.insertID(%*obj)

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
        return true
    except:
        echo getCurrentExceptionMsg()
        return false

################
#### DELETE ####
################

if isMainModule:

    # let x = MovementTable.db_read

    # for i in x:
    #     echo $x

    # let y = x.len

    # echo y
    # echo y is Positive
    let 
        criteria = (
            symmetry: Bilateral,
            concentric_type: Push, 
        )

    #     new_vals = (
    #         name: "Wide Ring Dips",
    #         area: Upper
    #     )

    #     any = MovementTable.db_connect
    #                        .matching_all(criteria)
    #                        .db_read
                                    
    # MovementTable.db_connect.select("id", "name", "concentric_type")
    #                       .matching_any((id: 4)).update(new_vals.to_json)
    
    var results = MovementTable.db_connect
                               .query_matching_all(criteria)
                               .select("name")
                               .db_read
    echo results
    # echo all
    # echo any.len, all.len